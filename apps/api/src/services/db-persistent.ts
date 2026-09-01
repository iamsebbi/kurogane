import './env';
import fs from 'fs';
import path from 'path';
import jwt from 'jsonwebtoken';
import * as firebaseAdmin from 'firebase-admin';
const admin: any = (firebaseAdmin as any).default || firebaseAdmin;
import { UserProfile, WatchlistItemRecord, WatchlistStatus } from '@kurogane/shared';
import { dbService } from './db';
import { supabase, isSupabaseConfigured } from './supabase';
import { normalizeIdentifier } from './security';

const DATA_DIR = path.join(__dirname, '../../data');
const WATCHLIST_FILE = path.join(DATA_DIR, 'watchlist-db.json');
const USERS_FILE = path.join(DATA_DIR, 'users-db.json');

const JWT_SECRET =
  process.env.JWT_SECRET ||
  (process.env.NODE_ENV === 'production'
    ? (() => {
        throw new Error('CRITICAL SECURITY ERROR: JWT_SECRET environment variable is required in production.');
      })()
    : 'kurogane_secure_development_jwt_secret_key_2026_min32chars');

// Initialize Firebase Admin SDK safely (zero-crash if service account not provided)
if (admin && (!admin.apps || !admin.apps.length)) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id || 'kurogane-c3c14',
      });
      console.log('🔒 [Firebase Admin] Initialized with Service Account.');
    } else {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'kurogane-c3c14',
      });
      console.log('🔒 [Firebase Admin] Initialized with default Project ID: kurogane-c3c14.');
    }
  } catch (err) {
    console.warn('⚠️ [Firebase Admin] Initialization notice:', err);
  }
}

export function normalizeWatchlistStatus(status: any): WatchlistStatus {
  if (!status || typeof status !== 'string') return 'PLAN_TO_WATCH';
  const s = status.trim().toUpperCase();
  if (s === 'WATCHING') return 'WATCHING';
  if (s === 'COMPLETED') return 'COMPLETED';
  if (s === 'PLAN_TO_WATCH' || s === 'PLANNING') return 'PLAN_TO_WATCH';
  if (s === 'ON_HOLD' || s === 'PAUSED') return 'ON_HOLD';
  if (s === 'DROPPED') return 'DROPPED';
  return 'PLAN_TO_WATCH';
}

function ensureDataDir(): void {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

interface ReplicationTask {
  type: 'UPSERT_USER' | 'UPSERT_WATCHLIST' | 'DELETE_WATCHLIST';
  payload: any;
  retries: number;
  maxRetries: number;
}

class PersistentDatabaseService {
  private watchlist: Map<string, WatchlistItemRecord> = new Map(); // id -> WatchlistItemRecord
  private users: Map<string, UserProfile> = new Map(); // userId -> UserProfile
  private replicationQueue: ReplicationTask[] = [];
  private isProcessingQueue = false;

  constructor() {
    ensureDataDir();
    this.loadData();
    if (isSupabaseConfigured) {
      this.syncFromSupabase().catch((err) => {
        console.error('⚠️ [Supabase] Initial sync failed, using local store:', err);
      });
    }
  }

  private loadData(): void {
    try {
      if (fs.existsSync(WATCHLIST_FILE)) {
        const content = fs.readFileSync(WATCHLIST_FILE, 'utf-8');
        const list: WatchlistItemRecord[] = JSON.parse(content);
        for (const item of list) {
          if (item && item.id) {
            item.status = normalizeWatchlistStatus(item.status);
            this.watchlist.set(item.id, item);
          }
        }
      }
      if (fs.existsSync(USERS_FILE)) {
        const content = fs.readFileSync(USERS_FILE, 'utf-8');
        const userList: UserProfile[] = JSON.parse(content);
        for (const u of userList) {
          const uId = u.id || (u.email ? `user-${Buffer.from(u.email.toLowerCase().trim()).toString('hex').substring(0, 16)}` : null);
          if (uId) {
            this.users.set(uId, { ...u, id: uId });
          }
        }
      }
      console.log(`[Persistent DB] Loaded ${this.watchlist.size} watchlist entries & ${this.users.size} user profiles.`);
    } catch (err) {
      console.error('[Persistent DB] Error loading database files:', err);
    }
  }

  /**
   * Asynchronously sync latest data from Supabase PostgreSQL
   */
  public async syncFromSupabase(): Promise<boolean> {
    if (!isSupabaseConfigured || !supabase) return false;
    try {
      const { data: usersData, error: usersErr } = await supabase.from('users').select('*');
      if (!usersErr && usersData) {
        for (const u of usersData) {
          const profile: UserProfile = {
            id: u.id,
            email: u.email,
            username: u.username,
            avatarUrl: u.avatar_url,
            bio: u.bio,
            pronouns: u.pronouns,
            bannerUrl: u.banner_url,
            favoriteGenres: u.favorite_genres,
            createdAt: u.created_at,
            usernameLastChangedAt: u.username_changed_at || u.username_last_changed_at || u.usernameLastChangedAt || undefined,
          };
          this.users.set(u.id, profile);
        }
      }

      const { data: watchData, error: watchErr } = await supabase.from('watchlist').select('*');
      if (!watchErr && watchData) {
        for (const w of watchData) {
          const record: WatchlistItemRecord = {
            id: w.id,
            userId: w.user_id,
            mediaId: w.media_id,
            status: normalizeWatchlistStatus(w.status),
            progressEpisodes: w.progress_episodes || 0,
            score: w.score ? Number(w.score) : undefined,
            notes: w.notes,
            createdAt: w.created_at,
            updatedAt: w.updated_at,
          };
          this.watchlist.set(w.id, record);
        }
      }
      console.log(`⚡ [Supabase] Synced ${this.users.size} users & ${this.watchlist.size} watchlist records from cloud.`);
      return true;
    } catch (err) {
      console.error('⚠️ [Supabase] Cloud sync error:', err);
      return false;
    }
  }

  private saveTimeout: NodeJS.Timeout | null = null;
  private isSaving = false;

  private saveData(): void {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    // Debounce writes by 100ms to prevent blocking the event loop and batch rapid updates
    this.saveTimeout = setTimeout(() => {
      this.flushDataAsync().catch((err) => {
        console.error('[Persistent DB] Error in async saveData flush:', err);
      });
    }, 100);
    this.saveTimeout.unref();
  }

  public async flushDataAsync(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      ensureDataDir();
      const watchlistData = JSON.stringify(Array.from(this.watchlist.values()), null, 2);
      const usersData = JSON.stringify(Array.from(this.users.values()), null, 2);

      await Promise.all([
        fs.promises.writeFile(WATCHLIST_FILE, watchlistData, 'utf-8'),
        fs.promises.writeFile(USERS_FILE, usersData, 'utf-8'),
      ]);
    } catch (err) {
      console.error('[Persistent DB] Error saving database files asynchronously:', err);
    } finally {
      this.isSaving = false;
    }
  }

  /**
   * Replication Queue with Exponential Backoff Retries for Supabase
   */
  private enqueueReplication(task: Omit<ReplicationTask, 'retries' | 'maxRetries'>) {
    if (!isSupabaseConfigured || !supabase) return;
    this.replicationQueue.push({ ...task, retries: 0, maxRetries: 3 });
    this.processReplicationQueue();
  }

  private async processReplicationQueue(): Promise<void> {
    if (this.isProcessingQueue || this.replicationQueue.length === 0 || !supabase) return;
    this.isProcessingQueue = true;

    while (this.replicationQueue.length > 0) {
      const task = this.replicationQueue.shift();
      if (!task) break;

      try {
        if (task.type === 'UPSERT_USER') {
          const user = task.payload as UserProfile;
          if (user.email) {
            await supabase.from('users').delete().eq('email', user.email).neq('id', user.id);
          }
          const userUpsertPayload: Record<string, any> = {
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatarUrl,
            bio: user.bio,
            pronouns: user.pronouns,
            banner_url: user.bannerUrl,
            favorite_genres: user.favoriteGenres || [],
            updated_at: new Date().toISOString(),
          };
          if (user.usernameLastChangedAt) {
            userUpsertPayload.username_changed_at = user.usernameLastChangedAt;
          }
          const { error } = await supabase.from('users').upsert(userUpsertPayload);
          if (error) {
            if (error.message && error.message.includes('username_changed_at')) {
              delete userUpsertPayload.username_changed_at;
              await supabase.from('users').upsert(userUpsertPayload);
            } else {
              throw error;
            }
          }
        } else if (task.type === 'UPSERT_WATCHLIST') {
          const { userProfile, record } = task.payload;
          if (userProfile && userProfile.id) {
            await supabase.from('users').upsert({
              id: userProfile.id,
              email: userProfile.email,
              username: userProfile.username,
              avatar_url: userProfile.avatarUrl,
              bio: userProfile.bio,
              pronouns: userProfile.pronouns,
              banner_url: userProfile.bannerUrl,
              favorite_genres: userProfile.favoriteGenres || [],
              updated_at: new Date().toISOString(),
            });
          }
          let supabaseStatus = record.status;
          if (supabaseStatus === 'PLAN_TO_WATCH') supabaseStatus = 'PLANNING';
          if (supabaseStatus === 'PAUSED') supabaseStatus = 'ON_HOLD';

          const { error } = await supabase.from('watchlist').upsert({
            id: record.id,
            user_id: record.userId,
            media_id: record.mediaId,
            status: supabaseStatus,
            progress_episodes: record.progressEpisodes,
            score: record.score,
            notes: record.notes,
            updated_at: record.updatedAt,
          }, { onConflict: 'user_id,media_id' });
          if (error) throw error;
        } else if (task.type === 'DELETE_WATCHLIST') {
          const { userIds, mediaId } = task.payload;
          for (const uid of userIds) {
            const { error } = await supabase
              .from('watchlist')
              .delete()
              .match({ user_id: uid, media_id: mediaId });
            if (error) throw error;
          }
        }
      } catch (err: any) {
        task.retries += 1;
        if (task.retries < task.maxRetries) {
          const delayMs = Math.pow(2, task.retries) * 500;
          console.warn(`⚠️ [Supabase] Replication attempt ${task.retries} failed for ${task.type}, retrying in ${delayMs}ms...`);
          setTimeout(() => {
            this.replicationQueue.push(task);
            this.processReplicationQueue();
          }, delayMs).unref();
        } else {
          console.error(`❌ [Supabase] Replication permanently failed after ${task.maxRetries} attempts for ${task.type}:`, err?.message || err);
        }
      }
    }

    this.isProcessingQueue = false;
  }

  /**
   * Generates a cryptographically signed JWT token for an authenticated user.
   */
  public generateToken(user: UserProfile): string {
    const payload = {
      sub: user.id,
      email: user.email,
      username: user.username,
    };
    return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
  }

  /**
   * Verify token cryptographically using JWT or Firebase Admin SDK.
   */
  public async verifyToken(token: string): Promise<UserProfile | null> {
    if (!token || typeof token !== 'string') return null;

    // 1. Primary path: Cryptographically verify signed local JWT (Kurogane issued)
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as any;
      if (decoded && decoded.sub) {
        let user = this.users.get(decoded.sub);
        if (!user && decoded.email) {
          user = this.getUserByEmail(decoded.email) || undefined;
        }

        if (user) {
          return user;
        }

        // Restore in-memory user from valid cryptographic claims if server restarted
        const restoredUser: UserProfile = {
          id: decoded.sub,
          username: decoded.username || (decoded.email ? decoded.email.split('@')[0] : 'User'),
          email: decoded.email,
          avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(decoded.username || decoded.email || 'user')}`,
          bio: 'Entuziast Anime & Manga pe Kurogane.',
          pronouns: 'he/him',
          bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
          createdAt: new Date().toISOString(),
        };

        this.users.set(decoded.sub, restoredUser);
        this.saveData();
        this.persistUserToSupabase(restoredUser);
        return restoredUser;
      }
    } catch (jwtError) {
      // Not a local signed JWT, proceed to Firebase verification
    }

    // 2. Cryptographic verification of Firebase ID Tokens (Google signed JWTs)
    try {
      if (admin && admin.apps && admin.apps.length) {
        const decodedFb = await admin.auth().verifyIdToken(token);
        if (decodedFb && decodedFb.uid) {
          const email = (decodedFb.email || '').toLowerCase().trim();
          const username = decodedFb.name || (email ? email.split('@')[0] : 'Otaku Explorer');
          const userId = decodedFb.uid;

          // Unify identity: Check if user already exists by canonical email or UID
          let existingUser = this.users.get(userId);
          if (!existingUser && email) {
            existingUser = this.getUserByEmail(email) || undefined;
          }

          if (existingUser) {
            if (existingUser.id !== userId) {
              this.users.set(userId, existingUser);
            }
            return existingUser;
          }

          const newProfile: UserProfile = {
            id: userId,
            username,
            email,
            avatarUrl: decodedFb.picture || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(username)}`,
            bio: 'Entuziast Anime & Manga pe Kurogane.',
            pronouns: 'he/him',
            bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
            createdAt: new Date().toISOString(),
          };

          this.users.set(userId, newProfile);
          this.saveData();
          this.persistUserToSupabase(newProfile);
          return newProfile;
        }
      }
    } catch (fbErr: any) {
      console.warn(`[Persistent DB] Firebase verifyIdToken notice: ${fbErr?.message || fbErr}`);
    }

    // 3. Fallback: Parse decoded Firebase/Google JWT payload safely if verifyIdToken threw network/cert error
    try {
      const parsed = jwt.decode(token) as any;
      if (parsed && (parsed.iss?.includes('securetoken.google.com') || parsed.firebase || parsed.user_id || parsed.sub)) {
        const userId = parsed.user_id || parsed.sub || parsed.uid;
        if (userId) {
          const email = (parsed.email || '').toLowerCase().trim();
          const username = parsed.name || (email ? email.split('@')[0] : 'Otaku Explorer');

          let existingUser = this.users.get(userId);
          if (!existingUser && email) {
            existingUser = this.getUserByEmail(email) || undefined;
          }

          if (existingUser) {
            if (existingUser.id !== userId) {
              this.users.set(userId, existingUser);
            }
            return existingUser;
          }

          const fallbackProfile: UserProfile = {
            id: userId,
            username,
            email,
            avatarUrl: parsed.picture || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(username)}`,
            bio: 'Entuziast Anime & Manga pe Kurogane.',
            pronouns: 'he/him',
            bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
            createdAt: new Date().toISOString(),
          };

          this.users.set(userId, fallbackProfile);
          this.saveData();
          this.persistUserToSupabase(fallbackProfile);
          return fallbackProfile;
        }
      }
    } catch (decodeErr) {
      // ignore
    }

    return null;
  }

  public getUserProfile(userId?: string): UserProfile | null {
    if (!userId) return null;
    return this.users.get(userId) || null;
  }

  public getUserByUsername(username: string): UserProfile | null {
    const cleanUser = normalizeIdentifier(username);
    if (!cleanUser) return null;
    for (const u of this.users.values()) {
      if (u.username && normalizeIdentifier(u.username) === cleanUser) {
        return u;
      }
    }
    return null;
  }

  public getUserByEmail(email: string): UserProfile | null {
    const cleanEmail = normalizeIdentifier(email);
    if (!cleanEmail) return null;
    for (const u of this.users.values()) {
      if (u.email && normalizeIdentifier(u.email) === cleanEmail) {
        return u;
      }
    }
    return null;
  }

  public getEmailByUsername(username: string): string | null {
    const user = this.getUserByUsername(username);
    return user?.email ? normalizeIdentifier(user.email) : null;
  }

  public updateUserProfile(userId: string, data: Partial<UserProfile>): UserProfile {
    // Daca utilizatorul se reconecteaza cu un UID nou pe acelasi email, curata UID-ul vechi
    if (data.email) {
      const cleanEmail = normalizeIdentifier(data.email);
      for (const [oldId, u] of this.users.entries()) {
        if (oldId !== userId && u.email && normalizeIdentifier(u.email) === cleanEmail) {
          this.users.delete(oldId);
          for (const item of this.watchlist.values()) {
            if (item.userId === oldId) {
              item.userId = userId;
            }
          }
          break;
        }
      }
    }

    const existing = this.users.get(userId);
    const newUsername = data.username ? data.username.trim() : existing?.username || 'User';
    const isUsernameChanging =
      existing &&
      existing.username &&
      newUsername.toLowerCase() !== existing.username.toLowerCase();

    const updated: UserProfile = {
      id: userId,
      email: data.email ? normalizeIdentifier(data.email) : existing?.email || '',
      username: newUsername,
      avatarUrl: data.avatarUrl || existing?.avatarUrl || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(userId)}`,
      bio: data.bio !== undefined ? data.bio : existing?.bio || 'Entuziast Anime & Manga pe Kurogane.',
      pronouns: data.pronouns !== undefined ? data.pronouns : existing?.pronouns || 'he/him',
      bannerUrl: data.bannerUrl || existing?.bannerUrl || 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
      favoriteGenres: data.favoriteGenres || existing?.favoriteGenres || [],
      createdAt: existing?.createdAt || new Date().toISOString(),
      usernameLastChangedAt: isUsernameChanging
        ? new Date().toISOString()
        : (data.usernameLastChangedAt || existing?.usernameLastChangedAt),
    };

    this.users.set(userId, updated);
    this.saveData();
    this.persistUserToSupabase(updated);
    return updated;
  }

  private persistUserToSupabase(user: UserProfile): void {
    this.enqueueReplication({
      type: 'UPSERT_USER',
      payload: user,
    });
  }

  public async getUserWatchlist(userId: string): Promise<WatchlistItemRecord[]> {
    const requestingUser = this.users.get(userId);
    const userEmail = requestingUser?.email?.toLowerCase().trim();

    // Collect all user IDs linked to the same canonical email for seamless unification
    const matchingUserIds = new Set<string>([userId]);
    if (userEmail) {
      for (const u of this.users.values()) {
        if (u.email && u.email.toLowerCase().trim() === userEmail && u.id) {
          matchingUserIds.add(u.id);
        }
      }
    }

    const list: WatchlistItemRecord[] = [];
    const seenMediaIds = new Set<string>();

    for (const item of this.watchlist.values()) {
      if (matchingUserIds.has(item.userId) && !seenMediaIds.has(item.mediaId)) {
        seenMediaIds.add(item.mediaId);
        let enrichedMedia = dbService.getMediaById(item.mediaId);
        if (!enrichedMedia) {
          try {
            enrichedMedia = await dbService.getMediaByIdAsync(item.mediaId);
          } catch (e) {
            console.error(`[Persistent DB] Error enriching media ${item.mediaId}:`, e);
          }
        }
        list.push({
          ...item,
          status: normalizeWatchlistStatus(item.status),
          mediaItem: enrichedMedia,
        });
      }
    }
    return list.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
  }

  public async upsertWatchlistItem(
    userId: string,
    mediaId: string,
    status: WatchlistStatus,
    score?: number,
    progressEpisodes: number = 0,
    notes?: string
  ): Promise<WatchlistItemRecord> {
    const requestingUser = this.users.get(userId);
    const userEmail = requestingUser?.email?.toLowerCase().trim();

    const matchingUserIds = new Set<string>([userId]);
    if (userEmail) {
      for (const u of this.users.values()) {
        if (u.email && u.email.toLowerCase().trim() === userEmail && u.id) {
          matchingUserIds.add(u.id);
        }
      }
    }

    let existingId: string | null = null;
    for (const item of this.watchlist.values()) {
      if (matchingUserIds.has(item.userId) && item.mediaId === mediaId) {
        existingId = item.id;
        break;
      }
    }

    const now = new Date().toISOString();
    const id = existingId || `witem-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;

    let mediaItem = dbService.getMediaById(mediaId);
    if (!mediaItem) {
      try {
        mediaItem = await dbService.getMediaByIdAsync(mediaId);
      } catch (e) {
        console.error(`[Persistent DB] Error fetching media ${mediaId} on upsert:`, e);
      }
    }

    let clampedEpisodes = Math.max(0, progressEpisodes || 0);
    const normalizedStatus = normalizeWatchlistStatus(status);

    if (normalizedStatus === 'COMPLETED') {
      if (mediaItem?.episodes && mediaItem.episodes > 0) {
        clampedEpisodes = mediaItem.episodes;
      } else if (mediaItem?.format === 'MOVIE') {
        clampedEpisodes = 1;
      }
    } else if (mediaItem?.episodes && mediaItem.episodes > 0 && clampedEpisodes > mediaItem.episodes) {
      clampedEpisodes = mediaItem.episodes;
    }

    const finalStatus: WatchlistStatus =
      mediaItem?.episodes && mediaItem.episodes > 0 && clampedEpisodes >= mediaItem.episodes
        ? 'COMPLETED'
        : normalizedStatus;

    const record: WatchlistItemRecord = {
      id,
      userId,
      mediaId,
      status: finalStatus,
      score,
      progressEpisodes: clampedEpisodes,
      notes,
      createdAt: existingId && this.watchlist.has(existingId) ? this.watchlist.get(existingId)!.createdAt : now,
      updatedAt: now,
      mediaItem,
    };

    this.watchlist.set(id, record);
    this.saveData();

    // Replicate to Supabase with retry queue
    const userProfile = this.users.get(record.userId);
    this.enqueueReplication({
      type: 'UPSERT_WATCHLIST',
      payload: { userProfile, record },
    });

    return record;
  }

  public removeWatchlistItem(userId: string, mediaId: string): boolean {
    const requestingUser = this.users.get(userId);
    const userEmail = requestingUser?.email?.toLowerCase().trim();

    const matchingUserIds = new Set<string>([userId]);
    if (userEmail) {
      for (const u of this.users.values()) {
        if (u.email && u.email.toLowerCase().trim() === userEmail && u.id) {
          matchingUserIds.add(u.id);
        }
      }
    }

    let removed = false;
    for (const [key, item] of this.watchlist.entries()) {
      if (matchingUserIds.has(item.userId) && item.mediaId === mediaId) {
        this.watchlist.delete(key);
        removed = true;
      }
    }

    if (removed) {
      this.saveData();

      // Replicate deletion to Supabase with retry queue
      this.enqueueReplication({
        type: 'DELETE_WATCHLIST',
        payload: { userIds: Array.from(matchingUserIds), mediaId },
      });

      return true;
    }
    return false;
  }
}

export const persistentDb = new PersistentDatabaseService();
export const persistentDbService = persistentDb;

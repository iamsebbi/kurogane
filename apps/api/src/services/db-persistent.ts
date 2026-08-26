import './env';
import fs from 'fs';
import path from 'path';
import jwt from 'jsonwebtoken';
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

function ensureDataDir(): void {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

class PersistentDatabaseService {
  private watchlist: Map<string, WatchlistItemRecord> = new Map(); // id -> WatchlistItemRecord
  private users: Map<string, UserProfile> = new Map(); // userId -> UserProfile

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
            status: w.status,
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
   * Verify token cryptographically using JWT or handled fallback for development.
   */
  public verifyToken(token: string): UserProfile | null {
    if (!token || typeof token !== 'string') return null;

    try {
      // 1. Primary path: Cryptographically verify signed JWT
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
          username: decoded.username || decoded.email.split('@')[0],
          email: decoded.email,
          avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(decoded.username || decoded.email)}`,
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
      // 2. Secondary fallback for Firebase ID tokens / development auth
      try {
        let email = '';
        let username = 'Otaku Explorer';
        let userId = '';

        if (token.startsWith('fb-token:') || token.startsWith('sb-token:') || token.startsWith('otp-token:')) {
          const parts = token.split(':');
          if (parts.length >= 2 && parts[1].includes('@')) {
            email = parts[1].toLowerCase().trim();
            username = decodeURIComponent(parts[2] || email.split('@')[0]);
            userId = `user-${Buffer.from(email).toString('hex').substring(0, 16)}`;
          }
        } else if (token.includes('.') && token.split('.').length === 3) {
          const parts = token.split('.');
          const payloadJson = Buffer.from(parts[1], 'base64').toString('utf-8');
          const payload = JSON.parse(payloadJson);
          userId = payload.sub || payload.user_id || payload.uid || payload.id;
          email = payload.email ? payload.email.toLowerCase().trim() : '';
          username = payload.user_metadata?.full_name || payload.name || email.split('@')[0] || username;
        }

        if (userId && email) {
          let existing = this.users.get(userId) || this.getUserByEmail(email);
          if (existing) return existing;

          const newProfile: UserProfile = {
            id: userId,
            username,
            email,
            avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(username)}`,
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
      } catch {
        return null;
      }
    }

    return null;
  }

  public getUserProfile(userId: string): UserProfile | null {
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
    const existing = this.users.get(userId);
    const updated: UserProfile = {
      id: userId,
      email: data.email ? normalizeIdentifier(data.email) : existing?.email || '',
      username: data.username ? data.username.trim() : existing?.username || 'User',
      avatarUrl: data.avatarUrl || existing?.avatarUrl || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(userId)}`,
      bio: data.bio !== undefined ? data.bio : existing?.bio || 'Entuziast Anime & Manga pe Kurogane.',
      pronouns: data.pronouns !== undefined ? data.pronouns : existing?.pronouns || 'he/him',
      bannerUrl: data.bannerUrl || existing?.bannerUrl || 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
      favoriteGenres: data.favoriteGenres || existing?.favoriteGenres || [],
      createdAt: existing?.createdAt || new Date().toISOString(),
    };
    this.users.set(userId, updated);
    this.saveData();
    this.persistUserToSupabase(updated);
    return updated;
  }

  private persistUserToSupabase(user: UserProfile): void {
    if (!isSupabaseConfigured || !supabase) return;
    (async () => {
      try {
        const { error } = await supabase.from('users').upsert({
          id: user.id,
          email: user.email,
          username: user.username,
          avatar_url: user.avatarUrl,
          bio: user.bio,
          pronouns: user.pronouns,
          banner_url: user.bannerUrl,
          favorite_genres: user.favoriteGenres || [],
          updated_at: new Date().toISOString(),
        });
        if (error) console.error('⚠️ [Supabase] Error saving user profile:', error.message);
      } catch (err: any) {
        console.error('⚠️ [Supabase] Network error saving user:', err?.message || err);
      }
    })();
  }

  public async getUserWatchlist(userId: string): Promise<WatchlistItemRecord[]> {
    const list: WatchlistItemRecord[] = [];
    for (const item of this.watchlist.values()) {
      if (item.userId === userId) {
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
    let existingId: string | null = null;
    for (const item of this.watchlist.values()) {
      if (item.userId === userId && item.mediaId === mediaId) {
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
    if (mediaItem?.episodes && mediaItem.episodes > 0 && clampedEpisodes > mediaItem.episodes) {
      clampedEpisodes = mediaItem.episodes;
    }

    const finalStatus: WatchlistStatus =
      mediaItem?.episodes && mediaItem.episodes > 0 && clampedEpisodes >= mediaItem.episodes
        ? 'COMPLETED'
        : status;

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

    // Replicate to Supabase asynchronously
    if (isSupabaseConfigured && supabase) {
      (async () => {
        try {
          const userProfile = this.users.get(record.userId);
          if (userProfile) {
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
          const { error } = await supabase.from('watchlist').upsert({
            id: record.id,
            user_id: record.userId,
            media_id: record.mediaId,
            status: record.status,
            progress_episodes: record.progressEpisodes,
            score: record.score,
            notes: record.notes,
            updated_at: record.updatedAt,
          });
          if (error) console.error('⚠️ [Supabase] Error saving watchlist record:', error.message);
        } catch (err: any) {
          console.error('⚠️ [Supabase] Network error saving watchlist:', err?.message || err);
        }
      })();
    }

    return record;
  }

  public removeWatchlistItem(userId: string, mediaId: string): boolean {
    let foundId: string | null = null;
    for (const item of this.watchlist.values()) {
      if (item.userId === userId && item.mediaId === mediaId) {
        foundId = item.id;
        break;
      }
    }

    if (foundId) {
      this.watchlist.delete(foundId);
      this.saveData();

      // Delete in Supabase asynchronously
      if (isSupabaseConfigured && supabase) {
        (async () => {
          try {
            const { error } = await supabase
              .from('watchlist')
              .delete()
              .match({ user_id: userId, media_id: mediaId });
            if (error) console.error('⚠️ [Supabase] Error deleting watchlist record:', error.message);
          } catch (err: any) {
            console.error('⚠️ [Supabase] Network error deleting watchlist:', err?.message || err);
          }
        })();
      }

      return true;
    }
    return false;
  }
}

export const persistentDb = new PersistentDatabaseService();
export const persistentDbService = persistentDb;

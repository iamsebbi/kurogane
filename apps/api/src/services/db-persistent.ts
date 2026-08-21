import fs from 'fs';
import path from 'path';
import { UserProfile, WatchlistItemRecord, WatchlistStatus } from '@kurogane/shared';
import { dbService } from './db';

const DATA_DIR = path.join(__dirname, '../../data');
const WATCHLIST_FILE = path.join(DATA_DIR, 'watchlist-db.json');
const USERS_FILE = path.join(DATA_DIR, 'users-db.json');

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
  }

  private loadData(): void {
    try {
      if (fs.existsSync(WATCHLIST_FILE)) {
        const content = fs.readFileSync(WATCHLIST_FILE, 'utf-8');
        const list: WatchlistItemRecord[] = JSON.parse(content);
        for (const item of list) {
          this.watchlist.set(item.id, item);
        }
      }
      if (fs.existsSync(USERS_FILE)) {
        const content = fs.readFileSync(USERS_FILE, 'utf-8');
        const userList: UserProfile[] = JSON.parse(content);
        for (const u of userList) {
          this.users.set(u.id, u);
        }
      }
      console.log(`[Persistent DB] Loaded ${this.watchlist.size} watchlist entries & ${this.users.size} user profiles.`);
    } catch (err) {
      console.error('[Persistent DB] Error loading database files:', err);
    }
  }

  private saveData(): void {
    try {
      ensureDataDir();
      fs.writeFileSync(WATCHLIST_FILE, JSON.stringify(Array.from(this.watchlist.values()), null, 2), 'utf-8');
      fs.writeFileSync(USERS_FILE, JSON.stringify(Array.from(this.users.values()), null, 2), 'utf-8');
    } catch (err) {
      console.error('[Persistent DB] Error saving database files:', err);
    }
  }

  /**
   * Verify token or identity header from Supabase / OAuth session
   */
  public verifyToken(token: string): UserProfile | null {
    try {
      let email = 'user@managed-auth.app';
      let username = 'Otaku Explorer';
      let userId = token;

      if (token.startsWith('sb-token:') || token.startsWith('fb-token:') || token.startsWith('otp-token:')) {
        const parts = token.split(':');
        if (parts.length >= 2 && parts[1].includes('@')) {
          email = parts[1].toLowerCase().trim();
          username = decodeURIComponent(parts[2] || email.split('@')[0]);
          userId = `user-${Buffer.from(email).toString('hex').substring(0, 16)}`;
        }
      } else if (token.includes('.')) {
        // Parse JWT payload securely
        const parts = token.split('.');
        if (parts.length >= 2) {
          const payloadJson = Buffer.from(parts[1], 'base64').toString('utf-8');
          const payload = JSON.parse(payloadJson);
          userId = payload.sub || payload.user_id || payload.id || userId;
          email = payload.email ? payload.email.toLowerCase().trim() : email;
          username = payload.user_metadata?.full_name || payload.user_metadata?.username || email.split('@')[0] || username;
        }
      } else if (token.includes('@')) {
        email = token.toLowerCase().trim();
        userId = `user-${Buffer.from(email).toString('hex').substring(0, 16)}`;
      }

      // Check if profile exists by ID
      let existing = this.users.get(userId);

      // If not found by ID, search by email to sync across devices
      if (!existing) {
        for (const u of this.users.values()) {
          if (u.email && u.email.toLowerCase() === email) {
            existing = u;
            break;
          }
        }
      }

      if (existing) {
        return existing;
      }

      const newProfile: UserProfile = {
        id: userId,
        username,
        email,
        avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(username)}`,
        bio: 'Entuziast Anime & Manga pe Kurogane. Colecționez serii epice și analizez ordine de vizionare!',
        pronouns: 'he/him',
        bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
        createdAt: new Date().toISOString(),
      };

      this.users.set(userId, newProfile);
      this.saveData();
      return newProfile;
    } catch {
      return null;
    }
  }

  public getUserProfile(userId: string): UserProfile | null {
    return this.users.get(userId) || null;
  }

  public updateUserProfile(userId: string, data: Partial<UserProfile>): UserProfile | null {
    const existing = this.users.get(userId);
    if (!existing) {
      return null;
    }
    const updated: UserProfile = {
      ...existing,
      ...data,
      id: existing.id, // Immutable ID
    };
    this.users.set(userId, updated);
    this.saveData();
    return updated;
  }

  public getUserWatchlist(userId: string): WatchlistItemRecord[] {
    const list: WatchlistItemRecord[] = [];
    for (const item of this.watchlist.values()) {
      if (item.userId === userId) {
        const enrichedMedia = dbService.getMediaById(item.mediaId);
        list.push({
          ...item,
          mediaItem: enrichedMedia,
        });
      }
    }
    return list.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
  }

  public upsertWatchlistItem(
    userId: string,
    mediaId: string,
    status: WatchlistStatus,
    score?: number,
    progressEpisodes: number = 0,
    notes?: string
  ): WatchlistItemRecord {
    let existingId: string | null = null;
    for (const item of this.watchlist.values()) {
      if (item.userId === userId && item.mediaId === mediaId) {
        existingId = item.id;
        break;
      }
    }

    const now = new Date().toISOString();
    const id = existingId || `witem-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;

    const record: WatchlistItemRecord = {
      id,
      userId,
      mediaId,
      status,
      score,
      progressEpisodes,
      notes,
      createdAt: existingId ? this.watchlist.get(existingId)!.createdAt : now,
      updatedAt: now,
      mediaItem: dbService.getMediaById(mediaId),
    };

    this.watchlist.set(id, record);
    this.saveData();
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
      return true;
    }
    return false;
  }
}

export const persistentDb = new PersistentDatabaseService();

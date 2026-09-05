export interface Bindings {
  DB: D1Database;
  CACHE_KV: KVNamespace;
  ENVIRONMENT: string;
  ANILIST_API_URL: string;
  FIREBASE_PROJECT_ID: string;
  JWT_SECRET: string;
  OTP_SALT: string;
  RESEND_API_KEY: string;
}

export type WatchlistStatus =
  | 'WATCHING'
  | 'COMPLETED'
  | 'PLAN_TO_WATCH'
  | 'ON_HOLD'
  | 'DROPPED';

export interface UserProfile {
  id: string;
  username: string;
  email?: string;
  avatarUrl?: string;
  bio?: string;
  pronouns?: string;
  bannerUrl?: string;
  favoriteGenres?: string[];
  usernameLastChangedAt?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface WatchlistItemRecord {
  id: string;
  userId: string;
  mediaId: string;
  status: WatchlistStatus;
  progressEpisodes: number;
  score?: number;
  notes?: string;
  startedAt?: string;
  completedAt?: string;
  media?: any;
  mediaItem?: any;
  createdAt: string;
  updatedAt: string;
}

export interface WatchOrderPreset {
  id: string;
  franchiseRoot: string;
  title: string;
  description?: string;
  submittedBy: string;
  submitterUsername: string;
  status: string;
  upvotes: number;
  downvotes: number;
  reportCount: number;
  isSelectiveCurated: boolean;
  items: Array<{
    id: string;
    mediaId: string;
    position: number;
    isCanon?: boolean;
    note?: string;
  }>;
  hasUpvoted?: boolean;
  hasDownvoted?: boolean;
  createdAt: string;
  updatedAt: string;
}

-- Cloudflare D1 Schema for Kurogane

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT DEFAULT '',
  pronouns TEXT DEFAULT 'he/him',
  banner_url TEXT DEFAULT '',
  favorite_genres TEXT DEFAULT '[]',
  is_banned INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- 2. Watchlist Table
CREATE TABLE IF NOT EXISTS watchlist (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  media_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PLAN_TO_WATCH',
  progress_episodes INTEGER NOT NULL DEFAULT 0,
  score REAL,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, media_id)
);

CREATE INDEX IF NOT EXISTS idx_watchlist_user_id ON watchlist(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_media_id ON watchlist(media_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_user_status ON watchlist(user_id, status);

-- 3. Watch Order Presets Table
CREATE TABLE IF NOT EXISTS watch_order_presets (
  id TEXT PRIMARY KEY,
  franchise_root TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  submitted_by TEXT NOT NULL,
  submitter_username TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending_review',
  upvotes INTEGER NOT NULL DEFAULT 0,
  downvotes INTEGER NOT NULL DEFAULT 0,
  report_count INTEGER NOT NULL DEFAULT 0,
  is_selective_curated INTEGER NOT NULL DEFAULT 0,
  items_json TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_presets_franchise ON watch_order_presets(franchise_root);
CREATE INDEX IF NOT EXISTS idx_presets_status ON watch_order_presets(status);

-- 4. Preset Votes Table
CREATE TABLE IF NOT EXISTS preset_votes (
  preset_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  vote_type TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (preset_id, user_id)
);

-- 5. Preset Reports Table
CREATE TABLE IF NOT EXISTS preset_reports (
  id TEXT PRIMARY KEY,
  preset_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reports_preset ON preset_reports(preset_id);

-- 6. OTPs Table
CREATE TABLE IF NOT EXISTS otps (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_otps_email ON otps(email);

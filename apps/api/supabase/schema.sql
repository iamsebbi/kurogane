-- ==============================================================================
-- Kurogane Media Platform - Supabase PostgreSQL Database Schema
-- ==============================================================================

-- 1. Create Users Table
CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    password_hash TEXT,
    avatar_url TEXT,
    bio TEXT DEFAULT 'Entuziast Anime & Manga pe Kurogane.',
    pronouns TEXT DEFAULT 'he/him',
    banner_url TEXT DEFAULT 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
    favorite_genres TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Watchlist Table
CREATE TABLE IF NOT EXISTS public.watchlist (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    media_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('WATCHING', 'PLAN_TO_WATCH', 'PLANNING', 'COMPLETED', 'ON_HOLD', 'PAUSED', 'DROPPED')),
    progress_episodes INTEGER DEFAULT 0,
    score NUMERIC(4, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_media UNIQUE (user_id, media_id)
);

-- 3. Create Performance Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_watchlist_user_id ON public.watchlist(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_media_id ON public.watchlist(media_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_status ON public.watchlist(status);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlist ENABLE ROW LEVEL SECURITY;

-- Allow public read access to user profiles and watchlist (or service_role full access)
CREATE POLICY "Allow public read access on users"
    ON public.users FOR SELECT
    USING (true);

CREATE POLICY "Allow service_role full access on users"
    ON public.users FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow public read access on watchlist"
    ON public.watchlist FOR SELECT
    USING (true);

CREATE POLICY "Allow service_role full access on watchlist"
    ON public.watchlist FOR ALL
    USING (true)
    WITH CHECK (true);

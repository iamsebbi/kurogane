import express, { Request, Response } from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';

// Automatic zero-dependency .env loader
[
  path.join(__dirname, '../.env'),
  path.join(__dirname, '../../.env'),
  path.join(process.cwd(), '.env'),
  path.join(process.cwd(), 'apps/api/.env'),
].forEach((envPath) => {
  if (fs.existsSync(envPath)) {
    try {
      const content = fs.readFileSync(envPath, 'utf-8');
      content.split('\n').forEach((line) => {
        const trimmed = line.trim();
        if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
          const idx = trimmed.indexOf('=');
          const key = trimmed.substring(0, idx).trim();
          const val = trimmed.substring(idx + 1).trim();
          if (key && !process.env[key]) {
            process.env[key] = val.replace(/^["']|["']$/g, '');
          }
        }
      });
    } catch (e) {}
  }
});

import { dbService } from './services/db';
import { franchiseService } from './services/franchise';
import { persistentDb } from './services/db-persistent';
import { newsAggregationService } from './services/news-rss';
import { KUROGANE_VERSION, SortOption, ReleaseStatus, MediaSeason, MediaType, MediaFormat, Demographic, WatchlistStatus } from '@kurogane/shared';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Helper middleware for auth
function authenticateUser(req: Request): any {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.substring(7);
  return persistentDb.verifyToken(token);
}

// Health Check
app.get('/api/health', (req: Request, res: Response) => {
  res.json({
    status: 'online',
    version: KUROGANE_VERSION,
    timestamp: new Date().toISOString(),
    localItemCount: dbService.getLocalMedia().length,
  });
});

import { resendService } from './services/resend';

// User Session Verification Endpoint (Managed External Auth)
app.get('/api/auth/me', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat. Autentifică-te prin Supabase sau OAuth.' });
  }
  res.json({ user });
});

// Resend Email OTP Endpoints
app.post('/api/auth/send-otp', async (req: Request, res: Response) => {
  const { email } = req.body;
  if (!email || typeof email !== 'string') {
    return res.status(400).json({ error: 'Adresa de email este obligatorie.' });
  }
  const result = await resendService.sendOtpEmail(email);
  if (!result.success) {
    return res.status(429).json({ error: result.message, waitSec: (result as any).waitSec });
  }
  res.json(result);
});

app.post('/api/auth/verify-otp', (req: Request, res: Response) => {
  const { email, code, username } = req.body;
  if (!email || !code) {
    return res.status(400).json({ error: 'Emailul și codul de verificare sunt obligatorii.' });
  }

  if (typeof code !== 'string' || code.trim().length !== 6 || !/^\d{6}$/.test(code.trim())) {
    return res.status(400).json({ error: 'Codul trebuie să fie format din exact 6 cifre.' });
  }

  const result = resendService.verifyOtp(email, code);
  if (!result.valid) {
    return res.status(401).json({ error: result.error || 'Codul de verificare este incorect sau a expirat.' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const uName = username ? username.trim() : cleanEmail.split('@')[0];
  const token = `fb-token:${cleanEmail}:${encodeURIComponent(uName)}`;
  let user = persistentDb.verifyToken(token);

  if (!user) {
    user = {
      id: `user-${Buffer.from(cleanEmail).toString('hex').substring(0, 16)}`,
      username: uName,
      email: cleanEmail,
      avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(uName)}`,
      bio: 'Entuziast Anime & Manga pe Kurogane.',
      pronouns: 'he/him',
      bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
      createdAt: new Date().toISOString(),
    };
  }

  res.json({ success: true, user, token });
});

// User Profile Management Endpoints
app.get('/api/user/profile', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat' });
  }
  const profile = persistentDb.getUserProfile(user.id) || user;
  res.json({ profile });
});

app.put('/api/user/profile', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat' });
  }
  const { username, bio, pronouns, avatarUrl, bannerUrl, favoriteGenres } = req.body;
  const updated = persistentDb.updateUserProfile(user.id, {
    username,
    bio,
    pronouns,
    avatarUrl,
    bannerUrl,
    favoriteGenres,
  });
  if (!updated) {
    return res.status(400).json({ error: 'Eroare la actualizarea profilului' });
  }
  res.json({ profile: updated });
});


// Watchlist Management Endpoints
app.get('/api/watchlist', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat. Autentifică-te pentru a accesa lista.' });
  }
  const items = persistentDb.getUserWatchlist(user.id);
  res.json({ items });
});

app.post('/api/watchlist', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat' });
  }
  const { mediaId, status, score, progressEpisodes, notes } = req.body;
  if (!mediaId || !status) {
    return res.status(400).json({ error: 'mediaId și status sunt obligatorii.' });
  }
  const item = persistentDb.upsertWatchlistItem(
    user.id,
    mediaId,
    status as WatchlistStatus,
    score ? parseFloat(score) : undefined,
    progressEpisodes ? parseInt(progressEpisodes, 10) : 0,
    notes
  );
  res.json({ success: true, item });
});

app.delete('/api/watchlist/:mediaId', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat' });
  }
  const { mediaId } = req.params;
  const removed = persistentDb.removeWatchlistItem(user.id, mediaId);
  res.json({ success: removed });
});

// Search API Endpoint (supports query, sort, status, season, year, genres, microTags, format, type, demographic)
app.get('/api/search', async (req: Request, res: Response) => {
  try {
    const q = (req.query.q as string) || '';
    const source = (req.query.source as 'all' | 'local' | 'anilist') || 'all';
    const type = (req.query.type as MediaType | 'ALL') || 'ALL';
    const format = (req.query.format as MediaFormat | 'ALL') || 'ALL';
    const status = (req.query.status as ReleaseStatus | 'ALL') || 'ALL';
    const demographic = (req.query.demographic as Demographic | 'ALL') || 'ALL';
    const season = (req.query.season as MediaSeason | 'ALL') || 'ALL';
    const year = req.query.year as string || 'ALL';
    const sortBy = (req.query.sortBy as SortOption) || 'RELEVANCE';

    // Parse multi-genre & multi-microTag options (support array or comma-delimited)
    let genres: string[] = [];
    if (req.query.genres) {
      if (Array.isArray(req.query.genres)) {
        genres = req.query.genres as string[];
      } else {
        genres = (req.query.genres as string).split(',').map((g) => g.trim()).filter(Boolean);
      }
    } else if (req.query.genre) {
      genres = (req.query.genre as string).split(',').map((g) => g.trim()).filter(Boolean);
    }

    let microTags: string[] = [];
    if (req.query.microTags) {
      if (Array.isArray(req.query.microTags)) {
        microTags = req.query.microTags as string[];
      } else {
        microTags = (req.query.microTags as string).split(',').map((t) => t.trim()).filter(Boolean);
      }
    } else if (req.query.microTag) {
      microTags = (req.query.microTag as string).split(',').map((t) => t.trim()).filter(Boolean);
    }

    const minScore = req.query.minScore ? parseFloat(req.query.minScore as string) : undefined;
    const limit = parseInt(req.query.limit as string) || 30;
    const page = parseInt(req.query.page as string) || 1;

    const response = await dbService.search({
      query: q,
      source,
      type,
      format,
      status,
      demographic,
      season,
      year,
      sortBy,
      genres,
      microTags,
      minScore,
      limit,
      page,
    });

    res.json(response);
  } catch (error: any) {
    console.error('[API Error] /api/search:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Get Media By ID
app.get('/api/media/:id', (req: Request, res: Response) => {
  const { id } = req.params;
  const item = dbService.getMediaById(id);

  if (!item) {
    return res.status(404).json({ error: 'Media not found' });
  }

  res.json(item);
});

// Get Curated Category Shelves
app.get('/api/categories', (req: Request, res: Response) => {
  try {
    const shelves = dbService.getCategoryShelves();
    res.json({ shelves });
  } catch (error: any) {
    console.error('[API Error] /api/categories:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Get Homepage All Sections Data
app.get('/api/homepage', async (req: Request, res: Response) => {
  try {
    const user = authenticateUser(req);
    let watchlist;
    let favoriteGenres;
    if (user) {
      watchlist = persistentDb.getUserWatchlist(user.id);
      const profile = persistentDb.getUserProfile(user.id);
      favoriteGenres = profile?.favoriteGenres;
    }
    const data = await dbService.getHomepageData(watchlist, favoriteGenres);
    res.json(data);
  } catch (error: any) {
    console.error('[API Error] /api/homepage:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Get Live RSS Anime & Manga News
app.get('/api/news', async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const category = req.query.category as string | undefined;
    const shouldRefresh = req.query.refresh === 'true';

    if (shouldRefresh) {
      await newsAggregationService.refreshAllFeeds();
    }

    const articles = newsAggregationService.getLatest(limit, category);
    res.json({
      total: newsAggregationService.getAllArticles().length,
      count: articles.length,
      articles,
    });
  } catch (error: any) {
    console.error('[API Error] /api/news:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Get Similar Recommended Media for a Given Title
app.get('/api/media/:id/similar', (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit as string) || 6;
    const result = dbService.getSimilarMedia(id, limit);
    res.json(result);
  } catch (error: any) {
    console.error('[API Error] /api/media/:id/similar:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Get Franchise Watch Order Guide for a Given Title
app.get('/api/media/:id/watch-order', (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const guide = franchiseService.getWatchOrderGuide(id);

    if (!guide) {
      return res.status(404).json({ error: 'Watch order guide not found' });
    }

    res.json(guide);
  } catch (error: any) {
    console.error('[API Error] /api/media/:id/watch-order:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`[Kurogane API] Server running on http://localhost:${PORT}`);
});


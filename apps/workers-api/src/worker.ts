import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Bindings, UserProfile } from './types';
import {
  verifyToken,
  getUserById,
  getUserByEmail,
  getUserByUsername,
  upsertUser,
  generateToken,
} from './services/auth';
import {
  getMediaById,
  searchMedia,
  getHomepageData,
} from './services/anilist';
import {
  getUserWatchlist,
  upsertWatchlistItem,
  deleteWatchlistItem,
  normalizeWatchlistStatus,
} from './services/watchlist';
import {
  getPresetsForFranchise,
  submitPreset,
  votePreset,
  reportPreset,
} from './services/presets';
import { getWatchOrderGuide, sanitizeRoot } from './services/franchise';
import { getNewsArticles } from './services/news';

const app = new Hono<{ Bindings: Bindings }>();

// Global CORS Middleware
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));

// Root / Health
app.get('/', (c) => {
  return c.json({
    status: 'online',
    service: 'kurogane-workers-api',
    environment: c.env.ENVIRONMENT || 'production',
    region: 'EEUR',
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/health', (c) => {
  return c.json({
    status: 'online',
    version: '1.0.0-worker',
    timestamp: new Date().toISOString(),
  });
});

// Helper for Auth Middleware
async function getAuthUser(c: any): Promise<UserProfile | null> {
  const authHeader = c.req.header('Authorization');
  return await verifyToken(c.env, authHeader);
}

// -------------------------------------------------------------
// 1. HOMEPAGE ROUTES
// -------------------------------------------------------------
app.get('/api/homepage', async (c) => {
  try {
    const user = await getAuthUser(c);
    let watchlist: any[] = [];
    let favoriteGenres: string[] | undefined = undefined;

    if (user && user.id) {
      watchlist = await getUserWatchlist(c.env.DB, c.env, user.id);
      favoriteGenres = user.favoriteGenres;
    }

    const data = await getHomepageData(c.env, watchlist, favoriteGenres);
    return c.json(data);
  } catch (err: any) {
    console.error('[Worker Error] GET /api/homepage:', err.message);
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

// -------------------------------------------------------------
// 2. MEDIA ROUTES
// -------------------------------------------------------------
app.get('/api/media/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const media = await getMediaById(c.env, id);
    if (!media) {
      return c.json({ error: 'Media item not found' }, 404);
    }
    return c.json(media);
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/media/:id/similar', async (c) => {
  try {
    const id = c.req.param('id');
    const media = await getMediaById(c.env, id);
    if (!media || !media.genres || media.genres.length === 0) {
      return c.json([]);
    }
    const genre = media.genres[0];
    const searchRes = await searchMedia(c.env, { genre, perPage: 7 });
    const similar = (searchRes.items || []).filter((m: any) => m.id !== media.id).slice(0, 6);
    return c.json({
      similarItems: similar.map((m: any) => ({ item: m })),
      items: similar,
      results: similar,
    });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/media/:id/relations', async (c) => {
  try {
    const id = c.req.param('id');
    const media = await getMediaById(c.env, id);
    if (!media) {
      return c.json({ error: 'Media item not found' }, 404);
    }
    return c.json({ relations: media.relations || [] });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/media/:id/watch-order', async (c) => {
  try {
    const id = c.req.param('id');
    const user = await getAuthUser(c);
    const guide = await getWatchOrderGuide(c.env, id);

    if (!guide) {
      return c.json(null);
    }

    const item = await getMediaById(c.env, id);
    const franchiseRoot = guide.canonicalRoot || (item ? sanitizeRoot(item.title?.userPreferred || '') : guide.franchiseId);

    if (franchiseRoot) {
      const presets = await getPresetsForFranchise(c.env.DB, franchiseRoot, user?.id);
      guide.communityPresets = presets;
      guide.authority = presets.length > 0 && presets.some((p: any) => p.status === 'community_verified')
        ? 'community_verified'
        : (guide.franchiseId.includes('series') || guide.franchiseId === 'attack-on-titan' ? 'editorial' : 'algorithmic');
    }

    return c.json(guide);
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/media/:id/watch-order/presets', async (c) => {
  try {
    const id = c.req.param('id');
    const user = await getAuthUser(c);
    const guide = await getWatchOrderGuide(c.env, id);
    const item = await getMediaById(c.env, id);
    const franchiseRoot = guide?.canonicalRoot || (item ? sanitizeRoot(item.title?.userPreferred || '') : id);
    const presets = await getPresetsForFranchise(c.env.DB, franchiseRoot, user?.id);
    return c.json({ presets });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.post('/api/media/:id/watch-order/presets', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Neautorizat. Autentifică-te pentru a trimite o propunere.' }, 401);
    }

    const id = c.req.param('id');
    const item = await getMediaById(c.env, id);
    const franchiseRoot = item ? sanitizeRoot(item.title?.userPreferred || '') : id;

    const body = await c.req.json();
    const { title, description, isSelectiveCurated, items } = body;

    if (!title || typeof title !== 'string' || title.trim().length < 3) {
      return c.json({ error: 'Titlul propunerii este obligatoriu (minim 3 caractere).' }, 400);
    }

    if (!Array.isArray(items) || items.length < 2) {
      return c.json({ error: 'Ghidul trebuie să conțină cel puțin 2 producții.' }, 400);
    }

    const preset = await submitPreset(c.env.DB, {
      franchiseRoot,
      title: title.trim(),
      description: description ? String(description).trim() : '',
      submittedBy: user.id,
      submitterUsername: user.username,
      isSelectiveCurated: Boolean(isSelectiveCurated),
      items,
    });

    return c.json({ success: true, preset }, 201);
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

async function handleVotePreset(c: any) {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Neautorizat.' }, 401);
    }

    const presetId = c.req.param('presetId');
    const body = await c.req.json();
    const voteType = body.voteType === 'DOWN' ? 'DOWN' : 'UP';

    const result = await votePreset(c.env.DB, presetId, user.id, voteType);
    return c.json(result);
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
}

async function handleReportPreset(c: any) {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Neautorizat.' }, 401);
    }

    const presetId = c.req.param('presetId');
    const body = await c.req.json();
    const reason = body.reason || 'Raportat de utilizator';

    await reportPreset(c.env.DB, presetId, user.id, String(reason));
    return c.json({ success: true });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
}

app.post('/api/media/:id/watch-order/presets/:presetId/vote', handleVotePreset);
app.post('/api/media/watch-order/presets/:presetId/vote', handleVotePreset);

app.post('/api/media/:id/watch-order/presets/:presetId/report', handleReportPreset);
app.post('/api/media/watch-order/presets/:presetId/report', handleReportPreset);

// -------------------------------------------------------------
// 3. SEARCH ROUTES
// -------------------------------------------------------------
app.get('/api/search', async (c) => {
  try {
    const query = c.req.query('q') || c.req.query('query') || '';
    const type = c.req.query('type') || 'ALL';
    const format = c.req.query('format') || 'ALL';
    const status = c.req.query('status') || 'ALL';
    const demographic = c.req.query('demographic') || 'ALL';
    const genre = c.req.query('genre');
    const genresRaw = c.req.query('genres');
    const genres = genresRaw
      ? genresRaw.split(',').map((g: string) => g.trim()).filter(Boolean)
      : (genre ? [genre] : undefined);
    const microTagsRaw = c.req.query('microTags');
    const microTags = microTagsRaw
      ? microTagsRaw.split(',').map((m: string) => m.trim()).filter(Boolean)
      : undefined;
    const sortBy = c.req.query('sortBy') || 'RELEVANCE';
    const minScore = c.req.query('minScore') ? parseFloat(c.req.query('minScore')!) : undefined;
    const page = parseInt(c.req.query('page') || '1', 10);
    const perPage = parseInt(c.req.query('limit') || c.req.query('perPage') || '30', 10);

    const searchRes = await searchMedia(c.env, {
      query,
      type,
      format,
      status,
      demographic,
      genre,
      genres,
      microTags,
      sortBy,
      minScore,
      page,
      perPage,
    });

    return c.json({
      results: searchRes.items,
      items: searchRes.items,
      pageInfo: searchRes.pageInfo,
      totalCount: searchRes.pageInfo?.total || searchRes.items.length,
    });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

// -------------------------------------------------------------
// 4. WATCHLIST ROUTES
// -------------------------------------------------------------
app.get('/api/watchlist', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Sesiune utilizator invalidă.' }, 401);
    }
    const items = await getUserWatchlist(c.env.DB, c.env, user.id);
    return c.json({ items });
  } catch (err: any) {
    return c.json({ error: 'Eroare la încărcarea listei.', message: err.message }, 500);
  }
});

app.post('/api/watchlist', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Sesiune utilizator invalidă.' }, 401);
    }
    const body = await c.req.json();
    const { mediaId, status, score, progressEpisodes, notes, startedAt, completedAt } = body;

    if (!mediaId || !status) {
      return c.json({ error: 'mediaId și status sunt obligatorii.' }, 400);
    }

    let parsedProgress = 0;
    if (progressEpisodes !== undefined && progressEpisodes !== null) {
      const num = typeof progressEpisodes === 'number' ? progressEpisodes : parseInt(String(progressEpisodes), 10);
      if (!isNaN(num)) parsedProgress = Math.max(0, num);
    }

    let parsedScore: number | undefined = undefined;
    if (score !== undefined && score !== null && score !== '') {
      const num = typeof score === 'number' ? score : parseFloat(String(score));
      if (!isNaN(num)) parsedScore = Math.max(0, Math.min(100, num));
    }

    const item = await upsertWatchlistItem(
      c.env.DB,
      c.env,
      user.id,
      String(mediaId).trim(),
      normalizeWatchlistStatus(status),
      parsedScore,
      parsedProgress,
      typeof notes === 'string' ? notes.trim() : undefined,
      typeof startedAt === 'string' ? startedAt.trim() : undefined,
      typeof completedAt === 'string' ? completedAt.trim() : undefined
    );

    return c.json({ success: true, item });
  } catch (err: any) {
    return c.json({ error: 'Eroare la salvarea elementului.', message: err.message }, 500);
  }
});

app.delete('/api/watchlist/:mediaId', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Sesiune utilizator invalidă.' }, 401);
    }
    const mediaId = c.req.param('mediaId');
    const removed = await deleteWatchlistItem(c.env.DB, user.id, String(mediaId).trim());
    return c.json({ success: removed });
  } catch (err: any) {
    return c.json({ error: 'Eroare la ștergerea elementului.', message: err.message }, 500);
  }
});

// -------------------------------------------------------------
// 5. USER PROFILE ROUTES
// -------------------------------------------------------------
app.get('/api/user/profile', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Sesiune utilizator invalidă.' }, 401);
    }
    return c.json({ profile: user });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.put('/api/user/profile', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Sesiune utilizator invalidă.' }, 401);
    }
    const body = await c.req.json();
    const { username, bio, pronouns, avatarUrl, bannerUrl, favoriteGenres } = body;

    const updated: UserProfile = {
      ...user,
      username: username ? String(username).trim() : user.username,
      bio: bio !== undefined ? String(bio).trim() : user.bio,
      pronouns: pronouns !== undefined ? String(pronouns).trim() : user.pronouns,
      avatarUrl: avatarUrl !== undefined ? String(avatarUrl).trim() : user.avatarUrl,
      bannerUrl: bannerUrl !== undefined ? String(bannerUrl).trim() : user.bannerUrl,
      favoriteGenres: Array.isArray(favoriteGenres) ? favoriteGenres : user.favoriteGenres,
      updatedAt: new Date().toISOString(),
    };

    await upsertUser(c.env.DB, updated);
    return c.json({ profile: updated });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/user/:username', async (c) => {
  try {
    const username = c.req.param('username');
    const profile = await getUserByUsername(c.env.DB, username);
    if (!profile) {
      return c.json({ error: 'Utilizatorul nu a fost găsit.' }, 404);
    }
    return c.json({ profile });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/user/:username/watchlist', async (c) => {
  try {
    const username = c.req.param('username');
    const profile = await getUserByUsername(c.env.DB, username);
    if (!profile) {
      return c.json({ error: 'Utilizatorul nu a fost găsit.' }, 404);
    }
    const items = await getUserWatchlist(c.env.DB, c.env, profile.id);
    return c.json({ items });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

// -------------------------------------------------------------
// 6. NEWS ROUTES
// -------------------------------------------------------------
app.get('/api/news', async (c) => {
  try {
    const limit = parseInt(c.req.query('limit') || '20', 10);
    const articles = await getNewsArticles(c.env, limit);
    return c.json({ items: articles });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

// -------------------------------------------------------------
// 7. AUTH ROUTES
// -------------------------------------------------------------
app.get('/api/auth/me', async (c) => {
  try {
    const user = await getAuthUser(c);
    if (!user) {
      return c.json({ error: 'Neautorizat.' }, 401);
    }
    return c.json({ user });
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.post('/api/auth/resolve-identifier', async (c) => {
  try {
    const body = await c.req.json();
    const identifier = (body.identifier || '').trim();
    if (!identifier) {
      return c.json({ error: 'Date de autentificare incorecte.' }, 401);
    }

    if (identifier.includes('@')) {
      return c.json({ email: identifier.toLowerCase(), identifierType: 'EMAIL' });
    }

    const user = await getUserByUsername(c.env.DB, identifier);
    if (user && user.email) {
      return c.json({ email: user.email, identifierType: 'USERNAME' });
    }

    return c.json({ error: 'Date de autentificare incorecte.' }, 401);
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

app.get('/api/auth/check-username', async (c) => {
  try {
    const raw = c.req.query('username');
    const excludeUserId = c.req.query('excludeUserId');
    const email = c.req.query('email');

    if (!raw || typeof raw !== 'string') {
      return c.json({ available: false, error: 'Introdu un nume de utilizator.' });
    }

    const clean = raw.trim();
    if (clean.length < 2 || clean.length > 24 || !/^[a-zA-Z0-9_.-]+$/.test(clean)) {
      return c.json({
        available: false,
        error: 'Format invalid (2-24 caractere, doar litere, cifre, _, -, .)',
      });
    }

    const existing = await getUserByUsername(c.env.DB, clean);
    if (existing) {
      if (excludeUserId && existing.id === excludeUserId) {
        return c.json({ available: true });
      }
      if (email && existing.email && existing.email.toLowerCase() === email.toLowerCase()) {
        return c.json({ available: true });
      }
      return c.json({ available: false, error: 'Acest nume de utilizator este deja folosit.' });
    }

    return c.json({ available: true });
  } catch (err: any) {
    return c.json({ available: false, error: err.message });
  }
});

app.post('/api/auth/register-user', async (c) => {
  try {
    const body = await c.req.json();
    const { id, email, username, avatarUrl } = body;

    if (!id || !username) {
      return c.json({ error: 'id și username sunt obligatorii.' }, 400);
    }

    const existing = await getUserById(c.env.DB, id);
    if (existing) {
      return c.json({ success: true, profile: existing });
    }

    const newProfile: UserProfile = {
      id,
      email: email ? String(email).trim().toLowerCase() : undefined,
      username: String(username).trim(),
      avatarUrl: avatarUrl || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(username)}`,
      bio: 'Entuziast Anime & Manga pe Kurogane.',
      pronouns: 'he/him',
      bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
      createdAt: new Date().toISOString(),
    };

    await upsertUser(c.env.DB, newProfile);
    const token = await generateToken(c.env, newProfile);

    return c.json({ success: true, profile: newProfile, token }, 201);
  } catch (err: any) {
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
  }
});

// Diagnostics
app.get('/test-anilist', async (c) => {
  const startTime = Date.now();
  const anilistUrl = c.env.ANILIST_API_URL || 'https://graphql.anilist.co';

  const query = `
    query {
      Page(page: 1, perPage: 5) {
        media(type: ANIME, sort: [TRENDING_DESC], isAdult: false) {
          id
          title {
            userPreferred
            english
          }
          averageScore
          episodes
        }
      }
    }
  `;

  try {
    const response = await fetch(anilistUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'KuroganeApp/1.0',
      },
      body: JSON.stringify({ query }),
    });

    const elapsedMs = Date.now() - startTime;
    const isOk = response.ok;
    const status = response.status;
    const headers = Object.fromEntries(response.headers.entries());

    let data: any = null;
    let rawText = '';
    if (isOk) {
      data = await response.json();
    } else {
      rawText = await response.text();
    }

    return c.json({
      success: isOk,
      statusCode: status,
      elapsedMs,
      cfRay: headers['cf-ray'] || null,
      server: headers['server'] || null,
      resultCount: data?.data?.Page?.media?.length || 0,
      sampleTitles: (data?.data?.Page?.media || []).map((m: any) => m.title.userPreferred),
      errorBody: !isOk ? rawText.slice(0, 500) : null,
    });
  } catch (error: any) {
    return c.json({
      success: false,
      error: error.message,
      elapsedMs: Date.now() - startTime,
    }, 500);
  }
});

export default app;

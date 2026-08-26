import { Router, Request, Response } from 'express';
import { dbService } from '../services/db';
import { persistentDb } from '../services/db-persistent';
import { authenticateUser } from '../middleware/auth.middleware';
import { KUROGANE_VERSION } from '@kurogane/shared';

const router = Router();

// GET /api/health - Server health check & status
router.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'online',
    version: KUROGANE_VERSION,
    timestamp: new Date().toISOString(),
    localItemCount: dbService.getLocalMedia().length,
  });
});

// GET /api/homepage - Aggregated homepage sections
router.get('/homepage', async (req: Request, res: Response) => {
  try {
    const user = authenticateUser(req);
    let watchlist;
    let favoriteGenres;

    if (user) {
      watchlist = await persistentDb.getUserWatchlist(user.id);
      const profile = persistentDb.getUserProfile(user.id);
      favoriteGenres = profile?.favoriteGenres;
    }

    const data = await dbService.getHomepageData(watchlist, favoriteGenres);
    res.json(data);
  } catch (error: any) {
    console.error('[API Error] GET /api/homepage:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

export default router;

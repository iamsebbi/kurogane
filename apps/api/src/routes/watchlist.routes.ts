import { Router, Request, Response } from 'express';
import { persistentDb, normalizeWatchlistStatus } from '../services/db-persistent';
import { requireAuth } from '../middleware/auth.middleware';

const router = Router();

// GET /api/watchlist - Get user watchlist items
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = req.user!;
    const items = await persistentDb.getUserWatchlist(user.id);
    res.json({ items });
  } catch (error: any) {
    console.error('[API Error] GET /api/watchlist:', error);
    res.status(500).json({ error: 'Eroare la încărcarea listei de urmărire.', message: error.message });
  }
});

// POST /api/watchlist - Add or update a watchlist item
router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = req.user!;
    const { mediaId, status, score, progressEpisodes, notes } = req.body;

    if (!mediaId || !status) {
      return res.status(400).json({ error: 'mediaId și status sunt obligatorii.' });
    }

    // Parse progress safely (handling 0 properly, whether number or string)
    let parsedProgress = 0;
    if (progressEpisodes !== undefined && progressEpisodes !== null) {
      const num = typeof progressEpisodes === 'number' ? progressEpisodes : parseInt(String(progressEpisodes), 10);
      if (!isNaN(num)) {
        parsedProgress = Math.max(0, num);
      }
    }

    // Parse score safely (handling 0..100 properly, whether number or string)
    let parsedScore: number | undefined = undefined;
    if (score !== undefined && score !== null && score !== '') {
      const num = typeof score === 'number' ? score : parseFloat(String(score));
      if (!isNaN(num)) {
        parsedScore = Math.max(0, Math.min(100, num));
      }
    }

    const item = await persistentDb.upsertWatchlistItem(
      user.id,
      String(mediaId).trim(),
      normalizeWatchlistStatus(status),
      parsedScore,
      parsedProgress,
      typeof notes === 'string' ? notes.trim() : undefined
    );

    res.json({ success: true, item });
  } catch (error: any) {
    console.error('[API Error] POST /api/watchlist:', error);
    res.status(500).json({ error: 'Eroare la salvarea elementului în listă.', message: error.message });
  }
});

// DELETE /api/watchlist/:mediaId - Remove an item from watchlist
router.delete('/:mediaId', requireAuth, (req: Request, res: Response) => {
  try {
    const user = req.user!;
    const { mediaId } = req.params;
    const removed = persistentDb.removeWatchlistItem(user.id, String(mediaId).trim());
    res.json({ success: removed });
  } catch (error: any) {
    console.error('[API Error] DELETE /api/watchlist/:mediaId:', error);
    res.status(500).json({ error: 'Eroare la ștergerea elementului din listă.', message: error.message });
  }
});

export default router;

import { Router, Request, Response } from 'express';
import { dbService } from '../services/db';
import { franchiseService } from '../services/franchise';

const router = Router();

// GET /api/categories - Curated category shelves
router.get('/categories', (req: Request, res: Response) => {
  try {
    const shelves = dbService.getCategoryShelves();
    res.json({ shelves });
  } catch (error: any) {
    console.error('[API Error] GET /api/categories:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// GET /api/media/:id - Full details for a media item
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const item = await dbService.getMediaByIdAsync(id);

    if (!item) {
      return res.status(404).json({ error: 'Media item not found' });
    }

    res.json(item);
  } catch (error: any) {
    console.error(`[API Error] GET /api/media/${req.params.id}:`, error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// GET /api/media/:id/similar - Content-similar recommendations
router.get('/:id/similar', (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit as string) || 6;
    const result = dbService.getSimilarMedia(id, limit);
    res.json(result);
  } catch (error: any) {
    console.error(`[API Error] GET /api/media/${req.params.id}/similar:`, error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// GET /api/media/:id/watch-order - Franchise watch order guide
router.get('/:id/watch-order', (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const guide = franchiseService.getWatchOrderGuide(id);

    if (!guide) {
      return res.status(404).json({ error: 'Watch order guide not found' });
    }

    res.json(guide);
  } catch (error: any) {
    console.error(`[API Error] GET /api/media/${req.params.id}/watch-order:`, error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

export default router;

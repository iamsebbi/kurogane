import { Router, Request, Response } from 'express';
import { dbService } from '../services/db';
import { franchiseService } from '../services/franchise';
import { watchOrderPresetService } from '../services/watch-order-preset.service';
import { authenticateUser, requireAuth } from '../middleware/auth.middleware';

const router = Router();

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

// GET /api/media/:id/relations - Dynamic relations (prequel, sequel, side stories, spin-offs, etc.)
router.get('/:id/relations', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const item = await dbService.getMediaByIdAsync(id);

    if (!item) {
      return res.status(404).json({ error: 'Media item not found' });
    }

    res.json({ relations: item.relations || [] });
  } catch (error: any) {
    console.error(`[API Error] GET /api/media/${req.params.id}/relations:`, error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// GET /api/media/:id/watch-order - Franchise watch order guide with community presets
router.get('/:id/watch-order', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const user = await authenticateUser(req);
    const guide = await franchiseService.getWatchOrderGuide(id);

    if (!guide) {
      return res.json(null);
    }

    const item = dbService.getMediaById(id);
    const canonicalRoot = item ? watchOrderPresetService.getCanonicalFranchiseId(item) : guide.franchiseId;

    if (canonicalRoot) {
      const presets = await watchOrderPresetService.getPresetsForFranchise(canonicalRoot, user?.id);
      guide.communityPresets = presets;

      const isEditorial = ['naruto-series', 'fate-series', 'demon-slayer', 'attack-on-titan'].includes(guide.franchiseId);
      if (isEditorial) {
        guide.authority = 'editorial';
      } else if (presets.some((p) => p.status === 'community_verified')) {
        guide.authority = 'community_verified';
      } else {
        guide.authority = 'algorithmic';
      }
    }

    res.json(guide);
  } catch (error: any) {
    console.error(`[API Error] GET /api/media/${req.params.id}/watch-order:`, error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// POST /api/media/:id/watch-order/presets - Trimite o propunere nouă de watch order
router.post('/:id/watch-order/presets', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id!;
    const { title, description, isSelectiveCurated, items } = req.body;

    if (!title || typeof title !== 'string' || title.trim().length < 3) {
      return res.status(400).json({ error: 'Titlul propunerii este obligatoriu (minim 3 caractere).' });
    }

    if (!items || !Array.isArray(items) || items.length < 2) {
      return res.status(400).json({ error: 'O ordine de vizionare trebuie să conțină cel puțin 2 titluri.' });
    }

    const created = await watchOrderPresetService.createPreset(userId, id, {
      title,
      description,
      isSelectiveCurated,
      items,
    });

    res.status(201).json(created);
  } catch (error: any) {
    console.error(`[API Error] POST /api/media/${req.params.id}/watch-order/presets:`, error);
    res.status(400).json({ error: error.message || 'Eroare la crearea propunerii' });
  }
});

// POST /api/media/watch-order/presets/:presetId/vote - Votează un preset (+1 sau -1)
router.post('/watch-order/presets/:presetId/vote', requireAuth, async (req: Request, res: Response) => {
  try {
    const { presetId } = req.params;
    const userId = req.user!.id!;
    const { vote } = req.body;

    if (vote !== 1 && vote !== -1) {
      return res.status(400).json({ error: 'Votul trebuie să fie 1 (upvote) sau -1 (downvote).' });
    }

    const result = await watchOrderPresetService.votePreset(userId, presetId, vote);
    res.json(result);
  } catch (error: any) {
    console.error(`[API Error] POST /api/media/watch-order/presets/${req.params.presetId}/vote:`, error);
    const statusCode = error.message.includes('propria ta propunere') ? 403 : 400;
    res.status(statusCode).json({ error: error.message || 'Eroare la înregistrarea votului' });
  }
});

// POST /api/media/watch-order/presets/:presetId/report - Raportează un preset
router.post('/watch-order/presets/:presetId/report', requireAuth, async (req: Request, res: Response) => {
  try {
    const { presetId } = req.params;
    const userId = req.user!.id!;
    const { reason } = req.body;

    const result = await watchOrderPresetService.reportPreset(userId, presetId, reason || 'Inapropriat / Spam');
    res.json(result);
  } catch (error: any) {
    console.error(`[API Error] POST /api/media/watch-order/presets/${req.params.presetId}/report:`, error);
    res.status(400).json({ error: error.message || 'Eroare la raportarea presetului' });
  }
});

// PATCH /api/media/watch-order/presets/:presetId/moderate - Moderare administrativă
router.patch('/watch-order/presets/:presetId/moderate', requireAuth, async (req: Request, res: Response) => {
  try {
    const { presetId } = req.params;
    const { action } = req.body;

    if (!['approve', 'reject', 'reopen'].includes(action)) {
      return res.status(400).json({ error: 'Acțiune invalidă. Permise: approve, reject, reopen.' });
    }

    const result = await watchOrderPresetService.moderatePreset(presetId, action);
    res.json(result);
  } catch (error: any) {
    console.error(`[API Error] PATCH /api/media/watch-order/presets/${req.params.presetId}/moderate:`, error);
    res.status(400).json({ error: error.message || 'Eroare la moderarea presetului' });
  }
});

export default router;

import { Router, Request, Response } from 'express';
import { dbService } from '../services/db';
import {
  MediaType,
  MediaFormat,
  ReleaseStatus,
  Demographic,
  MediaSeason,
  SortOption,
} from '@kurogane/shared';

const router = Router();

// GET /api/search - Multi-faceted search endpoint
router.get('/', async (req: Request, res: Response) => {
  try {
    const q = (req.query.q as string) || '';
    const source = (req.query.source as 'all' | 'local' | 'anilist') || 'all';
    const type = (req.query.type as MediaType | 'ALL') || 'ALL';
    const format = (req.query.format as MediaFormat | 'ALL') || 'ALL';
    const status = (req.query.status as ReleaseStatus | 'ALL') || 'ALL';
    const demographic = (req.query.demographic as Demographic | 'ALL') || 'ALL';
    const season = (req.query.season as MediaSeason | 'ALL') || 'ALL';
    const year = (req.query.year as string) || 'ALL';
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
    console.error('[API Error] GET /api/search:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

export default router;

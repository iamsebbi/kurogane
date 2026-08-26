import { Router, Request, Response } from 'express';
import { newsAggregationService } from '../services/news-rss';

const router = Router();

// GET /api/news - Live aggregated RSS news feed
router.get('/', async (req: Request, res: Response) => {
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
    console.error('[API Error] GET /api/news:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

export default router;

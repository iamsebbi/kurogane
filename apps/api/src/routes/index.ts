import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import watchlistRoutes from './watchlist.routes';
import mediaRoutes from './media.routes';
import searchRoutes from './search.routes';
import newsRoutes from './news.routes';
import homepageRoutes from './homepage.routes';
import { dbService } from '../services/db';

const apiRouter = Router();

// Mount all specific modular prefix routes
apiRouter.use('/auth', authRoutes);
apiRouter.use('/user', userRoutes);
apiRouter.use('/watchlist', watchlistRoutes);
apiRouter.use('/search', searchRoutes);
apiRouter.use('/news', newsRoutes);
apiRouter.use('/media', mediaRoutes);

// GET /api/categories - Curated category shelves
apiRouter.get('/categories', (req, res) => {
  try {
    const shelves = dbService.getCategoryShelves();
    res.json({ shelves });
  } catch (error: any) {
    console.error('[API Error] GET /api/categories:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Mount /api/health and /api/homepage
apiRouter.use('/', homepageRoutes);

export default apiRouter;

import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import watchlistRoutes from './watchlist.routes';
import mediaRoutes from './media.routes';
import searchRoutes from './search.routes';
import newsRoutes from './news.routes';
import homepageRoutes from './homepage.routes';

const apiRouter = Router();

// Mount all modular routes
apiRouter.use('/auth', authRoutes);
apiRouter.use('/user', userRoutes);
apiRouter.use('/watchlist', watchlistRoutes);
apiRouter.use('/search', searchRoutes);
apiRouter.use('/news', newsRoutes);
apiRouter.use('/media', mediaRoutes);
apiRouter.use('/', mediaRoutes); // for /api/categories
apiRouter.use('/', homepageRoutes); // for /api/health and /api/homepage

export default apiRouter;

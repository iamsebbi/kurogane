import { Router, Request, Response } from 'express';
import { persistentDb } from '../services/db-persistent';
import { requireAuth } from '../middleware/auth.middleware';

const router = Router();

// GET /api/user/profile - Get current user profile
router.get('/profile', requireAuth, (req: Request, res: Response) => {
  const user = req.user!;
  const profile = persistentDb.getUserProfile(user.id) || user;
  res.json({ profile });
});

// PUT /api/user/profile - Update current user profile
router.put('/profile', requireAuth, (req: Request, res: Response) => {
  const user = req.user!;
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
    return res.status(400).json({ error: 'Eroare la actualizarea profilului.' });
  }

  res.json({ profile: updated });
});

export default router;

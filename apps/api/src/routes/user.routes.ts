import { Router, Request, Response } from 'express';
import { persistentDb } from '../services/db-persistent';
import { requireAuth } from '../middleware/auth.middleware';

const router = Router();

// GET /api/user/profile - Get current user profile
router.get('/profile', requireAuth, (req: Request, res: Response) => {
  const user = req.user!;
  if (!user.id) {
    return res.status(401).json({ error: 'Sesiune utilizator invalidă.' });
  }
  const profile = persistentDb.getUserProfile(user.id) || user;
  res.json({ profile });
});

// PUT /api/user/profile - Update current user profile with validation & sanitization
router.put('/profile', requireAuth, (req: Request, res: Response) => {
  const user = req.user!;
  if (!user.id) {
    return res.status(401).json({ error: 'Sesiune utilizator invalidă.' });
  }
  const { username, bio, pronouns, avatarUrl, bannerUrl, favoriteGenres } = req.body;

  // Validation & Sanitization
  let sanitizedUsername: string | undefined;
  if (username !== undefined && username !== null) {
    const cleanUsername = String(username).trim();
    if (cleanUsername.length > 0) {
      if (cleanUsername.length < 2 || cleanUsername.length > 30) {
        return res.status(400).json({ error: 'Numele de utilizator trebuie să aibă între 2 și 30 de caractere.' });
      }
      if (!/^[a-zA-Z0-9_.-]+$/.test(cleanUsername)) {
        return res.status(400).json({ error: 'Numele de utilizator conține caractere nepermise.' });
      }
      sanitizedUsername = cleanUsername;
    }
  }

  let sanitizedBio: string | undefined;
  if (bio !== undefined && bio !== null) {
    const cleanBio = String(bio).trim().replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '');
    if (cleanBio.length > 500) {
      return res.status(400).json({ error: 'Biografia nu poate depăși 500 de caractere.' });
    }
    sanitizedBio = cleanBio;
  }

  let sanitizedPronouns: string | undefined;
  if (pronouns !== undefined && pronouns !== null) {
    const cleanPronouns = String(pronouns).trim();
    if (cleanPronouns.length > 30) {
      return res.status(400).json({ error: 'Pronumele nu pot depăși 30 de caractere.' });
    }
    sanitizedPronouns = cleanPronouns;
  }

  let sanitizedAvatarUrl: string | undefined;
  if (avatarUrl !== undefined && avatarUrl !== null) {
    const cleanAvatar = String(avatarUrl).trim();
    if (cleanAvatar.length > 0 && !cleanAvatar.startsWith('http://') && !cleanAvatar.startsWith('https://')) {
      return res.status(400).json({ error: 'URL-ul avatarului trebuie să înceapă cu http:// sau https://.' });
    }
    sanitizedAvatarUrl = cleanAvatar;
  }

  let sanitizedBannerUrl: string | undefined;
  if (bannerUrl !== undefined && bannerUrl !== null) {
    sanitizedBannerUrl = String(bannerUrl).trim().substring(0, 1000);
  }

  let sanitizedGenres: string[] | undefined;
  if (Array.isArray(favoriteGenres)) {
    sanitizedGenres = favoriteGenres
      .filter((g) => typeof g === 'string' && g.trim().length > 0)
      .map((g) => String(g).trim().substring(0, 50))
      .slice(0, 20);
  }

  const updated = persistentDb.updateUserProfile(user.id, {
    username: sanitizedUsername,
    bio: sanitizedBio,
    pronouns: sanitizedPronouns,
    avatarUrl: sanitizedAvatarUrl,
    bannerUrl: sanitizedBannerUrl,
    favoriteGenres: sanitizedGenres,
  });

  if (!updated) {
    return res.status(400).json({ error: 'Eroare la actualizarea profilului.' });
  }

  res.json({ profile: updated });
});

export default router;

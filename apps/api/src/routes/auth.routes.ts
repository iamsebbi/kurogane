import { Router, Request, Response } from 'express';
import { persistentDb } from '../services/db-persistent';
import { resendService } from '../services/resend';
import { createAuthRateLimiter } from '../services/rate-limiter';
import { authenticateUser } from '../middleware/auth.middleware';
import {
  normalizeIdentifier,
  performConstantTimeDummyHash,
  isCommonWeakPassword,
} from '../services/security';

const router = Router();

// Rate Limiter instances for Auth & OTP routes
const authRateLimiter = createAuthRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 10, // 10 attempts per minute per IP
  message: 'Prea multe încercări. Te rugăm să încerci din nou mai târziu.',
});

const otpRateLimiter = createAuthRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 5, // 5 requests per minute per IP
  message: 'Prea multe solicitări de cod OTP. Te rugăm să aștepți un minut.',
});

// GET /api/auth/me - Verify current session
router.get('/me', (req: Request, res: Response) => {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Neautorizat. Autentifică-te pentru a continua.' });
  }
  res.json({ user });
});

// POST /api/auth/resolve-identifier - Username/Email resolver with timing attack protection
router.post('/resolve-identifier', authRateLimiter, async (req: Request, res: Response) => {
  const { identifier } = req.body;
  if (!identifier || typeof identifier !== 'string') {
    await performConstantTimeDummyHash();
    return res.status(401).json({ error: 'Date de autentificare incorecte.' });
  }

  const clean = normalizeIdentifier(identifier);
  if (!clean) {
    await performConstantTimeDummyHash();
    return res.status(401).json({ error: 'Date de autentificare incorecte.' });
  }

  if (clean.includes('@')) {
    return res.json({ email: clean, identifierType: 'EMAIL' });
  }

  const resolvedEmail = persistentDb.getEmailByUsername(clean);
  if (resolvedEmail) {
    return res.json({ email: resolvedEmail, identifierType: 'USERNAME' });
  }

  // Mitigation for Timing Attack & User Enumeration:
  await performConstantTimeDummyHash();

  return res.status(401).json({
    error: 'Date de autentificare incorecte.',
  });
});

// POST /api/auth/register-user - Register or sync user profile
router.post('/register-user', authRateLimiter, (req: Request, res: Response) => {
  const { email, username, id, password } = req.body;
  if (!email || !username) {
    return res.status(400).json({ error: 'Emailul și numele de utilizator sunt obligatorii.' });
  }

  const cleanEmail = normalizeIdentifier(email);
  const cleanUsername = username.trim();

  // Password validation: minimum 8 characters & blacklist check
  if (password && typeof password === 'string') {
    if (password.length < 8) {
      return res.status(400).json({ error: 'Parola trebuie să conțină cel puțin 8 caractere.' });
    }
    if (isCommonWeakPassword(password)) {
      return res.status(400).json({ error: 'Parola aleasă este prea comună și ușor de ghicit. Alege o parolă mai sigură.' });
    }
  }

  // Username validation: minimum 2, max 24 chars, valid chars
  if (cleanUsername.length < 2 || cleanUsername.length > 24) {
    return res.status(400).json({ error: 'Numele de utilizator trebuie să aibă între 2 și 24 caractere.' });
  }

  const userId = id || `user-${Buffer.from(cleanEmail).toString('hex').substring(0, 16)}`;

  const profile = persistentDb.updateUserProfile(userId, {
    username: cleanUsername,
    email: cleanEmail,
    avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUsername)}`,
  }) || {
    id: userId,
    username: cleanUsername,
    email: cleanEmail,
    avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUsername)}`,
    createdAt: new Date().toISOString(),
  };

  res.json({ success: true, profile });
});

// POST /api/auth/send-otp - Request 6-digit OTP code via email
router.post('/send-otp', otpRateLimiter, async (req: Request, res: Response) => {
  const { email } = req.body;
  if (!email || typeof email !== 'string') {
    return res.status(400).json({ error: 'Adresa de email este obligatorie.' });
  }
  const cleanEmail = normalizeIdentifier(email);
  const result = await resendService.sendOtpEmail(cleanEmail);
  if (!result.success) {
    return res.status(429).json({ error: result.message, waitSec: result.waitSec });
  }
  res.json(result);
});

// POST /api/auth/verify-otp - Verify OTP and issue cryptographically signed JWT
router.post('/verify-otp', otpRateLimiter, (req: Request, res: Response) => {
  const { email, code, username } = req.body;
  if (!email || !code) {
    return res.status(400).json({ error: 'Emailul și codul de verificare sunt obligatorii.' });
  }

  if (typeof code !== 'string' || code.trim().length !== 6 || !/^\d{6}$/.test(code.trim())) {
    return res.status(400).json({ error: 'Codul trebuie să fie format din exact 6 cifre.' });
  }

  const cleanEmail = normalizeIdentifier(email);
  const result = resendService.verifyOtp(cleanEmail, code);
  if (!result.valid) {
    return res.status(401).json({ error: result.error || 'Codul de verificare este incorect sau a expirat.' });
  }

  const uName = username ? username.trim() : cleanEmail.split('@')[0];
  const userId = `user-${Buffer.from(cleanEmail).toString('hex').substring(0, 16)}`;
  let user = persistentDb.getUserProfile(userId) || persistentDb.getUserByEmail(cleanEmail);

  if (!user) {
    user = {
      id: userId,
      username: uName,
      email: cleanEmail,
      avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(uName)}`,
      bio: 'Entuziast Anime & Manga pe Kurogane.',
      pronouns: 'he/him',
      bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
      createdAt: new Date().toISOString(),
    };
    persistentDb.updateUserProfile(userId, user);
  }

  const token = persistentDb.generateToken(user);

  res.json({ success: true, user, token });
});

export default router;

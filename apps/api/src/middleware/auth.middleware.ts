import { Request, Response, NextFunction } from 'express';
import { persistentDb } from '../services/db-persistent';
import { UserProfile } from '@kurogane/shared';

// Extend Express Request to optionally hold authenticated user
declare global {
  namespace Express {
    interface Request {
      user?: UserProfile;
    }
  }
}

/**
 * Extracts and verifies the bearer token from the Authorization header.
 * Returns the UserProfile if valid, or null otherwise.
 */
export async function authenticateUser(req: Request): Promise<UserProfile | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.substring(7).trim();
  if (!token) {
    return null;
  }
  return await persistentDb.verifyToken(token);
}

/**
 * Express middleware that rejects unauthorized requests with 401 status.
 */
export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  try {
    const user = await authenticateUser(req);
    if (!user) {
      return res.status(401).json({
        error: 'Neautorizat. Autentifică-te pentru a accesa această resursă.',
      });
    }
    req.user = user;
    next();
  } catch (error: any) {
    return res.status(401).json({
      error: 'Eroare la validarea sesiunii de autentificare.',
    });
  }
}

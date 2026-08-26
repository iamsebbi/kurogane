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
export function authenticateUser(req: Request): UserProfile | null {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.substring(7).trim();
  if (!token) {
    return null;
  }
  return persistentDb.verifyToken(token);
}

/**
 * Express middleware that rejects unauthorized requests with 401 status.
 */
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const user = authenticateUser(req);
  if (!user) {
    return res.status(401).json({
      error: 'Neautorizat. Autentifică-te pentru a accesa această resursă.',
    });
  }
  req.user = user;
  next();
}

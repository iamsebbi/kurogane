import { Request, Response, NextFunction } from 'express';

interface RateLimitRecord {
  timestamps: number[];
}

class MemoryRateLimiter {
  private store: Map<string, RateLimitRecord> = new Map();
  private cleanupTimer: NodeJS.Timeout | null = null;
  private maxEntries = 10000;

  constructor() {
    // Run memory cleanup every 5 minutes
    this.cleanupTimer = setInterval(() => this.cleanup(), 5 * 60 * 1000);
    this.cleanupTimer.unref();
  }

  private cleanup(): void {
    const now = Date.now();
    const maxWindow = 15 * 60 * 1000; // 15 min max window
    for (const [key, record] of this.store.entries()) {
      record.timestamps = record.timestamps.filter((t) => now - t < maxWindow);
      if (record.timestamps.length === 0) {
        this.store.delete(key);
      }
    }
  }

  /**
   * Checks if an action is allowed under the rate limit.
   * Returns { allowed: boolean, remaining: number, resetSec: number }
   */
  public check(key: string, maxRequests: number, windowMs: number): { allowed: boolean; remaining: number; resetSec: number } {
    const now = Date.now();
    let record = this.store.get(key);

    if (!record) {
      // Evict oldest record if maximum entries reached
      if (this.store.size >= this.maxEntries) {
        const firstKey = this.store.keys().next().value;
        if (firstKey !== undefined) {
          this.store.delete(firstKey);
        }
      }
      record = { timestamps: [] };
      this.store.set(key, record);
    }

    // Keep only timestamps within window
    record.timestamps = record.timestamps.filter((t) => now - t < windowMs);

    if (record.timestamps.length >= maxRequests) {
      const oldestInWindow = record.timestamps[0];
      const resetSec = Math.max(1, Math.ceil((oldestInWindow + windowMs - now) / 1000));
      return { allowed: false, remaining: 0, resetSec };
    }

    record.timestamps.push(now);
    const remaining = maxRequests - record.timestamps.length;
    const resetSec = Math.ceil(windowMs / 1000);

    return { allowed: true, remaining, resetSec };
  }
}

export const rateLimiter = new MemoryRateLimiter();

/**
 * Express middleware generator for rate limiting authentication endpoints
 */
export function createAuthRateLimiter(options: {
  windowMs?: number;
  maxRequests?: number;
  message?: string;
  keyGenerator?: (req: Request) => string;
}) {
  const windowMs = options.windowMs || 60 * 1000; // default 1 minute
  const maxRequests = options.maxRequests || 5; // default 5 attempts per min
  const message = options.message || 'Prea multe încercări. Te rugăm să încerci din nou mai târziu.';

  return (req: Request, res: Response, next: NextFunction) => {
    // Determine client identifier (IP + optional identifier body)
    const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket.remoteAddress || 'unknown-ip';
    const key = options.keyGenerator ? options.keyGenerator(req) : `auth_${req.path}_${clientIp}`;

    const result = rateLimiter.check(key, maxRequests, windowMs);

    res.setHeader('X-RateLimit-Limit', maxRequests.toString());
    res.setHeader('X-RateLimit-Remaining', result.remaining.toString());
    res.setHeader('X-RateLimit-Reset', result.resetSec.toString());

    if (!result.allowed) {
      res.setHeader('Retry-After', result.resetSec.toString());
      return res.status(429).json({
        error: message,
        retryAfter: result.resetSec,
      });
    }

    next();
  };
}

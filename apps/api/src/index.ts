import './services/env';
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import apiRouter from './routes';

const app = express();
const PORT = process.env.PORT || 4000;

// Security HTTP Headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

// Restricted CORS Policy
const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
  : [
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'https://kurogane.vercel.app',
    ];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow non-browser clients (mobile apps, server-to-server, curl)
      if (!origin) return callback(null, true);
      if (
        allowedOrigins.includes(origin) ||
        allowedOrigins.includes('*') ||
        process.env.NODE_ENV !== 'production'
      ) {
        return callback(null, true);
      }
      return callback(new Error(`Origin-ul '${origin}' nu este autorizat de politica CORS Kurogane.`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  })
);

// Strict Body Parser Limits
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Mount Modular API Routes
app.use('/api', apiRouter);

// Global Express Error Handler Middleware
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('[Global Error Handler]:', err);
  if (res.headersSent) {
    return next(err);
  }
  const statusCode = typeof err.status === 'number' ? err.status : 500;
  res.status(statusCode).json({
    error: 'Eroare internă de server.',
    message: process.env.NODE_ENV === 'production' ? undefined : err.message || 'Unknown server error',
  });
});

// Process-level safety net for unhandled rejections / exceptions
process.on('uncaughtException', (err) => {
  console.error('[FATAL] Uncaught Exception:', err);
});

process.on('unhandledRejection', (reason) => {
  console.error('[FATAL] Unhandled Rejection:', reason);
});

import { persistentDb } from './services/db-persistent';
import { isSupabaseConfigured } from './services/supabase';

async function startServer() {
  if (isSupabaseConfigured) {
    try {
      console.log('⚡ [Startup] Synchronizing persistent state from Supabase Cloud...');
      await persistentDb.syncFromSupabase();
    } catch (syncErr) {
      console.warn('⚠️ [Startup] Initial Cloud sync notice:', syncErr);
    }
  }

  app.listen(PORT, () => {
    console.log(`[Kurogane API] Server running on http://localhost:${PORT}`);
  });
}

startServer();

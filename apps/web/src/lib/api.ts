/**
 * Kurogane API Base URL helper
 * Dynamically resolves to NEXT_PUBLIC_API_URL in production (Vercel)
 * or defaults to http://localhost:4000 in local development.
 */
export const API_BASE_URL = (
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000'
).replace(/\/$/, '');

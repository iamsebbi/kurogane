import { Bindings, WatchlistItemRecord, WatchlistStatus } from '../types';
import { getMediaById } from './anilist';

export function normalizeWatchlistStatus(status: any): WatchlistStatus {
  if (!status || typeof status !== 'string') return 'PLAN_TO_WATCH';
  const s = status.trim().toUpperCase();
  if (s === 'WATCHING') return 'WATCHING';
  if (s === 'COMPLETED') return 'COMPLETED';
  if (s === 'PLAN_TO_WATCH' || s === 'PLANNING') return 'PLAN_TO_WATCH';
  if (s === 'ON_HOLD' || s === 'PAUSED') return 'ON_HOLD';
  if (s === 'DROPPED') return 'DROPPED';
  return 'PLAN_TO_WATCH';
}

export async function getUserWatchlist(
  db: D1Database,
  env: Bindings,
  userId: string
): Promise<WatchlistItemRecord[]> {
  const { results } = await db
    .prepare('SELECT * FROM watchlist WHERE user_id = ? ORDER BY updated_at DESC')
    .bind(userId)
    .all<any>();

  const rawRows = (results || []).map(mapWatchlistRow);

  // Enrich with media objects (posters, titles, episodes, format)
  // Return BOTH media and mediaItem for complete cross-client compatibility
  const enriched = await Promise.all(
    rawRows.map(async (row) => {
      const media = await getMediaById(env, row.mediaId);
      return {
        ...row,
        media: media || undefined,
        mediaItem: media || undefined,
      };
    })
  );

  return enriched;
}

export async function upsertWatchlistItem(
  db: D1Database,
  env: Bindings,
  userId: string,
  mediaId: string,
  status: WatchlistStatus,
  score?: number,
  progressEpisodes: number = 0,
  notes?: string,
  startedAt?: string,
  completedAt?: string
): Promise<WatchlistItemRecord> {
  const existing = await db
    .prepare('SELECT id, created_at, started_at, completed_at FROM watchlist WHERE user_id = ? AND media_id = ?')
    .bind(userId, mediaId)
    .first<any>();

  const id = existing ? existing.id : `witem-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;
  const now = new Date().toISOString();
  const createdAt = existing ? existing.created_at : now;
  const resolvedStartedAt = startedAt !== undefined ? startedAt : (existing?.started_at || null);
  const resolvedCompletedAt = completedAt !== undefined ? completedAt : (existing?.completed_at || null);

  await db.prepare(`
    INSERT INTO watchlist (id, user_id, media_id, status, progress_episodes, score, notes, started_at, completed_at, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, media_id) DO UPDATE SET
      status = excluded.status,
      progress_episodes = excluded.progress_episodes,
      score = excluded.score,
      notes = excluded.notes,
      started_at = excluded.started_at,
      completed_at = excluded.completed_at,
      updated_at = excluded.updated_at
  `).bind(
    id,
    userId,
    mediaId,
    status,
    progressEpisodes,
    score !== undefined && score !== null ? score : null,
    notes || null,
    resolvedStartedAt,
    resolvedCompletedAt,
    createdAt,
    now
  ).run();

  const media = await getMediaById(env, mediaId);

  return {
    id,
    userId,
    mediaId,
    status,
    progressEpisodes,
    score,
    notes,
    startedAt: resolvedStartedAt || undefined,
    completedAt: resolvedCompletedAt || undefined,
    media: media || undefined,
    mediaItem: media || undefined,
    createdAt,
    updatedAt: now,
  };
}

export async function deleteWatchlistItem(
  db: D1Database,
  userId: string,
  mediaId: string
): Promise<boolean> {
  const result = await db
    .prepare('DELETE FROM watchlist WHERE user_id = ? AND media_id = ?')
    .bind(userId, mediaId)
    .run();

  return (result.meta?.changes ?? 0) > 0;
}

function mapWatchlistRow(row: any): WatchlistItemRecord {
  return {
    id: row.id,
    userId: row.user_id,
    mediaId: row.media_id,
    status: normalizeWatchlistStatus(row.status),
    progressEpisodes: row.progress_episodes || 0,
    score: row.score !== null ? row.score : undefined,
    notes: row.notes || undefined,
    startedAt: row.started_at || undefined,
    completedAt: row.completed_at || undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

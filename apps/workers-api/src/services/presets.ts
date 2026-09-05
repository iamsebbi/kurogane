import { WatchOrderPreset } from '../types';

export async function getPresetsForFranchise(
  db: D1Database,
  franchiseRoot: string,
  userId?: string
): Promise<WatchOrderPreset[]> {
  const { results: presets } = await db
    .prepare(`
      SELECT * FROM watch_order_presets 
      WHERE LOWER(franchise_root) = LOWER(?) AND status IN ('active', 'pending_review', 'community_verified')
      ORDER BY upvotes DESC, created_at DESC
    `)
    .bind(franchiseRoot)
    .all<any>();

  if (!presets || presets.length === 0) return [];

  let userVotesMap = new Map<string, string>();
  if (userId) {
    const { results: userVotes } = await db
      .prepare('SELECT preset_id, vote_type FROM preset_votes WHERE user_id = ?')
      .bind(userId)
      .all<any>();

    for (const v of userVotes || []) {
      userVotesMap.set(v.preset_id, v.vote_type);
    }
  }

  return presets.map((p) => {
    let items = [];
    try {
      items = JSON.parse(p.items_json || '[]');
    } catch (e) {
      items = [];
    }

    const userVote = userVotesMap.get(p.id);

    return {
      id: p.id,
      franchiseRoot: p.franchise_root,
      title: p.title,
      description: p.description || '',
      submittedBy: p.submitted_by,
      submitterUsername: p.submitter_username,
      status: p.status,
      upvotes: p.upvotes || 0,
      downvotes: p.downvotes || 0,
      reportCount: p.report_count || 0,
      isSelectiveCurated: Boolean(p.is_selective_curated),
      items,
      hasUpvoted: userVote === 'UP',
      hasDownvoted: userVote === 'DOWN',
      createdAt: p.created_at,
      updatedAt: p.updated_at,
    };
  });
}

export async function submitPreset(
  db: D1Database,
  data: {
    franchiseRoot: string;
    title: string;
    description?: string;
    submittedBy: string;
    submitterUsername: string;
    isSelectiveCurated?: boolean;
    items: Array<{
      mediaId: string;
      position: number;
      isCanon?: boolean;
      note?: string;
    }>;
  }
): Promise<WatchOrderPreset> {
  const id = `preset-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
  const now = new Date().toISOString();
  const itemsWithId = data.items.map((item, idx) => ({
    id: `item-${id}-${idx + 1}`,
    presetId: id,
    mediaId: item.mediaId,
    position: item.position || idx + 1,
    isCanon: item.isCanon ?? true,
    note: item.note || '',
  }));

  const itemsJson = JSON.stringify(itemsWithId);

  await db.prepare(`
    INSERT INTO watch_order_presets (
      id, franchise_root, title, description, submitted_by, submitter_username,
      status, upvotes, downvotes, report_count, is_selective_curated, items_json,
      created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, 'pending_review', 0, 0, 0, ?, ?, ?, ?)
  `).bind(
    id,
    data.franchiseRoot,
    data.title,
    data.description || '',
    data.submittedBy,
    data.submitterUsername,
    data.isSelectiveCurated ? 1 : 0,
    itemsJson,
    now,
    now
  ).run();

  return {
    id,
    franchiseRoot: data.franchiseRoot,
    title: data.title,
    description: data.description || '',
    submittedBy: data.submittedBy,
    submitterUsername: data.submitterUsername,
    status: 'pending_review',
    upvotes: 0,
    downvotes: 0,
    reportCount: 0,
    isSelectiveCurated: Boolean(data.isSelectiveCurated),
    items: itemsWithId,
    createdAt: now,
    updatedAt: now,
  };
}

export async function votePreset(
  db: D1Database,
  presetId: string,
  userId: string,
  voteType: 'UP' | 'DOWN'
): Promise<{ success: boolean; upvotes: number; downvotes: number; userVote: 'UP' | 'DOWN' | null }> {
  const existingVote = await db
    .prepare('SELECT vote_type FROM preset_votes WHERE preset_id = ? AND user_id = ?')
    .bind(presetId, userId)
    .first<any>();

  let newVote: 'UP' | 'DOWN' | null = voteType;

  if (existingVote) {
    if (existingVote.vote_type === voteType) {
      // Toggle off
      await db.prepare('DELETE FROM preset_votes WHERE preset_id = ? AND user_id = ?').bind(presetId, userId).run();
      newVote = null;
    } else {
      // Change vote
      await db.prepare('UPDATE preset_votes SET vote_type = ? WHERE preset_id = ? AND user_id = ?').bind(voteType, presetId, userId).run();
    }
  } else {
    // New vote
    await db.prepare('INSERT INTO preset_votes (preset_id, user_id, vote_type) VALUES (?, ?, ?)').bind(presetId, userId, voteType).run();
  }

  // Recalculate vote counts
  const counts = await db.prepare(`
    SELECT 
      SUM(CASE WHEN vote_type = 'UP' THEN 1 ELSE 0 END) as up,
      SUM(CASE WHEN vote_type = 'DOWN' THEN 1 ELSE 0 END) as down
    FROM preset_votes WHERE preset_id = ?
  `).bind(presetId).first<any>();

  const up = counts?.up || 0;
  const down = counts?.down || 0;

  await db.prepare('UPDATE watch_order_presets SET upvotes = ?, downvotes = ?, updated_at = datetime(\'now\') WHERE id = ?')
    .bind(up, down, presetId)
    .run();

  return {
    success: true,
    upvotes: up,
    downvotes: down,
    userVote: newVote,
  };
}

export async function reportPreset(
  db: D1Database,
  presetId: string,
  userId: string,
  reason: string
): Promise<boolean> {
  const id = `report-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;
  await db.prepare('INSERT INTO preset_reports (id, preset_id, user_id, reason) VALUES (?, ?, ?, ?)')
    .bind(id, presetId, userId, reason)
    .run();

  await db.prepare('UPDATE watch_order_presets SET report_count = report_count + 1 WHERE id = ?')
    .bind(presetId)
    .run();

  return true;
}

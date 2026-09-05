const fs = require('fs');
const path = require('path');

const API_DATA_DIR = path.resolve(__dirname, '../../api/data');
const OUT_SQL = path.resolve(__dirname, 'data-migration.sql');

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
}

let sqlStatements = [];

// 1. Migrate Users
const usersPath = path.join(API_DATA_DIR, 'users-db.json');
if (fs.existsSync(usersPath)) {
  const users = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
  for (const u of users) {
    const favGenres = JSON.stringify(u.favoriteGenres || []);
    sqlStatements.push(
      `INSERT INTO users (id, email, username, avatar_url, bio, pronouns, banner_url, favorite_genres, is_banned, created_at, updated_at) ` +
      `VALUES (${escapeSql(u.id)}, ${escapeSql(u.email)}, ${escapeSql(u.username)}, ${escapeSql(u.avatarUrl)}, ${escapeSql(u.bio || '')}, ${escapeSql(u.pronouns || 'he/him')}, ${escapeSql(u.bannerUrl || '')}, ${escapeSql(favGenres)}, 0, ${escapeSql(u.createdAt || new Date().toISOString())}, ${escapeSql(u.updatedAt || u.createdAt || new Date().toISOString())}) ` +
      `ON CONFLICT(id) DO UPDATE SET email=excluded.email, username=excluded.username, avatar_url=excluded.avatar_url, bio=excluded.bio, pronouns=excluded.pronouns, banner_url=excluded.banner_url, favorite_genres=excluded.favorite_genres;`
    );
  }
}

// 2. Migrate Watchlist
const watchlistPath = path.join(API_DATA_DIR, 'watchlist-db.json');
if (fs.existsSync(watchlistPath)) {
  const watchlist = JSON.parse(fs.readFileSync(watchlistPath, 'utf8'));
  for (const item of watchlist) {
    const scoreVal = item.score !== undefined && item.score !== null ? item.score : 'NULL';
    sqlStatements.push(
      `INSERT INTO watchlist (id, user_id, media_id, status, progress_episodes, score, notes, created_at, updated_at) ` +
      `VALUES (${escapeSql(item.id)}, ${escapeSql(item.userId)}, ${escapeSql(item.mediaId)}, ${escapeSql(item.status || 'PLAN_TO_WATCH')}, ${item.progressEpisodes || 0}, ${scoreVal}, ${escapeSql(item.notes)}, ${escapeSql(item.createdAt || new Date().toISOString())}, ${escapeSql(item.updatedAt || new Date().toISOString())}) ` +
      `ON CONFLICT(user_id, media_id) DO UPDATE SET status=excluded.status, progress_episodes=excluded.progress_episodes, score=excluded.score, notes=excluded.notes, updated_at=excluded.updated_at;`
    );
  }
}

// 3. Migrate Watch Order Presets
const presetsPath = path.join(API_DATA_DIR, 'watch-order-presets-db.json');
if (fs.existsSync(presetsPath)) {
  const presetData = JSON.parse(fs.readFileSync(presetsPath, 'utf8'));
  const presets = presetData.presets || [];
  for (const p of presets) {
    const itemsJson = JSON.stringify(p.items || []);
    sqlStatements.push(
      `INSERT INTO watch_order_presets (id, franchise_root, title, description, submitted_by, submitter_username, status, upvotes, downvotes, report_count, is_selective_curated, items_json, created_at, updated_at) ` +
      `VALUES (${escapeSql(p.id)}, ${escapeSql(p.franchiseRoot)}, ${escapeSql(p.title)}, ${escapeSql(p.description || '')}, ${escapeSql(p.submittedBy)}, ${escapeSql(p.submitterUsername)}, ${escapeSql(p.status || 'pending_review')}, ${p.upvotes || 0}, ${p.downvotes || 0}, ${p.reportCount || 0}, ${p.isSelectiveCurated ? 1 : 0}, ${escapeSql(itemsJson)}, ${escapeSql(p.createdAt || new Date().toISOString())}, ${escapeSql(p.updatedAt || new Date().toISOString())}) ` +
      `ON CONFLICT(id) DO UPDATE SET title=excluded.title, description=excluded.description, status=excluded.status, upvotes=excluded.upvotes, downvotes=excluded.downvotes, report_count=excluded.report_count, items_json=excluded.items_json;`
    );
  }

  const votes = presetData.votes || [];
  for (const v of votes) {
    sqlStatements.push(
      `INSERT INTO preset_votes (preset_id, user_id, vote_type, created_at) ` +
      `VALUES (${escapeSql(v.presetId)}, ${escapeSql(v.userId)}, ${escapeSql(v.voteType || 'UP')}, ${escapeSql(v.createdAt || new Date().toISOString())}) ` +
      `ON CONFLICT(preset_id, user_id) DO UPDATE SET vote_type=excluded.vote_type;`
    );
  }

  const reports = presetData.reports || [];
  for (const r of reports) {
    const reportId = `report-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;
    sqlStatements.push(
      `INSERT INTO preset_reports (id, preset_id, user_id, reason, created_at) ` +
      `VALUES (${escapeSql(reportId)}, ${escapeSql(r.presetId)}, ${escapeSql(r.userId)}, ${escapeSql(r.reason)}, ${escapeSql(r.createdAt || new Date().toISOString())});`
    );
  }
}

fs.writeFileSync(OUT_SQL, sqlStatements.join('\n'), 'utf8');
console.log(`Generated ${sqlStatements.length} SQL statements in ${OUT_SQL}`);

// scripts/audit_endpoints.mjs
const WORKER_URL = 'https://kurogane-api.kurogane-workers-api.workers.dev';
const LOCAL_WRANGLER_URL = 'http://localhost:8787';

const endpoints = [
  { name: 'Root /', path: '/', method: 'GET' },
  { name: 'Health', path: '/api/health', method: 'GET' },
  { name: 'Homepage', path: '/api/homepage', method: 'GET' },
  { name: 'Media Detail (JJK)', path: '/api/media/anilist-113415', method: 'GET' },
  { name: 'Media Relations (JJK)', path: '/api/media/anilist-113415/relations', method: 'GET' },
  { name: 'Media Characters (JJK)', path: '/api/media/anilist-113415/characters', method: 'GET' },
  { name: 'Media Similar (JJK)', path: '/api/media/anilist-113415/similar', method: 'GET' },
  { name: 'Media Watch-Order (JJK)', path: '/api/media/anilist-113415/watch-order', method: 'GET' },
  { name: 'Search (q=jujutsu)', path: '/api/search?q=jujutsu', method: 'GET' },
  { name: 'Search (genre=Action)', path: '/api/search?genre=Action', method: 'GET' },
  { name: 'Search (empty)', path: '/api/search', method: 'GET' },
  { name: 'News (Live RSS)', path: '/api/news', method: 'GET' },
  { name: 'Categories (Shelves)', path: '/api/categories', method: 'GET' },
  { name: 'Watchlist (Requires Auth)', path: '/api/watchlist', method: 'GET' },
  { name: 'Profile (Requires Auth)', path: '/api/user/profile', method: 'GET' },
  { name: 'Auth Check Username', path: '/api/auth/check-username?username=testuserunique999', method: 'GET' },
  { name: 'Auth Resolve Identifier', path: '/api/auth/resolve-identifier', method: 'POST', body: { identifier: 'test@example.com' } },
  { name: 'Test AniList Upstream Health', path: '/test-anilist', method: 'GET' },
];

async function testTarget(baseUrl, name) {
  console.log(`\n========================================`);
  console.log(`Auditing: ${name} (${baseUrl})`);
  console.log(`========================================\n`);

  for (const ep of endpoints) {
    const url = `${baseUrl}${ep.path}`;
    const start = Date.now();
    try {
      const opts = {
        method: ep.method,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      };
      if (ep.body) {
        opts.body = JSON.stringify(ep.body);
      }

      const res = await fetch(url, opts);
      const ms = Date.now() - start;
      const contentType = res.headers.get('content-type') || '';
      let bodyPreview = '';

      if (contentType.includes('application/json')) {
        const json = await res.json();
        bodyPreview = JSON.stringify(json).slice(0, 150);
      } else {
        const text = await res.text();
        bodyPreview = text.slice(0, 150);
      }

      const icon = res.status >= 200 && res.status < 400 ? '✅' : (res.status === 401 ? '🔒' : (res.status === 404 ? '⚠️ 404' : '❌'));
      console.log(`${icon} [${res.status}] ${ep.method} ${ep.path} (${ms}ms) -> ${bodyPreview}`);
    } catch (err) {
      console.log(`ℹ️ [Skipped/Offline] ${ep.method} ${ep.path}: ${err.message}`);
    }
  }
}

async function main() {
  await testTarget(WORKER_URL, 'Cloudflare Workers (Edge API - CANONICAL)');
  try {
    const ping = await fetch(`${LOCAL_WRANGLER_URL}/api/health`);
    if (ping.ok) {
      await testTarget(LOCAL_WRANGLER_URL, 'Local Wrangler Dev (Port 8787)');
    }
  } catch (_) {
    console.log('\n(Local Wrangler Dev on port 8787 is not currently running. Edge API is the active source.)\n');
  }
}

main().catch(console.error);

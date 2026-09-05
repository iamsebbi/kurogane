// Automated Integration / API Unit Test Suite for Kurogane API
import assert from 'node:assert';

const API_BASE = 'https://kurogane-api.kurogane-workers-api.workers.dev';

let passed = 0;
let failed = 0;

async function runTest(name, fn) {
  process.stdout.write(`Testing: ${name}... `);
  try {
    await fn();
    console.log('✅ PASSED');
    passed++;
  } catch (err) {
    console.log(`❌ FAILED: ${err.message}`);
    console.error(err);
    failed++;
  }
}

async function main() {
  console.log(`\n========================================`);
  console.log(`RUNNING KUROGANE API INTEGRATION TESTS`);
  console.log(`Endpoint: ${API_BASE}`);
  console.log(`========================================\n`);

  // 1. Homepage & Seasonal Test
  await runTest('Homepage returns modern seasonal anime and valid hero items', async () => {
    const res = await fetch(`${API_BASE}/api/homepage`);
    assert.strictEqual(res.status, 200, 'Status should be 200');
    const data = await res.json();
    assert.ok(Array.isArray(data.heroItems) && data.heroItems.length > 0, 'heroItems should not be empty');
    assert.ok(Array.isArray(data.featuredSeason) && data.featuredSeason.length > 0, 'featuredSeason should not be empty');
    
    // Check first seasonal item
    const firstSeasonal = data.featuredSeason[0];
    assert.strictEqual(firstSeasonal.season, 'SUMMER', `Seasonal anime season should be SUMMER, but got ${firstSeasonal.season}`);
    assert.strictEqual(firstSeasonal.year, 2026, `Seasonal anime year should be 2026, but got ${firstSeasonal.year}`);
    assert.ok(firstSeasonal.title?.userPreferred, 'Seasonal item must have userPreferred title');
    assert.ok(firstSeasonal.coverImage?.large, 'Seasonal item must have coverImage.large');
  });

  // 2. Acronym Search: JJK
  await runTest('Search expands acronym "jjk" to Jujutsu Kaisen', async () => {
    const res = await fetch(`${API_BASE}/api/search?q=jjk`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.results) && data.results.length > 0, 'Should return results for jjk');
    const matched = data.results.some(r => 
      (r.title?.userPreferred || '').toLowerCase().includes('jujutsu') ||
      (r.title?.romaji || '').toLowerCase().includes('jujutsu')
    );
    assert.ok(matched, 'Results should contain Jujutsu Kaisen');
  });

  // 3. Acronym Search: AOT
  await runTest('Search expands acronym "aot" to Attack on Titan', async () => {
    const res = await fetch(`${API_BASE}/api/search?q=aot`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.results) && data.results.length > 0, 'Should return results for aot');
    const matched = data.results.some(r => 
      (r.title?.userPreferred || '').toLowerCase().includes('titan') ||
      (r.title?.romaji || '').toLowerCase().includes('shingeki')
    );
    assert.ok(matched, 'Results should contain Attack on Titan / Shingeki no Kyojin');
  });

  // 4. Acronym Search: KNY
  await runTest('Search expands acronym "kny" to Demon Slayer / Kimetsu', async () => {
    const res = await fetch(`${API_BASE}/api/search?q=kny`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.results) && data.results.length > 0, 'Should return results for kny');
    const matched = data.results.some(r => 
      (r.title?.userPreferred || '').toLowerCase().includes('demon slayer') ||
      (r.title?.romaji || '').toLowerCase().includes('kimetsu')
    );
    assert.ok(matched, 'Results should contain Kimetsu no Yaiba');
  });

  // 5. Acronym Search: FMA
  await runTest('Search expands acronym "fma" to Fullmetal Alchemist', async () => {
    const res = await fetch(`${API_BASE}/api/search?q=fma`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.results) && data.results.length > 0, 'Should return results for fma');
    const matched = data.results.some(r => 
      (r.title?.userPreferred || '').toLowerCase().includes('fullmetal') ||
      (r.title?.romaji || '').toLowerCase().includes('hagane')
    );
    assert.ok(matched, 'Results should contain Fullmetal Alchemist');
  });

  // 6. Format Filtering
  await runTest('Search filters correctly by format=MOVIE', async () => {
    const res = await fetch(`${API_BASE}/api/search?format=MOVIE&limit=10`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.results) && data.results.length > 0, 'Should return movies');
    for (const item of data.results) {
      assert.strictEqual(item.format, 'MOVIE', `Item ${item.id} should have format MOVIE`);
    }
  });

  // 7. Sort by Year Descending
  await runTest('Search sorting by YEAR_DESC returns modern anime first', async () => {
    const res = await fetch(`${API_BASE}/api/search?sortBy=YEAR_DESC&limit=10`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.results) && data.results.length > 0, 'Should return results');
    const firstYear = data.results[0].year || 0;
    assert.ok(firstYear >= 2024, `First item should be recent (>= 2024), but got ${firstYear}`);
  });

  // 8. Sequel Synthesized Relation
  await runTest('Media detail for sequel (anilist-180860) succeeds without 404', async () => {
    const res = await fetch(`${API_BASE}/api/media/anilist-180860`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(data.id === 'anilist-180860', 'Should return media object for anilist-180860');
    assert.ok(data.title?.userPreferred || data.title?.romaji, 'Should have valid title');
    assert.ok(data.coverImage?.large, 'Should have cover image');
  });

  // 9. Similar Media Payload Contract
  await runTest('Similar media returns both similarItems array and items', async () => {
    const res = await fetch(`${API_BASE}/api/media/anilist-154587/similar`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.similarItems), 'Response must contain similarItems array');
    assert.ok(Array.isArray(data.items), 'Response must contain items array');
    if (data.similarItems.length > 0) {
      assert.ok(data.similarItems[0].item, 'similarItems entry must contain item subkey for Flutter compatibility');
    }
  });

  // 10. Watchlist Enrichment Test
  await runTest('User watchlist returns fully enriched media and mediaItem objects', async () => {
    const res = await fetch(`${API_BASE}/api/user/milbei/watchlist`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.items), 'Watchlist must return items array');
    for (const item of data.items) {
      assert.ok(item.media, `Item ${item.mediaId} must have enriched media`);
      assert.ok(item.mediaItem, `Item ${item.mediaId} must have enriched mediaItem`);
      assert.ok(item.media.title?.userPreferred, `Item ${item.mediaId} media must have userPreferred title`);
      assert.ok(item.media.coverImage?.large, `Item ${item.mediaId} media must have cover image`);
    }
  });

  // 11. Watch Order Preset Vote Route
  await runTest('Watch order preset vote endpoint route is registered (not 404)', async () => {
    const res = await fetch(`${API_BASE}/api/media/watch-order/presets/test-preset/vote`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ vote: 1 }),
    });
    // Expected 401 Unauthorized since no token provided, but NEVER 404 Not Found!
    assert.notStrictEqual(res.status, 404, 'Route should exist and not return 404');
    assert.strictEqual(res.status, 401, 'Should require authentication (401)');
  });

  // 12. Media Relations Endpoint Test
  await runTest('Media Relations endpoint returns rich relations for series', async () => {
    const res = await fetch(`${API_BASE}/api/media/113415/relations`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.relations), 'Response should have relations array');
    assert.ok(data.relations.length >= 2, `Expected >= 2 relations for JJK, got ${data.relations.length}`);
    const hasSequel = data.relations.some(r => r.relationType === 'SEQUEL' || r.relationType === 'PREQUEL');
    assert.ok(hasSequel, 'Should contain prequel or sequel');
  });

  // 13. Media Characters Endpoint Test
  await runTest('Media Characters endpoint returns rich character roster', async () => {
    const res = await fetch(`${API_BASE}/api/media/113415/characters`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(Array.isArray(data.characters), 'Response should have characters array');
    assert.ok(data.characters.length >= 4, `Expected >= 4 characters for JJK, got ${data.characters.length}`);
    const firstChar = data.characters[0];
    assert.ok(firstChar.name && firstChar.name !== 'Main Character', 'Character should have authentic name');
    assert.ok(firstChar.image, 'Character should have image url');
  });

  console.log(`\n========================================`);
  console.log(`TEST SUMMARY: ${passed} passed, ${failed} failed`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

main().catch(err => {
  console.error('Fatal error in test suite:', err);
  process.exit(1);
});

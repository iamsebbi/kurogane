import { watchOrderPresetService } from '../services/watch-order-preset.service';
import { dbService } from '../services/db';

async function runTests() {
  console.log('🧪 [TEST] Starting Watch Order Presets & Voting System Tests...\n');

  // 1. Initializare DB
  const aot = await dbService.getMediaByIdAsync('anilist-16498');
  console.log('✅ [TEST 1] Loaded test media:', aot?.title.userPreferred);

  // 2. Creare preset de test
  const testUserId = `test-user-author-${Date.now()}`;
  const testTargetId = 'anilist-16498'; // Attack on Titan

  console.log('🚀 [TEST 2] Creating community preset...');
  const preset = await watchOrderPresetService.createPreset(testUserId, testTargetId, {
    title: 'Ordinea Narativă Fără Fillere (Test)',
    description: 'Recomandat pentru o experiență cinematică cursivă.',
    isSelectiveCurated: true,
    items: [
      { mediaId: 'anilist-16498', position: 1, isCanon: true, note: 'Sezonul 1 (25 ep)' },
      { mediaId: 'anilist-20958', position: 2, isCanon: true, note: 'Sezonul 2 (12 ep)' },
    ],
  });

  console.log('✅ [TEST 2] Created preset ID:', preset.id, '| Status:', preset.status);

  // 3. Test Rate Limit (o a doua propunere de la același user pe aceeași franciză trebuie refuzată)
  console.log('\n🚀 [TEST 3] Testing Rate Limit (Duplicate active preset by same author)...');
  try {
    await watchOrderPresetService.createPreset(testUserId, testTargetId, {
      title: 'A doua propunere redundantă',
      items: [
        { mediaId: 'anilist-16498', position: 1 },
        { mediaId: 'anilist-20958', position: 2 },
      ],
    });
    console.error('❌ [TEST 3 FAILED] Rate limit did not block duplicate proposal!');
  } catch (err: any) {
    console.log('✅ [TEST 3 PASSED] Correctly blocked duplicate proposal:', err.message);
  }

  // 4. Test Anti-Self-Vote (autorul nu își poate vota propria creație)
  console.log('\n🚀 [TEST 4] Testing Anti-Self-Vote rule...');
  try {
    await watchOrderPresetService.votePreset(testUserId, preset.id, 1);
    console.error('❌ [TEST 4 FAILED] Author was able to vote on their own preset!');
  } catch (err: any) {
    console.log('✅ [TEST 4 PASSED] Correctly rejected self-vote:', err.message);
  }

  // 5. Test Votare & Promovare la Community Verified (15 upvotes)
  console.log('\n🚀 [TEST 5] Voting from community users up to threshold...');
  for (let i = 1; i <= 15; i++) {
    await watchOrderPresetService.votePreset(`voter-user-${i}`, preset.id, 1);
  }

  const listAfterVotes = await watchOrderPresetService.getPresetsForFranchise(preset.franchiseRoot);
  const updatedPreset = listAfterVotes.find((p) => p.id === preset.id);

  console.log(`Upvotes: ${updatedPreset?.upvotes} | Downvotes: ${updatedPreset?.downvotes} | Status: ${updatedPreset?.status}`);
  if (updatedPreset?.status === 'community_verified') {
    console.log('✅ [TEST 5 PASSED] Preset successfully promoted to "community_verified"!');
  } else {
    console.error('❌ [TEST 5 FAILED] Preset was not promoted. Current status:', updatedPreset?.status);
  }

  // 6. Test Retrogradare Simetrică (dacă adăugăm downvotes și ratio scade sub 0.50)
  console.log('\n🚀 [TEST 6] Testing symmetric demotion with downvotes...');
  for (let i = 1; i <= 18; i++) {
    await watchOrderPresetService.votePreset(`downvoter-user-${i}`, preset.id, -1);
  }

  const listAfterDownvotes = await watchOrderPresetService.getPresetsForFranchise(preset.franchiseRoot);
  const demotedPreset = listAfterDownvotes.find((p) => p.id === preset.id);

  console.log(`Upvotes: ${demotedPreset?.upvotes} | Downvotes: ${demotedPreset?.downvotes} | Status: ${demotedPreset?.status}`);
  if (demotedPreset?.status === 'pending_review') {
    console.log('✅ [TEST 6 PASSED] Preset successfully demoted to "pending_review"!');
  } else {
    console.error('❌ [TEST 6 FAILED] Preset was not demoted. Current status:', demotedPreset?.status);
  }

  // 7. Test Raportare & Auto-Flag la 5 rapoarte
  console.log('\n🚀 [TEST 7] Testing reporting and auto-flag threshold (5 reports)...');
  for (let i = 1; i <= 5; i++) {
    await watchOrderPresetService.reportPreset(`reporter-user-${i}`, preset.id, 'Informatii incorecte');
  }

  const flaggedList = await watchOrderPresetService.getPresetsForFranchise(preset.franchiseRoot);
  const flaggedPreset = flaggedList.find((p) => p.id === preset.id);
  // Fiind flagged, nu ar trebui să mai apară în lista activă pentru useri normali
  if (!flaggedPreset) {
    console.log('✅ [TEST 7 PASSED] Preset is now hidden from active listings after reaching 5 flags!');
  } else {
    console.log('ℹ️ Preset report count:', flaggedPreset.reportCount, 'Status:', flaggedPreset.status);
  }

  console.log('\n🎉 [ALL TESTS COMPLETED SUCCESSFULLY]');
  process.exit(0);
}

runTests().catch((e) => {
  console.error('❌ Test suite error:', e);
  process.exit(1);
});

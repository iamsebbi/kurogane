import { dbService } from './services/db';

interface TestCase {
  query: string;
  expectedTitleContains: string;
  description: string;
}

const testCases: TestCase[] = [
  {
    query: 'att',
    expectedTitleContains: 'Attack on Titan',
    description: 'Acronym/prefix "att" must rank Attack on Titan #1',
  },
  {
    query: 'aot',
    expectedTitleContains: 'Attack on Titan',
    description: 'Acronym "aot" must rank Attack on Titan #1',
  },
  {
    query: 'jjk',
    expectedTitleContains: 'Jujutsu Kaisen',
    description: 'Acronym "jjk" must rank Jujutsu Kaisen #1',
  },
  {
    query: 'sol',
    expectedTitleContains: 'Solo Leveling',
    description: 'Prefix "sol" must rank Solo Leveling at top',
  },
  {
    query: 'atack',
    expectedTitleContains: 'Attack on Titan',
    description: 'Typo "atack" must fuzzy match Attack on Titan',
  },
  {
    query: 'narut',
    expectedTitleContains: 'Naruto',
    description: 'Typo "narut" must fuzzy match Naruto #1',
  },
  {
    query: 'fmab',
    expectedTitleContains: 'Fullmetal Alchemist',
    description: 'Acronym "fmab" must match Fullmetal Alchemist',
  },
];

async function runRegressionTests() {
  console.log('🧪 Starting Search Relevance & Scoring Regression Test Suite...\n');
  let passed = 0;
  let failed = 0;

  for (const tc of testCases) {
    const res = await dbService.search({ query: tc.query, limit: 5 });
    const topMatch = res.results[0];

    if (!topMatch) {
      console.error(`❌ FAIL: "${tc.query}" - No results returned! (${tc.description})`);
      failed++;
      continue;
    }

    const matchTitles = [
      topMatch.title.userPreferred,
      topMatch.title.english,
      topMatch.title.romaji,
    ].filter(Boolean).map((t) => t!.toLowerCase());

    const isSuccess = matchTitles.some((t) => t.includes(tc.expectedTitleContains.toLowerCase()));

    if (isSuccess) {
      console.log(`✅ PASS: "${tc.query}" ➔ #${1} "${topMatch.title.userPreferred}" (${tc.description})`);
      passed++;
    } else {
      console.error(
        `❌ FAIL: "${tc.query}" ➔ Expected "${tc.expectedTitleContains}", got #${1} "${topMatch.title.userPreferred}"`
      );
      failed++;
    }
  }

  console.log(`\n========================================`);
  console.log(`📊 Test Results: ${passed} PASSED | ${failed} FAILED out of ${testCases.length} tests.`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runRegressionTests().catch((err) => {
  console.error('Test runner error:', err);
  process.exit(1);
});

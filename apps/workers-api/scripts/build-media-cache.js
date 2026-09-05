const fs = require('fs');

async function getKitsuAnime(searchText) {
  const url = `https://kitsu.io/api/edge/anime?filter[text]=${encodeURIComponent(searchText)}&include=characters.character,genres&page[limit]=1`;
  const res = await fetch(url, { headers: { 'Accept': 'application/vnd.api+json' } });
  if (!res.ok) return null;
  const json = await res.json();
  if (!json.data || json.data.length === 0) return null;
  return { main: json.data[0], included: json.included || [] };
}

function mapKitsuToMedia(anilistId, kitsuData, overrideThemes = []) {
  const a = kitsuData.main.attributes;
  const id = `anilist-${anilistId}`;
  const inc = kitsuData.included;

  const characters = inc
    .filter(i => i.type === 'characters')
    .slice(0, 12)
    .map(c => ({
      id: parseInt(c.id, 10),
      name: c.attributes?.name || c.attributes?.canonicalName || 'Character',
      image: c.attributes?.image?.original || c.attributes?.image?.medium || '',
      role: 'MAIN',
    }));

  const genres = inc
    .filter(i => i.type === 'genres')
    .map(g => g.attributes?.name)
    .filter(Boolean);

  const avgScore = a.averageRating ? Math.round(parseFloat(a.averageRating)) / 10 : 8.0;

  const themes = overrideThemes.map(t => ({
    title: t.title,
    type: t.type || 'OPENING',
    artist: t.artist || '',
  }));

  const format = (a.subtype || 'TV').toUpperCase();
  let status = 'FINISHED';
  if (a.status === 'current') status = 'RELEASING';
  if (a.status === 'unreleased') status = 'UPCOMING';

  const year = a.startDate ? parseInt(a.startDate.split('-')[0], 10) : 2024;

  let franchiseId = undefined;
  const titleLower = (a.canonicalTitle || '').toLowerCase();
  if (titleLower.includes('titan') || titleLower.includes('kyojin')) franchiseId = 'attack-on-titan';
  if (titleLower.includes('demon slayer') || titleLower.includes('kimetsu')) franchiseId = 'demon-slayer';
  if (titleLower.includes('naruto') || titleLower.includes('boruto')) franchiseId = 'naruto-series';
  if (titleLower.includes('mushoku')) franchiseId = 'mushoku-tensei';
  if (titleLower.includes('frieren')) franchiseId = 'frieren-series';
  if (titleLower.includes('solo leveling')) franchiseId = 'solo-leveling';

  return {
    id,
    anilistId,
    title: {
      romaji: a.titles?.en_jp || a.canonicalTitle,
      english: a.titles?.en || a.canonicalTitle,
      native: a.titles?.ja_jp || a.canonicalTitle,
      userPreferred: a.canonicalTitle || a.titles?.en || a.titles?.en_jp || 'Anime',
    },
    type: 'ANIME',
    format,
    status,
    season: 'SPRING',
    episodes: a.episodeCount || 12,
    genres: genres.length > 0 ? genres : ['Action', 'Adventure', 'Fantasy'],
    studios: ['Animation Studio'],
    description: (a.synopsis || a.description || '').replace(/\r\n/g, '\n'),
    coverImage: {
      extraLarge: a.posterImage?.large || a.posterImage?.original || '',
      large: a.posterImage?.medium || a.posterImage?.large || '',
      medium: a.posterImage?.small || '',
      color: '#3b82f6',
    },
    bannerImage: a.coverImage?.large || a.coverImage?.original || a.posterImage?.large || null,
    trailerUrl: a.youtubeVideoId ? `https://www.youtube.com/watch?v=${a.youtubeVideoId}` : null,
    year,
    scores: {
      averageScore: avgScore,
      reviewCount: a.userCount || 15000,
      weightedScore: avgScore,
    },
    franchiseId,
    characters,
    staff: [
      { id: 1, name: 'Director', role: 'Director' },
      { id: 2, name: 'Music Composer', role: 'Music' }
    ],
    themes,
    source: 'ANILIST',
    relations: [],
  };
}

async function main() {
  const seedTargets = [
    {
      anilistId: 101922,
      search: 'Kimetsu no Yaiba',
      themes: [
        { title: 'Gurenge', artist: 'LiSA', type: 'OPENING' },
        { title: 'from the edge', artist: 'FictionJunction feat. LiSA', type: 'ENDING' }
      ]
    },
    {
      anilistId: 154587,
      search: 'Sousou no Frieren',
      themes: [
        { title: 'Yuusha', artist: 'YOASOBI', type: 'OPENING' },
        { title: 'Anytime Anywhere', artist: 'milet', type: 'ENDING' }
      ]
    },
    {
      anilistId: 159309,
      search: 'Mushoku Tensei Season 2',
      themes: [
        { title: 'spiral', artist: 'LONGMAN', type: 'OPENING' },
        { title: 'Musubime', artist: 'Yuiko Ohara', type: 'ENDING' }
      ]
    },
    {
      anilistId: 16498,
      search: 'Shingeki no Kyojin',
      themes: [
        { title: 'Guren no Yumiya', artist: 'Linked Horizon', type: 'OPENING' },
        { title: 'Utsukushiki Zankoku na Sekai', artist: 'Yoko Hikasa', type: 'ENDING' }
      ]
    },
    {
      anilistId: 182255,
      search: 'Solo Leveling',
      themes: [
        { title: 'LEveL', artist: 'SawanoHiroyuki[nZk]:TOMORROW X TOGETHER', type: 'OPENING' },
        { title: 'request', artist: 'krage', type: 'ENDING' }
      ]
    },
    {
      anilistId: 204466,
      search: 'Make Heroine ga Oosugiru',
      themes: [
        { title: 'Tsuyogaru Girl', artist: 'BotchiBoromaru feat. Mossa', type: 'OPENING' },
        { title: 'LOVE 2000', artist: 'Anna Yanami', type: 'ENDING' }
      ]
    },
    {
      anilistId: 207141,
      search: 'Oshi no Ko Season 2',
      themes: [
        { title: 'Fatal', artist: 'GEMN', type: 'OPENING' },
        { title: 'Burning', artist: 'Hitsujibungaku', type: 'ENDING' }
      ]
    },
    {
      anilistId: 20,
      search: 'Naruto',
      themes: [
        { title: 'Rocks', artist: 'Hound Dog', type: 'OPENING' },
        { title: 'Wind', artist: 'Akeboshi', type: 'ENDING' }
      ]
    },
    {
      anilistId: 1735,
      search: 'Naruto Shippuuden',
      themes: [
        { title: 'Blue Bird', artist: 'Ikimono Gakari', type: 'OPENING' },
        { title: 'Silhouette', artist: 'KANA-BOON', type: 'OPENING' }
      ]
    },
    {
      anilistId: 21,
      search: 'One Piece',
      themes: [
        { title: 'We Are!', artist: 'Hiroshi Kitadani', type: 'OPENING' }
      ]
    },
    {
      anilistId: 269,
      search: 'Bleach',
      themes: [
        { title: 'Asterisk', artist: 'Orange Range', type: 'OPENING' }
      ]
    }
  ];

  const results = {};
  for (const t of seedTargets) {
    try {
      console.log(`Fetching Kitsu data for ${t.search}...`);
      const k = await getKitsuAnime(t.search);
      if (k) {
        const mapped = mapKitsuToMedia(t.anilistId, k, t.themes);
        results[t.anilistId] = mapped;
        console.log(`-> Mapped ${mapped.id}: ${mapped.title.userPreferred} (characters: ${mapped.characters.length}, themes: ${mapped.themes.length})`);
      }
    } catch (err) {
      console.error(`Error fetching ${t.search}:`, err.message);
    }
  }

  fs.writeFileSync('D:/kurogane/apps/workers-api/scripts/seed-anime-cache.json', JSON.stringify(results, null, 2), 'utf8');
  console.log('Saved seed-anime-cache.json with', Object.keys(results).length, 'anime.');
}

main();

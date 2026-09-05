import { Bindings } from '../types';
import STATIC_SEED_RAW from '../data/seed-anime-rich.json';

const STATIC_SEED: Record<string, any> = STATIC_SEED_RAW as Record<string, any>;
const ANILIST_GRAPHQL_ENDPOINT = 'https://graphql.anilist.co';

const MEDIA_QUERY_FRAGMENT = `
  id
  type
  format
  status
  description(asHtml: false)
  startDate { year month day }
  season
  seasonYear
  episodes
  duration
  chapters
  volumes
  countryOfOrigin
  isAdult
  genres
  synonyms
  averageScore
  meanScore
  popularity
  favourites
  trending
  title {
    romaji
    english
    native
    userPreferred
  }
  coverImage {
    extraLarge
    large
    medium
    color
  }
  bannerImage
  studios(isMain: true) {
    nodes {
      name
      isAnimationStudio
    }
  }
  trailer {
    id
    site
  }
  characters(sort: [ROLE, RELEVANCE], perPage: 16) {
    edges {
      role
      node {
        id
        name {
          userPreferred
          full
        }
        image {
          large
          medium
        }
      }
      voiceActors(language: JAPANESE, sort: [RELEVANCE]) {
        id
        name {
          userPreferred
          full
        }
        image {
          large
          medium
        }
        languageV2
      }
    }
  }
  staff(sort: [RELEVANCE], perPage: 12) {
    edges {
      role
      node {
        id
        name {
          userPreferred
          full
        }
        image {
          large
          medium
        }
      }
    }
  }
  relations {
    edges {
      relationType(version: 2)
      node {
        id
        type
        format
        status
        season
        seasonYear
        episodes
        title {
          userPreferred
          english
          romaji
        }
        coverImage {
          extraLarge
          large
          medium
          color
        }
        startDate {
          year
        }
      }
    }
  }
`;

export function formatMediaItem(raw: any): any {
  if (!raw) return null;
  const anilistId = typeof raw.id === 'number'
    ? raw.id
    : parseInt(String(raw.id).replace('anilist-', ''), 10);
  const id = `anilist-${anilistId}`;

  const studios = (raw.studios?.nodes || raw.studios || []).map((s: any) =>
    typeof s === 'string' ? s : s.name
  ).filter(Boolean);

  let trailerUrl: string | undefined = raw.trailerUrl || undefined;
  if (!trailerUrl && raw.trailer?.site === 'youtube' && raw.trailer.id) {
    trailerUrl = `https://www.youtube.com/watch?v=${raw.trailer.id}`;
  }

  const averageScore = raw.scores?.averageScore !== undefined
    ? raw.scores.averageScore
    : (raw.averageScore ? Math.round((raw.averageScore / 10) * 10) / 10 : 0);

  // Map Characters
  const characters = (raw.characters?.edges || raw.characters || []).map((edge: any) => {
    // If it's already flat (e.g. from static seed)
    if (edge.name && !edge.node) {
      return {
        id: edge.id || Math.floor(Math.random() * 100000),
        name: typeof edge.name === 'string' ? edge.name : (edge.name?.userPreferred || 'Character'),
        image: typeof edge.image === 'string' ? edge.image : (edge.image?.large || edge.image?.medium || ''),
        role: edge.role || 'MAIN',
        voiceActor: edge.voiceActor ? {
          id: edge.voiceActor.id || 0,
          name: typeof edge.voiceActor.name === 'string' ? edge.voiceActor.name : (edge.voiceActor.name?.userPreferred || ''),
          image: typeof edge.voiceActor.image === 'string' ? edge.voiceActor.image : (edge.voiceActor.image?.medium || ''),
          language: edge.voiceActor.language || 'Japanese',
        } : undefined,
      };
    }

    // From AniList GraphQL
    const va = edge.voiceActors?.[0];
    return {
      id: edge.node?.id || Math.floor(Math.random() * 100000),
      name: edge.node?.name?.userPreferred || edge.node?.name?.full || 'Character',
      image: edge.node?.image?.large || edge.node?.image?.medium || '',
      role: edge.role || 'MAIN',
      voiceActor: va ? {
        id: va.id,
        name: va.name?.userPreferred || va.name?.full || '',
        image: va.image?.medium || va.image?.large || '',
        language: va.languageV2 || 'Japanese',
      } : undefined,
    };
  });

  // Map Staff
  const staff = (raw.staff?.edges || raw.staff || []).map((edge: any) => {
    if (edge.name && !edge.node) {
      return {
        id: edge.id || Math.floor(Math.random() * 100000),
        name: typeof edge.name === 'string' ? edge.name : (edge.name?.userPreferred || 'Staff Member'),
        image: typeof edge.image === 'string' ? edge.image : (edge.image?.large || edge.image?.medium || ''),
        role: edge.role || 'Production Staff',
      };
    }
    return {
      id: edge.node?.id || Math.floor(Math.random() * 100000),
      name: edge.node?.name?.userPreferred || edge.node?.name?.full || 'Staff Member',
      image: edge.node?.image?.large || edge.node?.image?.medium || '',
      role: edge.role || 'Production Staff',
    };
  });

  // Map Themes (Must have type 'OP' or 'ED' and artists as array for Flutter)
  const themes = (raw.themes || []).map((t: any) => {
    let type = (t.type || 'OP').toUpperCase();
    if (type === 'OPENING') type = 'OP';
    if (type === 'ENDING') type = 'ED';

    const artists = Array.isArray(t.artists)
      ? t.artists
      : (t.artist ? [String(t.artist)] : ['Original Artist']);

    return {
      type,
      title: t.title || 'Theme Song',
      artists,
      episodes: t.episodes || null,
    };
  });

  // Map Relations (Flutter expects flat fields on MediaRelation)
  const relations = (raw.relations?.edges || raw.relations || []).map((edge: any) => {
    if (edge.title && !edge.node) {
      const relAnilistId = edge.anilistId || (edge.id ? parseInt(String(edge.id).replace('anilist-', ''), 10) : undefined);
      return {
        id: edge.id || (relAnilistId ? `anilist-${relAnilistId}` : ''),
        anilistId: relAnilistId,
        relationType: edge.relationType || 'OTHER',
        title: typeof edge.title === 'string' ? edge.title : (edge.title?.userPreferred || edge.title?.romaji || 'Titlu Conex'),
        format: edge.format || 'TV',
        type: edge.type || 'ANIME',
        status: edge.status || 'FINISHED',
        season: edge.season || null,
        episodes: edge.episodes || null,
        releaseYear: edge.releaseYear || edge.year || null,
        coverImage: typeof edge.coverImage === 'string' ? edge.coverImage : (edge.coverImage?.large || edge.coverImage?.medium || ''),
        media: edge.media || undefined,
      };
    }

    const node = edge.node || {};
    const relAnilistId = node.id;
    const titleStr = typeof node.title === 'string'
      ? node.title
      : (node.title?.userPreferred || node.title?.romaji || node.title?.english || 'Titlu Conex');
    const coverStr = typeof node.coverImage === 'string'
      ? node.coverImage
      : (node.coverImage?.extraLarge || node.coverImage?.large || node.coverImage?.medium || '');

    return {
      id: `anilist-${relAnilistId}`,
      anilistId: relAnilistId,
      relationType: edge.relationType || 'OTHER',
      title: titleStr,
      format: node.format || 'TV',
      type: node.type || 'ANIME',
      status: node.status || 'FINISHED',
      season: node.season || null,
      episodes: node.episodes || null,
      releaseYear: node.startDate?.year || node.seasonYear || null,
      coverImage: coverStr,
      media: {
        id: `anilist-${relAnilistId}`,
        anilistId: relAnilistId,
        type: node.type || 'ANIME',
        format: node.format || 'TV',
        status: node.status || 'FINISHED',
        title: titleStr,
        coverImage: coverStr,
        year: node.startDate?.year || node.seasonYear || null,
      }
    };
  });

  // Resolve Franchise ID
  let franchiseId: string | undefined = raw.franchiseId;
  if (!franchiseId) {
    const titleLower = (raw.title?.userPreferred || raw.title?.romaji || raw.title?.english || '').toLowerCase();
    if (titleLower.includes('titan') || titleLower.includes('kyojin')) franchiseId = 'attack-on-titan';
    else if (titleLower.includes('demon slayer') || titleLower.includes('kimetsu')) franchiseId = 'demon-slayer';
    else if (titleLower.includes('naruto') || titleLower.includes('boruto')) franchiseId = 'naruto-series';
    else if (titleLower.includes('frieren')) franchiseId = 'frieren';
    else if (titleLower.includes('mushoku')) franchiseId = 'mushoku-tensei';
    else if (titleLower.includes('level up') || titleLower.includes('solo level')) franchiseId = 'solo-leveling';
    else if (titleLower.includes('losing heroines') || titleLower.includes('makeine') || titleLower.includes('make heroine')) franchiseId = 'makeine';
    else if (titleLower.includes('oshi no ko')) franchiseId = 'oshi-no-ko';
    else if (titleLower.includes('jujutsu')) franchiseId = 'jujutsu-kaisen';
    else if (titleLower.includes('chainsaw')) franchiseId = 'chainsaw-man';
    else if (titleLower.includes('bleach')) franchiseId = 'bleach';
    else if (titleLower.includes('one piece')) franchiseId = 'one-piece';
    else if (titleLower.includes('fate/')) franchiseId = 'fate-series';
    else if (titleLower.includes('hero academia') || titleLower.includes('boku no hero')) franchiseId = 'my-hero-academia';
    else if (titleLower.includes('slime') || titleLower.includes('tensei shitara slime')) franchiseId = 'tensei-slime';
    else if (titleLower.includes('haikyuu')) franchiseId = 'haikyuu';
    else if (titleLower.includes('vinland')) franchiseId = 'vinland-saga';
    else if (titleLower.includes('dandadan')) franchiseId = 'dandadan';
    else if (titleLower.includes('bocchi')) franchiseId = 'bocchi-rock';
    else if (titleLower.includes('death note')) franchiseId = 'death-note';
    else if (titleLower.includes('fullmetal') || titleLower.includes('hagane no renkinjutsushi')) franchiseId = 'fma';
  }

  return {
    id,
    anilistId,
    title: {
      romaji: raw.title?.romaji || '',
      english: raw.title?.english || null,
      native: raw.title?.native || null,
      userPreferred: raw.title?.userPreferred || raw.title?.english || raw.title?.romaji || 'Unknown Title',
    },
    type: raw.type || 'ANIME',
    format: raw.format || 'TV',
    status: raw.status || 'FINISHED',
    season: raw.season || null,
    episodes: raw.episodes || null,
    genres: raw.genres || [],
    microTags: raw.microTags || raw.genres || [],
    studios: studios.length > 0 ? studios : ['Animation Studio'],
    description: raw.description ? raw.description.replace(/<[^>]*>?/gm, '') : '',
    coverImage: {
      extraLarge: raw.coverImage?.extraLarge || raw.coverImage?.large || '',
      large: raw.coverImage?.large || raw.coverImage?.medium || '',
      medium: raw.coverImage?.medium || '',
      color: raw.coverImage?.color || '#3b82f6',
    },
    bannerImage: raw.bannerImage || null,
    trailerUrl: trailerUrl || null,
    year: raw.year || raw.startDate?.year || raw.seasonYear || null,
    scores: {
      averageScore,
      reviewCount: raw.scores?.reviewCount || raw.popularity || raw.favourites || 10000,
      weightedScore: averageScore,
    },
    franchiseId,
    characters,
    staff,
    themes,
    source: raw.source || 'ANILIST',
    relations,
  };
}

export async function fetchAniListGraphQL(
  env: Bindings,
  query: string,
  variables: Record<string, any> = {}
): Promise<any> {
  const anilistUrl = env.ANILIST_API_URL || ANILIST_GRAPHQL_ENDPOINT;
  try {
    const res = await fetch(anilistUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'KuroganeApp/1.0',
      },
      body: JSON.stringify({ query, variables }),
    });

    if (!res.ok) {
      return null;
    }

    const json: any = await res.json();
    return json?.data || null;
  } catch (err: any) {
    return null;
  }
}

// Real-time search fallback via Kitsu API
async function searchKitsuApi(query: string, limit: number = 20): Promise<any[]> {
  try {
    const safeLimit = Math.min(Math.max(1, limit || 20), 20);
    const url = `https://kitsu.io/api/edge/anime?filter[text]=${encodeURIComponent(query)}&page[limit]=${safeLimit}&include=genres`;
    const res = await fetch(url, {
      headers: {
        'Accept': 'application/vnd.api+json',
        'User-Agent': 'KuroganeApp/1.0',
      },
    });
    if (!res.ok) {
      console.error('[Kitsu Error] Status:', res.status, res.statusText);
      return [];
    }
    const json: any = await res.json();
    const data = json.data || [];
    console.log('[Kitsu Success] query:', query, 'count:', data.length);

    return data.map((item: any) => {
      const a = item.attributes;
      const anilistId = 500000 + parseInt(item.id, 10);
      const avgScore = a.averageRating ? Math.round(parseFloat(a.averageRating)) / 10 : 7.8;
      const format = (a.subtype || 'TV').toUpperCase();
      let status = 'FINISHED';
      if (a.status === 'current') status = 'RELEASING';
      if (a.status === 'unreleased') status = 'UPCOMING';

      return formatMediaItem({
        id: anilistId,
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
        episodes: a.episodeCount || 12,
        genres: ['Action', 'Fantasy'],
        studios: ['Animation Studio'],
        description: (a.synopsis || a.description || '').replace(/<[^>]*>?/gm, ''),
        coverImage: {
          extraLarge: a.posterImage?.large || a.posterImage?.original || '',
          large: a.posterImage?.medium || a.posterImage?.large || '',
          medium: a.posterImage?.small || '',
          color: '#3b82f6',
        },
        bannerImage: a.coverImage?.large || a.coverImage?.original || a.posterImage?.large || null,
        year: a.startDate ? parseInt(a.startDate.split('-')[0], 10) : 2024,
        scores: {
          averageScore: avgScore,
          reviewCount: a.userCount || 10000,
          weightedScore: avgScore,
        },
        characters: [],
        staff: [],
        themes: [],
        relations: [],
      });
    });
  } catch (e) {
    return [];
  }
}

export async function getMediaById(env: Bindings, mediaId: string): Promise<any | null> {
  const cleanId = String(mediaId).replace('anilist-', '').trim();
  const numId = parseInt(cleanId, 10);
  if (isNaN(numId)) return null;

  // 1. Check KV cache
  const cacheKey = `anilist:media:${numId}`;
  const cached = await env.CACHE_KV.get(cacheKey, 'json');
  if (cached) {
    return cached;
  }

  // 2. Check Static Seed (Instant, zero-latency)
  if (STATIC_SEED[cleanId] || STATIC_SEED[numId]) {
    const item = formatMediaItem(STATIC_SEED[cleanId] || STATIC_SEED[numId]);
    await env.CACHE_KV.put(cacheKey, JSON.stringify(item), { expirationTtl: 86400 * 7 });
    return item;
  }

  // 3. Check KV rich seed
  const seedRich: any = await env.CACHE_KV.get('anilist:seed_rich', 'json');
  if (seedRich && (seedRich[cleanId] || seedRich[numId])) {
    const item = formatMediaItem(seedRich[cleanId] || seedRich[numId]);
    await env.CACHE_KV.put(cacheKey, JSON.stringify(item), { expirationTtl: 86400 * 7 });
    return item;
  }

  // 4. Check general seed cache
  const seedCache: any = await env.CACHE_KV.get('anilist:seed_cache', 'json');
  if (seedCache?.entries?.guest_recommendations_v2?.data) {
    const recs = seedCache.entries.guest_recommendations_v2.data;
    const found = recs.find((r: any) => r.media.id === `anilist-${numId}` || r.media.anilistId === numId);
    if (found) {
      const item = formatMediaItem(found.media);
      await env.CACHE_KV.put(cacheKey, JSON.stringify(item), { expirationTtl: 86400 * 7 });
      return item;
    }
  }

  // 5. Try live AniList GraphQL (if available)
  const query = `
    query ($id: Int) {
      Media(id: $id, type: ANIME) {
        ${MEDIA_QUERY_FRAGMENT}
      }
    }
  `;

  const data = await fetchAniListGraphQL(env, query, { id: numId });
  if (data?.Media) {
    const formatted = formatMediaItem(data.Media);
    await env.CACHE_KV.put(cacheKey, JSON.stringify(formatted), { expirationTtl: 86400 * 7 });
    return formatted;
  }

  return null;
}

export async function searchMedia(
  env: Bindings,
  params: {
    query?: string;
    type?: string;
    format?: string;
    status?: string;
    demographic?: string;
    genre?: string;
    genres?: string[];
    microTags?: string[];
    sortBy?: string;
    minScore?: number;
    page?: number;
    perPage?: number;
  }
): Promise<{ items: any[]; pageInfo: any }> {
  const page = params.page || 1;
  const perPage = params.perPage || 30;
  const q = (params.query || '').trim();

  // 1. Try Live AniList GraphQL first
  const gql = `
    query ($search: String, $page: Int, $perPage: Int, $genre: String) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
          perPage
        }
        media(type: ANIME, search: $search, genre: $genre, sort: [POPULARITY_DESC]) {
          ${MEDIA_QUERY_FRAGMENT}
        }
      }
    }
  `;

  const vars: any = { page, perPage };
  if (q) vars.search = q;
  if (params.genre && params.genre !== 'ALL') vars.genre = params.genre;

  const data = await fetchAniListGraphQL(env, gql, vars);
  if (data?.Page?.media && data.Page.media.length > 0) {
    const items = data.Page.media.map(formatMediaItem);
    return { items, pageInfo: data.Page.pageInfo };
  }

  // 2. Fallback: Gather all seed catalog items
  let pool: any[] = [];
  if (STATIC_SEED) {
    pool.push(...Object.values(STATIC_SEED));
  }
  const seedRich: any = await env.CACHE_KV.get('anilist:seed_rich', 'json');
  if (seedRich) {
    pool.push(...Object.values(seedRich));
  }
  const seedCache: any = await env.CACHE_KV.get('anilist:seed_cache', 'json');
  if (seedCache?.entries?.guest_recommendations_v2?.data) {
    pool.push(...seedCache.entries.guest_recommendations_v2.data.map((d: any) => d.media));
  }

  // Deduplicate pool
  const seen = new Set<string>();
  let allCatalog: any[] = [];
  for (const item of pool) {
    if (item && item.id && !seen.has(item.id)) {
      seen.add(item.id);
      allCatalog.push(formatMediaItem(item));
    }
  }

  // If search query is non-empty, also fetch live from Kitsu
  if (q.length > 0) {
    const kitsuMatches = await searchKitsuApi(q, perPage);
    console.log('[searchMedia] q:', q, 'kitsuMatches count:', kitsuMatches.length);
    for (const km of kitsuMatches) {
      if (!seen.has(km.id)) {
        seen.add(km.id);
        allCatalog.push(km);
      }
    }
  }

  // 3. Apply Multi-facet Filters
  let filtered = allCatalog;

  // Text search
  if (q.length > 0) {
    const qLower = q.toLowerCase();
    filtered = filtered.filter((item: any) => {
      const titles = [
        item.title?.userPreferred,
        item.title?.english,
        item.title?.romaji,
        item.title?.native,
      ].map((t: string) => (t || '').toLowerCase());
      return titles.some((t: string) => t.includes(qLower));
    });
  }

  // Type filter (ALL, ANIME, MANGA, etc.)
  if (params.type && params.type !== 'ALL') {
    filtered = filtered.filter((i: any) => (i.type || 'ANIME').toUpperCase() === params.type?.toUpperCase());
  }

  // Format filter (ALL, TV, MOVIE, OVA, etc.)
  if (params.format && params.format !== 'ALL') {
    filtered = filtered.filter((i: any) => (i.format || 'TV').toUpperCase() === params.format?.toUpperCase());
  }

  // Status filter (ALL, FINISHED, RELEASING, UPCOMING)
  if (params.status && params.status !== 'ALL') {
    filtered = filtered.filter((i: any) => (i.status || 'FINISHED').toUpperCase() === params.status?.toUpperCase());
  }

  // Genre filter (single)
  if (params.genre && params.genre !== 'ALL') {
    const gLower = params.genre.toLowerCase();
    filtered = filtered.filter((i: any) => (i.genres || []).some((g: string) => g.toLowerCase() === gLower));
  }

  // Genres filter (multi-select)
  if (params.genres && params.genres.length > 0) {
    const gList = params.genres.map(g => g.toLowerCase());
    filtered = filtered.filter((i: any) =>
      gList.some(g => (i.genres || []).some((itemG: string) => itemG.toLowerCase() === g))
    );
  }

  // MicroTags filter (e.g. Isekai, Overpowered MC, School Life, High Fantasy)
  if (params.microTags && params.microTags.length > 0) {
    const mList = params.microTags.map(m => m.toLowerCase());
    filtered = filtered.filter((i: any) =>
      mList.some(m =>
        (i.microTags || []).some((tag: string) => tag.toLowerCase().includes(m)) ||
        (i.genres || []).some((tag: string) => tag.toLowerCase().includes(m)) ||
        (i.description || '').toLowerCase().includes(m)
      )
    );
  }

  // Score filter
  if (params.minScore && params.minScore > 0) {
    filtered = filtered.filter((i: any) => (i.scores?.averageScore || 0) >= (params.minScore || 0));
  }

  // Sorting
  const sortBy = params.sortBy || 'RELEVANCE';
  if (sortBy === 'SCORE' || sortBy === 'TOP_RATED') {
    filtered.sort((a, b) => (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0));
  } else if (sortBy === 'POPULARITY') {
    filtered.sort((a, b) => (b.scores?.reviewCount || 0) - (a.scores?.reviewCount || 0));
  }

  const offset = (page - 1) * perPage;
  const paginated = filtered.slice(offset, offset + perPage);

  return {
    items: paginated,
    pageInfo: {
      total: filtered.length,
      currentPage: page,
      lastPage: Math.ceil(filtered.length / perPage) || 1,
      hasNextPage: offset + perPage < filtered.length,
      perPage,
    },
  };
}

export async function getHomepageData(
  env: Bindings,
  userWatchlist?: any[],
  favoriteGenres?: string[]
): Promise<any> {
  let catalog: any[] = [];
  if (STATIC_SEED) catalog.push(...Object.values(STATIC_SEED));

  const seedRich: any = await env.CACHE_KV.get('anilist:seed_rich', 'json');
  if (seedRich) catalog.push(...Object.values(seedRich));

  const seedCache: any = await env.CACHE_KV.get('anilist:seed_cache', 'json');
  if (seedCache?.entries?.guest_recommendations_v2?.data) {
    catalog.push(...seedCache.entries.guest_recommendations_v2.data.map((d: any) => d.media));
  }

  // Deduplicate
  const seen = new Set<string>();
  const allMedia: any[] = [];
  for (const m of catalog) {
    if (m && m.id && !seen.has(m.id)) {
      seen.add(m.id);
      allMedia.push(formatMediaItem(m));
    }
  }

  const featuredSeason = allMedia.slice(0, 10);
  const topAiring = allMedia.filter((m: any) => m.status === 'RELEASING').slice(0, 10);
  const topUpcoming = allMedia.filter((m: any) => m.status === 'UPCOMING').slice(0, 10);
  const top100 = [...allMedia].sort((a, b) => (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0)).slice(0, 15);

  let recommendations = allMedia.map((m: any) => ({
    media: m,
    recommendationReason: 'Top recomandat de comunitate',
    isPersonalized: false,
    matchPercentage: 94.0,
    badgeLabel: 'TOP RECOMANDAT',
  }));

  const newsCache: any = await env.CACHE_KV.get('news:items', 'json');
  const newsBeta = newsCache?.items || newsCache || [];

  const recentlyAired = (topAiring.length > 0 ? topAiring : allMedia).slice(0, 6).map((m: any, idx: number) => ({
    media: m,
    episodeNumber: idx + 1,
    episodeTitle: `Episodul ${idx + 1}`,
    airDateRelative: 'Recent',
    airDateExact: new Date().toISOString(),
    thumbnailUrl: m.bannerImage || m.coverImage?.large,
  }));

  return {
    featuredSeason: featuredSeason.length > 0 ? featuredSeason : allMedia.slice(0, 8),
    topAiring: topAiring.length > 0 ? topAiring : allMedia.slice(0, 8),
    topUpcoming: topUpcoming.length > 0 ? topUpcoming : allMedia.slice(2, 10),
    top100: top100.length > 0 ? top100 : allMedia.slice(0, 10),
    recentlyAired,
    recommendations,
    newsBeta: newsBeta.slice(0, 10),
    spotlightMedia: featuredSeason[0] || allMedia[0],
  };
}

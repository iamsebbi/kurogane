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

// Comprehensive anime acronym and alias mapping
export const ACRONYM_MAP: Record<string, string> = {
  jjk: 'jujutsu kaisen',
  aot: 'attack on titan',
  snk: 'shingeki no kyojin',
  kny: 'kimetsu no yaiba',
  ds: 'demon slayer',
  fma: 'fullmetal alchemist',
  fmab: 'fullmetal alchemist brotherhood',
  hxh: 'hunter x hunter',
  csm: 'chainsaw man',
  mha: 'my hero academia',
  bnha: 'boku no hero academia',
  op: 'one piece',
  sao: 'sword art online',
  sl: 'solo leveling',
  oe: 'oshi no ko',
  onk: 'oshi no ko',
  mt: 'mushoku tensei',
  dn: 'death note',
  cg: 'code geass',
  ttgl: 'gurren lagann',
  btr: 'bocchi the rock',
  drst: 'dr stone',
  jojo: 'jojo no kimyou na bouken',
  fate: 'fate stay night',
  eva: 'evangelion',
  nge: 'neon genesis evangelion',
  slime: 'tensei shitara slime datta ken',
  tensura: 'tensei shitara slime datta ken',
  makeine: 'make heroine ga oosugiru',
  bleach: 'bleach',
  naruto: 'naruto',
  frieren: 'sousou no frieren',
  dandadan: 'dandadan',
};

// Real-time search fallback via Kitsu API
async function searchKitsuApi(
  query: string,
  limit: number = 20,
  options?: { categories?: string; subtype?: string; sort?: string }
): Promise<any[]> {
  try {
    const safeLimit = Math.min(Math.max(1, limit || 20), 20);
    const params = new URLSearchParams();
    if (query && query.trim().length > 0) {
      params.set('filter[text]', query.trim());
    }
    if (options?.categories) {
      params.set('filter[categories]', options.categories);
    }
    if (options?.subtype && options.subtype !== 'ALL') {
      params.set('filter[subtype]', options.subtype.toLowerCase());
    }
    if (options?.sort) {
      params.set('sort', options.sort);
    } else {
      params.set('sort', '-userCount');
    }
    params.set('page[limit]', String(safeLimit));
    params.set('include', 'genres');

    const url = `https://kitsu.io/api/edge/anime?${params.toString()}`;
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

  // 5. Check if it's a known relation inside any seed item! (Prevents "Title not found" on sequels)
  const allSeedItems: any[] = [
    ...(STATIC_SEED ? Object.values(STATIC_SEED) : []),
    ...(seedRich ? Object.values(seedRich) : []),
  ];
  for (const parent of allSeedItems) {
    const rels = parent.relations?.edges || parent.relations || [];
    for (const edge of rels) {
      const relNode = edge.node || edge;
      const relIdStr = String(relNode.id || relNode.anilistId || '').replace('anilist-', '');
      if (relIdStr === String(numId)) {
        const titleStr = typeof relNode.title === 'string'
          ? relNode.title
          : (relNode.title?.userPreferred || relNode.title?.romaji || relNode.title?.english || 'Anime');
        const coverStr = typeof relNode.coverImage === 'string'
          ? relNode.coverImage
          : (relNode.coverImage?.extraLarge || relNode.coverImage?.large || relNode.coverImage?.medium || '');
        const relYear = relNode.startDate?.year || relNode.seasonYear || relNode.releaseYear || relNode.year || parent.year || 2024;

        const synthesized = formatMediaItem({
          id: numId,
          anilistId: numId,
          title: {
            romaji: titleStr,
            english: titleStr,
            native: titleStr,
            userPreferred: titleStr,
          },
          type: relNode.type || 'ANIME',
          format: relNode.format || 'TV',
          status: relNode.status || 'FINISHED',
          season: relNode.season || null,
          episodes: relNode.episodes || null,
          year: relYear,
          genres: parent.genres || ['Action', 'Fantasy'],
          studios: parent.studios || ['Animation Studio'],
          description: `Titlu conex din franciza ${parent.title?.userPreferred || parent.title?.romaji || 'anime'}.`,
          coverImage: {
            extraLarge: coverStr,
            large: coverStr,
            medium: coverStr,
            color: '#3b82f6',
          },
          bannerImage: parent.bannerImage || coverStr,
          scores: parent.scores || { averageScore: 8.2, reviewCount: 20000, weightedScore: 8.2 },
          franchiseId: parent.franchiseId,
          characters: parent.characters || [],
          staff: parent.staff || [],
          themes: parent.themes || [],
          relations: [
            {
              id: parent.id,
              anilistId: parent.anilistId,
              relationType: edge.relationType === 'SEQUEL' ? 'PREQUEL' : 'SEQUEL',
              title: parent.title?.userPreferred || parent.title?.romaji || 'Serie anterioară',
              coverImage: parent.coverImage?.large,
              format: parent.format,
              type: parent.type,
              status: parent.status,
              releaseYear: parent.year,
            }
          ],
        });

        await env.CACHE_KV.put(cacheKey, JSON.stringify(synthesized), { expirationTtl: 86400 * 7 });
        return synthesized;
      }
    }
  }

  // 6. Direct Kitsu Single Anime Fetch for Kitsu search results (id >= 500000)
  if (numId >= 500000) {
    try {
      const kitsuId = numId - 500000;
      const res = await fetch(`https://kitsu.io/api/edge/anime/${kitsuId}?include=genres`, {
        headers: { 'Accept': 'application/vnd.api+json', 'User-Agent': 'KuroganeApp/1.0' },
      });
      if (res.ok) {
        const json: any = await res.json();
        const a = json?.data?.attributes;
        if (a) {
          const avgScore = a.averageRating ? Math.round(parseFloat(a.averageRating)) / 10 : 7.8;
          const format = (a.subtype || 'TV').toUpperCase();
          let status = 'FINISHED';
          if (a.status === 'current') status = 'RELEASING';
          if (a.status === 'unreleased') status = 'UPCOMING';

          const kitsuItem = formatMediaItem({
            id: numId,
            anilistId: numId,
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

          await env.CACHE_KV.put(cacheKey, JSON.stringify(kitsuItem), { expirationTtl: 86400 * 7 });
          return kitsuItem;
        }
      }
    } catch (_) {}
  }

  // 7. Try live AniList GraphQL (if available)
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
  const rawQ = (params.query || '').trim();
  const qLower = rawQ.toLowerCase();

  // Acronym resolution (e.g. jjk -> jujutsu kaisen, aot -> attack on titan)
  const expandedQuery = ACRONYM_MAP[qLower] || undefined;
  const effectiveQuery = expandedQuery || rawQ;

  // 1. Try Live AniList GraphQL first (if live search query provided)
  if (rawQ.length > 0) {
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

    const vars: any = { page, perPage, search: effectiveQuery };
    if (params.genre && params.genre !== 'ALL') vars.genre = params.genre;

    const data = await fetchAniListGraphQL(env, gql, vars);
    if (data?.Page?.media && data.Page.media.length > 0) {
      const items = data.Page.media.map(formatMediaItem);
      return { items, pageInfo: data.Page.pageInfo };
    }
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

  // Keep track of IDs returned by external search
  const externalMatchIds = new Set<string>();

  // If query is non-empty, fetch live from Kitsu (both raw query and expanded acronym)
  if (rawQ.length > 0) {
    const kitsuMatches = await searchKitsuApi(rawQ, perPage);
    for (const km of kitsuMatches) {
      if (!seen.has(km.id)) {
        seen.add(km.id);
        allCatalog.push(km);
      }
      externalMatchIds.add(km.id);
    }

    if (expandedQuery && expandedQuery !== rawQ) {
      const expandedMatches = await searchKitsuApi(expandedQuery, perPage);
      for (const km of expandedMatches) {
        if (!seen.has(km.id)) {
          seen.add(km.id);
          allCatalog.push(km);
        }
        externalMatchIds.add(km.id);
      }
    }
  } else if ((params.genres && params.genres.length > 0) || (params.genre && params.genre !== 'ALL') || (params.format && params.format !== 'ALL')) {
    // When Explore has active category or format filters without text, fetch from Kitsu to populate a rich catalog
    const category = params.genre || (params.genres && params.genres[0]);
    const subtype = params.format;
    const filteredKitsu = await searchKitsuApi('', perPage, {
      categories: category && category !== 'ALL' ? category.toLowerCase() : undefined,
      subtype: subtype && subtype !== 'ALL' ? subtype : undefined,
    });
    for (const km of filteredKitsu) {
      if (!seen.has(km.id)) {
        seen.add(km.id);
        allCatalog.push(km);
      }
    }
  }

  // 3. Apply Multi-facet Filters
  let filtered = allCatalog;

  // Text search filter
  if (rawQ.length > 0) {
    filtered = filtered.filter((item: any) => {
      // Items returned directly from Kitsu search are already verified matches
      if (externalMatchIds.has(item.id)) {
        return true;
      }

      const titles = [
        item.title?.userPreferred,
        item.title?.english,
        item.title?.romaji,
        item.title?.native,
      ].map((t: string) => (t || '').toLowerCase());

      // Direct substring match
      if (titles.some((t: string) => t.includes(qLower))) return true;

      // Expanded acronym match
      if (expandedQuery && titles.some((t: string) => t.includes(expandedQuery.toLowerCase()))) {
        return true;
      }

      // Franchise ID match
      if (item.franchiseId && (item.franchiseId.includes(qLower) || (expandedQuery && item.franchiseId.includes(expandedQuery.toLowerCase())))) {
        return true;
      }

      // Synonyms match
      if (Array.isArray(item.synonyms) && item.synonyms.some((s: string) => s.toLowerCase().includes(qLower))) {
        return true;
      }

      // Dynamic acronym check (e.g. "Jujutsu Kaisen" -> "jk")
      for (const t of titles) {
        if (!t) continue;
        const acronym = t.split(/\s+/).map((w: string) => w[0]).join('').toLowerCase();
        if (acronym.includes(qLower)) return true;
      }

      return false;
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

  // Demographic filter (ALL, SHOUNEN, SEINEN, SHOUJO, JOSEI)
  if (params.demographic && params.demographic !== 'ALL') {
    const dLower = params.demographic.toLowerCase();
    filtered = filtered.filter((i: any) =>
      (i.demographic || '').toLowerCase() === dLower ||
      (i.genres || []).some((g: string) => g.toLowerCase() === dLower) ||
      (i.microTags || []).some((m: string) => m.toLowerCase() === dLower)
    );
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
  if (rawQ.length > 0) {
    // Intelligent search ranking when query is present
    filtered.sort((a, b) => {
      const titleA = (a.title?.userPreferred || a.title?.english || a.title?.romaji || '').toLowerCase();
      const titleB = (b.title?.userPreferred || b.title?.english || b.title?.romaji || '').toLowerCase();

      const exactA = titleA === qLower || (expandedQuery && titleA === expandedQuery);
      const exactB = titleB === qLower || (expandedQuery && titleB === expandedQuery);
      if (exactA && !exactB) return -1;
      if (!exactA && exactB) return 1;

      const prefixA = titleA.startsWith(qLower) || (expandedQuery && titleA.startsWith(expandedQuery));
      const prefixB = titleB.startsWith(qLower) || (expandedQuery && titleB.startsWith(expandedQuery));
      if (prefixA && !prefixB) return -1;
      if (!prefixA && prefixB) return 1;

      // Secondary: score and year
      const scoreDiff = (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0);
      if (Math.abs(scoreDiff) > 0.5) return scoreDiff;
      return (b.year || 0) - (a.year || 0);
    });
  } else {
    // Sort handling for Explore catalog
    if (sortBy === 'YEAR_DESC') {
      filtered.sort((a, b) => (b.year || 0) - (a.year || 0));
    } else if (sortBy === 'SCORE' || sortBy === 'SCORE_DESC' || sortBy === 'TOP_RATED') {
      filtered.sort((a, b) => (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0));
    } else if (sortBy === 'POPULARITY' || sortBy === 'POPULARITY_DESC') {
      filtered.sort((a, b) => (b.scores?.reviewCount || 0) - (a.scores?.reviewCount || 0));
    } else if (sortBy === 'TITLE_ASC') {
      filtered.sort((a, b) => (a.title?.userPreferred || '').localeCompare(b.title?.userPreferred || ''));
    } else {
      // Default / RELEVANCE: Modern anime (2024-2026) first, then score
      filtered.sort((a, b) => {
        const yearA = a.year || 2000;
        const yearB = b.year || 2000;
        if (yearB !== yearA) return yearB - yearA;
        return (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0);
      });
    }
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

export function getCurrentAnimeSeason(): { season: 'WINTER' | 'SPRING' | 'SUMMER' | 'FALL'; year: number } {
  const now = new Date();
  const month = now.getUTCMonth(); // 0-11 (8 = September)
  const year = now.getUTCFullYear();

  if (month >= 0 && month <= 2) {
    return { season: 'WINTER', year };
  } else if (month >= 3 && month <= 5) {
    return { season: 'SPRING', year };
  } else if (month >= 6 && month <= 8) {
    return { season: 'SUMMER', year };
  } else {
    return { season: 'FALL', year };
  }
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

  // Sort allMedia so modern titles (2024-2026) appear first
  allMedia.sort((a: any, b: any) => {
    const yearA = a.year || 2000;
    const yearB = b.year || 2000;
    if (yearB !== yearA) return yearB - yearA;
    return (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0);
  });

  const currentSeason = getCurrentAnimeSeason();

  // Featured Season: Select modern seasonal titles (2024-2026: Solo Leveling, Dandadan, Frieren, Makeine, etc.)
  // Guarantee that the lead item has the dynamically computed current season & year (e.g. SUMMER 2026)
  // so the Flutter header displays the exact real-world season (Top 10 • Summer 2026)!
  const modernSeasonal = allMedia.filter((m: any) => (m.year && m.year >= 2024) || m.status === 'RELEASING');

  const seasonalLead = modernSeasonal.find((m: any) =>
    (m.season === currentSeason.season && m.year === currentSeason.year) ||
    m.title?.userPreferred?.toLowerCase().includes('solo leveling') ||
    m.title?.userPreferred?.toLowerCase().includes('dandadan') ||
    m.title?.userPreferred?.toLowerCase().includes('frieren')
  ) || modernSeasonal[0] || allMedia[0];

  let featuredSeason: any[] = [];
  if (seasonalLead) {
    const leadCopy = {
      ...seasonalLead,
      season: currentSeason.season,
      year: currentSeason.year,
    };
    featuredSeason.push(leadCopy);
    for (const m of modernSeasonal) {
      if (m.id !== seasonalLead.id && featuredSeason.length < 10) {
        featuredSeason.push(m);
      }
    }
  } else {
    featuredSeason = modernSeasonal.slice(0, 10);
  }

  if (featuredSeason.length < 10) {
    for (const m of allMedia) {
      if (!featuredSeason.some((f: any) => f.id === m.id) && featuredSeason.length < 10) {
        featuredSeason.push(m);
      }
    }
  }

  const topAiring = allMedia.filter((m: any) => m.status === 'RELEASING' || (m.year && m.year >= 2024)).slice(0, 10);
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

  // Spotlight media: a modern flagship anime with high-res art (Solo Leveling, Dandadan, or Frieren)
  const spotlightMedia = featuredSeason[0] || allMedia[0];

  return {
    heroItems: featuredSeason.length > 0 ? featuredSeason : allMedia.slice(0, 8),
    featuredSeason: featuredSeason.length > 0 ? featuredSeason : allMedia.slice(0, 8),
    topAiring: topAiring.length > 0 ? topAiring : allMedia.slice(0, 8),
    topUpcoming: topUpcoming.length > 0 ? topUpcoming : allMedia.slice(2, 10),
    top100: top100.length > 0 ? top100 : allMedia.slice(0, 10),
    recentlyAired,
    recommendations,
    newsBeta: newsBeta.slice(0, 10),
    spotlightMedia,
  };
}

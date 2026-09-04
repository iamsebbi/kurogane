import {
  MediaItem,
  MediaType,
  ScoreMetrics,
  ReleaseStatus,
  MediaSeason,
  RecentlyAiredEpisode,
  SearchQueryOptions,
  MediaCharacter,
  MediaStaff,
  MediaThemeSong,
  CommunityMetrics,
  MediaRelation,
  MediaRelationType,
} from '@kurogane/shared';

export const ANILIST_GRAPHQL_URL = 'https://graphql.anilist.co';

export const ANILIST_REQUEST_HEADERS: Record<string, string> = {
  'Content-Type': 'application/json',
  Accept: 'application/json',
  Origin: 'https://anilist.co',
  Referer: 'https://anilist.co/',
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
};

const SEARCH_MEDIA_QUERY = `
query ($search: String, $type: MediaType, $format: MediaFormat, $status: MediaStatus, $genre_in: [String], $tag_in: [String], $countryOfOrigin: CountryCode, $season: MediaSeason, $seasonYear: Int, $sort: [MediaSort], $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      total
      perPage
      currentPage
      lastPage
      hasNextPage
    }
    media(search: $search, type: $type, format: $format, status: $status, genre_in: $genre_in, tag_in: $tag_in, countryOfOrigin: $countryOfOrigin, season: $season, seasonYear: $seasonYear, sort: $sort, isAdult: false) {
      id
      title {
        romaji
        english
        native
        userPreferred
      }
      type
      format
      status
      season
      episodes
      chapters
      volumes
      genres
      description(asHtml: false)
      countryOfOrigin
      coverImage {
        extraLarge
        large
        medium
        color
      }
      bannerImage
      trailer {
        id
        site
        thumbnail
      }
      startDate {
        year
      }
      studios {
        nodes {
          id
          name
          isAnimationStudio
        }
      }
      averageScore
      meanScore
      stats {
        scoreDistribution {
          score
          amount
        }
      }
    }
  }
}
`;

const FETCH_RANKINGS_NO_STATUS = `
query ($type: MediaType, $sort: [MediaSort], $perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    media(type: $type, sort: $sort, isAdult: false) {
      id
      title {
        romaji
        english
        native
        userPreferred
      }
      type
      format
      status
      season
      episodes
      chapters
      volumes
      genres
      description(asHtml: false)
      countryOfOrigin
      coverImage {
        extraLarge
        large
        medium
        color
      }
      bannerImage
      trailer {
        id
        site
        thumbnail
      }
      startDate {
        year
      }
      studios {
        nodes {
          id
          name
          isAnimationStudio
        }
      }
      averageScore
      meanScore
      stats {
        scoreDistribution {
          score
          amount
        }
      }
    }
  }
}
`;

const FETCH_RANKINGS_WITH_STATUS = `
query ($type: MediaType, $status: MediaStatus, $sort: [MediaSort], $perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    media(type: $type, status: $status, sort: $sort, isAdult: false) {
      id
      title {
        romaji
        english
        native
        userPreferred
      }
      type
      format
      status
      season
      episodes
      chapters
      volumes
      genres
      description(asHtml: false)
      countryOfOrigin
      coverImage {
        extraLarge
        large
        medium
        color
      }
      bannerImage
      trailer {
        id
        site
        thumbnail
      }
      startDate {
        year
      }
      studios {
        nodes {
          id
          name
          isAnimationStudio
        }
      }
      averageScore
      meanScore
      stats {
        scoreDistribution {
          score
          amount
        }
      }
    }
  }
}
`;

const FETCH_CURRENT_SEASON_FEATURED = `
query ($season: MediaSeason, $seasonYear: Int, $sort: [MediaSort], $perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    media(
      type: ANIME,
      season: $season,
      seasonYear: $seasonYear,
      status_in: [RELEASING, NOT_YET_RELEASED, FINISHED],
      sort: $sort,
      isAdult: false
    ) {
      id
      title {
        romaji
        english
        native
        userPreferred
      }
      type
      format
      status
      season
      seasonYear
      episodes
      chapters
      volumes
      genres
      description(asHtml: false)
      countryOfOrigin
      coverImage {
        extraLarge
        large
        medium
        color
      }
      bannerImage
      trailer {
        id
        site
        thumbnail
      }
      startDate {
        year
        month
        day
      }
      studios {
        nodes {
          id
          name
          isAnimationStudio
        }
      }
      averageScore
      meanScore
      stats {
        scoreDistribution {
          score
          amount
        }
      }
    }
  }
}
`;

const RECENTLY_AIRED_QUERY = `
query ($perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    airingSchedules(notYetAired: false, sort: TIME_DESC) {
      id
      airingAt
      episode
      media {
        id
        title {
          romaji
          english
          native
          userPreferred
        }
        type
        format
        status
        season
        episodes
        chapters
        volumes
        genres
        description(asHtml: false)
        countryOfOrigin
        coverImage {
          extraLarge
          large
          medium
          color
        }
        bannerImage
        trailer {
          id
          site
          thumbnail
        }
        startDate {
          year
        }
        studios {
          nodes {
            id
            name
            isAnimationStudio
          }
        }
        averageScore
        meanScore
        stats {
          scoreDistribution {
            score
            amount
          }
        }
      }
    }
  }
}
`;

interface AniListMedia {
  id: number;
  idMal?: number;
  title: {
    romaji?: string;
    english?: string;
    native?: string;
    userPreferred: string;
  };
  type: string;
  format?: string;
  status?: string;
  season?: string;
  episodes?: number;
  chapters?: number;
  volumes?: number;
  genres: string[];
  description?: string;
  countryOfOrigin?: string;
  coverImage: {
    extraLarge?: string;
    large: string;
    medium?: string;
    color?: string;
  };
  bannerImage?: string;
  trailer?: {
    id?: string | number | null;
    site?: string | null;
    thumbnail?: string | null;
  } | null;
  startDate?: {
    year?: number | null;
    month?: number | null;
    day?: number | null;
  };
  endDate?: {
    year?: number | null;
    month?: number | null;
    day?: number | null;
  };
  source?: string;
  studios?: {
    nodes?: {
      id: number;
      name: string;
      isAnimationStudio?: boolean;
    }[];
  };
  averageScore?: number;
  meanScore?: number;
  rankings?: {
    rank: number;
    type: string;
    context: string;
    allTime: boolean;
  }[];
  stats?: {
    scoreDistribution?: { score: number; amount: number }[];
    statusDistribution?: { status: string; amount: number }[];
  };
  characters?: {
    edges?: {
      role: string;
      node: {
        id: number;
        name: { userPreferred: string };
        image?: { medium?: string };
      };
      voiceActors?: {
        id: number;
        name: { userPreferred: string };
        image?: { medium?: string };
        languageV2?: string;
      }[];
    }[];
  };
  staff?: {
    edges?: {
      role: string;
      node: {
        id: number;
        name: { userPreferred: string };
        image?: { medium?: string };
      };
    }[];
  };
  relations?: {
    edges?: {
      relationType: string;
      node: {
        id: number;
        type?: string;
        format?: string;
        status?: string;
        season?: string;
        seasonYear?: number;
        episodes?: number;
        title?: {
          romaji?: string;
          english?: string;
          native?: string;
          userPreferred?: string;
        };
        coverImage?: {
          large?: string;
          medium?: string;
        };
        startDate?: {
          year?: number;
        };
      };
    }[];
  };
}

export function mapAniListToMediaItem(item: AniListMedia): MediaItem {
  let mediaType: MediaType = item.type === 'MANGA' ? 'MANGA' : 'ANIME';
  if (item.countryOfOrigin === 'CN') {
    mediaType = item.type === 'MANGA' ? 'MANHUA' : 'DONGHUA';
  } else if (item.countryOfOrigin === 'KR') {
    mediaType = item.type === 'MANGA' ? 'MANHWA' : 'ANIME';
  }

  let releaseStatus: ReleaseStatus = 'FINISHED';
  if (item.status === 'RELEASING') releaseStatus = 'RELEASING';
  else if (item.status === 'NOT_YET_RELEASED') releaseStatus = 'UPCOMING';
  else if (item.status === 'CANCELLED') releaseStatus = 'CANCELLED';
  else if (item.status === 'HIATUS') releaseStatus = 'HIATUS';

  const avgScore = item.averageScore ? item.averageScore / 10 : item.meanScore ? item.meanScore / 10 : 0;
  const reviewCount = item.stats?.scoreDistribution?.reduce((acc, curr) => acc + curr.amount, 0) || 1000;
  const weightedScore = avgScore > 0 ? Number(avgScore.toFixed(1)) : 0;

  const scores: ScoreMetrics = {
    averageScore: Number(avgScore.toFixed(1)),
    reviewCount,
    weightedScore,
  };

  let trailerUrl: string | undefined = undefined;
  if (item.trailer?.id) {
    const site = String(item.trailer.site || '').toLowerCase();
    const trailerId = String(item.trailer.id);
    if (trailerId.startsWith('http://') || trailerId.startsWith('https://')) {
      trailerUrl = trailerId;
    } else if (site === 'youtube') {
      trailerUrl = `https://www.youtube.com/watch?v=${trailerId}`;
    } else if (site === 'dailymotion') {
      trailerUrl = `https://www.dailymotion.com/video/${trailerId}`;
    }
  }

  const studioNames: string[] = item.studios?.nodes
    ?.map(s => s.name)
    .filter((n): n is string => Boolean(n)) || [];

  const characters: MediaCharacter[] = (item.characters?.edges || []).map((edge) => {
    const primaryVa = edge.voiceActors?.[0];
    return {
      id: edge.node.id,
      name: edge.node.name.userPreferred,
      image: edge.node.image?.medium,
      role: edge.role,
      voiceActor: primaryVa
        ? {
            id: primaryVa.id,
            name: primaryVa.name.userPreferred,
            image: primaryVa.image?.medium,
            language: primaryVa.languageV2 || 'Japanese',
          }
        : undefined,
    };
  });

  const staff: MediaStaff[] = (item.staff?.edges || []).map((edge) => ({
    id: edge.node.id,
    name: edge.node.name.userPreferred,
    image: edge.node.image?.medium,
    role: edge.role,
  }));

  const communityMetrics: CommunityMetrics | undefined = (item.rankings || item.stats?.statusDistribution || item.stats?.scoreDistribution)
    ? {
        rankings: (item.rankings || []).map((r) => ({
          rank: r.rank,
          type: r.type,
          context: r.context,
          allTime: Boolean(r.allTime),
        })),
        scoreDistribution: item.stats?.scoreDistribution || [],
        statusDistribution: item.stats?.statusDistribution || [],
      }
    : undefined;

  return {
    id: `anilist-${item.id}`,
    anilistId: item.id,
    title: {
      romaji: item.title.romaji,
      english: item.title.english,
      native: item.title.native,
      userPreferred: item.title.userPreferred || item.title.english || item.title.romaji || 'Untitled',
    },
    type: mediaType,
    format: item.format as any,
    status: releaseStatus,
    season: item.season as MediaSeason,
    episodes: item.episodes,
    chapters: item.chapters,
    volumes: item.volumes,
    genres: item.genres || [],
    studios: studioNames,
    description: item.description?.replace(/<[^>]*>?/gm, '') || '',
    coverImage: {
      extraLarge: item.coverImage.extraLarge,
      large: item.coverImage.large || item.coverImage.medium || '',
      medium: item.coverImage.medium,
      color: item.coverImage.color || '#3b82f6',
    },
    bannerImage: item.bannerImage,
    trailerUrl,
    year: item.startDate?.year ?? undefined,
    scores,
    source: 'ANILIST',
    characters: characters.length > 0 ? characters : undefined,
    staff: staff.length > 0 ? staff : undefined,
    communityMetrics,
    startDate: item.startDate ? {
      year: item.startDate.year,
      month: item.startDate.month,
      day: item.startDate.day,
    } : undefined,
    endDate: item.endDate ? {
      year: item.endDate.year,
      month: item.endDate.month,
      day: item.endDate.day,
    } : undefined,
    adaptationSource: item.source || undefined,
    relations: (item.relations?.edges || []).length > 0
      ? (item.relations!.edges || [])
          .filter((e) => e && e.node && e.node.id)
          .map((e) => {
            const n = e.node;
            const relType = (e.relationType || 'OTHER') as MediaRelationType;
            const title = n.title?.userPreferred || n.title?.english || n.title?.romaji || 'Titlu Conex';
            const cover = n.coverImage?.large || n.coverImage?.medium;
            return {
              id: `anilist-${n.id}`,
              anilistId: n.id,
              relationType: relType,
              title,
              format: n.format,
              type: n.type,
              status: n.status,
              season: n.season,
              episodes: n.episodes,
              releaseYear: n.startDate?.year || n.seasonYear,
              coverImage: cover,
            };
          })
      : undefined,
  };
}

export const MICROTAG_TO_ANILIST_TAGS: Record<string, string> = {
  'Overpowered MC': 'Super Power',
  'Isekai': 'Isekai',
  'Anti-Hero': 'Anti-Hero',
  'Xianxia': 'Martial Arts',
  'Cyberpunk': 'Cyberpunk',
  'Post-Apocalyptic': 'Post-Apocalyptic',
  'Time Travel': 'Time Manipulation',
  'High Fantasy': 'Magic',
  'Revenge': 'Revenge',
  'System': 'Super Power',
  'Female Protagonist': 'Female Protagonist',
  'School Life': 'School',
  'Virtual Reality': 'Virtual World',
  'Murim': 'Martial Arts',
  'Regression': 'Time Manipulation',
  'Mecha': 'Super Robot',
  'Psychological': 'Psychological',
  'Survival': 'Survival',
  'Romance': 'Romance',
  'Harem': 'Female Harem',
  'Slice of Life': 'Iyashikei',
  'Sports': 'Sports',
  'Music': 'Music',
  'Horror': 'Horror',
  'Military': 'Military',
  'Historical': 'Historical',
  'Mythology': 'Mythology',
  'Martial Arts': 'Martial Arts',
  'Detective': 'Detective',
  'Super Power': 'Super Power',
  'Space': 'Space Opera',
  'Gore': 'Body Horror',
  'Vampire': 'Vampires',
  'Demons': 'Mythology',
  'Magic': 'Magic',
  'Tower': 'Dungeon',
  'Solo Player': 'Anti-Hero',
};

export async function searchAniList(
  queryOrOptions?: string | SearchQueryOptions,
  fallbackLimit: number = 24
): Promise<{ items: MediaItem[]; total: number }> {
  try {
    const opts: SearchQueryOptions =
      typeof queryOrOptions === 'string'
        ? { query: queryOrOptions, limit: fallbackLimit }
        : queryOrOptions || { query: '', limit: fallbackLimit };

    const variables: any = {
      page: opts.page || 1,
      perPage: Math.min(opts.limit || fallbackLimit, 50),
    };

    if (opts.query && opts.query.trim() !== '') {
      variables.search = opts.query.trim();
    }

    if (opts.type && opts.type !== 'ALL') {
      if (opts.type === 'ANIME') {
        variables.type = 'ANIME';
      } else if (opts.type === 'MANGA') {
        variables.type = 'MANGA';
      } else if (opts.type === 'DONGHUA') {
        variables.type = 'ANIME';
        variables.countryOfOrigin = 'CN';
      } else if (opts.type === 'MANHWA') {
        variables.type = 'MANGA';
        variables.countryOfOrigin = 'KR';
      } else if (opts.type === 'MANHUA') {
        variables.type = 'MANGA';
        variables.countryOfOrigin = 'CN';
      } else if (opts.type === 'WEBTOON') {
        variables.type = 'MANGA';
      }
    }

    if (opts.format && opts.format !== 'ALL') {
      variables.format = opts.format;
    }

    if (opts.status && opts.status !== 'ALL') {
      if (opts.status === 'UPCOMING') {
        variables.status = 'NOT_YET_RELEASED';
      } else {
        variables.status = opts.status;
      }
    }

    if (opts.season && opts.season !== 'ALL') {
      variables.season = opts.season;
    }

    if (opts.year && opts.year !== 'ALL') {
      const parsedYear = parseInt(String(opts.year), 10);
      if (!isNaN(parsedYear)) {
        variables.seasonYear = parsedYear;
      }
    }

    const genres = opts.genres && opts.genres.length > 0 ? opts.genres : opts.genre ? [opts.genre] : [];
    if (genres.length > 0) {
      variables.genre_in = genres;
    }

    const microTags = opts.microTags && opts.microTags.length > 0 ? opts.microTags : opts.microTag ? [opts.microTag] : [];
    if (microTags.length > 0) {
      const resolvedTags = microTags.map(t => MICROTAG_TO_ANILIST_TAGS[t] || t).filter(Boolean);
      if (resolvedTags.length > 0) {
        variables.tag_in = resolvedTags;
      }
    }

    if (opts.sortBy) {
      switch (opts.sortBy) {
        case 'SCORE_DESC':
          variables.sort = ['SCORE_DESC'];
          break;
        case 'POPULARITY_DESC':
          variables.sort = ['POPULARITY_DESC'];
          break;
        case 'YEAR_DESC':
          variables.sort = ['START_DATE_DESC'];
          break;
        case 'YEAR_ASC':
          variables.sort = ['START_DATE'];
          break;
        case 'TITLE_ASC':
          variables.sort = ['TITLE_ROMAJI'];
          break;
        case 'RELEVANCE':
        default:
          variables.sort = opts.query?.trim() ? ['SEARCH_MATCH', 'POPULARITY_DESC'] : ['POPULARITY_DESC'];
          break;
      }
    } else {
      variables.sort = opts.query?.trim() ? ['SEARCH_MATCH', 'POPULARITY_DESC'] : ['POPULARITY_DESC'];
    }

    const cacheKey = JSON.stringify(variables);
    const cached = searchCache[cacheKey];
    if (cached && Date.now() - cached.timestamp < SEARCH_CACHE_TTL) {
      return cached.data;
    }

    let response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: ANILIST_REQUEST_HEADERS,
      body: JSON.stringify({
        query: SEARCH_MEDIA_QUERY,
        variables,
      }),
    });

    if (response.status === 429) {
      console.warn(`[AniList API] Rate limited (429), attempting quick retry / cache fallback...`);
      if (cached) {
        return cached.data;
      }
      await new Promise(res => setTimeout(res, 800));
      response = await fetch(ANILIST_GRAPHQL_URL, {
        method: 'POST',
        headers: ANILIST_REQUEST_HEADERS,
        body: JSON.stringify({
          query: SEARCH_MEDIA_QUERY,
          variables,
        }),
      });
    }

    if (!response.ok) {
      console.warn(`[AniList API] Failed response: ${response.status} ${response.statusText}`);
      if (cached) return cached.data;
      return { items: [], total: 0 };
    }

    const json = await response.json();
    const pageData = json.data?.Page;
    const mediaList: AniListMedia[] = pageData?.media || [];
    const total = pageData?.pageInfo?.total || mediaList.length;

    const result = {
      items: mediaList.map(mapAniListToMediaItem),
      total,
    };

    if (result.items.length > 0) {
      searchCache[cacheKey] = {
        data: result,
        timestamp: Date.now(),
      };
    }

    return result;
  } catch (error) {
    console.error('[AniList API Error]:', error);
    return { items: [], total: 0 };
  }
}

// 30-minute in-memory cache for search and rankings
const searchCache: Record<string, { data: { items: MediaItem[]; total: number }; timestamp: number }> = {};
const SEARCH_CACHE_TTL = 30 * 60 * 1000; // 30 mins
const rankingsCache: Record<string, { data: MediaItem[]; timestamp: number }> = {};
const RANKINGS_CACHE_TTL = 30 * 60 * 1000; // 30 mins

export async function fetchAniListRankings(
  sort: string[],
  status?: string,
  perPage: number = 100,
  type: string = 'ANIME'
): Promise<MediaItem[]> {
  const cacheKey = `${type}_${status || 'ALL'}_${sort.join('_')}_${perPage}`;
  const cached = rankingsCache[cacheKey];
  if (cached && Date.now() - cached.timestamp < RANKINGS_CACHE_TTL) {
    return cached.data;
  }

  try {
    const queryToUse = status ? FETCH_RANKINGS_WITH_STATUS : FETCH_RANKINGS_NO_STATUS;
    const variables: any = {
      type,
      sort,
      perPage,
    };
    if (status) {
      variables.status = status;
    }

    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: ANILIST_REQUEST_HEADERS,
      body: JSON.stringify({
        query: queryToUse,
        variables,
      }),
    });

    if (!response.ok) {
      console.warn(`[AniList API Rankings] Error response ${response.status}`);
      return [];
    }

    const json = await response.json();
    const mediaList: AniListMedia[] = json.data?.Page?.media || [];
    const mapped = mediaList.map(mapAniListToMediaItem);

    if (mapped.length > 0) {
      rankingsCache[cacheKey] = {
        data: mapped,
        timestamp: Date.now(),
      };
    }

    return mapped;
  } catch (error) {
    console.error('[AniList API Rankings Error]:', error);
    return [];
  }
}

function formatRelativeTime(airingAt: number): string {
  const now = Math.floor(Date.now() / 1000);
  const diffSeconds = now - airingAt;

  if (diffSeconds < 0) {
    const futureMin = Math.max(1, Math.floor(Math.abs(diffSeconds) / 60));
    if (futureMin < 60) return `In ${futureMin}m`;
    const futureHours = Math.floor(futureMin / 60);
    return `In ${futureHours}h`;
  }

  const minutes = Math.floor(diffSeconds / 60);
  if (minutes < 60) {
    return minutes <= 1 ? 'Just now' : `${minutes}m ago`;
  }

  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return `${hours}h ago`;
  }

  const days = Math.floor(hours / 24);
  if (days === 1) return 'Yesterday';
  return `${days}d ago`;
}

let recentlyAiredCache: { data: RecentlyAiredEpisode[]; timestamp: number } | null = null;

export async function fetchAniListRecentlyAired(limit: number = 12): Promise<RecentlyAiredEpisode[]> {
  if (recentlyAiredCache && Date.now() - recentlyAiredCache.timestamp < 10 * 60 * 1000) {
    return recentlyAiredCache.data;
  }

  try {
    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: ANILIST_REQUEST_HEADERS,
      body: JSON.stringify({
        query: RECENTLY_AIRED_QUERY,
        variables: { perPage: 40 },
      }),
    });

    if (!response.ok) return [];

    const json = await response.json();
    const schedules: any[] = json.data?.Page?.airingSchedules || [];

    const seenMediaIds = new Set<string>();
    const mapped: RecentlyAiredEpisode[] = [];

    for (const sched of schedules) {
      if (!sched.media) continue;
      const mediaId = `anilist-${sched.media.id}`;
      if (seenMediaIds.has(mediaId)) continue;
      seenMediaIds.add(mediaId);

      const mediaItem = mapAniListToMediaItem(sched.media);
      mapped.push({
        media: mediaItem,
        episodeNumber: sched.episode,
        episodeTitle: `Episode ${sched.episode}`,
        airDateRelative: formatRelativeTime(sched.airingAt),
        airDateExact: new Date(sched.airingAt * 1000).toISOString(),
        thumbnailUrl: mediaItem.coverImage.extraLarge || mediaItem.coverImage.large,
      });

      if (mapped.length >= limit) break;
    }

    if (mapped.length > 0) {
      recentlyAiredCache = {
        data: mapped,
        timestamp: Date.now(),
      };
    }

    return mapped;
  } catch (error) {
    console.error('[AniList Recently Aired Error]:', error);
    return [];
  }
}

const CONTINUOUS_SHOWS_BLACKLIST = [
  'one piece',
  'detective conan',
  'case closed',
  'crayon shin-chan',
  'chibi maruko-chan',
  'sazae-san',
  'doraemon',
  'pokemon',
  'pokémon',
  'boruto',
  'yu-gi-oh',
  'yu-gi-oh!',
  'ninjala',
  'precure',
  'pretty cure',
  'soreike! anpanman',
  'anpanman',
  'meitantei conan',
];

// Helper methods for specific AniList Live Rankings
export async function fetchAniListTop100(): Promise<MediaItem[]> {
  return fetchAniListRankings(['SCORE_DESC'], undefined, 100, 'ANIME');
}

export async function fetchAniListTopAiring(limit: number = 12): Promise<MediaItem[]> {
  const allAiring = await fetchAniListRankings(['POPULARITY_DESC'], 'RELEASING', 40, 'ANIME');
  const currentYear = new Date().getFullYear();

  const filtered = allAiring.filter((item) => {
    if (item.format && !['TV', 'TV_SHORT', 'ONA', 'MOVIE'].includes(item.format)) return false;

    const titleLower = (item.title.userPreferred || item.title.english || item.title.romaji || '').toLowerCase();
    if (CONTINUOUS_SHOWS_BLACKLIST.some((b) => titleLower.includes(b))) return false;

    // Exclude continuous running series (>50 episodes) that started before current/previous year
    if (item.episodes && item.episodes > 50 && item.year && item.year < currentYear - 1) {
      return false;
    }

    return true;
  });

  return filtered.slice(0, limit);
}

export async function fetchAniListTopUpcoming(limit: number = 12): Promise<MediaItem[]> {
  const allUpcoming = await fetchAniListRankings(['POPULARITY_DESC'], 'NOT_YET_RELEASED', 30, 'ANIME');

  const filtered = allUpcoming.filter((item) => {
    if (item.format && !['TV', 'TV_SHORT', 'ONA', 'MOVIE'].includes(item.format)) return false;
    const titleLower = (item.title.userPreferred || item.title.english || item.title.romaji || '').toLowerCase();
    if (CONTINUOUS_SHOWS_BLACKLIST.some((b) => titleLower.includes(b))) return false;
    return true;
  });

  return filtered.slice(0, limit);
}

export function getCurrentAnimeSeason(): { season: 'WINTER' | 'SPRING' | 'SUMMER' | 'FALL'; year: number } {
  const now = new Date();
  const m = now.getMonth();
  const year = now.getFullYear();
  let season: 'WINTER' | 'SPRING' | 'SUMMER' | 'FALL' = 'WINTER';
  if (m >= 0 && m <= 2) season = 'WINTER';
  else if (m >= 3 && m <= 5) season = 'SPRING';
  else if (m >= 6 && m <= 8) season = 'SUMMER';
  else season = 'FALL';
  return { season, year };
}

export async function fetchAniListFeatured(limit: number = 8): Promise<MediaItem[]> {
  const { season, year } = getCurrentAnimeSeason();
  const cacheKey = `featured_${season}_${year}`;

  if (rankingsCache[cacheKey] && Date.now() - rankingsCache[cacheKey].timestamp < 15 * 60 * 1000) {
    return rankingsCache[cacheKey].data;
  }

  try {
    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: ANILIST_REQUEST_HEADERS,
      body: JSON.stringify({
        query: FETCH_CURRENT_SEASON_FEATURED,
        variables: {
          season,
          seasonYear: year,
          sort: ['TRENDING_DESC', 'POPULARITY_DESC'],
          perPage: 40,
        },
      }),
    });

    if (!response.ok) return [];

    const json = await response.json();
    const mediaList: AniListMedia[] = json.data?.Page?.media || [];

    // Filter out continuous long-running shows or non-seasonal entries
    const continuousShowsBlacklist = [
      'one piece',
      'detective conan',
      'case closed',
      'crayon shin-chan',
      'chibi maruko-chan',
      'sazae-san',
      'doraemon',
      'pokemon',
      'pokémon',
      'boruto',
      'yu-gi-oh',
    ];

    const filtered = mediaList.filter((m) => {
      // Must be TV, TV_SHORT, ONA or MOVIE
      if (m.format && !['TV', 'TV_SHORT', 'ONA', 'MOVIE'].includes(m.format)) return false;

      // Exclude titles in continuous shows blacklist
      const titleLower = (m.title?.userPreferred || m.title?.romaji || m.title?.english || '').toLowerCase();
      if (continuousShowsBlacklist.some((b) => titleLower.includes(b))) return false;

      // Exclude shows with > 50 total episodes unless started in current season
      if (m.episodes && m.episodes > 50 && m.startDate?.year && m.startDate.year < year) {
        return false;
      }

      return true;
    });

    const mapped = filtered.map(mapAniListToMediaItem).slice(0, limit);

    if (mapped.length > 0) {
      rankingsCache[cacheKey] = {
        data: mapped,
        timestamp: Date.now(),
      };
    }

    return mapped;
  } catch (error) {
    console.error('[AniList API Featured Error]:', error);
    return [];
  }
}

const FETCH_MEDIA_BY_ID_QUERY = `
query ($id: Int) {
  Media(id: $id) {
    id
    idMal
    title {
      romaji
      english
      native
      userPreferred
    }
    type
    format
    status
    season
    episodes
    chapters
    volumes
    genres
    description(asHtml: false)
    countryOfOrigin
    coverImage {
      extraLarge
      large
      medium
      color
    }
    bannerImage
    trailer {
      id
      site
      thumbnail
    }
    startDate {
      year
      month
      day
    }
    endDate {
      year
      month
      day
    }
    source
    studios {
      nodes {
        id
        name
        isAnimationStudio
      }
    }
    averageScore
    meanScore
    rankings {
      rank
      type
      context
      allTime
    }
    stats {
      scoreDistribution {
        score
        amount
      }
      statusDistribution {
        status
        amount
      }
    }
    characters(sort: [ROLE, RELEVANCE], perPage: 12) {
      edges {
        role
        node {
          id
          name {
            userPreferred
          }
          image {
            medium
          }
        }
        voiceActors(language: JAPANESE, sort: [RELEVANCE]) {
          id
          name {
            userPreferred
          }
          image {
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
          }
          image {
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
            romaji
            english
          }
          coverImage {
            large
            medium
          }
          startDate {
            year
          }
        }
      }
    }
  }
}
`;

const themesCache = new Map<number, MediaThemeSong[]>();

export async function fetchThemeSongs(anilistId: number): Promise<MediaThemeSong[]> {
  if (themesCache.has(anilistId)) {
    return themesCache.get(anilistId)!;
  }
  try {
    const url = `https://api.animethemes.moe/anime?filter[has]=resources&filter[site]=AniList&filter[external_id]=${anilistId}&include=animethemes.song.artists`;
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Kurogane/1.0 (https://kurogane.app)',
        'Accept': 'application/json',
      },
    });
    if (!res.ok) {
      themesCache.set(anilistId, []);
      return [];
    }
    const data: any = await res.json();
    const animethemes = data.anime?.[0]?.animethemes as any[] | undefined;
    if (!animethemes || !Array.isArray(animethemes)) {
      themesCache.set(anilistId, []);
      return [];
    }
    const songs: MediaThemeSong[] = animethemes.map((theme) => {
      const type: 'OP' | 'ED' = theme.type === 'ED' ? 'ED' : 'OP';
      const artists = (theme.song?.artists || []).map((a: any) => a.name).filter(Boolean);
      return {
        type,
        title: theme.song?.title || theme.slug || 'Theme',
        artists: artists.length > 0 ? artists : ['Artist necunoscut'],
        episodes: theme.slug,
      };
    });
    themesCache.set(anilistId, songs);
    return songs;
  } catch (err) {
    console.error(`[AnimeThemes Error for ${anilistId}]:`, err);
    return [];
  }
}

export async function fetchAniListMediaById(rawId: string | number): Promise<MediaItem | null> {
  const numericId = typeof rawId === 'number' ? rawId : parseInt(String(rawId).replace(/\D/g, ''), 10);
  if (!numericId || isNaN(numericId)) return null;

  try {
    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: ANILIST_REQUEST_HEADERS,
      body: JSON.stringify({
        query: FETCH_MEDIA_BY_ID_QUERY,
        variables: { id: numericId },
      }),
    });

    if (!response.ok) {
      console.error(`[AniList API fetchById HTTP ${response.status}]`);
      return null;
    }

    const json = await response.json();
    if (json.errors) {
      console.error('[AniList API fetchById GraphQL Errors]:', json.errors);
    }
    const media: AniListMedia = json.data?.Media;
    if (!media) return null;

    const mapped = mapAniListToMediaItem(media);
    if (media.id && media.type !== 'MANGA') {
      try {
        const themes = await fetchThemeSongs(media.id);
        if (themes.length > 0) {
          mapped.themes = themes;
        }
      } catch (_) {}
    }

    return mapped;
  } catch (error) {
    console.error('[AniList API fetchById Error]:', error);
    return null;
  }
}




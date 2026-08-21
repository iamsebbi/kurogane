import { MediaItem, MediaType, ScoreMetrics, ReleaseStatus, MediaSeason, RecentlyAiredEpisode } from '@kurogane/shared';

const ANILIST_GRAPHQL_URL = 'https://graphql.anilist.co';

const SEARCH_MEDIA_QUERY = `
query ($search: String, $type: MediaType, $countryOfOrigin: CountryCode, $season: MediaSeason, $seasonYear: Int, $limit: Int) {
  Page(page: 1, perPage: $limit) {
    media(search: $search, type: $type, countryOfOrigin: $countryOfOrigin, season: $season, seasonYear: $seasonYear, sort: POPULARITY_DESC, isAdult: false) {
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
      startDate {
        year
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
      startDate {
        year
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
      startDate {
        year
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
      startDate {
        year
        month
        day
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
        startDate {
          year
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
  startDate?: {
    year?: number;
  };
  averageScore?: number;
  meanScore?: number;
  stats?: {
    scoreDistribution?: { score: number; amount: number }[];
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
    description: item.description?.replace(/<[^>]*>?/gm, '') || '',
    coverImage: {
      extraLarge: item.coverImage.extraLarge,
      large: item.coverImage.large || item.coverImage.medium || '',
      medium: item.coverImage.medium,
      color: item.coverImage.color || '#3b82f6',
    },
    bannerImage: item.bannerImage,
    year: item.startDate?.year,
    scores,
    source: 'ANILIST',
  };
}

export async function searchAniList(query?: string, limit: number = 12): Promise<MediaItem[]> {
  try {
    const variables: any = { limit };
    if (query && query.trim() !== '') {
      variables.search = query.trim();
    }

    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        query: SEARCH_MEDIA_QUERY,
        variables,
      }),
    });

    if (!response.ok) {
      console.warn(`[AniList API] Failed response: ${response.status} ${response.statusText}`);
      return [];
    }

    const json = await response.json();
    const mediaList: AniListMedia[] = json.data?.Page?.media || [];
    return mediaList.map(mapAniListToMediaItem);
  } catch (error) {
    console.error('[AniList API Error]:', error);
    return [];
  }
}

// 30-minute in-memory cache for live AniList rankings
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
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
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
    if (futureMin < 60) return `În ${futureMin} min`;
    const futureHours = Math.floor(futureMin / 60);
    return `În ${futureHours} ore`;
  }

  const minutes = Math.floor(diffSeconds / 60);
  if (minutes < 60) {
    return minutes <= 1 ? 'Acum 1 min' : `Acum ${minutes} min`;
  }

  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return hours === 1 ? 'Acum 1 oră' : `Acum ${hours} ore`;
  }

  const days = Math.floor(hours / 24);
  if (days === 1) return 'Ieri';
  return `Acum ${days} zile`;
}

let recentlyAiredCache: { data: RecentlyAiredEpisode[]; timestamp: number } | null = null;

export async function fetchAniListRecentlyAired(limit: number = 12): Promise<RecentlyAiredEpisode[]> {
  if (recentlyAiredCache && Date.now() - recentlyAiredCache.timestamp < 10 * 60 * 1000) {
    return recentlyAiredCache.data;
  }

  try {
    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
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
        episodeTitle: `Episodul ${sched.episode}`,
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
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
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
  Media(id: $id, isAdult: false) {
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
    startDate {
      year
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
`;

export async function fetchAniListMediaById(rawId: string | number): Promise<MediaItem | null> {
  const numericId = typeof rawId === 'number' ? rawId : parseInt(String(rawId).replace(/\D/g, ''), 10);
  if (!numericId || isNaN(numericId)) return null;

  try {
    const response = await fetch(ANILIST_GRAPHQL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        query: FETCH_MEDIA_BY_ID_QUERY,
        variables: { id: numericId },
      }),
    });

    if (!response.ok) return null;

    const json = await response.json();
    const media: AniListMedia = json.data?.Media;
    if (!media) return null;

    return mapAniListToMediaItem(media);
  } catch (error) {
    console.error('[AniList API fetchById Error]:', error);
    return null;
  }
}




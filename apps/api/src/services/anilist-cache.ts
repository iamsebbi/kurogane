import fs from 'fs';
import path from 'path';
import {
  MediaItem,
  RecommendedMediaItem,
  ScoreMetrics,
} from '@kurogane/shared';
import { mapAniListToMediaItem, ANILIST_REQUEST_HEADERS } from './anilist';

const DATA_DIR = path.join(__dirname, '../../data');
const CACHE_FILE = path.join(DATA_DIR, 'anilist-cache.json');
const ANILIST_GRAPHQL_URL = 'https://graphql.anilist.co';

interface CacheRecord<T = any> {
  data: T;
  timestamp: number;
  ttl: number;
}

interface PersistedCacheStore {
  entries: Record<string, CacheRecord>;
  scores: Record<string, ScoreMetrics & { timestamp: number }>;
}

const BATCH_MEDIA_QUERY = `
query ($ids: [Int], $perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    media(id_in: $ids, isAdult: false) {
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

const RECOMMENDATIONS_BATCH_QUERY = `
query ($mediaIds: [Int], $perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    recommendations(mediaId_in: $mediaIds, sort: RATING_DESC) {
      rating
      userRating
      media {
        id
      }
      mediaRecommendation {
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

const GUEST_RECOMMENDATIONS_QUERY = `
query ($perPage: Int) {
  trending: Page(page: 1, perPage: $perPage) {
    media(type: ANIME, sort: [TRENDING_DESC, POPULARITY_DESC], isAdult: false, format_in: [TV, MOVIE, ONA]) {
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
      genres
      description(asHtml: false)
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
  topRated: Page(page: 1, perPage: $perPage) {
    media(type: ANIME, sort: [SCORE_DESC], isAdult: false, format_in: [TV, MOVIE, ONA]) {
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
      genres
      description(asHtml: false)
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

class AniListCacheService {
  private entries: Map<string, CacheRecord> = new Map();
  private scores: Map<number, ScoreMetrics & { timestamp: number }> = new Map();
  private isSaving: boolean = false;
  private pendingBackgroundFetches: Set<string> = new Set();

  constructor() {
    this.ensureDataDir();
    this.loadCache();
  }

  private ensureDataDir(): void {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
  }

  private loadCache(): void {
    try {
      if (fs.existsSync(CACHE_FILE)) {
        const raw = fs.readFileSync(CACHE_FILE, 'utf-8');
        const parsed: PersistedCacheStore = JSON.parse(raw);

        if (parsed.entries) {
          for (const [k, v] of Object.entries(parsed.entries)) {
            this.entries.set(k, v);
          }
        }
        if (parsed.scores) {
          for (const [k, v] of Object.entries(parsed.scores)) {
            const idNum = parseInt(k, 10);
            if (!isNaN(idNum)) {
              this.scores.set(idNum, v);
            }
          }
        }
        console.log(
          `[AniList Cache] Loaded ${this.entries.size} cache entries & ${this.scores.size} scores from disk.`
        );
      }
    } catch (err) {
      console.warn('[AniList Cache] Could not load persisted cache:', err);
    }
  }

  private saveCache(): void {
    if (this.isSaving) return;
    this.isSaving = true;

    setTimeout(() => {
      try {
        this.ensureDataDir();
        const entriesObj: Record<string, CacheRecord> = {};
        for (const [k, v] of this.entries.entries()) {
          if (v && v.data) {
            entriesObj[k] = v;
          }
        }

        const scoresObj: Record<string, ScoreMetrics & { timestamp: number }> = {};
        for (const [k, v] of this.scores.entries()) {
          scoresObj[k.toString()] = v;
        }

        const payload: PersistedCacheStore = {
          entries: entriesObj,
          scores: scoresObj,
        };

        fs.writeFileSync(CACHE_FILE, JSON.stringify(payload), 'utf-8');
      } catch (err) {
        console.warn('[AniList Cache] Error saving cache to disk:', err);
      } finally {
        this.isSaving = false;
      }
    }, 1000);
  }

  public getAllCachedMedia(): MediaItem[] {
    const items: MediaItem[] = [];
    const seen = new Set<string>();
    for (const record of this.entries.values()) {
      if (Array.isArray(record?.data)) {
        for (const entry of record.data) {
          const m = entry?.media?.id ? entry.media : entry?.id && entry.title ? entry : null;
          if (m && m.id && !seen.has(m.id)) {
            seen.add(m.id);
            items.push(m);
          }
        }
      }
    }
    return items;
  }

  public getCachedScore(anilistId?: number): ScoreMetrics | null {
    if (!anilistId) return null;
    const s = this.scores.get(anilistId);
    if (!s) return null;
    return {
      averageScore: s.averageScore,
      reviewCount: s.reviewCount,
      weightedScore: s.weightedScore,
    };
  }

  public setCachedScore(anilistId: number, score: ScoreMetrics): void {
    this.scores.set(anilistId, {
      ...score,
      timestamp: Date.now(),
    });
    this.saveCache();
  }

  public async fetchWithSWR<T>(
    key: string,
    ttlMs: number,
    fetchFn: () => Promise<T>,
    fallbackValue: T
  ): Promise<T> {
    const cached = this.entries.get(key);
    const now = Date.now();

    if (cached) {
      const isExpired = now - cached.timestamp > cached.ttl;
      if (isExpired && !this.pendingBackgroundFetches.has(key)) {
        this.pendingBackgroundFetches.add(key);
        (async () => {
          try {
            const fresh = await fetchFn();
            if (fresh) {
              this.entries.set(key, {
                data: fresh,
                timestamp: Date.now(),
                ttl: ttlMs,
              });
              this.saveCache();
            }
          } catch (err) {
            console.warn(`[AniList SWR Background Error] (${key}):`, err);
          } finally {
            this.pendingBackgroundFetches.delete(key);
          }
        })();
      }
      return cached.data as T;
    }

    try {
      const fresh = await fetchFn();
      if (fresh) {
        this.entries.set(key, {
          data: fresh,
          timestamp: Date.now(),
          ttl: ttlMs,
        });
        this.saveCache();
        return fresh;
      }
    } catch (err) {
      console.warn(`[AniList Cold Fetch Error] (${key}):`, err);
    }

    return fallbackValue;
  }

  public async fetchMediaBatch(anilistIds: number[]): Promise<Map<number, MediaItem>> {
    const resultMap = new Map<number, MediaItem>();
    const missingIds = anilistIds.filter((id) => !this.scores.has(id));

    if (missingIds.length === 0) {
      return resultMap;
    }

    const batch = missingIds.slice(0, 50);

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 3500);

      const response = await fetch(ANILIST_GRAPHQL_URL, {
        method: 'POST',
        headers: ANILIST_REQUEST_HEADERS,
        body: JSON.stringify({
          query: BATCH_MEDIA_QUERY,
          variables: { ids: batch, perPage: batch.length },
        }),
        signal: controller.signal,
      });

      clearTimeout(timeout);

      if (response.ok) {
        const json = await response.json();
        const list: any[] = json.data?.Page?.media || [];
        for (const raw of list) {
          const item = mapAniListToMediaItem(raw);
          if (item.anilistId) {
            resultMap.set(item.anilistId, item);
            this.scores.set(item.anilistId, {
              ...item.scores,
              timestamp: Date.now(),
            });
          }
        }
        this.saveCache();
      }
    } catch (err) {
      console.warn('[AniList Batch Fetch Error]:', err);
    }

    return resultMap;
  }

  public async fetchGuestRecommendations(limit: number = 12): Promise<RecommendedMediaItem[]> {
    const cacheKey = 'guest_recommendations_v2';
    const TTL_MS = 45 * 60 * 1000;

    return this.fetchWithSWR<RecommendedMediaItem[]>(
      cacheKey,
      TTL_MS,
      async () => {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 3500);

        const response = await fetch(ANILIST_GRAPHQL_URL, {
          method: 'POST',
          headers: ANILIST_REQUEST_HEADERS,
          body: JSON.stringify({
            query: GUEST_RECOMMENDATIONS_QUERY,
            variables: { perPage: 25 },
          }),
          signal: controller.signal,
        });

        clearTimeout(timeout);

        if (!response.ok) {
          throw new Error(`AniList HTTP ${response.status}`);
        }

        const json = await response.json();
        const trendingList: any[] = json.data?.trending?.media || [];
        const topRatedList: any[] = json.data?.topRated?.media || [];

        const combinedRaw = [...trendingList, ...topRatedList];
        const seenIds = new Set<number>();
        const mappedItems: MediaItem[] = [];

        for (const raw of combinedRaw) {
          if (!raw.id || seenIds.has(raw.id)) continue;
          seenIds.add(raw.id);

          const item = mapAniListToMediaItem(raw);
          if (item.anilistId) {
            this.scores.set(item.anilistId, {
              ...item.scores,
              timestamp: Date.now(),
            });
          }

          if (item.scores.averageScore >= 7.6) {
            mappedItems.push(item);
          }
        }

        const editorialBadges = [
          'TOP RECOMANDAT',
          'CAPODOPERĂ',
          'APRECIAT',
          'POPULAR',
          'SELECȚIE SPECIALĂ',
          'TOP RECOMANDAT',
          'APRECIAT',
          'POPULAR',
          'CAPODOPERĂ',
          'TOP RECOMANDAT',
          'APRECIAT',
          'SELECȚIE SPECIALĂ',
        ];

        const editorialReasons = [
          'Capodoperă vizuală și poveste captivantă',
          'Recomandat pentru iubitorii de Dark Fantasy & Action',
          'Producție de vârf apreciată unanim de comunitate',
          'Animație excepțională și coloană sonoră memorabilă',
          'Univers bine conturat cu bătălii strategice',
          'Producție de referință cu scor excepțional',
          'Narațiune profundă și personaje memorabile',
          'Recomandare de top cu recenzii excepționale',
          'Poveste captivantă cu dezvoltare remarcabilă',
          'Regie impecabilă și univers captivant',
          'Scenariu apreciat de critici și fani',
          'Selecție de vârf din catalogul Kurogane',
        ];

        return mappedItems.slice(0, limit).map((media, idx) => ({
          media,
          recommendationReason: editorialReasons[idx % editorialReasons.length],
          isPersonalized: false,
          badgeLabel: editorialBadges[idx % editorialBadges.length],
        }));
      },
      []
    );
  }

  public async fetchPersonalizedRecommendations(
    watchlistAnilistIds: number[],
    favoriteGenres: string[] = [],
    existingWatchlistMediaIds: Set<string> = new Set()
  ): Promise<RecommendedMediaItem[]> {
    if (watchlistAnilistIds.length === 0 && favoriteGenres.length === 0) {
      return [];
    }

    const idsHash = watchlistAnilistIds.slice(0, 15).sort().join('-');
    const genresHash = favoriteGenres.sort().join('-');
    const cacheKey = `user_recs_${idsHash}_${genresHash}`;
    const TTL_MS = 30 * 60 * 1000;

    return this.fetchWithSWR<RecommendedMediaItem[]>(
      cacheKey,
      TTL_MS,
      async () => {
        const targetIds = watchlistAnilistIds.slice(0, 10);
        let recommendedMediaMap = new Map<number, { media: MediaItem; rating: number }>();

        if (targetIds.length > 0) {
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 3500);

          try {
            const response = await fetch(ANILIST_GRAPHQL_URL, {
              method: 'POST',
              headers: ANILIST_REQUEST_HEADERS,
              body: JSON.stringify({
                query: RECOMMENDATIONS_BATCH_QUERY,
                variables: { mediaIds: targetIds, perPage: 40 },
              }),
              signal: controller.signal,
            });

            clearTimeout(timeout);

            if (response.ok) {
              const json = await response.json();
              const recNodes: any[] = json.data?.Page?.recommendations || [];

              for (const node of recNodes) {
                const recRaw = node.mediaRecommendation;
                if (!recRaw || !recRaw.id) continue;

                const recItem = mapAniListToMediaItem(recRaw);
                if (existingWatchlistMediaIds.has(recItem.id) || existingWatchlistMediaIds.has(`anilist-${recItem.anilistId}`)) {
                  continue;
                }

                if (recItem.anilistId) {
                  this.scores.set(recItem.anilistId, {
                    ...recItem.scores,
                    timestamp: Date.now(),
                  });
                }

                const existing = recommendedMediaMap.get(recItem.anilistId || 0);
                const currentRating = node.rating || 1;
                if (!existing || currentRating > existing.rating) {
                  recommendedMediaMap.set(recItem.anilistId || 0, { media: recItem, rating: currentRating });
                }
              }
            }
          } catch (err) {
            console.warn('[AniList Personalized Recs Query Error]:', err);
          }
        }

        const candidateItems = Array.from(recommendedMediaMap.values()).map((v) => v.media);
        if (candidateItems.length === 0) {
          return [];
        }

        const userGenreWeights: Record<string, number> = {};
        for (const fg of favoriteGenres) {
          userGenreWeights[fg.toLowerCase()] = 6;
        }

        const scoredResults: RecommendedMediaItem[] = candidateItems
          .filter((item) => item.scores.averageScore >= 6.8)
          .map((item) => {
            const itemGenres = (item.genres || []).map((g: string) => g.toLowerCase());
            let overlapCount = 0;
            const matchedLabels: string[] = [];

            for (const g of itemGenres) {
              if (userGenreWeights[g]) {
                overlapCount += 1;
                matchedLabels.push(g.charAt(0).toUpperCase() + g.slice(1));
              }
            }

            const overlapRatio = Math.min(1.0, overlapCount / Math.min(item.genres.length || 1, 3));
            const qualityBonus = Math.min(1.0, Math.max(0, (item.scores.averageScore - 6.8) / 2.5));
            const rawPct = 76 + overlapRatio * 14 + qualityBonus * 8;
            const matchPct = Math.min(98, Math.max(76, Math.round(rawPct)));

            const matchedText = matchedLabels.slice(0, 2).join(' & ') || item.genres[0] || item.type;

            return {
              media: item,
              recommendationReason: `Bazat pe preferințele tale pentru ${matchedText}`,
              matchPercentage: matchPct,
              isPersonalized: true,
              badgeLabel: `${matchPct}% POTRIVIRE`,
            };
          })
          .sort((a, b) => (b.matchPercentage || 0) - (a.matchPercentage || 0) || b.media.scores.averageScore - a.media.scores.averageScore)
          .slice(0, 12);

        return scoredResults;
      },
      []
    );
  }
}

export const anilistCacheService = new AniListCacheService();

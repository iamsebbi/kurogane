import fs from 'fs';
import path from 'path';
import {
  MediaItem,
  MediaType,
  MediaFormat,
  ReleaseStatus,
  Demographic,
  MediaSeason,
  SortOption,
  SearchQueryOptions,
  SearchResponse,
  DataSource,
  CategoryShelf,
  SimilarMediaResponse,
  NewsArticle,
  RecentlyAiredEpisode,
  RecommendedMediaItem,
  HomepageData,
} from '@kurogane/shared';
import {
  searchAniList,
  fetchAniListTop100,
  fetchAniListTopAiring,
  fetchAniListTopUpcoming,
  fetchAniListFeatured,
  fetchAniListRecentlyAired,
  fetchAniListMediaById,
} from './anilist';
import { anilistCacheService } from './anilist-cache';
import { newsAggregationService } from './news-rss';

const TAG_TAXONOMY_PATH = path.join(__dirname, '../data/tag-taxonomy.json');
const OFFLINE_DB_PATHS = [
  path.join(process.cwd(), 'anime-offline-database-minified.json'),
  path.join(process.cwd(), '../anime-offline-database-minified.json'),
  path.resolve(__dirname, '../../../anime-offline-database-minified.json'),
  path.resolve(__dirname, '../../../../anime-offline-database-minified.json'),
  path.join(__dirname, '../data/anime-offline-database-minified.json'),
  'd:/kurogane/anime-offline-database-minified.json',
  'd:\\kurogane\\anime-offline-database-minified.json',
];

interface TaxonomyRule {
  label: string;
  patterns: string[];
}

interface TagTaxonomy {
  microTags: TaxonomyRule[];
  demographics: TaxonomyRule[];
}

function loadTagTaxonomy(): TagTaxonomy {
  try {
    if (fs.existsSync(TAG_TAXONOMY_PATH)) {
      const data = fs.readFileSync(TAG_TAXONOMY_PATH, 'utf-8');
      const parsed = JSON.parse(data);
      console.log(`[Tag Taxonomy] Loaded ${parsed.microTags?.length || 0} micro-tag rules and ${parsed.demographics?.length || 0} demographic rules.`);
      return parsed;
    }
  } catch (err) {
    console.error('[Tag Taxonomy] Error loading tag-taxonomy.json:', err);
  }
  return { microTags: [], demographics: [] };
}

const TAG_TAXONOMY = loadTagTaxonomy();

interface IndexedItem {
  item: MediaItem;
  normTitle: string;
  normSynonyms: string;
  normTags: string;
  allTokens: Set<string>;
}

function normalize(str: string): string {
  return str.toLowerCase().replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
}

function levenshteinDistance(a: string, b: string): number {
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;

  const matrix: number[][] = [];

  for (let i = 0; i <= a.length; i++) matrix[i] = [i];
  for (let j = 0; j <= b.length; j++) matrix[0][j] = j;

  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost
      );
    }
  }

  return matrix[a.length][b.length];
}

// Dynamic Algorithmic Initialisms & Acronym Generator (e.g. "Attack on Titan" -> ["aot", "att", "a"], "Jujutsu Kaisen" -> ["jjk", "jk"])
function generateTitleInitialisms(title: string): string[] {
  if (!title) return [];
  const words = title
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .split(/\s+/)
    .filter((w) => w.length > 0 && !['the', 'a', 'an', 'of', 'no', 'to', 'in', 'on', 'at', 'by', 'for', 'with'].includes(w));

  if (words.length < 2) return [];

  // 1. First letter of each word (e.g., Attack on Titan -> aot)
  const initials = words.map((w) => w[0]).join('');

  // 2. First 3 letters of first word if >=3 chars (e.g., Attack -> att)
  const firstWordPrefix = words[0].length >= 3 ? words[0].substring(0, 3) : '';

  // 3. Repeated initials for double letters (e.g., Jujutsu Kaisen -> jjk)
  const jjkStyle = words.length === 2 && words[0].length >= 2 ? `${words[0].substring(0, 2)}${words[1][0]}` : '';

  return Array.from(new Set([initials, firstWordPrefix, jjkStyle].filter((s) => s.length >= 2)));
}

class JSONDatabaseService {
  private offlineItems: MediaItem[] = [];
  private indexedOffline: IndexedItem[] = [];

  // O(1) Fast lookup index by ID and AniList ID
  private itemsById: Map<string, MediaItem> = new Map();
  private itemsByAnilistId: Map<number, MediaItem> = new Map();

  // Inverted Index Map (Token -> Set of offline array indices)
  private invertedIndex: Map<string, Set<number>> = new Map();
  private dictionaryWords: string[] = [];

  // Genre to items index for fast content similarity calculations
  private genreToIndices: Map<string, number[]> = new Map();

  // Precomputed Curated Category Shelves
  private precomputedShelves: CategoryShelf[] = [];

  // LRU / Map Caches with 10-Minute TTL for High-Performance
  private searchCache: Map<string, { data: SearchResponse; timestamp: number }> = new Map();
  private CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes TTL
  private maxCacheSize = 500;
  private similarityCache: Map<string, SimilarMediaResponse> = new Map();
  private maxSimilarityCacheSize = 500;
  private fuzzyWordCache: Map<string, string[]> = new Map();
  private maxFuzzyCacheSize = 1000;

  private setInLruMap<K, V>(map: Map<K, V>, key: K, value: V, maxSize: number): void {
    if (map.size >= maxSize && !map.has(key)) {
      const firstKey = map.keys().next().value;
      if (firstKey !== undefined) {
        map.delete(firstKey);
      }
    }
    map.set(key, value);
  }

  constructor() {
    this.initialize();
  }

  public initialize(): void {
    this.searchCache.clear();
    this.similarityCache.clear();
    this.fuzzyWordCache.clear();
    this.loadOfflineDatabase();
  }

  private loadOfflineDatabase(): void {
    const cachedItems = anilistCacheService.getAllCachedMedia();
    for (const item of cachedItems) {
      this.itemsById.set(item.id, item);
      if (item.anilistId) {
        this.itemsByAnilistId.set(item.anilistId, item);
      }
    }
    console.log(`[API Service] Online cloud mode: Loaded ${this.itemsById.size} media items into memory.`);
  }

  private buildCuratedShelves(): void {
    const validOffline = this.offlineItems.filter(
      (i) => (i.type === 'ANIME' || i.type === 'DONGHUA' || i.type === 'AENI') && i.scores.averageScore > 0 && i.coverImage.large
    );

    const masterpieces = [...validOffline]
      .filter((i) => i.scores.averageScore >= 8.5)
      .sort((a, b) => b.scores.averageScore - a.scores.averageScore)
      .slice(0, 8);

    const topDonghua = [...validOffline]
      .filter((i) => i.type === 'DONGHUA')
      .sort((a, b) => b.scores.averageScore - a.scores.averageScore)
      .slice(0, 8);

    const shounenAction = [...validOffline]
      .filter((i) => i.genres.some((g) => ['action', 'shounen', 'supernatural'].includes(g.toLowerCase())))
      .sort((a, b) => b.scores.averageScore - a.scores.averageScore)
      .slice(0, 8);

    const topMovies = [...validOffline]
      .filter((i) => i.format === 'MOVIE')
      .sort((a, b) => b.scores.averageScore - a.scores.averageScore)
      .slice(0, 8);

    const fantasyAdventures = [...validOffline]
      .filter((i) => i.genres.some((g) => ['fantasy', 'adventure', 'action'].includes(g.toLowerCase())))
      .sort((a, b) => b.scores.averageScore - a.scores.averageScore)
      .slice(0, 8);

    this.precomputedShelves = [
      {
        id: 'masterpieces',
        title: '🏆 Capodopere Animație (Scor ≥ 8.5)',
        description: 'Cele mai bune producții din toate timpurile cu cele mai mari note de la comunitate.',
        items: masterpieces,
      },
      {
        id: 'top-donghua',
        title: '🐉 Top Donghua (Animație Chineză)',
        description: 'Serii de colecție din universuri Xianxia, Martial Arts și Fantasy.',
        items: topDonghua,
      },
      {
        id: 'shounen-action',
        title: '⚔️ Acțiune & Shounen Epice',
        description: 'Bătălii intense, rivalități legendare și eroi de neoprit.',
        items: shounenAction,
      },
      {
        id: 'top-movies',
        title: '🎬 Filme Animație De Colecție',
        description: 'Lungmetraje fantastice cu grafică spectaculoasă și povești memorabile.',
        items: topMovies,
      },
      {
        id: 'fantasy-adventures',
        title: '🪄 Lumi Fantastice & Aventură',
        description: 'Călătorii epice în tărâmuri magice și bătălii legendare.',
        items: fantasyAdventures,
      },
    ];
  }

  public getLocalMedia(): MediaItem[] {
    return this.offlineItems.slice(0, 50);
  }

  public getAllOfflineMedia(): MediaItem[] {
    return this.offlineItems;
  }

  public getMediaById(id: string): MediaItem | undefined {
    return this.itemsById.get(id);
  }

  public async getMediaByIdAsync(id: string): Promise<MediaItem | undefined> {
    if (this.itemsById.has(id)) {
      return this.itemsById.get(id);
    }
    const item = await fetchAniListMediaById(id);
    if (item) {
      this.itemsById.set(id, item);
      this.itemsById.set(item.id, item);
      if (item.anilistId) {
        this.itemsByAnilistId.set(item.anilistId, item);
      }
      return item;
    }
    return undefined;
  }

  public getCategoryShelves(): CategoryShelf[] {
    return this.precomputedShelves;
  }

  public getSimilarMedia(targetId: string, limit: number = 6): SimilarMediaResponse {
    if (this.similarityCache.has(targetId)) {
      const cached = this.similarityCache.get(targetId)!;
      return {
        ...cached,
        similarItems: cached.similarItems.slice(0, limit),
      };
    }

    const target = this.getMediaById(targetId);
    if (!target) {
      return { targetId, similarItems: [] };
    }

    const targetGenres = new Set(target.genres.map((g) => g.toLowerCase()));
    const targetType = target.type;
    const targetFormat = target.format;
    const targetScore = target.scores.averageScore;

    const scored: { item: MediaItem; similarityScore: number; commonGenres: string[] }[] = [];

    const candidateItems: MediaItem[] = [];
    if (this.offlineItems.length > 0) {
      const candidateIndices = new Set<number>();
      for (const g of targetGenres) {
        const indices = this.genreToIndices.get(g);
        if (indices) {
          for (const idx of indices) {
            candidateIndices.add(idx);
          }
        }
      }
      for (const idx of candidateIndices) {
        if (this.offlineItems[idx]) candidateItems.push(this.offlineItems[idx]);
      }
    } else {
      for (const item of this.itemsById.values()) {
        if (item && item.id !== target.id) {
          candidateItems.push(item);
        }
      }
    }

    for (const item of candidateItems) {
      if (!item || item.id === target.id) continue;
      if (item.scores.averageScore === 0) continue;

      const itemGenres = item.genres.map((g) => g.toLowerCase());
      const common = itemGenres.filter((g) => targetGenres.has(g));

      if (common.length === 0 && item.type !== targetType && item.format !== targetFormat) {
        continue;
      }

      const union = new Set([...targetGenres, ...itemGenres]).size;
      const jaccard = union > 0 ? (common.length / union) * 50 : 0;
      const formatBonus = item.format === targetFormat ? 15 : 0;
      const typeBonus = item.type === targetType ? 15 : 0;
      const scoreProximity = Math.max(0, 10 - Math.abs(targetScore - item.scores.averageScore));

      // Algorithmic Generic Title Normalizer (Zero Hardcoding)
      const sanitizeRoot = (t: string) =>
        t
          .toLowerCase()
          .replace(/:\s*(season|part|cour)\s*\d+/gi, '')
          .replace(/\s+\d+(st|nd|rd|th)?\s+(season|part|cour)/gi, '')
          .replace(/\s+(season|part|cour)\s+\d+/gi, '')
          .replace(/[:\-].*$/, '')
          .replace(/[^a-z0-9]/gi, '');

      const targetRoot = sanitizeRoot(target.title.userPreferred || '');
      const itemRoot = sanitizeRoot(item.title.userPreferred || '');

      const isSameFranchise =
        targetRoot.length >= 4 &&
        itemRoot.length >= 4 &&
        (targetRoot.includes(itemRoot) || itemRoot.includes(targetRoot));

      const franchiseBonus = isSameFranchise ? 40 : 0;

      const rawScore = jaccard + formatBonus + typeBonus + scoreProximity + franchiseBonus;
      const similarityScore = isSameFranchise
        ? Math.min(99, Math.max(92, Math.round(rawScore)))
        : Math.min(95, Math.round(rawScore));

      if (similarityScore >= 35) {
        scored.push({
          item,
          similarityScore,
          commonGenres: common,
        });
      }
    }

    scored.sort((a, b) => b.similarityScore - a.similarityScore || b.item.scores.averageScore - a.item.scores.averageScore);

    const result: SimilarMediaResponse = {
      targetId,
      targetItem: target,
      similarItems: scored.slice(0, 20),
    };

    this.setInLruMap(this.similarityCache, targetId, result, this.maxSimilarityCacheSize);

    return {
      ...result,
      similarItems: result.similarItems.slice(0, limit),
    };
  }

  private findFuzzyMatches(queryToken: string): string[] {
    if (queryToken.length < 3) return [];

    if (this.fuzzyWordCache.has(queryToken)) {
      return this.fuzzyWordCache.get(queryToken)!;
    }

    const matches: string[] = [];
    const maxDistance = queryToken.length > 5 ? 2 : 1;

    for (const dictWord of this.dictionaryWords) {
      if (Math.abs(dictWord.length - queryToken.length) > maxDistance) continue;
      const dist = levenshteinDistance(queryToken, dictWord);
      if (dist <= maxDistance) {
        matches.push(dictWord);
      }
    }

    this.setInLruMap(this.fuzzyWordCache, queryToken, matches, this.maxFuzzyCacheSize);
    return matches;
  }

  private matchesFilter(
    item: MediaItem,
    typeFilter: MediaType | null,
    formatFilter: MediaFormat | null,
    statusFilter: ReleaseStatus | null,
    demoFilter: Demographic | null,
    seasonFilter: MediaSeason | null,
    yearFilter: string | null,
    genresList: string[],
    microTagsList: string[],
    minScore?: number
  ): boolean {
    if (typeFilter && item.type !== typeFilter) return false;
    if (formatFilter && item.format !== formatFilter) return false;
    if (statusFilter && item.status !== statusFilter) return false;
    if (demoFilter && item.demographic !== demoFilter) return false;
    if (seasonFilter && item.season !== seasonFilter) return false;
    if (minScore !== undefined && item.scores.averageScore < minScore) return false;

    // Year, Decade, or Range filter
    if (yearFilter && yearFilter !== 'ALL') {
      if (!item.year) return false;
      if (yearFilter === '2020s') {
        if (item.year < 2020 || item.year > 2029) return false;
      } else if (yearFilter === '2010s') {
        if (item.year < 2010 || item.year > 2019) return false;
      } else if (yearFilter === '2000s') {
        if (item.year < 2000 || item.year > 2009) return false;
      } else if (yearFilter === '1990s') {
        if (item.year < 1990 || item.year > 1999) return false;
      } else if (yearFilter === '1980s') {
        if (item.year < 1980 || item.year > 1989) return false;
      } else if (yearFilter === '1970s') {
        if (item.year < 1970 || item.year > 1979) return false;
      } else if (yearFilter === '1960s') {
        if (item.year < 1960 || item.year > 1969) return false;
      } else if (yearFilter === 'pre1960') {
        if (item.year >= 1960) return false;
      } else if (yearFilter.includes('-')) {
        const [minY, maxY] = yearFilter.split('-').map((y) => parseInt(y, 10));
        if (!isNaN(minY) && item.year < minY) return false;
        if (!isNaN(maxY) && item.year > maxY) return false;
      } else {
        const yNum = parseInt(yearFilter, 10);
        if (!isNaN(yNum) && item.year !== yNum) return false;
      }
    }

    // Multi-Genre matching (AND logic - item must contain all requested genres)
    if (genresList.length > 0) {
      const itemGenresLower = item.genres.map((g) => g.toLowerCase());
      const allMatch = genresList.every((reqG) =>
        itemGenresLower.some((ig) => ig.includes(reqG.toLowerCase()))
      );
      if (!allMatch) return false;
    }

    // Multi-MicroTag matching (AND logic - item must contain all requested micro-tags)
    if (microTagsList.length > 0) {
      if (!item.microTags || item.microTags.length === 0) return false;
      const itemTagsLower = item.microTags.map((t) => t.toLowerCase());
      const allMatch = microTagsList.every((reqT) =>
        itemTagsLower.some((it) => it.includes(reqT.toLowerCase()))
      );
      if (!allMatch) return false;
    }

    return true;
  }

  private sortItems(
    items: { item: MediaItem; score?: number }[],
    sortBy: SortOption = 'RELEVANCE',
    hasQuery: boolean = false
  ): MediaItem[] {
    const effectiveSort = sortBy === 'RELEVANCE' && !hasQuery ? 'SCORE_DESC' : sortBy;

    return items
      .sort((a, b) => {
        const aTitle = a.item.title?.userPreferred || a.item.title?.english || a.item.title?.romaji || '';
        const bTitle = b.item.title?.userPreferred || b.item.title?.english || b.item.title?.romaji || '';
        const aScore = a.item.scores?.averageScore || 0;
        const bScore = b.item.scores?.averageScore || 0;
        const aReviews = a.item.scores?.reviewCount || 0;
        const bReviews = b.item.scores?.reviewCount || 0;

        switch (effectiveSort) {
          case 'RELEVANCE':
            return (b.score || 0) - (a.score || 0) || bScore - aScore;
          case 'SCORE_DESC':
            return bScore - aScore || bReviews - aReviews;
          case 'POPULARITY_DESC':
            return bReviews - aReviews || bScore - aScore;
          case 'YEAR_DESC':
            return (b.item.year || 0) - (a.item.year || 0) || bScore - aScore;
          case 'YEAR_ASC':
            return (a.item.year || 9999) - (b.item.year || 9999) || bScore - aScore;
          case 'TITLE_ASC':
            return aTitle.localeCompare(bTitle);
          default:
            return bScore - aScore;
        }
      })
      .map((entry) => entry.item);
  }
  private computeRelevanceScore(item: MediaItem, rawQuery: string): number {
    if (!rawQuery.trim()) return item.scores.averageScore || 0;

    const qNorm = normalize(rawQuery.trim());
    const qTokens = qNorm.split(' ').filter(Boolean);

    const titlePref = normalize(item.title.userPreferred || '');
    const titleEng = item.title.english ? normalize(item.title.english) : '';
    const titleRom = item.title.romaji ? normalize(item.title.romaji) : '';

    const allTitles = [titlePref, titleEng, titleRom].filter(Boolean);

    let textScore = 0;

    // 1. Exact Match (+10,000 pts)
    if (allTitles.some((t) => t === qNorm)) {
      textScore += 10000;
    }
    // 2. Title Starts With Query (+5,000 pts)
    else if (allTitles.some((t) => t.startsWith(qNorm))) {
      textScore += 5000;
    }
    // 3. Word in Title Starts With Query (+3,000 pts)
    else if (allTitles.some((t) => t.split(' ').some((word) => word.startsWith(qNorm)))) {
      textScore += 3000;
    }
    // 4. Dynamic Algorithmic Initialism Match (+4,000 pts - e.g. "Attack on Titan" -> "aot"/"att", "Jujutsu Kaisen" -> "jjk")
    else if (
      allTitles.some((t) =>
        generateTitleInitialisms(t).some((init) => init === qNorm || init.startsWith(qNorm))
      )
    ) {
      textScore += 4000;
    }
    // 5. Title / Subtitle Contains Substring (+1,000 pts)
    else if (allTitles.some((t) => t.includes(qNorm))) {
      textScore += 1000;
    }
    // 6. Fuzzy Match for Typos (Levenshtein distance <= 2 on query >= 4 chars, +300 pts)
    else if (
      qNorm.length >= 4 &&
      allTitles.some((t) =>
        t.split(' ').some((word) => word.length >= 3 && levenshteinDistance(qNorm, word) <= (qNorm.length >= 6 ? 2 : 1))
      )
    ) {
      textScore += 300;
    }
    // 7. Tokens match (+500 pts per matched token)
    else {
      for (const token of qTokens) {
        if (allTitles.some((t) => t.includes(token))) {
          textScore += 500;
        }
      }
    }

    if (textScore === 0) return 0;

    // 8. Popularity & Quality Boost Logarithmic Formula (Log10 reviewCount * 250 + ratingWeight + airingBonus)
    const reviewCount = item.scores.reviewCount || 10;
    const popularityBoost = Math.log10(reviewCount + 1) * 250;
    const ratingBoost = (item.scores.averageScore || 5) * 20;
    const airingBonus = item.status === 'RELEASING' ? 150 : 0;

    return textScore + popularityBoost + ratingBoost + airingBonus;
  }

  public searchLocal(options: SearchQueryOptions): { items: MediaItem[]; total: number } {
    const {
      query = '',
      type = 'ALL',
      format = 'ALL',
      status = 'ALL',
      demographic = 'ALL',
      season = 'ALL',
      year = 'ALL',
      sortBy = 'RELEVANCE',
      genre = '',
      genres = [],
      microTag = '',
      microTags = [],
      minScore,
      limit = 30,
      page = 1,
    } = options;

    const qRaw = (query || '').trim();
    const typeFilter = type && type !== 'ALL' ? type : null;
    const formatFilter = format && format !== 'ALL' ? format : null;
    const statusFilter = status && status !== 'ALL' ? status : null;
    const demoFilter = demographic && demographic !== 'ALL' ? demographic : null;
    const seasonFilter = season && season !== 'ALL' ? season : null;
    const yearFilter = year && year !== 'ALL' ? String(year) : null;

    // Combine genre / genres into a unified list
    const combinedGenres = [
      ...genres,
      ...(genre ? genre.split(',') : []),
    ].map((g) => g.trim()).filter(Boolean);

    // Combine microTag / microTags into a unified list
    const combinedMicroTags = [
      ...microTags,
      ...(microTag ? microTag.split(',') : []),
    ].map((t) => t.trim()).filter(Boolean);

    if (!qRaw) {
      const filteredOffline = this.offlineItems.filter((item) => {
        if (item.scores.averageScore <= 0) return false;
        return this.matchesFilter(
          item,
          typeFilter,
          formatFilter,
          statusFilter,
          demoFilter,
          seasonFilter,
          yearFilter,
          combinedGenres,
          combinedMicroTags,
          minScore
        );
      });

      const combinedEntries = filteredOffline.map((item) => ({ item }));

      const sorted = this.sortItems(combinedEntries, sortBy, false);
      const total = sorted.length;
      const start = (page - 1) * limit;
      const items = sorted.slice(start, start + limit);
      return { items, total };
    }

    const qNorm = normalize(qRaw);
    const qTokens = qNorm.split(' ').filter(Boolean);

    const searchTokens = new Set<string>(qTokens);

    const candidateIndicesSets: Set<number>[] = [];
    const tokenFuzzyMatchesMap = new Map<string, string[]>();

    for (const token of searchTokens) {
      let matchingIndices = this.invertedIndex.get(token);

      if (!matchingIndices || matchingIndices.size === 0) {
        const prefixMatches = new Set<number>();
        for (const [dictWord, indices] of this.invertedIndex.entries()) {
          if (dictWord.startsWith(token)) {
            for (const idx of indices) prefixMatches.add(idx);
          }
        }
        if (prefixMatches.size > 0) {
          matchingIndices = prefixMatches;
        }
      }

      const fuzzyWords = this.findFuzzyMatches(token);
      tokenFuzzyMatchesMap.set(token, fuzzyWords);

      if (!matchingIndices || matchingIndices.size === 0) {
        if (fuzzyWords.length > 0) {
          const fuzzyIndices = new Set<number>();
          for (const fw of fuzzyWords) {
            const fwIndices = this.invertedIndex.get(fw);
            if (fwIndices) {
              for (const idx of fwIndices) fuzzyIndices.add(idx);
            }
          }
          matchingIndices = fuzzyIndices;
        }
      }

      if (matchingIndices) {
        candidateIndicesSets.push(matchingIndices);
      }
    }

    const scoredMap = new Map<number, { item: MediaItem; score: number }>();

    if (candidateIndicesSets.length > 0) {
      const candidateUnion = new Set<number>();
      for (const set of candidateIndicesSets) {
        for (const idx of set) candidateUnion.add(idx);
      }

      for (const idx of candidateUnion) {
        const entry = this.indexedOffline[idx];
        if (
          !this.matchesFilter(
            entry.item,
            typeFilter,
            formatFilter,
            statusFilter,
            demoFilter,
            seasonFilter,
            yearFilter,
            combinedGenres,
            combinedMicroTags,
            minScore
          )
        ) {
          continue;
        }

        const score = this.computeRelevanceScore(entry.item, qRaw);
        if (score > 0) {
          scoredMap.set(idx, { item: entry.item, score });
        }
      }
    }

    const allCandidates = Array.from(scoredMap.values());

    const sorted = this.sortItems(allCandidates, sortBy, true);
    const total = sorted.length;

    const start = (page - 1) * limit;
    const items = sorted.slice(start, start + limit);

    return { items, total };
  }

  public async search(options: SearchQueryOptions): Promise<SearchResponse> {
    const { query = '', type = 'ALL', source = 'all', sortBy = 'RELEVANCE', limit = 30, page = 1 } = options;
    const genresKey = options.genres?.join(',') || options.genre || '';
    const microTagsKey = options.microTags?.join(',') || options.microTag || '';
    const cacheKey = `${query.toLowerCase().trim()}|${type}|${options.format || 'ALL'}|${options.status || 'ALL'}|${options.demographic || 'ALL'}|${options.season || 'ALL'}|${options.year || 'ALL'}|${genresKey}|${microTagsKey}|${options.minScore || 0}|${sortBy}|${source}|${limit}|${page}`;

    const cached = this.searchCache.get(cacheKey);
    if (cached) {
      if (Date.now() - cached.timestamp < this.CACHE_TTL_MS) {
        return {
          ...cached.data,
          isCached: true,
          executionTimeMs: 0,
        };
      } else {
        this.searchCache.delete(cacheKey);
      }
    }

    const startTime = Date.now();
    let results: MediaItem[] = [];
    const sourcesUsed: DataSource[] = [];
    let totalMatches = 0;

    // 1. Search Local Database
    if (source === 'all' || source === 'local') {
      const localResult = this.searchLocal(options);
      results.push(...localResult.items);
      totalMatches = localResult.total;
      sourcesUsed.push('LOCAL_JSON', 'LOCAL_OFFLINE_DB');
    }

    // 2. Search AniList API
    const shouldFetchAniList = source === 'anilist' || source === 'all';

    if (shouldFetchAniList) {
      const aniListResponse = await searchAniList(options, limit);
      const aniListResults = aniListResponse.items;

      for (const item of aniListResults) {
        this.itemsById.set(item.id, item);
        if (item.anilistId) {
          this.itemsByAnilistId.set(item.anilistId, item);
        }
      }

      const existingAnilistIds = new Set(
        results.map((r) => r.anilistId).filter(Boolean)
      );

      const existingNormalizedTitles = new Set(
        results.map((r) => normalize(r.title.userPreferred))
      );

      const filteredAniList = aniListResults.filter((item) => {
        if (item.anilistId && existingAnilistIds.has(item.anilistId)) return false;
        if (existingNormalizedTitles.has(normalize(item.title.userPreferred))) return false;
        if (item.title.romaji && existingNormalizedTitles.has(normalize(item.title.romaji))) return false;
        if (item.title.english && existingNormalizedTitles.has(normalize(item.title.english))) return false;
        return true;
      });

      results.push(...filteredAniList);
      totalMatches = Math.max(totalMatches, aniListResponse.total || filteredAniList.length);
      sourcesUsed.push('ANILIST');
    }

    // Unified Hybrid Re-Ranking with Relevance Engine
    if (query.trim().length > 0) {
      const candidates = results.map((item) => ({
        item,
        score: this.computeRelevanceScore(item, query),
      }));
      results = this.sortItems(candidates, sortBy, true);
    }

    // Enrich results with official AniList scores from cache (score 0 if not present)
    const enrichedResults = results.slice(0, limit).map((item) => {
      if (item.source === 'LOCAL_OFFLINE_DB' || item.source === 'LOCAL_JSON') {
        const cached = anilistCacheService.getCachedScore(item.anilistId);
        return {
          ...item,
          scores: cached || {
            averageScore: 0,
            reviewCount: 0,
            weightedScore: 0,
          },
        };
      }
      return item;
    });

    // Non-blocking background fetch of missing scores for search results that have an anilistId
    const missingAnilistIds = enrichedResults
      .map((i) => i.anilistId)
      .filter((id): id is number => typeof id === 'number' && !anilistCacheService.getCachedScore(id));

    if (missingAnilistIds.length > 0) {
      anilistCacheService.fetchMediaBatch(missingAnilistIds).catch(() => {});
    }

    const totalPages = Math.ceil(totalMatches / limit) || 1;
    const executionTimeMs = Date.now() - startTime;

    const response: SearchResponse = {
      results: enrichedResults,
      total: totalMatches,
      sourcesUsed,
      query,
      page,
      totalPages,
      hasMore: page < totalPages,
      executionTimeMs,
      isCached: false,
    };

    if (this.searchCache.size >= this.maxCacheSize) {
      const firstKey = this.searchCache.keys().next().value;
      if (firstKey) this.searchCache.delete(firstKey);
    }
    this.searchCache.set(cacheKey, { data: response, timestamp: Date.now() });

    return response;
  }

  public async getHomepageData(userWatchlist?: any[], favoriteGenres?: string[]): Promise<HomepageData> {
    const isCleanTitle = (item: MediaItem): boolean => {
      const t = (item.title?.userPreferred || item.title?.english || item.title?.romaji || '').trim();
      if (!t) return false;
      // Exclude titles starting with quotes, brackets, or weird symbols
      if (/^[!"#$%&'()*+,\-./:;<=>?@[\]^_`{|}~]/.test(t)) return false;
      const tagsLower = (item.genres || []).map((g) => g.toLowerCase());
      if (
        tagsLower.some((g) =>
          ['hentai', 'advertisement', 'promotional', 'commercial', 'short episodes'].includes(g)
        )
      ) {
        return false;
      }
      return true;
    };

    const allKnownItems = this.offlineItems.length > 0 ? this.offlineItems : Array.from(this.itemsById.values());
    const validOfflineAllCategories = allKnownItems.filter(
      (i) => (i.scores?.averageScore || 0) > 0 && i.coverImage?.large && isCleanTitle(i)
    );

    const validOffline = validOfflineAllCategories.filter((i) => i.type === 'ANIME');

    // 1. Trending Season (Most popular & trending current season anime titles only, excluding continuous series)
    const currentYear = new Date().getFullYear();
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

    const trendingSeasonCandidates = [...validOffline]
      .filter((i) => {
        if (i.type !== 'ANIME') return false;
        if (!i.format || !['TV', 'MOVIE', 'ONA'].includes(i.format)) return false;
        if ((i.scores?.averageScore || 0) < 7.4) return false;

        const titleLower = (i.title?.userPreferred || i.title?.english || i.title?.romaji || '').toLowerCase();
        if (continuousShowsBlacklist.some((b) => titleLower.includes(b))) return false;

        // Exclude shows with > 50 episodes unless released recently
        if (i.episodes && i.episodes > 50) return false;

        return i.status === 'RELEASING' || (i.year && i.year >= currentYear - 1);
      })
      .sort(
        (a, b) =>
          (b.scores?.reviewCount || 0) * (b.scores?.averageScore || 1) -
          (a.scores?.reviewCount || 0) * (a.scores?.averageScore || 1)
      );

    const fallbackFeatured = trendingSeasonCandidates.slice(0, 8);

    // 2. Ultimele episoade ieșite Fallback (Strictly RELEASING currently airing media)
    const releasingCandidates = [...validOffline]
      .filter(
        (i) =>
          i.type === 'ANIME' &&
          (i.format === 'TV' || i.format === 'ONA') &&
          i.status === 'RELEASING'
      )
      .sort((a, b) => (b.year || 0) - (a.year || 0) || b.scores.averageScore - a.scores.averageScore);

    const relativeTimeLabels = [
      'Acum 45 min',
      'Acum 2 ore',
      'Acum 5 ore',
      'Ieri la 21:00',
      'Ieri la 18:30',
      'Acum 2 zile',
      'Acum 3 zile',
      'Acum 4 zile',
    ];

    const fallbackRecentlyAired: RecentlyAiredEpisode[] = releasingCandidates
      .slice(0, 12)
      .map((item, idx) => ({
        media: item,
        episodeNumber: item.episodes ? Math.min(idx + 1, item.episodes) : (idx + 1) * 2,
        episodeTitle: `Episodul ${idx + 1}`,
        airDateRelative: relativeTimeLabels[idx % relativeTimeLabels.length],
        airDateExact: new Date(Date.now() - idx * 3600 * 1000 * 8).toISOString(),
        thumbnailUrl: item.coverImage.extraLarge || item.coverImage.large,
      }));

    // 3. News Feed (Auto-Aggregated Live RSS News from official feeds)
    const newsBeta: NewsArticle[] = newsAggregationService.getLatest(4);

    // 4. Recomandări (Direct din AniList SWR Cache cu Batching pe Watchlist/Favorite)
    let recommendations: RecommendedMediaItem[] = [];

    const userWatchlistIds = new Set((userWatchlist || []).map((w: any) => w.mediaId));
    const watchlistAnilistIds: number[] = [];

    if (userWatchlist && userWatchlist.length > 0) {
      for (const item of userWatchlist) {
        if (item.mediaItem?.anilistId) {
          watchlistAnilistIds.push(item.mediaItem.anilistId);
        } else if (item.mediaId) {
          if (item.mediaId.startsWith('anilist-')) {
            const parsed = parseInt(item.mediaId.replace('anilist-', ''), 10);
            if (!isNaN(parsed)) watchlistAnilistIds.push(parsed);
          } else {
            const local = this.itemsById.get(item.mediaId);
            if (local?.anilistId) watchlistAnilistIds.push(local.anilistId);
          }
        }
      }
    }

    if (watchlistAnilistIds.length > 0 || (favoriteGenres && favoriteGenres.length > 0)) {
      recommendations = await anilistCacheService.fetchPersonalizedRecommendations(
        watchlistAnilistIds,
        favoriteGenres,
        userWatchlistIds
      );
    }

    if (recommendations.length === 0) {
      recommendations = await anilistCacheService.fetchGuestRecommendations(12);
    }

    // Safe parallel fetch for live AniList rankings & schedule
    const [featuredRes, airingRes, upcomingRes, top100Res, recentlyAiredRes] = await Promise.allSettled([
      fetchAniListFeatured(),
      fetchAniListTopAiring(),
      fetchAniListTopUpcoming(),
      fetchAniListTop100(),
      fetchAniListRecentlyAired(),
    ]);

    let recentlyAired =
      recentlyAiredRes.status === 'fulfilled' && recentlyAiredRes.value && recentlyAiredRes.value.length > 0
        ? recentlyAiredRes.value.filter((item) => item.media.type === 'ANIME')
        : fallbackRecentlyAired;

    let featuredSeason =
      featuredRes.status === 'fulfilled' && featuredRes.value && featuredRes.value.length > 0
        ? featuredRes.value.filter((item) => item.type === 'ANIME')
        : fallbackFeatured;

    let topAiring =
      airingRes.status === 'fulfilled' && airingRes.value && airingRes.value.length > 0
        ? airingRes.value.filter((item) => item.type === 'ANIME')
        : [...validOffline]
            .filter((i) => i.type === 'ANIME' && (i.status === 'RELEASING' || (i.year && i.year >= 2024)))
            .sort((a, b) => (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0) || (b.year || 0) - (a.year || 0))
            .slice(0, 10);

    let topUpcoming =
      upcomingRes.status === 'fulfilled' && upcomingRes.value && upcomingRes.value.length > 0
        ? upcomingRes.value.filter((item) => item.type === 'ANIME')
        : [...validOffline]
            .filter((i) => i.type === 'ANIME' && (i.status === 'UPCOMING' || (i.year && i.year >= 2025)))
            .sort((a, b) => (b.year || 0) - (a.year || 0) || (b.scores?.averageScore || 0) - (a.scores?.averageScore || 0))
            .slice(0, 10);

    let top100 =
      top100Res.status === 'fulfilled' && top100Res.value && top100Res.value.length > 0
        ? top100Res.value.filter((item) => item.type === 'ANIME')
        : [...validOffline]
            .filter(
              (i) =>
                i.type === 'ANIME' &&
                (i.format === 'TV' || i.format === 'MOVIE' || i.format === 'ONA' || i.format === 'OVA') &&
                i.status !== 'UPCOMING' &&
                (!i.year || i.year <= 2025) &&
                (i.scores?.averageScore || 0) >= 7.0 &&
                (i.scores?.averageScore || 0) <= 9.9
            )
            .sort(
              (a, b) =>
                (b.scores?.weightedScore || b.scores?.averageScore || 0) -
                  (a.scores?.weightedScore || a.scores?.averageScore || 0) ||
                (b.scores?.reviewCount || 0) - (a.scores?.reviewCount || 0) ||
                (b.year || 0) - (a.year || 0)
            )
            .slice(0, 100);

    return {
      featuredSeason,
      recentlyAired,
      newsBeta,
      recommendations,
      topAiring,
      topUpcoming,
      top100,
    };
  }
}

export const dbService = new JSONDatabaseService();

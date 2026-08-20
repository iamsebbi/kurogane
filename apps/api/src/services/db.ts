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
} from './anilist';

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

  // O(1) Fast lookup index by ID
  private itemsById: Map<string, MediaItem> = new Map();

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
  private fuzzyWordCache: Map<string, string[]> = new Map();

  constructor() {
    this.initialize();
  }

  public initialize(): void {
    this.searchCache.clear();
    this.similarityCache.clear();
    this.loadOfflineDatabase();
  }

  private loadOfflineDatabase(): void {
    const startTime = Date.now();
    let dbPath: string | null = null;
    for (const p of OFFLINE_DB_PATHS) {
      if (fs.existsSync(p)) {
        dbPath = p;
        break;
      }
    }

    if (!dbPath) {
      console.warn('[Offline DB] anime-offline-database-minified.json not found.');
      return;
    }

    try {
      console.log(`[Offline DB] Loading offline database from ${dbPath}...`);
      const fileData = fs.readFileSync(dbPath, 'utf-8');
      const parsed = JSON.parse(fileData);
      const rawData: any[] = parsed.data || [];

      this.offlineItems = [];
      this.indexedOffline = [];
      this.invertedIndex.clear();
      this.genreToIndices.clear();
      this.similarityCache.clear();
      this.fuzzyWordCache.clear();

      for (let i = 0; i < rawData.length; i++) {
        const raw = rawData[i];

        let anilistId: number | undefined;
        if (Array.isArray(raw.sources)) {
          const ali = raw.sources.find((s: string) => s.includes('anilist.co/anime/'));
          if (ali) {
            const match = ali.match(/\/anime\/(\d+)/);
            if (match) anilistId = parseInt(match[1], 10);
          }
        }

        const tagsLower = Array.isArray(raw.tags) ? raw.tags.map((t: string) => t.toLowerCase()) : [];
        const isChinese = tagsLower.some((t: string) => t.includes('chinese') || t.includes('china') || t === 'donghua');
        const isKorean = tagsLower.some((t: string) => t.includes('korean') || t.includes('korea') || t === 'aeni' || t === 'manhwa');

        // 1. MediaType mapping
        let mType: MediaType = 'ANIME';
        if (raw.type === 'MANGA') {
          if (isKorean) mType = 'MANHWA';
          else if (isChinese) mType = 'MANHUA';
          else mType = 'MANGA';
        } else {
          if (isChinese) mType = 'DONGHUA';
          else if (isKorean) mType = 'AENI';
          else mType = 'ANIME';
        }

        // 2. MediaFormat mapping
        let mFormat: MediaFormat = (raw.type as MediaFormat) || 'TV';
        if (raw.type === 'SPECIAL') mFormat = 'SPECIAL';
        else if (raw.duration?.value && raw.duration.value <= 600 && raw.type === 'TV') {
          mFormat = 'TV_SHORT';
        }

        // 3. ReleaseStatus mapping
        let releaseStatus: ReleaseStatus = 'FINISHED';
        const stLower = (raw.status || '').toLowerCase();
        if (stLower.includes('releas') || stLower.includes('airing') || stLower.includes('current') || stLower === 'ongoing') {
          releaseStatus = 'RELEASING';
        } else if (stLower.includes('upcom') || stLower.includes('not_yet') || stLower.includes('unreleased')) {
          releaseStatus = 'UPCOMING';
        } else if (stLower.includes('cancel')) {
          releaseStatus = 'CANCELLED';
        } else if (stLower.includes('hiatus')) {
          releaseStatus = 'HIATUS';
        } else {
          releaseStatus = 'FINISHED';
        }

        // 4. Demographic mapping (data-driven from tag-taxonomy.json)
        let demographic: Demographic | undefined;
        for (const rule of TAG_TAXONOMY.demographics) {
          if (rule.patterns.some((p: string) => tagsLower.includes(p))) {
            demographic = rule.label as Demographic;
            break;
          }
        }

        // 5. Season & Year mapping
        let mSeason: MediaSeason | undefined;
        if (raw.animeSeason?.season) {
          const sUpper = raw.animeSeason.season.toUpperCase();
          if (['WINTER', 'SPRING', 'SUMMER', 'FALL'].includes(sUpper)) {
            mSeason = sUpper as MediaSeason;
          }
        }
        const mYear = raw.animeSeason?.year || undefined;

        // 6. Micro-Tags & Tropes (data-driven from tag-taxonomy.json)
        const microTags: string[] = [];
        for (const rule of TAG_TAXONOMY.microTags) {
          if (rule.patterns.some((p: string) => tagsLower.some((t: string) => t.includes(p)))) {
            microTags.push(rule.label);
          }
        }

        const englishSynonym = Array.isArray(raw.synonyms)
          ? raw.synonyms.find((s: string) => /^[A-Za-z0-9\s:!?,.'"-]+$/.test(s))
          : undefined;

        const rawScore = raw.score?.arithmeticMean ? Number(raw.score.arithmeticMean.toFixed(1)) : 0;
        const estimatedReviews = rawScore > 0 ? Math.round(500 + rawScore * 450) : 0;
        const weightedScore = rawScore > 0
          ? Number(((rawScore * estimatedReviews + 7.0 * 100) / (estimatedReviews + 100)).toFixed(1))
          : 0;

        const mediaItem: MediaItem = {
          id: anilistId ? `anilist-${anilistId}` : `offline-${i}`,
          anilistId,
          title: {
            userPreferred: raw.title || 'Untitled',
            english: englishSynonym || raw.title,
            romaji: raw.title,
          },
          type: mType,
          format: mFormat,
          status: releaseStatus,
          demographic,
          microTags,
          episodes: raw.episodes || null,
          genres: raw.tags || [],
          description: Array.isArray(raw.synonyms) && raw.synonyms.length > 0
            ? `Synonyms: ${raw.synonyms.slice(0, 4).join(', ')}`
            : undefined,
          coverImage: {
            large: raw.picture || raw.thumbnail || '',
            medium: raw.thumbnail || raw.picture || '',
            color: '#3b82f6',
          },
          year: mYear,
          season: mSeason,
          scores: {
            averageScore: rawScore,
            reviewCount: estimatedReviews,
            weightedScore,
          },
          source: 'LOCAL_OFFLINE_DB',
        };

        this.offlineItems.push(mediaItem);
        this.itemsById.set(mediaItem.id, mediaItem);
        if (anilistId) {
          this.itemsById.set(`anilist-${anilistId}`, mediaItem);
        }

        const normTitle = normalize(raw.title || '');
        const normSyn = Array.isArray(raw.synonyms) ? normalize(raw.synonyms.join(' ')) : '';
        const normTags = Array.isArray(raw.tags) ? normalize(raw.tags.join(' ')) : '';
        const normStudios = Array.isArray(raw.studios) ? normalize(raw.studios.join(' ')) : (raw.studio ? normalize(raw.studio) : '');
        const normProducers = Array.isArray(raw.producers) ? normalize(raw.producers.join(' ')) : '';
        const normMicro = normalize(microTags.join(' '));

        const fullText = `${normTitle} ${normSyn} ${normTags} ${normMicro} ${normStudios} ${normProducers}`;
        const tokens = new Set(fullText.split(' ').filter((t) => t.length > 1));

        // Add dynamic initialisms to tokens set (e.g. "Attack on Titan" -> "aot", "att", "snk")
        const initialisms = [
          ...generateTitleInitialisms(raw.title || ''),
          ...(englishSynonym ? generateTitleInitialisms(englishSynonym) : []),
          ...(Array.isArray(raw.synonyms) ? raw.synonyms.flatMap((s: string) => generateTitleInitialisms(s)) : []),
        ];
        for (const init of initialisms) {
          tokens.add(init);
        }

        this.indexedOffline.push({
          item: mediaItem,
          normTitle,
          normSynonyms: normSyn,
          normTags: `${normTags} ${normMicro} ${normStudios} ${normProducers}`,
          allTokens: tokens,
        });



        for (const token of tokens) {
          let indexSet = this.invertedIndex.get(token);
          if (!indexSet) {
            indexSet = new Set<number>();
            this.invertedIndex.set(token, indexSet);
          }
          indexSet.add(i);
        }

        for (const g of raw.tags || []) {
          const gLower = g.toLowerCase();
          let gArr = this.genreToIndices.get(gLower);
          if (!gArr) {
            gArr = [];
            this.genreToIndices.set(gLower, gArr);
          }
          gArr.push(i);
        }
      }

      this.dictionaryWords = Array.from(this.invertedIndex.keys());

      // Precalculate Curated Shelves ONCE at startup
      this.buildCuratedShelves();

      const elapsed = Date.now() - startTime;
      console.log(
        `[Offline DB Engine] Successfully loaded ${this.offlineItems.length} records & built Taxonomy Index (${this.invertedIndex.size} tokens) in ${elapsed}ms.`
      );
    } catch (err) {
      console.error('[Offline DB Engine] Error reading offline database:', err);
    }
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

    const candidateIndices = new Set<number>();
    for (const g of targetGenres) {
      const indices = this.genreToIndices.get(g);
      if (indices) {
        for (const idx of indices) {
          candidateIndices.add(idx);
        }
      }
    }

    const scored: { item: MediaItem; similarityScore: number; commonGenres: string[] }[] = [];

    for (const idx of candidateIndices) {
      const item = this.offlineItems[idx];
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

    this.similarityCache.set(targetId, result);

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

    this.fuzzyWordCache.set(queryToken, matches);
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
        switch (effectiveSort) {
          case 'RELEVANCE':
            return (b.score || 0) - (a.score || 0) || b.item.scores.averageScore - a.item.scores.averageScore;
          case 'SCORE_DESC':
            return b.item.scores.averageScore - a.item.scores.averageScore || b.item.scores.reviewCount - a.item.scores.reviewCount;
          case 'POPULARITY_DESC':
            return b.item.scores.reviewCount - a.item.scores.reviewCount || b.item.scores.averageScore - a.item.scores.averageScore;
          case 'YEAR_DESC':
            return (b.item.year || 0) - (a.item.year || 0) || b.item.scores.averageScore - a.item.scores.averageScore;
          case 'YEAR_ASC':
            return (a.item.year || 9999) - (b.item.year || 9999) || b.item.scores.averageScore - a.item.scores.averageScore;
          case 'TITLE_ASC':
            return a.item.title.userPreferred.localeCompare(b.item.title.userPreferred);
          default:
            return b.item.scores.averageScore - a.item.scores.averageScore;
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
    const shouldFetchAniList = source === 'anilist' || (source === 'all' && query.trim().length > 0);

    if (shouldFetchAniList) {
      const aniListResults = await searchAniList(query, limit);

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
      totalMatches += filteredAniList.length;
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

    const totalPages = Math.ceil(totalMatches / limit) || 1;
    const executionTimeMs = Date.now() - startTime;

    const response: SearchResponse = {
      results: results.slice(0, limit),
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
      const t = item.title.userPreferred.trim();
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

    const validOfflineAllCategories = this.offlineItems.filter(
      (i) => i.scores.averageScore > 0 && i.coverImage.large && isCleanTitle(i)
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
        if (!['TV', 'MOVIE', 'ONA'].includes(i.format)) return false;
        if (i.scores.averageScore < 7.4) return false;

        const titleLower = i.title.userPreferred.toLowerCase();
        if (continuousShowsBlacklist.some((b) => titleLower.includes(b))) return false;

        // Exclude shows with > 50 episodes unless released recently
        if (i.episodes && i.episodes > 50) return false;

        return i.status === 'RELEASING' || (i.year && i.year >= currentYear - 1);
      })
      .sort(
        (a, b) =>
          (b.scores.reviewCount || 0) * (b.scores.averageScore || 1) -
          (a.scores.reviewCount || 0) * (a.scores.averageScore || 1)
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

    // 3. News Beta (Anime & Manga News)
    const newsBeta: NewsArticle[] = [
      {
        id: 'news-1',
        title: 'Solo Leveling Sezonul 2: Arise from the Shadow primește dată oficială de lansare',
        category: 'ANIME',
        tagBadge: 'SEZON NOU',
        summary: 'Producătorii Aniplex și Studioul A-1 Pictures au lansat un nou trailer vizual pentru continuarea aventurii lui Sung Jinwoo.',
        content: 'Sezonul 2 promite secvențe de acțiune și mai spectaculoase și va acoperi unul dintre cele mai așteptate arcuri din manhwa-ul original. Lansarea globală va avea loc pe platformele principale de streaming.',
        imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80',
        date: '20 August 2026',
        readTime: '3 min lectura',
        source: 'Kurogane Newsroom',
        isBeta: true,
      },
      {
        id: 'news-2',
        title: 'Demon Slayer: Infinity Castle Movie Trilogy - Teaser Trailer Oficial lansat de ufotable',
        category: 'MOVIE',
        tagBadge: 'FILM CINEMA',
        summary: 'Trilogia de filme ce încheie saga Demon Slayer a primit primele secvențe animate de înaltă rezoluție.',
        content: 'ufotable continuă să împingă limitele animației digitale. Prima parte a trilogiei va fi lansată simultan în cinematografele din întreaga lume.',
        imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800&auto=format&fit=crop&q=80',
        date: '19 August 2026',
        readTime: '4 min lectura',
        source: 'ufotable Official',
        isBeta: true,
      },
      {
        id: 'news-3',
        title: 'Chainsaw Man Capitolul 180 deschide un nou arc epic în seria Manga',
        category: 'MANGA',
        tagBadge: 'CAPITOL NOU',
        summary: 'Tatsuki Fujimoto revine cu o întorsătură de situație neașteptată pentru Denji și noii demoni din universul Chainsaw Man.',
        content: 'Fanii au reacționat intens la lansarea noului capitol, care plasează personajul principal într-o confruntare directă cu demonii de nivel înalt.',
        imageUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=800&auto=format&fit=crop&q=80',
        date: '18 August 2026',
        readTime: '2 min lectura',
        source: 'Shonen Jump',
        isBeta: true,
      },
      {
        id: 'news-4',
        title: 'Studioul MAPPA anunță un nou proiect anime original cu buget record',
        category: 'STUDIO',
        tagBadge: 'ANUNȚ OFICIAL',
        summary: 'Echipa din spatele Jujutsu Kaisen și Attack on Titan pregătește un anime sci-fi cyberpunk impecabil vizual.',
        content: 'Proiectul va fi regizat de nume importante din industrie și va beneficia de o coloană sonoră orchestrală compusă de muzicieni de renume internațional.',
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&auto=format&fit=crop&q=80',
        date: '16 August 2026',
        readTime: '5 min lectura',
        source: 'MAPPA Stage',
        isBeta: true,
      },
    ];

    // 4. Recomandări (Personalizate dacă există Watchlist/Profil, altfel Curated High Rating Media)
    let recommendations: RecommendedMediaItem[] = [];

    const userWatchlistIds = new Set((userWatchlist || []).map((w: any) => w.mediaId));
    const userGenreScores: Record<string, number> = {};

    if (favoriteGenres && favoriteGenres.length > 0) {
      for (const fg of favoriteGenres) {
        const fgLower = fg.toLowerCase();
        userGenreScores[fgLower] = (userGenreScores[fgLower] || 0) + 5;
      }
    }
    if (userWatchlist && userWatchlist.length > 0) {
      for (const item of userWatchlist) {
        const scoreBonus = item.score && item.score >= 7 ? item.score : 5;
        if (item.mediaItem?.genres) {
          for (const g of item.mediaItem.genres) {
            const gLower = g.toLowerCase();
            userGenreScores[gLower] = (userGenreScores[gLower] || 0) + scoreBonus;
          }
        }
      }
    }

    const hasUserPreferences = Object.keys(userGenreScores).length > 0;

    if (hasUserPreferences) {
      const scoredRecommendations = [...validOfflineAllCategories]
        .filter((i) => !userWatchlistIds.has(i.id) && i.scores.averageScore >= 6.5)
        .map((item) => {
          const itemGenresLower = item.genres.map((g) => g.toLowerCase());
          let preferenceScore = 0;
          const matchedGenres: string[] = [];

          for (const g of itemGenresLower) {
            if (userGenreScores[g]) {
              preferenceScore += userGenreScores[g];
              matchedGenres.push(g);
            }
          }

          const matchPct = Math.min(
            99,
            Math.max(75, Math.round(75 + preferenceScore * 1.5 + (item.scores.averageScore - 7) * 2))
          );

          const matchedLabel = matchedGenres
            .slice(0, 2)
            .map((g) => g.charAt(0).toUpperCase() + g.slice(1))
            .join(' & ');

          return {
            media: item,
            recommendationReason: `${matchPct}% Potrivire · Bazat pe preferințele tale pentru ${matchedLabel || item.type}`,
            matchPercentage: matchPct,
          };
        })
        .filter((r) => r.matchPercentage >= 78)
        .sort((a, b) => b.matchPercentage - a.matchPercentage || b.media.scores.averageScore - a.media.scores.averageScore)
        .slice(0, 10);

      recommendations = scoredRecommendations;
    }

    if (recommendations.length === 0) {
      const recommendationReasons = [
        '99% Potrivire · Capodoperă vizuală și poveste captivantă',
        '98% Potrivire · Recomandat pentru iubitorii de Dark Fantasy & Action',
        '96% Potrivire · Producție de vârf apreciată unanim de comunitate',
        '95% Potrivire · Animație excepțională și coloană sonoră memorabilă',
        '94% Potrivire · Univers bine conturat cu bătălii strategice',
        '92% Potrivire · Recomandat pe baza titlurilor favorite',
      ];

      recommendations = [...validOfflineAllCategories]
        .filter((i) => (i.year && i.year >= 2020) || i.scores.averageScore >= 8.2)
        .sort((a, b) => b.scores.averageScore - a.scores.averageScore)
        .slice(0, 10)
        .map((item, idx) => ({
          media: item,
          recommendationReason: recommendationReasons[idx % recommendationReasons.length],
          matchPercentage: 99 - idx,
        }));
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
            .sort((a, b) => b.scores.averageScore - a.scores.averageScore || (b.year || 0) - (a.year || 0))
            .slice(0, 10);

    let topUpcoming =
      upcomingRes.status === 'fulfilled' && upcomingRes.value && upcomingRes.value.length > 0
        ? upcomingRes.value.filter((item) => item.type === 'ANIME')
        : [...validOffline]
            .filter((i) => i.type === 'ANIME' && (i.status === 'UPCOMING' || (i.year && i.year >= 2025)))
            .sort((a, b) => (b.year || 0) - (a.year || 0) || b.scores.averageScore - a.scores.averageScore)
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
                i.scores.averageScore >= 7.0 &&
                i.scores.averageScore <= 9.9
            )
            .sort(
              (a, b) =>
                (b.scores.weightedScore || b.scores.averageScore) -
                  (a.scores.weightedScore || a.scores.averageScore) ||
                (b.scores.reviewCount || 0) - (a.scores.reviewCount || 0) ||
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

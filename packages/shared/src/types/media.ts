export type MediaType = 'ANIME' | 'DONGHUA' | 'AENI' | 'MANGA' | 'MANHWA' | 'MANHUA' | 'WEBTOON';

export type MediaFormat = 'TV' | 'TV_SHORT' | 'MOVIE' | 'OVA' | 'ONA' | 'SPECIAL' | 'MANGA' | 'NOVEL';

export type ReleaseStatus = 'RELEASING' | 'FINISHED' | 'UPCOMING' | 'CANCELLED' | 'HIATUS';

export type Demographic = 'Shounen' | 'Seinen' | 'Shoujo' | 'Josei' | 'Kids';

export type MediaSeason = 'WINTER' | 'SPRING' | 'SUMMER' | 'FALL';

export type SortOption = 'RELEVANCE' | 'SCORE_DESC' | 'POPULARITY_DESC' | 'YEAR_DESC' | 'YEAR_ASC' | 'TITLE_ASC';

export type WatchOrderMode = 'RECOMMENDED' | 'CHRONOLOGICAL' | 'RELEASE';

export type WatchlistStatus = 'WATCHING' | 'COMPLETED' | 'PLAN_TO_WATCH' | 'ON_HOLD' | 'DROPPED';

export type DataSource = 'LOCAL_JSON' | 'LOCAL_OFFLINE_DB' | 'ANILIST';

export interface ScoreMetrics {
  averageScore: number; // 0-100 or 0-10 zecimal
  reviewCount: number;
  weightedScore: number; // Anti-review bombing weighted metric
  distribution?: {
    [score: string]: number;
  };
}

export interface MediaTitle {
  romaji?: string;
  english?: string;
  native?: string;
  userPreferred: string;
}

export interface CoverImage {
  extraLarge?: string;
  large: string;
  medium?: string;
  color?: string;
}

export interface WatchOrderNode {
  id: string;
  mediaId: string;
  title: string;
  type: string; // 'TV', 'MOVIE', 'OVA', 'SPECIAL'
  episodesInfo?: string; // e.g. "Episoadele 1-24" or "Film (120 min)"
  releaseYear?: number;
  coverImage?: string;
  orderIndex: number;
  note?: string; // e.g. "Contribuie la misterul din Heaven's Feel"
  isCanon: boolean;
}

export type WatchOrderPresetStatus = 'draft' | 'pending_review' | 'community_verified' | 'rejected' | 'flagged';

export interface WatchOrderPresetItem {
  id?: string;
  presetId?: string;
  mediaId: string;
  position: number;
  isCanon?: boolean;
  note?: string;
  mediaItem?: Partial<MediaItem>;
}

export interface WatchOrderPreset {
  id: string;
  franchiseRoot: string;
  title: string;
  description?: string;
  submittedBy?: string | null;
  submitterUsername?: string;
  submitterAvatarUrl?: string;
  status: WatchOrderPresetStatus;
  upvotes: number;
  downvotes: number;
  reportCount?: number;
  isSelectiveCurated?: boolean;
  isPossiblyOutdated?: boolean;
  missingItemsCount?: number;
  missingTitles?: string[];
  userVote?: number | null; // 1, -1 sau null
  items: WatchOrderPresetItem[];
  createdAt: string;
  updatedAt: string;
}

export interface WatchOrderVoteResult {
  success: boolean;
  upvotes: number;
  downvotes: number;
  status: WatchOrderPresetStatus;
  ratio: number;
  userVote: number;
}

export interface WatchOrderGuide {
  franchiseId: string;
  franchiseName: string;
  description?: string;
  communityTip?: string; // Ghid explicativ de sfaturi pentru începători
  authority?: 'editorial' | 'community_verified' | 'algorithmic';
  paths: {
    RECOMMENDED: WatchOrderNode[];
    CHRONOLOGICAL: WatchOrderNode[];
    RELEASE: WatchOrderNode[];
  };
  spinOffs?: WatchOrderNode[];
  communityPresets?: WatchOrderPreset[];
}

export interface CharacterVoiceActor {
  id: number;
  name: string;
  image?: string;
  language?: string;
}

export interface MediaCharacter {
  id: number;
  name: string;
  image?: string;
  role: 'MAIN' | 'SUPPORTING' | string;
  voiceActor?: CharacterVoiceActor;
}

export interface MediaStaff {
  id: number;
  name: string;
  image?: string;
  role: string;
}

export interface MediaThemeSong {
  type: 'OP' | 'ED';
  title: string;
  artists: string[];
  episodes?: string;
}

export interface CommunityRanking {
  rank: number;
  type: 'RATED' | 'POPULAR' | string;
  allTime: boolean;
  context: string;
}

export interface ScoreDistributionItem {
  score: number;
  amount: number;
}

export interface StatusDistributionItem {
  status: 'CURRENT' | 'PLANNING' | 'COMPLETED' | 'DROPPED' | 'PAUSED' | string;
  amount: number;
}

export interface CommunityMetrics {
  rankings: CommunityRanking[];
  scoreDistribution: ScoreDistributionItem[];
  statusDistribution: StatusDistributionItem[];
}

export interface FuzzyDate {
  year?: number | null;
  month?: number | null;
  day?: number | null;
}

export type MediaRelationType =
  | 'PREQUEL'
  | 'SEQUEL'
  | 'PARENT'
  | 'SIDE_STORY'
  | 'SPIN_OFF'
  | 'ALTERNATIVE'
  | 'SUMMARY'
  | 'OTHER'
  | 'ADAPTATION'
  | 'CHARACTER';

export interface MediaRelation {
  id: string;
  anilistId: number;
  relationType: MediaRelationType;
  title: string;
  format?: string;
  type?: string;
  status?: string;
  episodes?: number;
  releaseYear?: number;
  coverImage?: string;
}

export interface MediaItem {
  id: string;
  anilistId?: number;
  title: MediaTitle;
  type: MediaType;
  format?: MediaFormat;
  status?: ReleaseStatus | string;
  demographic?: Demographic | string;
  microTags?: string[];
  episodes?: number | null;
  chapters?: number | null;
  volumes?: number | null;
  genres: string[];
  description?: string;
  coverImage: CoverImage;
  bannerImage?: string;
  year?: number;
  season?: MediaSeason | string;
  studios?: string[];
  producers?: string[];
  trailerUrl?: string;
  franchiseId?: string;
  scores: ScoreMetrics;
  source: DataSource;
  watchOrderTree?: WatchOrderNode[];
  characters?: MediaCharacter[];
  staff?: MediaStaff[];
  themes?: MediaThemeSong[];
  communityMetrics?: CommunityMetrics;
  startDate?: FuzzyDate;
  endDate?: FuzzyDate;
  adaptationSource?: string;
  relations?: MediaRelation[];
}

export interface CategoryShelf {
  id: string;
  title: string;
  description: string;
  icon?: string;
  items: MediaItem[];
}

export interface SimilarMediaResponse {
  targetId: string;
  targetItem?: MediaItem;
  similarItems: {
    item: MediaItem;
    similarityScore: number;
    commonGenres: string[];
  }[];
}

export interface SearchQueryOptions {
  query: string;
  type?: MediaType | 'ALL';
  format?: MediaFormat | 'ALL';
  status?: ReleaseStatus | 'ALL';
  demographic?: Demographic | 'ALL';
  genre?: string;
  genres?: string[];
  microTag?: string;
  microTags?: string[];
  year?: number | string | 'ALL';
  season?: MediaSeason | 'ALL';
  sortBy?: SortOption;
  minScore?: number;
  source?: 'all' | 'local' | 'anilist';
  limit?: number;
  page?: number;
}

export interface SearchResponse {
  results: MediaItem[];
  total: number;
  sourcesUsed: DataSource[];
  query: string;
  page?: number;
  totalPages?: number;
  hasMore?: boolean;
  executionTimeMs?: number;
  isCached?: boolean;
}

export interface UserProfile {
  id?: string;
  username: string;
  email: string;
  avatarUrl?: string;
  bio?: string;
  pronouns?: string;
  bannerUrl?: string;
  favoriteGenres?: string[];
  createdAt?: string;
  usernameLastChangedAt?: string;
}

export interface WatchlistItemRecord {
  id: string;
  userId: string;
  mediaId: string;
  status: WatchlistStatus;
  score?: number;
  progressEpisodes: number;
  notes?: string;
  startedAt?: string;
  completedAt?: string;
  mediaItem?: MediaItem;
  createdAt: string;
  updatedAt: string;
}

export interface NewsArticle {
  id: string;
  title: string;
  category: 'ANIME' | 'MANGA' | 'STUDIO' | 'MOVIE' | 'GAME';
  tagBadge: string;
  summary: string;
  content?: string;
  imageUrl: string;
  date: string;
  readTime: string;
  source: string;
  url?: string;
  isBeta?: boolean;
}

export interface RecentlyAiredEpisode {
  media: MediaItem;
  episodeNumber: number;
  episodeTitle?: string;
  airDateRelative: string;
  airDateExact: string;
  thumbnailUrl?: string;
}

export interface RecommendedMediaItem {
  media: MediaItem;
  recommendationReason: string;
  matchPercentage?: number;
  isPersonalized?: boolean;
  badgeLabel?: string;
}

export interface HomepageData {
  featuredSeason: MediaItem[];
  recentlyAired: RecentlyAiredEpisode[];
  newsBeta: NewsArticle[];
  recommendations: RecommendedMediaItem[];
  topAiring: MediaItem[];
  topUpcoming: MediaItem[];
  top100: MediaItem[];
}


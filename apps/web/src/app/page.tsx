'use client';

import React, { useState, useEffect, useTransition, useRef, useCallback } from 'react';
import Link from 'next/link';
import {
  Search,
  X,
  Star,
  Sparkles,
  Flame,
  Award,
  Film,
  Zap,
  Tag,
  SlidersHorizontal,
  ChevronDown,
  ChevronUp,
  Calendar,
  Sun,
  Snowflake,
  Flower2,
  Leaf,
  ArrowDownAZ,
  TrendingUp,
  Clock,
  Check,
  Play,
  Plus,
  ChevronLeft,
  ChevronRight,
  Newspaper,
  Eye,
  ExternalLink,
  BookOpen,
  Info,
  Tv,
  Layers,
  Heart,
  CheckCircle2,
} from 'lucide-react';
import {
  MediaItem,
  MediaType,
  MediaFormat,
  Demographic,
  ReleaseStatus,
  MediaSeason,
  SortOption,
  HomepageData,
  NewsArticle,
  RecentlyAiredEpisode,
  RecommendedMediaItem,
} from '@kurogane/shared';

const MAJOR_GENRES = [
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Fantasy',
  'Sci-Fi',
  'Mystery',
  'Horror',
  'Romance',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
  'Mecha',
  'Psychological',
];

const MICRO_TAGS = [
  { tag: 'Overpowered MC', label: '⚡ Overpowered MC' },
  { tag: 'Isekai', label: '🌀 Isekai' },
  { tag: 'Anti-Hero', label: '🗡️ Anti-hero' },
  { tag: 'Xianxia', label: '🥋 Xianxia / Cultivare' },
  { tag: 'Cyberpunk', label: '🌃 Cyberpunk' },
  { tag: 'Post-Apocalyptic', label: '☣️ Post-Apocaliptic' },
  { tag: 'High Fantasy', label: '🏰 High Fantasy' },
  { tag: 'Time Travel', label: '⏳ Time travel' },
  { tag: 'Revenge', label: '🔥 Revenge' },
  { tag: 'Female Protagonist', label: '👑 Protagonistă feminină' },
  { tag: 'School Life', label: '🎓 Viață școlară' },
  { tag: 'Virtual Reality', label: '🥽 Realitate virtuală' },
];

const getDynamicSeasonLabel = (item?: MediaItem): string => {
  if (item?.season) {
    const map: Record<string, string> = {
      WINTER: 'Winter',
      SPRING: 'Spring',
      SUMMER: 'Summer',
      FALL: 'Autumn',
      AUTUMN: 'Autumn',
    };
    const s = map[item.season.toUpperCase()] || item.season;
    return item.year ? `${s} ${item.year}` : s;
  }
  const now = new Date();
  const m = now.getMonth();
  const year = now.getFullYear();
  let s = 'Winter';
  if (m >= 2 && m <= 4) s = 'Spring';
  else if (m >= 5 && m <= 7) s = 'Summer';
  else if (m >= 8 && m <= 10) s = 'Autumn';
  return `${s} ${year}`;
};

const getCurrentSeasonInfo = (item?: MediaItem) => {
  const label = getDynamicSeasonLabel(item);
  const upper = label.toUpperCase();
  const yearMatch = label.match(/\d{4}/);
  const year = yearMatch ? yearMatch[0] : new Date().getFullYear().toString();

  if (upper.includes('SUMMER') || upper.includes('VARĂ')) {
    return {
      title: `Anime • Sezonul de Vară ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de vară ${year}`,
      Icon: Sun,
      iconColor: 'text-amber-400',
      iconBox: 'bg-amber-500/10 border-amber-500/20 text-amber-400',
    };
  }
  if (upper.includes('WINTER') || upper.includes('IARNĂ')) {
    return {
      title: `Anime • Sezonul de Iarnă ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de iarnă ${year}`,
      Icon: Snowflake,
      iconColor: 'text-sky-400',
      iconBox: 'bg-sky-500/10 border-sky-500/20 text-sky-400',
    };
  }
  if (upper.includes('SPRING') || upper.includes('PRIMĂVARĂ')) {
    return {
      title: `Anime • Sezonul de Primăvară ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de primăvară ${year}`,
      Icon: Flower2,
      iconColor: 'text-emerald-400',
      iconBox: 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400',
    };
  }
  return {
    title: `Anime • Sezonul de Toamnă ${year}`,
    subtitle: `Cele mai populare titluri lansate în sezonul de toamnă ${year}`,
    Icon: Leaf,
    iconColor: 'text-orange-400',
    iconBox: 'bg-orange-500/10 border-orange-500/20 text-orange-400',
  };
};

const getMediaAccentColor = (item?: MediaItem): string => {
  if (item?.coverImage?.color && item.coverImage.color.startsWith('#')) {
    return item.coverImage.color;
  }
  const g = (item?.genres?.[0] || '').toLowerCase();
  if (g.includes('action') || g.includes('adventure')) return '#f43f5e'; // rose red
  if (g.includes('fantasy') || g.includes('supernatural') || g.includes('magic')) return '#a855f7'; // purple
  if (g.includes('comedy') || g.includes('slice of life')) return '#f59e0b'; // amber
  if (g.includes('romance') || g.includes('drama')) return '#ec4899'; // pink
  if (g.includes('sci-fi') || g.includes('mecha') || g.includes('cyberpunk')) return '#06b6d4'; // cyan
  return '#3b82f6'; // blue
};

const getDisplayTitle = (title?: { english?: string; romaji?: string; native?: string; userPreferred?: string }): string => {
  if (!title) return '';
  return title.english?.trim() || title.userPreferred?.trim() || title.romaji?.trim() || '';
};

export default function Homepage() {
  // Homepage Sections State
  const [homepageData, setHomepageData] = useState<HomepageData | null>(null);
  const [loadingHomepage, setLoadingHomepage] = useState<boolean>(true);

  // Hero Slider Active Index
  const [activeHeroIndex, setActiveHeroIndex] = useState<number>(0);

  // Seasonal Carousel Scroll Ref
  const seasonCarouselRef = useRef<HTMLDivElement>(null);

  // Active Tab for Top Airing vs Top Upcoming
  const [activeTopTab, setActiveTopTab] = useState<'AIRING' | 'UPCOMING'>('AIRING');

  // Top 100 Filter & View State
  const [top100Search, setTop100Search] = useState<string>('');
  const [top100Format, setTop100Format] = useState<string>('ALL');
  const [top100Limit, setTop100Limit] = useState<number>(20);

  // Selected News Article for Modal
  const [selectedNews, setSelectedNews] = useState<NewsArticle | null>(null);

  // Global Watchlist State (mocked local set for instant UI feedback)
  const [savedWatchlistIds, setSavedWatchlistIds] = useState<Set<string>>(new Set());

  // Search & Filter Drawer State
  const [query, setQuery] = useState<string>('');
  const [selectedType, setSelectedType] = useState<MediaType | 'ALL'>('ALL');
  const [selectedFormat, setSelectedFormat] = useState<MediaFormat | 'ALL'>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<ReleaseStatus | 'ALL'>('ALL');
  const [selectedDemographic, setSelectedDemographic] = useState<Demographic | 'ALL'>('ALL');
  const [selectedSeason, setSelectedSeason] = useState<MediaSeason | 'ALL'>('ALL');
  const [selectedYear, setSelectedYear] = useState<string>('ALL');
  const [selectedSort, setSelectedSort] = useState<SortOption>('RELEVANCE');
  const [selectedGenres, setSelectedGenres] = useState<string[]>([]);
  const [selectedMicroTags, setSelectedMicroTags] = useState<string[]>([]);

  const [searchResults, setSearchResults] = useState<MediaItem[]>([]);
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState<boolean>(false);

  const abortControllerRef = useRef<AbortController | null>(null);

  // Fetch Homepage Data
  useEffect(() => {
    let isMounted = true;
    fetch('http://localhost:4000/api/homepage')
      .then((res) => (res.ok ? res.json() : null))
      .then((data: HomepageData | null) => {
        if (isMounted && data) {
          setHomepageData(data);
        }
      })
      .catch((err) => console.error('Error fetching homepage data:', err))
      .finally(() => {
        if (isMounted) setLoadingHomepage(false);
      });

    return () => {
      isMounted = false;
    };
  }, []);

  // Automatic hero slider cycle (6 seconds) with reset on manual selection
  useEffect(() => {
    if (!homepageData?.featuredSeason || homepageData.featuredSeason.length <= 1) return;
    const timer = setInterval(() => {
      setActiveHeroIndex((prev) => (prev + 1) % homepageData.featuredSeason.length);
    }, 6000);
    return () => clearInterval(timer);
  }, [homepageData?.featuredSeason, activeHeroIndex]);

  // Handle Search Query
  const performSearch = useCallback(async (searchQuery: string) => {
    if (!searchQuery.trim()) {
      setSearchResults([]);
      setIsSearching(false);
      return;
    }

    if (abortControllerRef.current) abortControllerRef.current.abort();
    const controller = new AbortController();
    abortControllerRef.current = controller;

    setIsSearching(true);
    try {
      const params = new URLSearchParams({
        q: searchQuery,
        type: selectedType,
        format: selectedFormat,
        status: selectedStatus,
        demographic: selectedDemographic,
        season: selectedSeason,
        year: selectedYear,
        sortBy: selectedSort,
        genres: selectedGenres.join(','),
        microTags: selectedMicroTags.join(','),
        limit: '24',
      });
      const res = await fetch(`http://localhost:4000/api/search?${params.toString()}`, {
        signal: controller.signal,
      });
      if (res.ok && !controller.signal.aborted) {
        const data = await res.json();
        setSearchResults(data.results || []);
      }
    } catch (err: any) {
      if (err?.name !== 'AbortError') console.error('Search error:', err);
    } finally {
      if (!controller.signal.aborted) {
        setIsSearching(false);
      }
    }
  }, [selectedType, selectedFormat, selectedStatus, selectedDemographic, selectedSeason, selectedYear, selectedSort, selectedGenres, selectedMicroTags]);

  useEffect(() => {
    if (query.trim().length > 0) {
      const timer = setTimeout(() => performSearch(query), 250);
      return () => clearTimeout(timer);
    } else {
      setSearchResults([]);
    }
  }, [query, performSearch]);

  const toggleWatchlist = (id: string) => {
    setSavedWatchlistIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const currentFeatured = homepageData?.featuredSeason?.[activeHeroIndex];

  // Filtered Top 100 list
  const filteredTop100 = (homepageData?.top100 || []).filter((item) => {
    const matchesQuery = top100Search.trim() === '' || 
      item.title.userPreferred.toLowerCase().includes(top100Search.toLowerCase()) ||
      (item.title.english && item.title.english.toLowerCase().includes(top100Search.toLowerCase()));
    
    const matchesFormat = top100Format === 'ALL' || item.format === top100Format;
    return matchesQuery && matchesFormat;
  });

  return (
    <div className="max-w-[1920px] mx-auto px-4 md:px-12 pt-10 sm:pt-12 md:pt-14 space-y-16 lg:space-y-20 pb-20">
      {/* SECTION 1: TRENDING ANIME (CURRENT SEASON POPULAR HERO CAROUSEL) */}
      {(() => {
        const heroArtColor = getMediaAccentColor(currentFeatured);

        return (
          <section
            className="relative rounded-3xl overflow-hidden bg-bgSurface border border-borderSubtle transition-all duration-1000 shadow-2xl h-[560px] sm:h-[620px] lg:h-[660px] xl:h-[680px]"
            style={{
              boxShadow: currentFeatured
                ? `0 20px 50px -10px rgba(0, 0, 0, 0.4), 0 0 40px -15px ${heroArtColor}25`
                : undefined,
            }}
          >
            {loadingHomepage ? (
              <div className="h-full flex items-center justify-center text-textSecondary">
                <div className="w-8 h-8 border-2 border-accentPrimary border-t-transparent rounded-full animate-spin mr-3" />
                <span>Se încarcă secțiunea Trending Anime...</span>
              </div>
            ) : currentFeatured ? (
              <div className="relative h-full flex flex-col justify-end p-6 sm:p-10 lg:p-14 pb-16 sm:pb-20 lg:pb-24 xl:pb-26">
                {/* Dynamic Ambient Artwork Color Glow for Hero Slide */}
                <div
                  className="absolute -right-24 -bottom-24 w-[500px] sm:w-[650px] h-[500px] sm:h-[650px] rounded-full blur-[140px] opacity-10 dark:opacity-25 transition-all duration-1000 pointer-events-none z-10"
                  style={{ backgroundColor: heroArtColor }}
                />
                <div
                  className="absolute -left-20 -top-20 w-[350px] sm:w-[450px] h-[350px] sm:h-[450px] rounded-full blur-[120px] opacity-5 dark:opacity-15 transition-all duration-1000 pointer-events-none z-10"
                  style={{ backgroundColor: heroArtColor }}
                />

                {/* Background Image Slides Stack (Right-aligned artwork with seamless blending) */}
                <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
                  {/* Right Side Image Container (Expanded width with CSS mask so left edge completely vanishes to transparent) */}
                  <div className="hero-art-mask absolute inset-y-0 right-0 w-full md:w-[70%] lg:w-[60%] xl:w-[54%] h-full">
                    {(homepageData?.featuredSeason || []).map((item, idx) => {
                      const isCurrent = idx === activeHeroIndex;
                      return (
                        <div
                          key={item.id}
                          className={`absolute inset-0 transition-opacity duration-[1200ms] ease-in-out ${
                            isCurrent ? 'opacity-100 z-10' : 'opacity-0 z-0 pointer-events-none'
                          }`}
                        >
                          <img
                            src={item.coverImage.extraLarge || item.coverImage.large}
                            alt={item.title.userPreferred}
                            className="w-full h-full object-cover object-center md:object-[70%_center] filter brightness-[0.7] md:brightness-[0.9] contrast-105"
                            loading={idx === 0 ? 'eager' : 'lazy'}
                          />
                        </div>
                      );
                    })}

                    {/* Subtle color highlight over hero image in dark mode */}
                    <div
                      className="absolute inset-0 hidden dark:block opacity-15 transition-all duration-1000 pointer-events-none z-10"
                      style={{
                        background: `linear-gradient(to right, transparent 15%, ${heroArtColor} 100%)`,
                        mixBlendMode: 'screen',
                      }}
                    />
                  </div>

                  {/* Seamless Blending Gradients Overlay */}
                  {/* 1. Left-to-Right Solid Gradient covering the entire text area */}
                  <div className="absolute inset-0 bg-gradient-to-r from-bgSurface via-bgSurface/95 via-30% md:via-40% to-transparent z-20" />
                  {/* 2. Bottom-to-Top Gradient */}
                  <div className="absolute inset-0 bg-gradient-to-t from-bgSurface via-bgSurface/50 via-15% to-transparent z-20" />
                  {/* 3. Top-to-Bottom Subtle Edge Gradient */}
                  <div className="absolute inset-0 bg-gradient-to-b from-bgSurface/40 via-transparent to-transparent z-20" />
                </div>

            {/* Top-Left Badges (Stationary) */}
            <div className="absolute top-6 left-6 lg:top-8 lg:left-10 z-30 flex items-center gap-2.5">
              <span className="px-3.5 py-1.5 rounded-full bg-accentPrimary text-white text-xs font-semibold uppercase tracking-normal shadow-lg flex items-center gap-1.5">
                <Flame className="w-3.5 h-3.5 text-scoreGold" />
                Trending • {getDynamicSeasonLabel(currentFeatured)}
              </span>
              {currentFeatured.status === 'RELEASING' && (
                <span className="text-signalLive text-xs font-semibold flex items-center gap-1.5 ml-1 drop-shadow-sm">
                  <span className="w-2 h-2 rounded-full bg-signalLive animate-pulse" />
                  Sezon Nou
                </span>
              )}
            </div>

            {/* Content Banner (Stationary container with animated info + stationary action buttons) */}
            <div className="relative z-10 max-w-3xl lg:max-w-4xl space-y-3 sm:space-y-4">
              {/* Dynamic Information Block (Title, Synopsis, Genre Chips with blur/fade animation) */}
              <div key={currentFeatured.id} className="space-y-2.5 sm:space-y-3.5 animate-hero-fade">
                {/* Title (Truncated/Clamped to max 2 lines to keep layout solid and predictable) */}
                <h1
                  className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-textPrimary leading-tight font-heading drop-shadow-md line-clamp-2 min-h-[2.5rem] sm:min-h-[3.25rem] lg:min-h-[3.75rem]"
                  title={getDisplayTitle(currentFeatured.title)}
                >
                  {getDisplayTitle(currentFeatured.title)}
                </h1>

                {/* Synopsis / Description with Smart Fallback handling */}
                {(() => {
                  const rawDesc = (currentFeatured.description || '').replace(/<[^>]*>/g, '').trim();
                  const hasValidDesc = rawDesc.length >= 25;

                  if (hasValidDesc) {
                    return (
                      <p className="text-textSecondary text-xs sm:text-sm line-clamp-4 leading-relaxed max-w-2xl min-h-[4.25rem] sm:min-h-[5rem]">
                        {rawDesc}
                      </p>
                    );
                  }

                  return (
                    <div className="flex flex-col justify-center space-y-1 max-w-2xl min-h-[4.25rem] sm:min-h-[5rem]">
                      <p className="text-textSecondary/75 text-xs sm:text-sm italic">
                        Sinopsis indisponibil momentan.
                      </p>
                      <p className="text-textSecondary text-[11px] sm:text-xs">
                        Producție {currentFeatured.format || currentFeatured.type || 'Anime'} {currentFeatured.genres?.length ? `• ${currentFeatured.genres.slice(0, 3).join(' • ')}` : ''} • Sezonul {getDynamicSeasonLabel(currentFeatured)}
                      </p>
                    </div>
                  );
                })()}

                {/* Genres Chips (Fully rounded pills) */}
                <div className="flex flex-wrap gap-1.5 pt-0.5 min-h-[28px]">
                  {currentFeatured.genres.slice(0, 4).map((genre) => (
                    <span
                      key={genre}
                      className="px-3.5 py-1 rounded-full bg-bgSurface border border-borderSubtle text-textSecondary text-[11px] font-medium"
                    >
                      {genre}
                    </span>
                  ))}
                </div>
              </div>

              {/* Action Buttons (Completely stationary, anchored) */}
              <div className="flex flex-wrap items-center gap-3 pt-2">
                <Link
                  href={`/media/${currentFeatured.id}`}
                  className="px-6 py-3 rounded-full bg-accentPrimary hover:opacity-90 text-white font-semibold text-xs sm:text-sm flex items-center gap-2 shadow-lg transition-all active:scale-95"
                >
                  <Play className="w-4 h-4 fill-white" /> Vezi Detalii & Episoade
                </Link>

                <button
                  onClick={() => toggleWatchlist(currentFeatured.id)}
                  className={`px-5 py-3 rounded-full text-xs sm:text-sm font-semibold flex items-center gap-2 border transition-all active:scale-95 ${
                    savedWatchlistIds.has(currentFeatured.id)
                      ? 'bg-signalLive text-slate-950 border-signalLive shadow-md'
                      : 'bg-bgSurface hover:bg-bgSurfaceHover text-textPrimary border-borderSubtle'
                  }`}
                >
                  {savedWatchlistIds.has(currentFeatured.id) ? (
                    <>
                      <CheckCircle2 className="w-4 h-4 text-slate-950" /> Adăugat în Listă
                    </>
                  ) : (
                    <>
                      <Plus className="w-4 h-4" /> Adaugă în Watchlist
                    </>
                  )}
                </button>
              </div>
            </div>

            {/* Carousel Navigation Controls (Sleek Dots & Active Filling Progress Pill with Cubic Bezier) */}
            <div className="absolute bottom-6 right-6 lg:bottom-10 lg:right-10 z-20 flex items-center gap-2 bg-bgSurface px-3 py-2 rounded-full border border-borderSubtle shadow-xl">
              {homepageData?.featuredSeason.map((_, idx) => {
                const isActive = idx === activeHeroIndex;
                return (
                  <button
                    key={idx}
                    onClick={() => setActiveHeroIndex(idx)}
                    className={`relative h-2 rounded-full overflow-hidden transition-[width,background-color,border-color] duration-700 [transition-timing-function:cubic-bezier(0.25,1,0.5,1)] ${
                      isActive
                        ? 'w-10 sm:w-12 bg-bgSurfaceHover border border-borderSubtle'
                        : 'w-2 bg-borderSubtle hover:bg-textSecondary'
                    }`}
                    aria-label={`Slide ${idx + 1}`}
                  >
                    {isActive && (
                      <div
                        key={activeHeroIndex}
                        className="h-full bg-accentPrimary rounded-full animate-timer-fill"
                      />
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        ) : null}
      </section>
    );
  })()}

          {/* SECTION 2: ANIME DIN SEZONUL CURENT (DYNAMIC SEASONAL LANDSCAPE CAROUSEL) */}
          {(() => {
            const seasonMeta = getCurrentSeasonInfo(homepageData?.featuredSeason?.[0] || homepageData?.topAiring?.[0]);
            const seasonalItems = (
              homepageData?.featuredSeason && homepageData.featuredSeason.length > 0
                ? homepageData.featuredSeason
                : homepageData?.topAiring || []
            ).slice(0, 6);

            return (
              <section className="space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
                    {seasonMeta.title}
                  </h2>

                  <div className="flex items-center gap-3">
                    {/* Carousel Navigation Buttons */}
                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => {
                          if (seasonCarouselRef.current) {
                            const w = seasonCarouselRef.current.clientWidth;
                            seasonCarouselRef.current.scrollBy({ left: -(w + 32), behavior: 'smooth' });
                          }
                        }}
                        className="p-2 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle text-textSecondary hover:text-textPrimary transition-all shadow-sm active:scale-95"
                        aria-label="Scroll la stânga în sezonul curent"
                      >
                        <ChevronLeft className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => {
                          if (seasonCarouselRef.current) {
                            const w = seasonCarouselRef.current.clientWidth;
                            seasonCarouselRef.current.scrollBy({ left: w + 32, behavior: 'smooth' });
                          }
                        }}
                        className="p-2 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle text-textSecondary hover:text-textPrimary transition-all shadow-sm active:scale-95"
                        aria-label="Scroll la dreapta în sezonul curent"
                      >
                        <ChevronRight className="w-4 h-4" />
                      </button>
                    </div>

                    <Link
                      href="/media?status=RELEASING&type=ANIME"
                      className="hidden sm:flex text-xs font-semibold text-accentPrimary hover:opacity-80 items-center gap-1 transition-opacity ml-2"
                    >
                      Vezi tot sezonul <ChevronRight className="w-3.5 h-3.5" />
                    </Link>
                  </div>
                </div>

                {/* Seasonal Horizontal Carousel (Aligned 100% to 12-column grid, 3 cards on desktop, 2 on tablet, 1 on mobile) */}
                <div
                  ref={seasonCarouselRef}
                  className="flex gap-5 md:gap-6 lg:gap-8 overflow-x-auto scrollbar-none no-scrollbar scroll-smooth snap-x snap-mandatory pb-3 pt-1"
                >
                  {seasonalItems.map((item) => {
                    const artColor = getMediaAccentColor(item);

                    return (
                      <Link
                        key={item.id}
                        href={`/media/${item.id}`}
                        className="snap-start group relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle transition-all duration-300 flex flex-row shrink-0 w-full md:w-[calc((100%-24px)/2)] lg:w-[calc((100%-64px)/3)] h-[250px] sm:h-[270px] md:h-[285px] lg:h-[295px] shadow-md hover:shadow-2xl cursor-pointer block text-left"
                      >
                        {/* Dynamic Ambient Artwork Glow (Tailored for both Dark and Light mode) */}
                        <div
                          className="absolute -right-10 -bottom-10 w-64 h-64 rounded-full blur-3xl opacity-5 dark:opacity-20 group-hover:opacity-15 dark:group-hover:opacity-35 transition-opacity duration-700 pointer-events-none"
                          style={{ backgroundColor: artColor }}
                        />
                        <div
                          className="absolute -left-10 -top-10 w-48 h-48 rounded-full blur-3xl opacity-0 dark:opacity-10 group-hover:opacity-10 dark:group-hover:opacity-20 transition-opacity duration-700 pointer-events-none"
                          style={{ backgroundColor: artColor }}
                        />

                        {/* Dynamic Hover Border Overlay tinted with the artwork color */}
                        <div
                          className="absolute inset-0 rounded-3xl border border-transparent group-hover:border-[var(--hover-border)] transition-colors duration-300 pointer-events-none z-30"
                          style={{ ['--hover-border' as any]: `${artColor}70` }}
                        />

                        {/* Left Side: Information & Title (No rating) */}
                        <div className="flex-1 p-5 sm:p-6 flex flex-col justify-between min-w-0 z-10 space-y-2">
                          {/* Top Meta: Format & Airing Status (High contrast in light & dark mode) */}
                          <div className="flex items-center gap-2">
                            <span
                              className="px-3 py-1 rounded-full text-[10px] sm:text-xs font-semibold uppercase bg-bgPrimary text-textPrimary border transition-colors"
                              style={{
                                borderColor: `${artColor}50`,
                              }}
                            >
                              {item.format || item.type}
                            </span>
                            {item.status === 'RELEASING' && (
                              <span className="text-[10px] sm:text-xs font-medium text-signalLive flex items-center gap-1.5">
                                <span className="w-2 h-2 rounded-full bg-signalLive animate-pulse" />
                                Sezon Nou
                              </span>
                            )}
                          </div>

                          {/* Title & Synopsis (Clamped, High Contrast, Brand Accent on Hover) */}
                          <div className="space-y-2 my-auto">
                            <h3
                              className="text-base sm:text-lg md:text-xl font-bold text-textPrimary group-hover:text-accentPrimary transition-colors line-clamp-2 font-heading leading-snug"
                              title={getDisplayTitle(item.title)}
                            >
                              {getDisplayTitle(item.title)}
                            </h3>
                            <p className="text-xs sm:text-[13px] text-textSecondary line-clamp-2 leading-relaxed">
                              {item.description || (item.genres && item.genres.length > 0 ? item.genres.slice(0, 4).join(' • ') : 'Sezon nou în difuzare.')}
                            </p>
                          </div>

                          {/* Bottom Row: Genre Pills (Full width without squeezing) */}
                          <div className="flex items-center gap-1.5 overflow-hidden pt-1">
                            {item.genres?.slice(0, 4).map((g) => (
                              <span
                                key={g}
                                className="px-2.5 py-1 rounded-full bg-bgSurfaceHover text-textSecondary text-[10px] sm:text-xs font-medium truncate shrink-0"
                              >
                                {g}
                              </span>
                            ))}
                          </div>
                        </div>

                        {/* Right Side: Landscape Artwork Cover with Seamless Alpha Mask & Dynamic Color Feathering */}
                        <div className="landscape-art-mask w-[160px] sm:w-[200px] md:w-[230px] lg:w-[260px] h-full relative shrink-0 overflow-hidden bg-transparent">
                          <img
                            src={item.coverImage.extraLarge || item.coverImage.large}
                            alt={getDisplayTitle(item.title)}
                            className="w-full h-full object-cover object-center group-hover:scale-105 transition-transform duration-500"
                          />

                          {/* Dynamic subtle color highlight over image in dark mode */}
                          <div
                            className="absolute inset-0 hidden dark:block opacity-20 group-hover:opacity-35 transition-opacity duration-500 pointer-events-none"
                            style={{
                              background: `linear-gradient(to right, transparent 10%, ${artColor} 100%)`,
                              mixBlendMode: 'screen',
                            }}
                          />

                          {/* Watchlist Toggle Button (Top Right of image) */}
                          <button
                            onClick={(e) => {
                              e.preventDefault();
                              e.stopPropagation();
                              toggleWatchlist(item.id);
                            }}
                            className={`absolute top-3 right-3 p-2 rounded-full backdrop-blur-md transition-all shadow-md active:scale-90 z-20 ${
                              savedWatchlistIds.has(item.id)
                                ? 'bg-signalLive text-slate-950 opacity-100'
                                : 'bg-bgSurface/90 hover:bg-bgSurface text-textPrimary opacity-0 group-hover:opacity-100 border border-borderSubtle'
                            }`}
                            aria-label={savedWatchlistIds.has(item.id) ? 'Elimină din Watchlist' : 'Adaugă în Watchlist'}
                          >
                            {savedWatchlistIds.has(item.id) ? (
                              <CheckCircle2 className="w-4 h-4 text-slate-950" />
                            ) : (
                              <Plus className="w-4 h-4" />
                            )}
                          </button>
                        </div>
                      </Link>
                    );
                  })}
                </div>
              </section>
            );
          })()}

          {/* SECTION 3: ULTIMELE EPISOADE IEȘITE (RECENTLY AIRED EPISODES) */}
          <section className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
                  <Tv className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-xl font-bold font-heading text-textPrimary tracking-normal flex items-center gap-2">
                    Ultimele Episoade Ieșite
                  </h2>
                  <p className="text-xs text-textSecondary">Cele mai proaspete episoade difuzate recent în Japonia & China</p>
                </div>
              </div>
              
              <Link
                href="/media?status=RELEASING"
                className="text-xs font-semibold text-blue-400 hover:text-blue-300 flex items-center gap-1"
              >
                Vezi toate difuzările <ChevronRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            {/* Recently Aired Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-5 md:gap-6 lg:gap-8">
              {(homepageData?.recentlyAired || []).slice(0, 12).map((item) => (
                <div
                  key={`${item.media.id}-${item.episodeNumber}`}
                  className="group relative bg-bgSurface rounded-2xl overflow-hidden border border-borderSubtle hover:border-signalLive/50 transition-all duration-300 flex flex-col shadow-md"
                >
                  <div className="relative aspect-[3/4] bg-bgSurfaceHover overflow-hidden">
                    <img
                      src={item.media.coverImage.large}
                      alt={getDisplayTitle(item.media.title)}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />

                    {/* Gradient Overlay */}
                    <div className="absolute inset-0 bg-gradient-to-t from-bgPrimary via-bgPrimary/20 to-transparent" />

                    {/* Episode Badge */}
                    <div className="absolute top-2 left-2 px-2 py-0.5 rounded-lg bg-signalLive text-slate-950 text-[11px] font-medium shadow-md flex items-center gap-1">
                      <Play className="w-2.5 h-2.5 fill-slate-950" />
                      EP {item.episodeNumber}
                    </div>

                    {/* Time Badge */}
                    <div className="absolute bottom-2 left-2 right-2 flex items-center justify-between text-[10px] font-medium text-textSecondary bg-bgPrimary/85 backdrop-blur-md px-2 py-1 rounded-md border border-borderSubtle">
                      <span className="flex items-center gap-1 text-signalLive font-medium">
                        <Clock className="w-3 h-3 text-signalLive" />
                        {item.airDateRelative}
                      </span>
                      <span className="text-textSecondary uppercase font-medium text-[9px]">{item.media.type}</span>
                    </div>
                  </div>

                  {/* Info */}
                  <div className="p-3 flex flex-col justify-between flex-1">
                    <h3 className="text-xs font-semibold text-textPrimary line-clamp-2 group-hover:text-signalLive transition-colors leading-snug">
                      {getDisplayTitle(item.media.title)}
                    </h3>

                    <Link
                      href={`/media/${item.media.id}`}
                      className="mt-3 w-full py-1.5 rounded-xl bg-bgSurfaceHover hover:bg-signalLive text-textSecondary hover:text-slate-950 text-[11px] font-semibold text-center transition-colors flex items-center justify-center gap-1"
                    >
                      <Eye className="w-3.5 h-3.5" /> Vezi Episodul
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* SECTION 3: ANIME & MANGA NEWS (BETA) */}
          <section className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 bg-bgSurface p-4 rounded-2xl border border-borderSubtle shadow-sm">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-accentPrimary/10 border border-accentPrimary/20 text-accentPrimary">
                  <Newspaper className="w-5 h-5" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-xl font-bold font-heading text-textPrimary tracking-normal">
                      Noutăți Anime & Manga
                    </h2>
                    {/* BETA STATUS BADGE */}
                    <span className="px-2 py-0.5 rounded-full bg-scoreGold/20 border border-scoreGold/40 text-scoreGold text-[10px] font-semibold tracking-normal uppercase shadow-sm animate-pulse">
                      BETA
                    </span>
                  </div>
                  <p className="text-xs text-textSecondary">Ultimele știri, anunțuri de sezoane noi și trailer-e din industrie</p>
                </div>
              </div>

              <div className="text-[11px] text-textSecondary flex items-center gap-1.5 bg-bgSurfaceHover px-3 py-1.5 rounded-xl border border-borderSubtle">
                <Info className="w-3.5 h-3.5 text-scoreGold" /> Modul Beta — În curând agregare automată de știri
              </div>
            </div>

            {/* News Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {(homepageData?.newsBeta || []).map((news) => (
                <div
                  key={news.id}
                  onClick={() => setSelectedNews(news)}
                  className="group cursor-pointer bg-bgSurface rounded-2xl overflow-hidden border border-borderSubtle hover:border-accentPrimary/50 transition-all duration-300 flex flex-col justify-between p-4 space-y-3 shadow-sm"
                >
                  <div className="space-y-3">
                    {/* Category Badge & Date */}
                    <div className="flex items-center justify-between">
                      <span className="px-2.5 py-0.5 rounded-md bg-accentPrimary/10 border border-accentPrimary/30 text-accentPrimary text-[10px] font-medium uppercase tracking-normal">
                        {news.tagBadge}
                      </span>
                      <span className="text-[10px] text-textSecondary font-medium flex items-center gap-1">
                        <Calendar className="w-3 h-3" /> {news.date}
                      </span>
                    </div>

                    {/* Image Preview if available */}
                    {news.imageUrl && (
                      <div className="aspect-[16/9] rounded-xl overflow-hidden bg-bgSurfaceHover relative">
                        <img
                          src={news.imageUrl}
                          alt={news.title}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      </div>
                    )}

                    {/* Title */}
                    <h3 className="text-sm font-semibold text-textPrimary group-hover:text-accentPrimary transition-colors leading-snug line-clamp-2">
                      {news.title}
                    </h3>

                    {/* Summary */}
                    <p className="text-xs text-textSecondary line-clamp-3 leading-relaxed">
                      {news.summary}
                    </p>
                  </div>

                  {/* Card Footer */}
                  <div className="pt-2 border-t border-borderSubtle flex items-center justify-between text-[11px] text-textSecondary font-medium">
                    <span className="text-textSecondary">{news.source}</span>
                    <span className="text-accentPrimary font-semibold group-hover:underline flex items-center gap-1">
                      Citește știrea <ChevronRight className="w-3 h-3" />
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* NEWS MODAL (BETA) */}
          {selectedNews && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200">
              <div className="bg-bgSurface border border-borderSubtle rounded-3xl w-full max-w-2xl p-6 sm:p-8 shadow-2xl relative max-h-[90vh] overflow-y-auto space-y-6 text-textPrimary">
                <button
                  onClick={() => setSelectedNews(null)}
                  className="absolute top-5 right-5 p-2 rounded-xl bg-bgSurfaceHover text-textSecondary hover:text-textPrimary transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>

                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="px-2.5 py-0.5 rounded-md bg-accentPrimary/10 border border-accentPrimary/30 text-accentPrimary text-[10px] font-medium uppercase tracking-normal">
                      {selectedNews.tagBadge}
                    </span>
                    <span className="px-2 py-0.5 rounded-full bg-scoreGold/20 text-scoreGold text-[10px] font-medium uppercase">
                      BETA ARTICLE
                    </span>
                  </div>
                  <h2 className="text-xl sm:text-2xl font-semibold text-textPrimary leading-tight font-heading">
                    {selectedNews.title}
                  </h2>
                  <div className="flex items-center gap-4 text-xs text-textSecondary font-medium pt-1">
                    <span>Sursă: <strong className="text-textPrimary">{selectedNews.source}</strong></span>
                    <span>•</span>
                    <span>Publicat: {selectedNews.date}</span>
                    <span>•</span>
                    <span>{selectedNews.readTime}</span>
                  </div>
                </div>

                {selectedNews.imageUrl && (
                  <div className="aspect-[16/9] rounded-2xl overflow-hidden bg-bgSurfaceHover">
                    <img src={selectedNews.imageUrl} alt={selectedNews.title} className="w-full h-full object-cover" />
                  </div>
                )}

                <div className="space-y-4 text-textSecondary text-xs sm:text-sm leading-relaxed border-t border-borderSubtle pt-4">
                  <p className="font-semibold text-textPrimary">{selectedNews.summary}</p>
                  <p>{selectedNews.content}</p>
                </div>

                <div className="p-4 rounded-xl bg-bgPrimary border border-borderSubtle text-xs text-textSecondary flex items-center justify-between">
                  <span>Sistem Beta de Știri Kurogane v0.1.0</span>
                  <button
                    onClick={() => setSelectedNews(null)}
                    className="px-4 py-2 rounded-lg bg-accentPrimary text-white font-semibold text-xs hover:opacity-90 transition-opacity"
                  >
                    Închide
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* SECTION 4: RECOMANDĂRI (RECOMMENDED FOR YOU) */}
          <section className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
                  <Sparkles className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-xl font-bold font-heading text-textPrimary tracking-normal">
                    Recomandări pentru Tine
                  </h2>
                  <p className="text-xs text-textSecondary">Selecții algoritmice bazate pe scorul de calitate și preferințele comunității</p>
                </div>
              </div>
            </div>

            {/* Recommendations Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-5 md:gap-6 lg:gap-8">
              {(homepageData?.recommendations || []).slice(0, 12).map((item) => (
                <div
                  key={item.media.id}
                  className="group bg-bgSurface rounded-2xl overflow-hidden border border-borderSubtle hover:border-badgeViolet/50 transition-all duration-300 flex flex-col justify-between shadow-sm"
                >
                  <div className="relative aspect-[3/4] bg-bgSurfaceHover overflow-hidden">
                    <img
                      src={item.media.coverImage.large}
                      alt={getDisplayTitle(item.media.title)}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />

                    {/* Match Score Badge */}
                    <div className="absolute top-2 left-2 px-2 py-0.5 rounded-lg bg-badgeViolet text-slate-950 text-[10px] font-medium shadow-md flex items-center gap-1">
                      <Sparkles className="w-3 h-3 text-scoreGold" />
                      {item.matchPercentage}% Potrivire
                    </div>

                    {/* Rating Badge */}
                    <div className="absolute top-2 right-2 bg-bgPrimary/85 backdrop-blur-md px-2 py-0.5 rounded-md text-[11px] font-medium text-scoreGold border border-borderSubtle flex items-center gap-1">
                      <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                      {item.media.scores.averageScore}
                    </div>
                  </div>

                  <div className="p-3 flex flex-col justify-between flex-1 space-y-2">
                    <div>
                      <span className="text-[9px] font-medium text-badgeViolet uppercase tracking-normal block mb-1">
                        {item.recommendationReason.split('·')[1] || item.recommendationReason}
                      </span>
                      <h3 className="text-xs font-semibold text-textPrimary line-clamp-2 group-hover:text-badgeViolet transition-colors">
                        {getDisplayTitle(item.media.title)}
                      </h3>
                    </div>

                    <Link
                      href={`/media/${item.media.id}`}
                      className="w-full py-1.5 rounded-xl bg-bgSurfaceHover hover:bg-badgeViolet text-textSecondary hover:text-slate-950 text-[11px] font-semibold text-center transition-colors block"
                    >
                      Vezi Titlul
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* SECTION 5: TOP AIRING ANIME + TOP UPCOMING ANIME */}
          <section className="space-y-4">
            {/* Header Tabs */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-borderSubtle pb-3">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-scoreGold/10 border border-scoreGold/20 text-scoreGold">
                  <Flame className="w-5 h-5" />
                </div>
                <h2 className="text-xl font-bold font-heading text-textPrimary tracking-normal">
                  Top Airing & În Curând
                </h2>
              </div>

              {/* Toggle Switch */}
              <div className="flex items-center p-1 rounded-xl bg-bgSurface border border-borderSubtle">
                <button
                  onClick={() => setActiveTopTab('AIRING')}
                  className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all flex items-center gap-1.5 ${
                    activeTopTab === 'AIRING'
                      ? 'bg-accentPrimary text-white shadow-md'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                >
                  <span className="w-2 h-2 rounded-full bg-signalLive animate-pulse" />
                  Top În Difuzare (Airing)
                </button>
                <button
                  onClick={() => setActiveTopTab('UPCOMING')}
                  className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all flex items-center gap-1.5 ${
                    activeTopTab === 'UPCOMING'
                      ? 'bg-accentPrimary text-white shadow-md'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                >
                  <Clock className="w-3.5 h-3.5 text-badgeViolet" />
                  Top Sezon Viitor (Upcoming)
                </button>
              </div>
            </div>

            {/* List Content */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5 md:gap-6 lg:gap-8">
              {(activeTopTab === 'AIRING' ? homepageData?.topAiring : homepageData?.topUpcoming)?.map(
                (item, index) => (
                  <div
                    key={item.id}
                    className="group bg-bgSurface rounded-2xl p-3 border border-borderSubtle hover:border-accentPrimary/50 transition-all duration-300 flex items-center gap-4 shadow-sm"
                  >
                    {/* Rank Badge */}
                    <div className="w-9 h-9 rounded-xl bg-bgSurfaceHover text-textSecondary font-semibold text-sm flex items-center justify-center border border-borderSubtle shrink-0 group-hover:bg-accentPrimary group-hover:text-white transition-colors">
                      #{index + 1}
                    </div>

                    {/* Thumbnail */}
                    <div className="w-14 h-20 rounded-xl overflow-hidden bg-bgSurfaceHover shrink-0 relative">
                      <img
                        src={item.coverImage.large}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                      />
                    </div>

                    {/* Details */}
                    <div className="flex-1 min-w-0 space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-medium text-accentPrimary uppercase tracking-normal">
                          {item.type} • {item.format}
                        </span>
                        {item.scores.averageScore > 0 && (
                          <span className="text-[10px] font-medium text-scoreGold flex items-center gap-0.5">
                            <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                            {item.scores.averageScore}
                          </span>
                        )}
                      </div>
                      
                      <h3 className="text-xs sm:text-sm font-semibold text-textPrimary truncate group-hover:text-accentPrimary transition-colors">
                        {getDisplayTitle(item.title)}
                      </h3>

                      <div className="flex items-center gap-2 text-[11px] text-textSecondary">
                        <span>{item.year || '2026'}</span>
                        {item.season && <span>• {item.season}</span>}
                        {item.episodes && <span>• {item.episodes} Episoade</span>}
                      </div>
                    </div>

                    {/* View Button */}
                    <Link
                      href={`/media/${item.id}`}
                      className="p-2.5 rounded-xl bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white transition-colors shrink-0"
                    >
                      <ChevronRight className="w-4 h-4" />
                    </Link>
                  </div>
                )
              )}
            </div>
          </section>

          {/* SECTION 6: TOP 100 ANIME (LEADERBOARD) */}
          <section className="space-y-6 pt-4 border-t border-borderSubtle">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-scoreGold/10 border border-scoreGold/20 text-scoreGold">
                  <Award className="w-6 h-6" />
                </div>
                <div>
                  <h2 className="text-2xl font-bold font-heading text-textPrimary tracking-normal flex items-center gap-2">
                    Top 100 Anime All-Time
                  </h2>
                  <p className="text-xs text-textSecondary">Clasamentul oficial al celor mai apreciate 100 de serii din toate timpurile</p>
                </div>
              </div>

              {/* Filter controls inside Top 100 */}
              <div className="flex flex-wrap items-center gap-2">
                <input
                  type="text"
                  value={top100Search}
                  onChange={(e) => setTop100Search(e.target.value)}
                  placeholder="Caută în Top 100..."
                  className="px-3 py-1.5 bg-bgSurface text-textPrimary border border-borderSubtle rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-scoreGold"
                />

                <select
                  value={top100Format}
                  onChange={(e) => setTop100Format(e.target.value)}
                  className="px-3 py-1.5 bg-bgSurface text-textPrimary border border-borderSubtle rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-scoreGold"
                >
                  <option value="ALL">Toate Formatele</option>
                  <option value="TV">TV Series</option>
                  <option value="MOVIE">Filme Cinema</option>
                  <option value="OVA">OVA / ONA</option>
                </select>
              </div>
            </div>

            {/* Leaderboard Table / Grid */}
            <div className="space-y-2">
              {filteredTop100.slice(0, top100Limit).map((item, index) => {
                const rank = index + 1;
                const isTop1 = rank === 1;
                const isTop2 = rank === 2;
                const isTop3 = rank === 3;

                return (
                  <div
                    key={item.id}
                    className={`group rounded-2xl p-3 sm:p-4 border transition-all duration-300 flex items-center justify-between gap-4 bg-bgSurface border-borderSubtle hover:border-accentPrimary/50 shadow-sm`}
                  >
                    <div className="flex items-center gap-3 sm:gap-4 min-w-0">
                      {/* Rank Number Badge */}
                      <div
                        className={`w-10 h-10 rounded-xl font-semibold text-sm sm:text-base flex items-center justify-center shrink-0 ${
                          isTop1
                            ? 'bg-gradient-to-tr from-amber-500 to-yellow-300 text-slate-950 shadow-md'
                            : isTop2
                            ? 'bg-gradient-to-tr from-slate-300 to-slate-100 text-slate-950'
                            : isTop3
                            ? 'bg-gradient-to-tr from-amber-700 to-orange-400 text-white'
                            : 'bg-bgSurfaceHover text-textSecondary border border-borderSubtle'
                        }`}
                      >
                        #{rank}
                      </div>

                      {/* Poster */}
                      <div className="w-12 h-16 sm:w-14 sm:h-20 rounded-xl overflow-hidden bg-bgSurfaceHover shrink-0">
                        <img
                          src={item.coverImage.large}
                          alt={getDisplayTitle(item.title)}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                        />
                      </div>

                      {/* Main Title & Tags */}
                      <div className="min-w-0 space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] font-medium text-accentPrimary uppercase tracking-normal">
                            {item.type} {item.format ? `• ${item.format}` : ''}
                          </span>
                          {item.year && <span className="text-[10px] text-textSecondary">• {item.year}</span>}
                        </div>

                        <h3 className="text-sm sm:text-base font-semibold text-textPrimary truncate group-hover:text-accentPrimary transition-colors">
                          {getDisplayTitle(item.title)}
                        </h3>

                        <div className="flex flex-wrap gap-1">
                          {item.genres.slice(0, 3).map((g) => (
                            <span key={g} className="px-2 py-0.5 rounded-md bg-bgSurfaceHover text-[10px] text-textSecondary">
                              {g}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>

                    {/* Score Metrics & Action */}
                    <div className="flex items-center gap-4 shrink-0">
                      <div className="text-right hidden sm:block">
                        <div className="text-sm font-semibold text-scoreGold flex items-center justify-end gap-1">
                          <Star className="w-4 h-4 fill-scoreGold text-scoreGold" />
                          {item.scores.averageScore}
                        </div>
                        <span className="text-[10px] text-textSecondary block">
                          Scor Comunitate
                        </span>
                      </div>

                      <Link
                        href={`/media/${item.id}`}
                        className="px-4 py-2 rounded-xl bg-bgSurfaceHover hover:bg-scoreGold hover:text-slate-950 font-semibold text-xs transition-all flex items-center gap-1 text-textPrimary"
                      >
                        Detalii <ChevronRight className="w-3.5 h-3.5" />
                      </Link>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Load More Top 100 Button */}
            {top100Limit < filteredTop100.length && (
              <div className="text-center pt-4">
                <button
                  onClick={() => setTop100Limit((prev) => prev + 20)}
                  className="px-6 py-3 rounded-2xl bg-bgSurface border border-borderSubtle hover:border-scoreGold/50 text-textSecondary hover:text-textPrimary font-semibold text-xs transition-all"
                >
                  Afișează Următoarele 20 de Titluri din Top 100
                </button>
              </div>
            )}
          </section>
    </div>
  );
}

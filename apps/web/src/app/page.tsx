"use client";

import React, {
  useState,
  useEffect,
  useTransition,
  useRef,
  useCallback,
} from "react";
import Link from "next/link";
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
  Bookmark,
  BookmarkCheck,
  Save,
  Radio,
} from "lucide-react";
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
} from "@kurogane/shared";

const MAJOR_GENRES = [
  "Action",
  "Adventure",
  "Comedy",
  "Drama",
  "Fantasy",
  "Sci-Fi",
  "Mystery",
  "Horror",
  "Romance",
  "Slice of Life",
  "Sports",
  "Supernatural",
  "Thriller",
  "Mecha",
  "Psychological",
];

const MICRO_TAGS = [
  { tag: "Overpowered MC", label: "⚡ Overpowered MC" },
  { tag: "Isekai", label: "🌀 Isekai" },
  { tag: "Anti-Hero", label: "🗡️ Anti-hero" },
  { tag: "Xianxia", label: "🥋 Xianxia / Cultivare" },
  { tag: "Cyberpunk", label: "🌃 Cyberpunk" },
  { tag: "Post-Apocalyptic", label: "☣️ Post-Apocaliptic" },
  { tag: "High Fantasy", label: "🏰 High Fantasy" },
  { tag: "Time Travel", label: "⏳ Time travel" },
  { tag: "Revenge", label: "🔥 Revenge" },
  { tag: "Female Protagonist", label: "👑 Protagonistă feminină" },
  { tag: "School Life", label: "🎓 Viață școlară" },
  { tag: "Virtual Reality", label: "🥽 Realitate virtuală" },
];

const getDynamicSeasonLabel = (item?: MediaItem): string => {
  if (item?.season) {
    const map: Record<string, string> = {
      WINTER: "Winter",
      SPRING: "Spring",
      SUMMER: "Summer",
      FALL: "Autumn",
      AUTUMN: "Autumn",
    };
    const s = map[item.season.toUpperCase()] || item.season;
    return item.year ? `${s} ${item.year}` : s;
  }
  const now = new Date();
  const m = now.getMonth();
  const year = now.getFullYear();
  let s = "Winter";
  if (m >= 2 && m <= 4) s = "Spring";
  else if (m >= 5 && m <= 7) s = "Summer";
  else if (m >= 8 && m <= 10) s = "Autumn";
  return `${s} ${year}`;
};

const getCurrentSeasonInfo = (item?: MediaItem) => {
  const label = getDynamicSeasonLabel(item);
  const upper = label.toUpperCase();
  const yearMatch = label.match(/\d{4}/);
  const year = yearMatch ? yearMatch[0] : new Date().getFullYear().toString();

  if (upper.includes("SUMMER") || upper.includes("VARĂ")) {
    return {
      title: `Anime • Sezonul de Vară ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de vară ${year}`,
      Icon: Sun,
      iconColor: "text-amber-400",
      iconBox: "bg-amber-500/10 border-amber-500/20 text-amber-400",
    };
  }
  if (upper.includes("WINTER") || upper.includes("IARNĂ")) {
    return {
      title: `Anime • Sezonul de Iarnă ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de iarnă ${year}`,
      Icon: Snowflake,
      iconColor: "text-sky-400",
      iconBox: "bg-sky-500/10 border-sky-500/20 text-sky-400",
    };
  }
  if (upper.includes("SPRING") || upper.includes("PRIMĂVARĂ")) {
    return {
      title: `Anime • Sezonul de Primăvară ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de primăvară ${year}`,
      Icon: Flower2,
      iconColor: "text-emerald-400",
      iconBox: "bg-emerald-500/10 border-emerald-500/20 text-emerald-400",
    };
  }
  return {
    title: `Anime • Sezonul de Toamnă ${year}`,
    subtitle: `Cele mai populare titluri lansate în sezonul de toamnă ${year}`,
    Icon: Leaf,
    iconColor: "text-orange-400",
    iconBox: "bg-orange-500/10 border-orange-500/20 text-orange-400",
  };
};

const getMediaAccentColor = (item?: MediaItem): string => {
  if (item?.coverImage?.color && item.coverImage.color.startsWith("#")) {
    return item.coverImage.color;
  }
  const g = (item?.genres?.[0] || "").toLowerCase();
  if (g.includes("action") || g.includes("adventure")) return "#f43f5e"; // rose red
  if (
    g.includes("fantasy") ||
    g.includes("supernatural") ||
    g.includes("magic")
  )
    return "#a855f7"; // purple
  if (g.includes("comedy") || g.includes("slice of life")) return "#f59e0b"; // amber
  if (g.includes("romance") || g.includes("drama")) return "#ec4899"; // pink
  if (g.includes("sci-fi") || g.includes("mecha") || g.includes("cyberpunk"))
    return "#06b6d4"; // cyan
  return "#3b82f6"; // blue
};

const getDisplayTitle = (title?: {
  english?: string;
  romaji?: string;
  native?: string;
  userPreferred?: string;
}): string => {
  if (!title) return "";
  return (
    title.english?.trim() ||
    title.userPreferred?.trim() ||
    title.romaji?.trim() ||
    ""
  );
};

const getDisplayCardTitle = (title?: {
  english?: string;
  romaji?: string;
  native?: string;
  userPreferred?: string;
}): string => {
  const raw = getDisplayTitle(title);
  if (!raw) return "";
  return raw
    .replace(/\s*:\s*/g, ": ")
    .replace(/\s*-\s*/g, " - ")
    .replace(/\s*—\s*/g, " — ");
};

const formatMediaFormat = (format?: string, type?: string): string => {
  if (!format && !type) return "Anime";
  const val = (format || type || "").toUpperCase();
  const formatMap: Record<string, string> = {
    TV_SHORT: "TV Short",
    TV: "TV",
    MOVIE: "Movie",
    OVA: "OVA",
    ONA: "ONA",
    SPECIAL: "Special",
    MUSIC: "Music",
    MANGA: "Manga",
    NOVEL: "Novel",
    ONE_SHOT: "One Shot",
    DONGHUA: "Donghua",
    AENI: "Aeni",
    MANHWA: "Manhwa",
    MANHUA: "Manhua",
    WEBTOON: "Webtoon",
  };
  return formatMap[val] || val.replace(/_/g, " ");
};

const isFreshEpisode = (
  airDateExact?: string,
  airDateRelative?: string,
): boolean => {
  if (airDateExact) {
    const timestamp = new Date(airDateExact).getTime();
    if (!isNaN(timestamp)) {
      const diffHours = (Date.now() - timestamp) / (1000 * 60 * 60);
      if (diffHours >= 0 && diffHours < 24) return true;
      if (diffHours >= 24) return false;
    }
  }
  if (airDateRelative) {
    const isHoursOrMinutes = /oră|ore|minut|secund/i.test(airDateRelative);
    const isDaysOrWeeks = /zi|zile|săpt|luni|ani/i.test(airDateRelative);
    if (isHoursOrMinutes && !isDaysOrWeeks) return true;
  }
  return false;
};

const getNewsBadgeConfig = (tagBadge?: string, category?: string) => {
  const tag = (tagBadge || category || "").toUpperCase();
  if (
    tag.includes("SEZON") ||
    tag.includes("ANIME") ||
    tag.includes("SERIE") ||
    tag.includes("TV")
  ) {
    return {
      label: tagBadge || "SEZON NOU",
      className: "bg-accentPrimary text-white shadow-sm",
      icon: Tv,
    };
  }
  if (
    tag.includes("CAPITOL") ||
    tag.includes("MANGA") ||
    tag.includes("MANHWA") ||
    tag.includes("MANHUA") ||
    tag.includes("NOVEL")
  ) {
    return {
      label: tagBadge || "CAPITOL NOU",
      className: "bg-badgeViolet text-slate-950 font-bold shadow-sm",
      icon: BookOpen,
    };
  }
  if (tag.includes("FILM") || tag.includes("MOVIE") || tag.includes("CINEMA")) {
    return {
      label: tagBadge || "FILM CINEMA",
      className: "bg-amber-500 text-slate-950 font-bold shadow-sm",
      icon: Film,
    };
  }
  // Official announcements / Studio / Industry (Electric Cyan with equal visual weight)
  return {
    label: tagBadge || "ANUNȚ OFICIAL",
    className: "bg-cyan-500 text-slate-950 font-bold shadow-sm",
    icon: Newspaper,
  };
};

function HeroSkeleton() {
  return (
    <div className="relative h-full flex flex-col justify-end p-6 sm:p-10 lg:p-14 pb-16 sm:pb-20 lg:pb-24 xl:pb-26 animate-skeleton-blur">
      {/* Top-Left Badges Skeleton */}
      <div className="absolute top-6 left-6 lg:top-8 lg:left-10 z-30 flex items-center gap-2.5">
        <div className="h-7 w-44 rounded-full bg-bgSurfaceHover animate-skeleton-shimmer" />
        <div className="h-4 w-20 rounded-full bg-bgSurfaceHover/60 hidden sm:block" />
      </div>

      {/* Right-Side Silhouette placeholder */}
      <div className="hero-art-mask absolute inset-y-0 right-0 w-full md:w-[70%] lg:w-[60%] xl:w-[54%] h-full pointer-events-none overflow-hidden">
        <div className="w-full h-full bg-gradient-to-l from-bgSurfaceHover/50 via-bgSurfaceHover/20 to-transparent animate-skeleton-shimmer" />
      </div>

      {/* Blending Gradients Overlay (same as real hero) */}
      <div className="absolute inset-0 bg-gradient-to-r from-bgSurface via-bgSurface/90 via-25% md:via-35% to-transparent z-20 pointer-events-none" />

      {/* Content Banner Skeleton */}
      <div className="relative z-20 max-w-3xl lg:max-w-4xl space-y-4">
        {/* Title skeleton */}
        <div className="space-y-2.5">
          <div className="h-9 sm:h-11 md:h-12 w-[80%] sm:w-[65%] rounded-2xl bg-bgSurfaceHover animate-skeleton-shimmer" />
          <div className="h-9 sm:h-11 md:h-12 w-[55%] sm:w-[40%] rounded-2xl bg-bgSurfaceHover/80 animate-skeleton-shimmer" />
        </div>

        {/* Synopsis skeleton */}
        <div className="space-y-2 max-w-2xl pt-1">
          <div className="h-3.5 sm:h-4 w-full rounded-full bg-bgSurfaceHover/70" />
          <div className="h-3.5 sm:h-4 w-[92%] rounded-full bg-bgSurfaceHover/70" />
          <div className="h-3.5 sm:h-4 w-[65%] rounded-full bg-bgSurfaceHover/70" />
        </div>

        {/* Genre Chips skeleton */}
        <div className="flex flex-wrap gap-2 pt-1">
          <div className="h-7 w-20 rounded-full bg-bgSurfaceHover/80" />
          <div className="h-7 w-24 rounded-full bg-bgSurfaceHover/80" />
          <div className="h-7 w-16 rounded-full bg-bgSurfaceHover/80" />
          <div className="h-7 w-28 rounded-full bg-bgSurfaceHover/80" />
        </div>

        {/* Action Buttons skeleton */}
        <div className="flex items-center gap-3 pt-2">
          <div className="h-11 sm:h-12 w-48 rounded-full bg-accentPrimary/50 animate-skeleton-shimmer" />
          <div className="h-11 sm:h-12 w-44 rounded-full bg-bgSurfaceHover/80" />
        </div>
      </div>

      {/* Dots skeleton at bottom-right */}
      <div className="absolute bottom-6 right-6 lg:bottom-10 lg:right-10 z-30 flex items-center gap-2 bg-bgSurface px-3 py-2 rounded-full border border-borderSubtle">
        <div className="w-10 sm:w-12 h-2 rounded-full bg-accentPrimary/40" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
      </div>
    </div>
  );
}

function SeasonalCardsSkeleton() {
  return (
    <div className="flex gap-5 md:gap-6 lg:gap-8 overflow-hidden pb-3 pt-1">
      {[1, 2, 3].map((n) => (
        <div
          key={n}
          className="relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle flex flex-row shrink-0 w-full md:w-[calc((100%-24px)/2)] lg:w-[calc((100%-64px)/3)] h-[250px] sm:h-[270px] md:h-[285px] lg:h-[295px] shadow-md animate-skeleton-blur"
        >
          <div className="flex-1 p-5 sm:p-6 flex flex-col justify-between min-w-0 z-10 space-y-2">
            <div className="flex items-center gap-2">
              <div className="h-5 w-16 rounded-full bg-bgSurfaceHover" />
              <div className="h-4 w-20 rounded-full bg-bgSurfaceHover/60" />
            </div>

            <div className="space-y-2 my-auto">
              <div className="h-6 w-[85%] rounded-xl bg-bgSurfaceHover animate-skeleton-shimmer" />
              <div className="h-6 w-[55%] rounded-xl bg-bgSurfaceHover/80 animate-skeleton-shimmer" />
              <div className="h-3.5 w-full rounded-full bg-bgSurfaceHover/50 mt-2" />
              <div className="h-3.5 w-[75%] rounded-full bg-bgSurfaceHover/50" />
            </div>

            <div className="flex items-center gap-1.5 pt-1">
              <div className="h-6 w-16 rounded-full bg-bgSurfaceHover/80" />
              <div className="h-6 w-14 rounded-full bg-bgSurfaceHover/80" />
              <div className="h-6 w-20 rounded-full bg-bgSurfaceHover/80" />
            </div>
          </div>

          <div className="landscape-art-mask w-[160px] sm:w-[200px] md:w-[230px] lg:w-[260px] h-full relative shrink-0 overflow-hidden bg-bgSurfaceHover/40 animate-skeleton-shimmer" />
        </div>
      ))}
    </div>
  );
}

function RecentlyAiredSkeleton() {
  return (
    <div className="flex gap-4 sm:gap-5 md:gap-6 overflow-hidden pb-4 pt-1">
      {[1, 2, 3, 4, 5, 6].map((n) => (
        <div
          key={n}
          className="relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle flex flex-col shrink-0 w-[170px] sm:w-[195px] md:w-[215px] lg:w-[225px] shadow-md animate-skeleton-blur"
        >
          <div className="relative aspect-[3/4] overflow-hidden rounded-t-3xl bg-bgSurfaceHover/50 animate-skeleton-shimmer">
            <div className="absolute top-3 left-3 h-6 w-16 rounded-full bg-bgSurface/80" />
            <div className="absolute top-3 right-3 h-6 w-10 rounded-full bg-bgSurface/80" />
          </div>

          <div className="p-4 sm:p-5 flex flex-col justify-between flex-1 space-y-3">
            <div className="space-y-1.5">
              <div className="h-4 w-[90%] rounded-lg bg-bgSurfaceHover" />
              <div className="h-4 w-[60%] rounded-lg bg-bgSurfaceHover/80" />
            </div>
            <div className="h-3 w-20 rounded-full bg-bgSurfaceHover/60" />
          </div>
        </div>
      ))}
    </div>
  );
}

export default function Homepage() {
  // Homepage Sections State
  const [homepageData, setHomepageData] = useState<HomepageData | null>(null);
  const [loadingHomepage, setLoadingHomepage] = useState<boolean>(true);

  // Hero Slider Active Index
  const [activeHeroIndex, setActiveHeroIndex] = useState<number>(0);

  // Seasonal Carousel Scroll Ref
  const seasonCarouselRef = useRef<HTMLDivElement>(null);

  // Recently Aired Carousel Scroll Ref
  const airedCarouselRef = useRef<HTMLDivElement>(null);

  // Active Tab for Top Airing vs Top Upcoming
  const [activeTopTab, setActiveTopTab] = useState<"AIRING" | "UPCOMING">(
    "AIRING",
  );

  // Top 100 Filter & View State
  const [top100Search, setTop100Search] = useState<string>("");
  const [top100Format, setTop100Format] = useState<string>("ALL");
  const [top100Limit, setTop100Limit] = useState<number>(20);

  // Global Watchlist State (mocked local set for instant UI feedback)
  const [savedWatchlistIds, setSavedWatchlistIds] = useState<Set<string>>(
    new Set(),
  );
  // User watched episodes progress map: mediaId -> progressEpisodes
  const [watchedEpisodes, setWatchedEpisodes] = useState<
    Record<string, number>
  >({});

  // Sync watchlist and episode progress from API/localStorage
  useEffect(() => {
    const token =
      typeof window !== "undefined"
        ? localStorage.getItem("kurogane_token")
        : null;
    if (!token) return;

    fetch("http://localhost:4000/api/watchlist", {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (data?.items) {
          const ids = new Set<string>();
          const epMap: Record<string, number> = {};
          data.items.forEach((item: any) => {
            ids.add(item.mediaId);
            if (item.progressEpisodes !== undefined) {
              epMap[item.mediaId] = item.progressEpisodes;
            }
          });
          setSavedWatchlistIds(ids);
          setWatchedEpisodes(epMap);
        }
      })
      .catch((err) =>
        console.error("Error loading watchlist in homepage:", err),
      );
  }, []);

  // Search & Filter Drawer State
  const [query, setQuery] = useState<string>("");
  const [selectedType, setSelectedType] = useState<MediaType | "ALL">("ALL");
  const [selectedFormat, setSelectedFormat] = useState<MediaFormat | "ALL">(
    "ALL",
  );
  const [selectedStatus, setSelectedStatus] = useState<ReleaseStatus | "ALL">(
    "ALL",
  );
  const [selectedDemographic, setSelectedDemographic] = useState<
    Demographic | "ALL"
  >("ALL");
  const [selectedSeason, setSelectedSeason] = useState<MediaSeason | "ALL">(
    "ALL",
  );
  const [selectedYear, setSelectedYear] = useState<string>("ALL");
  const [selectedSort, setSelectedSort] = useState<SortOption>("RELEVANCE");
  const [selectedGenres, setSelectedGenres] = useState<string[]>([]);
  const [selectedMicroTags, setSelectedMicroTags] = useState<string[]>([]);

  const [searchResults, setSearchResults] = useState<MediaItem[]>([]);
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState<boolean>(false);

  const abortControllerRef = useRef<AbortController | null>(null);

  // Fetch Homepage Data with User Token for Personalized Recommendations
  useEffect(() => {
    let isMounted = true;
    const token =
      typeof window !== "undefined"
        ? localStorage.getItem("kurogane_token")
        : null;

    fetch("http://localhost:4000/api/homepage", {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    })
      .then((res) => (res.ok ? res.json() : null))
      .then((data: HomepageData | null) => {
        if (isMounted && data) {
          setHomepageData(data);
        }
      })
      .catch((err) => console.error("Error fetching homepage data:", err))
      .finally(() => {
        if (isMounted) setLoadingHomepage(false);
      });

    return () => {
      isMounted = false;
    };
  }, []);

  // Automatic hero slider cycle (6 seconds) with reset on manual selection
  useEffect(() => {
    if (
      !homepageData?.featuredSeason ||
      homepageData.featuredSeason.length <= 1
    )
      return;
    const timer = setInterval(() => {
      setActiveHeroIndex(
        (prev) => (prev + 1) % homepageData.featuredSeason.length,
      );
    }, 6000);
    return () => clearInterval(timer);
  }, [homepageData?.featuredSeason, activeHeroIndex]);

  // Handle Search Query
  const performSearch = useCallback(
    async (searchQuery: string) => {
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
          genres: selectedGenres.join(","),
          microTags: selectedMicroTags.join(","),
          limit: "24",
        });
        const res = await fetch(
          `http://localhost:4000/api/search?${params.toString()}`,
          {
            signal: controller.signal,
          },
        );
        if (res.ok && !controller.signal.aborted) {
          const data = await res.json();
          setSearchResults(data.results || []);
        }
      } catch (err: any) {
        if (err?.name !== "AbortError") console.error("Search error:", err);
      } finally {
        if (!controller.signal.aborted) {
          setIsSearching(false);
        }
      }
    },
    [
      selectedType,
      selectedFormat,
      selectedStatus,
      selectedDemographic,
      selectedSeason,
      selectedYear,
      selectedSort,
      selectedGenres,
      selectedMicroTags,
    ],
  );

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

  const handleMarkWatched = async (
    e: React.MouseEvent,
    airedItem: RecentlyAiredEpisode,
  ) => {
    e.preventDefault();
    e.stopPropagation();

    const mediaId = airedItem.media.id;
    const epNum = airedItem.episodeNumber;
    const isCurrentlyWatched = (watchedEpisodes[mediaId] || 0) >= epNum;
    const newProgress = isCurrentlyWatched ? Math.max(0, epNum - 1) : epNum;

    // Optimistic state update
    setWatchedEpisodes((prev) => ({
      ...prev,
      [mediaId]: newProgress,
    }));
    setSavedWatchlistIds((prev) => {
      const next = new Set(prev);
      if (newProgress > 0) next.add(mediaId);
      return next;
    });

    const token =
      typeof window !== "undefined"
        ? localStorage.getItem("kurogane_token")
        : null;
    if (!token) return;

    try {
      const totalEpisodes = airedItem.media.episodes;
      const status =
        totalEpisodes && newProgress >= totalEpisodes
          ? "COMPLETED"
          : "WATCHING";

      await fetch("http://localhost:4000/api/watchlist", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          mediaId,
          status,
          progressEpisodes: newProgress,
        }),
      });
    } catch (err) {
      console.error("Error updating watched progress:", err);
    }
  };

  const currentFeatured = homepageData?.featuredSeason?.[activeHeroIndex];

  // Filtered Top 100 list
  const filteredTop100 = (homepageData?.top100 || []).filter((item) => {
    const matchesQuery =
      top100Search.trim() === "" ||
      item.title.userPreferred
        .toLowerCase()
        .includes(top100Search.toLowerCase()) ||
      (item.title.english &&
        item.title.english.toLowerCase().includes(top100Search.toLowerCase()));

    const matchesFormat =
      top100Format === "ALL" || item.format === top100Format;
    return matchesQuery && matchesFormat;
  });

  return (
    <div className="max-w-[1920px] mx-auto px-4 md:px-12 pt-10 sm:pt-12 md:pt-14 space-y-16 lg:space-y-20 pb-20">
      {/* SECTION 1: TRENDING ANIME (CURRENT SEASON POPULAR HERO CAROUSEL) */}
      {(() => {
        const heroArtColor = getMediaAccentColor(currentFeatured);

        return (
          <div className="relative w-full">
            {/* Ambient Lighting Glow Behind Hero Card for Light & Dark Mode */}
            <div
              className="absolute -inset-4 sm:-inset-6 lg:-inset-8 rounded-[3.5rem] blur-[100px] sm:blur-[130px] opacity-45 dark:opacity-25 transition-all duration-1000 pointer-events-none -z-10"
              style={{ backgroundColor: heroArtColor }}
            />

            <section
              className="relative rounded-3xl overflow-hidden bg-bgSurface border border-borderSubtle transition-all duration-1000 shadow-2xl h-[560px] sm:h-[620px] lg:h-[660px] xl:h-[680px]"
              style={{
                boxShadow: currentFeatured
                  ? `0 20px 50px -10px rgba(0, 0, 0, 0.25), 0 0 50px -10px ${heroArtColor}35`
                  : undefined,
              }}
            >
              {loadingHomepage ? (
                <HeroSkeleton />
              ) : currentFeatured ? (
                <div className="relative h-full flex flex-col justify-end p-6 sm:p-10 lg:p-14 pb-16 sm:pb-20 lg:pb-24 xl:pb-26">
                  {/* Dynamic Ambient Artwork Color Glow for Hero Slide */}
                  <div
                    className="absolute -right-24 -bottom-24 w-[500px] sm:w-[650px] h-[500px] sm:h-[650px] rounded-full blur-[140px] opacity-35 dark:opacity-25 transition-all duration-1000 pointer-events-none z-10"
                    style={{ backgroundColor: heroArtColor }}
                  />
                  <div
                    className="absolute -left-20 -top-20 w-[350px] sm:w-[450px] h-[350px] sm:h-[450px] rounded-full blur-[120px] opacity-25 dark:opacity-15 transition-all duration-1000 pointer-events-none z-10"
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
                              isCurrent
                                ? "opacity-100 z-10"
                                : "opacity-0 z-0 pointer-events-none"
                            }`}
                          >
                            <img
                              src={
                                item.coverImage.extraLarge ||
                                item.coverImage.large
                              }
                              alt={item.title.userPreferred}
                              className="w-full h-full object-cover object-center md:object-[70%_center] filter brightness-[0.8] md:brightness-[0.95] contrast-105"
                              loading={idx === 0 ? "eager" : "lazy"}
                            />
                          </div>
                        );
                      })}

                      {/* Subtle color highlight over hero image */}
                      <div
                        className="absolute inset-0 opacity-20 dark:opacity-15 transition-all duration-1000 pointer-events-none z-10"
                        style={{
                          background: `linear-gradient(to right, transparent 15%, ${heroArtColor} 100%)`,
                          mixBlendMode: "multiply",
                        }}
                      />
                    </div>

                    {/* Seamless Blending Gradients Overlay */}
                    {/* 1. Left-to-Right Solid Gradient covering the entire text area */}
                    <div className="absolute inset-0 bg-gradient-to-r from-bgSurface via-bgSurface/90 via-25% md:via-35% to-transparent z-20" />
                    {/* 2. Bottom-to-Top Gradient */}
                    <div className="absolute inset-0 bg-gradient-to-t from-bgSurface via-bgSurface/40 via-10% to-transparent z-20" />
                    {/* 3. Top-to-Bottom Subtle Edge Gradient */}
                    <div className="absolute inset-0 bg-gradient-to-b from-bgSurface/30 via-transparent to-transparent z-20" />
                  </div>

                  {/* Top-Left Badges (Stationary with Geometric Pill Alignment) */}
                  <div className="absolute top-6 left-6 lg:top-8 lg:left-10 z-30 flex items-center gap-2.5">
                    <span className="h-7 rounded-full bg-accentPrimary text-white text-[11px] sm:text-xs font-semibold uppercase tracking-normal shadow-lg inline-flex items-center overflow-hidden">
                      <span className="w-7 h-7 flex items-center justify-center shrink-0">
                        <Flame className="w-3.5 h-3.5 text-scoreGold" />
                      </span>
                      <span className="pr-3 -ml-1">
                        Trending • {getDynamicSeasonLabel(currentFeatured)}
                      </span>
                    </span>
                    {currentFeatured.status === "RELEASING" && (
                      <span className="text-signalLive text-xs font-semibold flex items-center gap-1.5 ml-1 drop-shadow-sm">
                        <span className="w-2 h-2 rounded-full bg-signalLive animate-pulse" />
                        Sezon Nou
                      </span>
                    )}
                  </div>

                  {/* Content Banner (Stationary container with animated info + stationary action buttons) */}
                  <div className="relative z-10 max-w-3xl lg:max-w-4xl space-y-3 sm:space-y-4">
                    {/* Dynamic Information Block (Title, Synopsis, Genre Chips with blur/fade animation) */}
                    <div
                      key={currentFeatured.id}
                      className="space-y-2.5 sm:space-y-3.5 animate-hero-fade"
                    >
                      {/* Title (Truncated/Clamped to max 2 lines to keep layout solid and predictable) */}
                      <h1
                        className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-textPrimary leading-tight font-heading drop-shadow-md line-clamp-2 min-h-[2.5rem] sm:min-h-[3.25rem] lg:min-h-[3.75rem]"
                        title={getDisplayTitle(currentFeatured.title)}
                      >
                        {getDisplayTitle(currentFeatured.title)}
                      </h1>

                      {/* Synopsis / Description with Smart Fallback handling */}
                      {(() => {
                        const rawDesc = (currentFeatured.description || "")
                          .replace(/<[^>]*>/g, "")
                          .trim();
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
                              Producție{" "}
                              {currentFeatured.format ||
                                currentFeatured.type ||
                                "Anime"}{" "}
                              {currentFeatured.genres?.length
                                ? `• ${currentFeatured.genres.slice(0, 3).join(" • ")}`
                                : ""}{" "}
                              • Sezonul {getDynamicSeasonLabel(currentFeatured)}
                            </p>
                          </div>
                        );
                      })()}

                      {/* Genres Chips (Fully rounded pills) */}
                      <div className="flex flex-wrap gap-1.5 pt-0.5 min-h-[28px]">
                        {currentFeatured.genres.slice(0, 4).map((genre) => (
                          <span
                            key={genre}
                            className="px-3.5 py-1 rounded-full bg-bgSurfaceHover/80 dark:bg-bgSurface border border-borderSubtle text-textSecondary text-[11px] font-medium shadow-sm"
                          >
                            {genre}
                          </span>
                        ))}
                      </div>
                    </div>

                    {/* Action Buttons (Completely stationary, anchored with geometric pill alignment) */}
                    <div className="flex flex-wrap items-center gap-3 pt-2">
                      <Link
                        href={`/media/${currentFeatured.id}`}
                        className="h-11 sm:h-12 rounded-full bg-accentPrimary hover:opacity-90 text-white font-semibold text-xs sm:text-sm inline-flex items-center shadow-lg transition-all active:scale-95 overflow-hidden"
                      >
                        <span className="w-11 sm:w-12 h-11 sm:h-12 flex items-center justify-center shrink-0">
                          <Play className="w-4 h-4 fill-white" />
                        </span>
                        <span className="pr-5 sm:pr-6 -ml-2 text-xs sm:text-sm font-semibold">
                          Vezi Detalii & Episoade
                        </span>
                      </Link>

                      <button
                        onClick={() => toggleWatchlist(currentFeatured.id)}
                        className={`h-11 sm:h-12 rounded-full text-xs sm:text-sm font-semibold inline-flex items-center border transition-all active:scale-95 overflow-hidden ${
                          savedWatchlistIds.has(currentFeatured.id)
                            ? "bg-accentPrimary text-white border-accentPrimary shadow-md"
                            : "bg-bgSurface hover:bg-bgSurfaceHover text-textPrimary border-borderSubtle shadow-sm"
                        }`}
                      >
                        <span className="w-11 sm:w-12 h-11 sm:h-12 flex items-center justify-center shrink-0">
                          <Bookmark
                            className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(currentFeatured.id) ? "fill-white" : ""}`}
                          />
                        </span>
                        <span className="pr-5 sm:pr-6 -ml-2 text-xs sm:text-sm font-semibold">
                          {savedWatchlistIds.has(currentFeatured.id)
                            ? "Adăugat în Listă"
                            : "Adaugă în Watchlist"}
                        </span>
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
                              ? "w-10 sm:w-12 bg-bgSurfaceHover border border-borderSubtle"
                              : "w-2 bg-borderSubtle hover:bg-textSecondary"
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
          </div>
        );
      })()}

      {/* SECTION 2: ANIME DIN SEZONUL CURENT (DYNAMIC SEASONAL LANDSCAPE CAROUSEL) */}
      {(() => {
        const seasonMeta = getCurrentSeasonInfo(
          homepageData?.featuredSeason?.[0] || homepageData?.topAiring?.[0],
        );
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
                        seasonCarouselRef.current.scrollBy({
                          left: -(w + 32),
                          behavior: "smooth",
                        });
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
                        seasonCarouselRef.current.scrollBy({
                          left: w + 32,
                          behavior: "smooth",
                        });
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
            {loadingHomepage ? (
              <SeasonalCardsSkeleton />
            ) : (
              <div
                ref={seasonCarouselRef}
                className="flex gap-5 md:gap-6 lg:gap-8 overflow-x-auto scrollbar-none no-scrollbar scroll-smooth snap-x snap-mandatory pb-3 pt-1"
              >
                {seasonalItems.map((item) => {
                  const artColor = getMediaAccentColor(item);

                  return (
                    <div
                      key={item.id}
                      className="snap-start group relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle transition-all duration-300 flex flex-row shrink-0 w-full md:w-[calc((100%-24px)/2)] lg:w-[calc((100%-64px)/3)] h-[250px] sm:h-[270px] md:h-[285px] lg:h-[295px] shadow-md hover:shadow-2xl text-left"
                    >
                      {/* Full-Card Background Navigation Overlay */}
                      <Link
                        href={`/media/${item.id}`}
                        className="absolute inset-0 z-0 cursor-pointer"
                        aria-label={getDisplayTitle(item.title)}
                      />

                      {/* Dynamic Ambient Artwork Glow (Tailored for both Dark and Light mode) */}
                      <div
                        className="absolute -right-10 -bottom-10 w-64 h-64 rounded-full blur-3xl opacity-30 dark:opacity-20 group-hover:opacity-50 dark:group-hover:opacity-35 transition-opacity duration-700 pointer-events-none"
                        style={{ backgroundColor: artColor }}
                      />
                      <div
                        className="absolute -left-10 -top-10 w-48 h-48 rounded-full blur-3xl opacity-20 dark:opacity-10 group-hover:opacity-35 dark:group-hover:opacity-20 transition-opacity duration-700 pointer-events-none"
                        style={{ backgroundColor: artColor }}
                      />

                      {/* Dynamic Hover Border Overlay tinted with the artwork color */}
                      <div
                        className="absolute inset-0 rounded-3xl border border-transparent group-hover:border-[var(--hover-border)] transition-colors duration-300 pointer-events-none z-30"
                        style={{ ["--hover-border" as any]: `${artColor}70` }}
                      />

                      {/* Left Side: Information & Title (No rating) */}
                      <div className="flex-1 p-5 sm:p-6 flex flex-col justify-between min-w-0 z-10 space-y-2 pointer-events-none">
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
                          {item.status === "RELEASING" && (
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
                            {item.description ||
                              (item.genres && item.genres.length > 0
                                ? item.genres.slice(0, 4).join(" • ")
                                : "Sezon nou în difuzare.")}
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
                      <div className="landscape-art-mask w-[160px] sm:w-[200px] md:w-[230px] lg:w-[260px] h-full relative shrink-0 overflow-hidden bg-transparent pointer-events-none">
                        <img
                          src={
                            item.coverImage.extraLarge || item.coverImage.large
                          }
                          alt={getDisplayTitle(item.title)}
                          className="w-full h-full object-cover object-center group-hover:scale-105 transition-transform duration-500"
                        />

                        {/* Dynamic subtle color highlight over image */}
                        <div
                          className="absolute inset-0 opacity-20 dark:opacity-20 group-hover:opacity-35 transition-opacity duration-500 pointer-events-none"
                          style={{
                            background: `linear-gradient(to right, transparent 10%, ${artColor} 100%)`,
                            mixBlendMode: "multiply",
                          }}
                        />

                        {/* Watchlist Toggle Button (Top Right of image, Always visible with sleek glass & Bookmark save icon) */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            toggleWatchlist(item.id);
                          }}
                          className={`absolute top-3 right-3 w-8 h-8 rounded-full flex items-center justify-center backdrop-blur-md transition-all shadow-md active:scale-90 z-20 pointer-events-auto ${
                            savedWatchlistIds.has(item.id)
                              ? "bg-accentPrimary text-white shadow-accentPrimary/25"
                              : "bg-black/60 hover:bg-accentPrimary text-white/90 hover:text-white border border-white/15"
                          }`}
                          aria-label={
                            savedWatchlistIds.has(item.id)
                              ? "Elimină din Watchlist"
                              : "Adaugă în Watchlist"
                          }
                          title={
                            savedWatchlistIds.has(item.id)
                              ? "În Watchlist"
                              : "Adaugă în Watchlist"
                          }
                        >
                          <Bookmark
                            className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(item.id) ? "fill-white" : ""}`}
                          />
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </section>
        );
      })()}

      {/* SECTION 3: ULTIMELE EPISOADE IEȘITE (RECENTLY AIRED EPISODES - HORIZONTAL CAROUSEL) */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
            Ultimele Episoade Ieșite
          </h2>

          <div className="flex items-center gap-3">
            {/* Carousel Navigation Buttons */}
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => {
                  if (airedCarouselRef.current) {
                    const w = airedCarouselRef.current.clientWidth;
                    airedCarouselRef.current.scrollBy({
                      left: -(w * 0.75),
                      behavior: "smooth",
                    });
                  }
                }}
                className="p-2 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle text-textSecondary hover:text-textPrimary transition-all shadow-sm active:scale-95"
                aria-label="Scroll la stânga în episoade recente"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                onClick={() => {
                  if (airedCarouselRef.current) {
                    const w = airedCarouselRef.current.clientWidth;
                    airedCarouselRef.current.scrollBy({
                      left: w * 0.75,
                      behavior: "smooth",
                    });
                  }
                }}
                className="p-2 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle text-textSecondary hover:text-textPrimary transition-all shadow-sm active:scale-95"
                aria-label="Scroll la dreapta în episoade recente"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>

            <Link
              href="/media?status=RELEASING"
              className="hidden sm:flex text-xs font-semibold text-accentPrimary hover:opacity-80 items-center gap-1 transition-opacity ml-2"
            >
              Vezi toate difuzările <ChevronRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>

        {/* Recently Aired Horizontal Carousel */}
        {loadingHomepage ? (
          <RecentlyAiredSkeleton />
        ) : (
          <div
            ref={airedCarouselRef}
            className="flex gap-4 sm:gap-5 md:gap-6 overflow-x-auto scrollbar-none no-scrollbar scroll-smooth snap-x snap-mandatory pb-4 pt-1"
          >
            {(homepageData?.recentlyAired || []).map((item) => {
              const artColor = getMediaAccentColor(item.media);
              const currentProgress = watchedEpisodes[item.media.id] || 0;
              const isWatched = currentProgress >= item.episodeNumber;
              const isFresh = isFreshEpisode(
                item.airDateExact,
                item.airDateRelative,
              );

              return (
                <div
                  key={`${item.media.id}-${item.episodeNumber}`}
                  className="snap-start group relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle transition-all duration-300 flex flex-col shrink-0 w-[170px] sm:w-[195px] md:w-[215px] lg:w-[225px] shadow-md hover:shadow-2xl hover:-translate-y-1 text-left"
                >
                  {/* Full-Card Background Navigation Overlay */}
                  <Link
                    href={`/media/${item.media.id}`}
                    className="absolute inset-0 z-0 cursor-pointer"
                    aria-label={getDisplayTitle(item.media.title)}
                  />

                  {/* Subtle Ambient Artwork Glow */}
                  <div
                    className="absolute -right-6 -bottom-6 w-36 h-36 rounded-full blur-2xl opacity-20 dark:opacity-0 group-hover:opacity-40 dark:group-hover:opacity-30 transition-opacity duration-500 pointer-events-none"
                    style={{ backgroundColor: artColor }}
                  />

                  {/* Artwork Poster Area with True Alpha Mask (Seamless Hover Glow Integration) */}
                  <div className="relative aspect-[3/4] overflow-hidden rounded-t-3xl bg-transparent pointer-events-none">
                    <div className="vertical-art-mask absolute inset-0">
                      <img
                        src={
                          item.thumbnailUrl ||
                          item.media.coverImage.extraLarge ||
                          item.media.coverImage.large
                        }
                        alt={getDisplayTitle(item.media.title)}
                        className="w-full h-full object-cover group-hover:scale-108 transition-transform duration-500 ease-out"
                        loading="lazy"
                      />
                    </div>

                    {/* Top Subtle Vignette for Badge Contrast (Protects badges on all artwork colors) */}
                    <div className="absolute inset-x-0 top-0 h-16 bg-gradient-to-b from-black/75 via-black/35 to-transparent pointer-events-none z-[4]" />

                    {/* Combined Dynamic Episode & Recency Badge (Top-Left, Clean Borderless & Typographic Baseline Lock) */}
                    {isFresh ? (
                      <div className="absolute top-3 left-3 h-6 rounded-full bg-signalLive text-slate-950 shadow-md inline-flex items-center backdrop-blur-sm z-10 overflow-hidden">
                        <span className="w-6 h-6 flex items-center justify-center shrink-0">
                          <Sparkles className="w-3 h-3 text-slate-950 fill-slate-950" />
                        </span>
                        <span className="pr-2.5 -ml-1 text-[10px] font-bold tracking-tight inline-flex items-center">
                          <span className="font-black tracking-wide">NOU</span>
                          <span className="text-slate-950/35 mx-1 font-light text-[11px] select-none">
                            |
                          </span>
                          <span className="tabular-nums">
                            EP {item.episodeNumber}
                          </span>
                        </span>
                      </div>
                    ) : (
                      <div className="absolute top-3 left-3 h-6 rounded-full bg-black/70 backdrop-blur-md text-white/90 text-[10px] font-semibold shadow-sm inline-flex items-center z-10 overflow-hidden">
                        <span className="w-6 h-6 flex items-center justify-center shrink-0">
                          <Tv className="w-3 h-3 text-white/70" />
                        </span>
                        <span className="pr-2.5 -ml-1 tabular-nums">
                          EP {item.episodeNumber}
                        </span>
                      </div>
                    )}

                    {/* Rating Badge (Top-Right of Poster) */}
                    {item.media.scores?.averageScore ? (
                      <div className="absolute top-3 right-3 h-6 rounded-full bg-black/70 backdrop-blur-md text-scoreGold font-semibold text-[10px] border border-white/10 inline-flex items-center shadow-[0_3px_8px_rgba(0,0,0,0.5)] z-10 overflow-hidden">
                        <span className="w-6 h-6 flex items-center justify-center shrink-0">
                          <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                        </span>
                        <span className="pr-2.5 -ml-1 font-bold tabular-nums">
                          {item.media.scores.averageScore}
                        </span>
                      </div>
                    ) : null}

                    {/* Floating Info Pill at Bottom of Poster (Geometric icon-wrapper alignment) */}
                    <div className="absolute bottom-3 left-3 right-3 h-6 flex items-center justify-between text-[9.5px] font-normal text-white/70 bg-black/55 backdrop-blur-md rounded-full shadow-sm z-10 overflow-hidden border border-white/5">
                      <div className="flex items-center min-w-0">
                        <span className="w-6 h-6 flex items-center justify-center shrink-0">
                          <Clock className="w-3 h-3 text-white/60" />
                        </span>
                        <span className="truncate text-white/70 text-[9.5px] font-medium pr-2">
                          {item.airDateRelative}
                        </span>
                      </div>
                      <span className="text-white/80 font-semibold text-[8.5px] tracking-wider uppercase px-2 py-0.5 rounded-full bg-white/10 mr-1.5 shrink-0">
                        {formatMediaFormat(item.media.format, item.media.type)}
                      </span>
                    </div>
                  </div>

                  {/* Details / Footer below Poster */}
                  <div className="p-4 flex flex-col justify-between flex-1 space-y-3 z-10 pointer-events-none">
                    <h3
                      className="text-sm font-bold text-textPrimary line-clamp-2 group-hover:text-accentPrimary transition-colors leading-snug font-heading min-h-[2.5rem] tracking-tight text-balance"
                      title={getDisplayCardTitle(item.media.title)}
                    >
                      {getDisplayCardTitle(item.media.title)}
                    </h3>

                    {/* Aligned Action Row: Left Pill Button + Right Circular Bookmark Button */}
                    <div className="flex items-center gap-2 pt-0.5 pointer-events-auto">
                      {/* Primary Episode Watch Tracker Pill Button */}
                      <button
                        type="button"
                        onClick={(e) => handleMarkWatched(e, item)}
                        className={`flex-1 h-9 rounded-full font-bold text-[11px] transition-all duration-200 flex items-center justify-center shadow-sm active:scale-95 z-20 px-3 truncate ${
                          isWatched
                            ? "bg-signalLive text-slate-950 hover:brightness-105 shadow-signalLive/20"
                            : "bg-bgSurfaceHover hover:bg-signalLive text-textSecondary hover:text-slate-950 border border-borderSubtle hover:border-transparent"
                        }`}
                        aria-label={
                          isWatched
                            ? `Episodul ${item.episodeNumber} vizionat`
                            : `Marchează episodul ${item.episodeNumber} ca vizionat`
                        }
                      >
                        <span className="truncate">
                          {isWatched
                            ? `Vizionat (EP ${item.episodeNumber})`
                            : "Marchează Vizionat"}
                        </span>
                      </button>

                      {/* Circular Bookmark Button (Perfect Horizontal & Vertical Centering) */}
                      <button
                        type="button"
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          toggleWatchlist(item.media.id);
                        }}
                        className={`w-9 h-9 rounded-full shrink-0 flex items-center justify-center transition-all duration-200 shadow-sm active:scale-90 z-20 ${
                          savedWatchlistIds.has(item.media.id)
                            ? "bg-accentPrimary text-white shadow-accentPrimary/25"
                            : "bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white border border-borderSubtle hover:border-transparent"
                        }`}
                        aria-label={
                          savedWatchlistIds.has(item.media.id)
                            ? "Elimină din Watchlist"
                            : "Adaugă seria în Watchlist"
                        }
                        title={
                          savedWatchlistIds.has(item.media.id)
                            ? "În Watchlist"
                            : "Adaugă în Watchlist"
                        }
                      >
                        <Bookmark
                          className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(item.media.id) ? "fill-white" : ""}`}
                        />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      {/* SECTION 3: ANIME & MANGA NEWS */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
            Noutăți Anime & Manga
          </h2>
        </div>

        {/* News Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {(homepageData?.newsBeta || []).map((news) => {
            const badgeConfig = getNewsBadgeConfig(
              news.tagBadge,
              news.category,
            );
            const BadgeIcon = badgeConfig.icon;

            return (
              <a
                key={news.id}
                href={news.url || "#"}
                target="_blank"
                rel="noopener noreferrer"
                className="group bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle hover:border-accentPrimary/50 transition-all duration-300 flex flex-col justify-between p-4 sm:p-5 space-y-4 shadow-md hover:shadow-xl hover:-translate-y-1 text-left h-full"
              >
                <div className="space-y-3.5 flex-1 flex flex-col">
                  {/* Category Badge & Date (Geometric Alignment) */}
                  <div className="flex items-center justify-between">
                    <span
                      className={`h-6 rounded-full text-[10px] font-bold shadow-sm inline-flex items-center overflow-hidden tracking-tight ${badgeConfig.className}`}
                    >
                      <span className="w-6 h-6 flex items-center justify-center shrink-0">
                        <BadgeIcon className="w-3 h-3" />
                      </span>
                      <span className="pr-2.5 -ml-1 uppercase">
                        {badgeConfig.label}
                      </span>
                    </span>
                    <span className="text-[11px] text-textSecondary font-medium flex items-center gap-1.5">
                      <Calendar className="w-3 h-3 text-textMuted" />{" "}
                      {news.date}
                    </span>
                  </div>

                  {/* Image Preview if available */}
                  {news.imageUrl && (
                    <div className="aspect-[16/9] rounded-2xl overflow-hidden bg-bgSurfaceHover relative shrink-0">
                      <img
                        src={news.imageUrl}
                        alt={news.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                      />
                    </div>
                  )}

                  {/* Title (Consistent 2-line height) */}
                  <h3 className="text-sm sm:text-[15px] font-bold text-textPrimary group-hover:text-accentPrimary transition-colors leading-snug line-clamp-2 min-h-[2.6rem] font-heading tracking-tight">
                    {news.title}
                  </h3>

                  {/* Summary (Sanitized with fallback 2-line height) */}
                  <p className="text-xs sm:text-[13px] text-textSecondary line-clamp-2 min-h-[2.4rem] leading-relaxed">
                    {(news.summary || "").replace(/<[^>]*>?/gm, "")}
                  </p>
                </div>

                {/* Card Footer (Clean spacing without arbitrary divider) */}
                <div className="pt-2 flex items-center justify-between text-xs text-textSecondary font-medium mt-auto">
                  <span className="text-textSecondary flex items-center gap-1.5 truncate">
                    <Layers className="w-3 h-3 text-accentPrimary shrink-0" />{" "}
                    {news.source}
                  </span>
                  <span className="text-accentPrimary font-bold group-hover:translate-x-0.5 transition-transform flex items-center gap-1 shrink-0">
                    Citește știrea <ExternalLink className="w-3.5 h-3.5" />
                  </span>
                </div>
              </a>
            );
          })}
        </div>
      </section>

      {/* SECTION 4: RECOMANDĂRI (RECOMMENDED FOR YOU) */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
              Recomandări pentru Tine
            </h2>
          </div>

          <Link
            href="/recommendations"
            className="hidden sm:flex text-xs font-semibold text-accentPrimary hover:opacity-80 items-center gap-1 transition-opacity ml-2"
          >
            Vezi toate recomandările <ChevronRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        {/* Recommendations Grid (Aligned to 6-column desktop grid, 4 tablet, 3 small tablet, 2 mobile) */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4 sm:gap-5 md:gap-6">
          {(homepageData?.recommendations || []).slice(0, 12).map((item) => {
            const artColor = getMediaAccentColor(item.media);
            const reasonLabel = item.recommendationReason.includes("·")
              ? item.recommendationReason.split("·")[1].trim()
              : item.recommendationReason;

            return (
              <div
                key={item.media.id}
                className="snap-start group relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle transition-all duration-300 flex flex-col justify-between shadow-md hover:shadow-2xl hover:-translate-y-1 text-left"
              >
                {/* Full-Card Background Navigation Overlay */}
                <Link
                  href={`/media/${item.media.id}`}
                  className="absolute inset-0 z-0 cursor-pointer"
                  aria-label={getDisplayTitle(item.media.title)}
                />

                {/* Dynamic Ambient Artwork Glow */}
                <div
                  className="absolute -right-6 -bottom-6 w-36 h-36 rounded-full blur-2xl opacity-20 dark:opacity-0 group-hover:opacity-40 dark:group-hover:opacity-30 transition-opacity duration-500 pointer-events-none"
                  style={{ backgroundColor: artColor }}
                />

                {/* Dynamic Hover Border Tint */}
                <div
                  className="absolute inset-0 rounded-3xl border border-transparent group-hover:border-[var(--hover-border)] transition-colors duration-300 pointer-events-none z-30"
                  style={{ ["--hover-border" as any]: `${artColor}70` }}
                />

                {/* Poster Area with True Alpha Mask */}
                <div className="relative aspect-[3/4] overflow-hidden rounded-t-3xl bg-transparent pointer-events-none">
                  <div className="vertical-art-mask absolute inset-0">
                    <img
                      src={
                        item.media.coverImage.extraLarge ||
                        item.media.coverImage.large
                      }
                      alt={getDisplayTitle(item.media.title)}
                      className="w-full h-full object-cover group-hover:scale-108 transition-transform duration-500 ease-out"
                      loading="lazy"
                    />
                  </div>

                  {/* Top Subtle Vignette for Badge Contrast */}
                  <div className="absolute inset-x-0 top-0 h-16 bg-gradient-to-b from-black/75 via-black/35 to-transparent pointer-events-none z-[4]" />

                  {/* Match Score / Editorial Badge (Top-Left, Geometric Pill) */}
                  <div className="absolute top-3 left-3 h-6 rounded-full bg-badgeViolet text-slate-950 shadow-md inline-flex items-center backdrop-blur-sm z-10 overflow-hidden">
                    <span className="w-6 h-6 flex items-center justify-center shrink-0">
                      <Sparkles className="w-3 h-3 text-slate-950 fill-slate-950" />
                    </span>
                    <span className="pr-2.5 -ml-1 text-[10px] font-black tracking-tight tabular-nums uppercase">
                      {item.isPersonalized && item.matchPercentage
                        ? `${item.matchPercentage}% POTRIVIRE`
                        : item.badgeLabel || "TOP RECOMANDAT"}
                    </span>
                  </div>

                  {/* Rating Badge (Top-Right) */}
                  {item.media.scores?.averageScore ? (
                    <div className="absolute top-3 right-3 h-6 rounded-full bg-black/70 backdrop-blur-md text-scoreGold font-semibold text-[10px] border border-white/10 inline-flex items-center shadow-[0_3px_8px_rgba(0,0,0,0.5)] z-10 overflow-hidden">
                      <span className="w-6 h-6 flex items-center justify-center shrink-0">
                        <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                      </span>
                      <span className="pr-2.5 -ml-1 font-bold tabular-nums">
                        {item.media.scores.averageScore}
                      </span>
                    </div>
                  ) : null}

                  {/* Floating Bottom Poster Pill (Geometric icon-wrapper alignment) */}
                  <div className="absolute bottom-3 left-3 right-3 h-6 flex items-center justify-between text-[9.5px] font-normal text-white/70 bg-black/55 backdrop-blur-md rounded-full shadow-sm z-10 overflow-hidden border border-white/5">
                    <div className="flex items-center min-w-0">
                      <span className="w-6 h-6 flex items-center justify-center shrink-0">
                        <Tag className="w-3 h-3 text-white/60" />
                      </span>
                      <span className="truncate text-white/75 text-[9.5px] font-medium pr-2">
                        {item.media.genres?.[0] || "Recomandat"}
                      </span>
                    </div>
                    <span className="text-white/80 font-semibold text-[8.5px] tracking-wider uppercase px-2 py-0.5 rounded-full bg-white/10 mr-1.5 shrink-0">
                      {formatMediaFormat(item.media.format, item.media.type)}
                    </span>
                  </div>
                </div>

                {/* Card Body & Details below Poster */}
                <div className="p-4 flex flex-col justify-between flex-1 space-y-3 z-10 pointer-events-none">
                  <div className="space-y-1.5">
                    <span
                      className="text-[9.5px] font-bold tracking-wider uppercase line-clamp-1 block text-badgeViolet"
                      title={reasonLabel}
                    >
                      {reasonLabel}
                    </span>
                    <h3
                      className="text-sm font-bold text-textPrimary line-clamp-2 group-hover:text-accentPrimary transition-colors leading-snug font-heading min-h-[2.5rem] tracking-tight"
                      title={getDisplayCardTitle(item.media.title)}
                    >
                      {getDisplayCardTitle(item.media.title)}
                    </h3>
                  </div>

                  {/* Action Row: Left Pill Button + Right Bookmark Button */}
                  <div className="flex items-center gap-2 pt-0.5 pointer-events-auto">
                    <Link
                      href={`/media/${item.media.id}`}
                      className="flex-1 h-9 rounded-full font-bold text-[11px] bg-bgSurfaceHover group-hover:bg-badgeViolet text-textSecondary group-hover:text-slate-950 border border-borderSubtle group-hover:border-transparent transition-all duration-200 flex items-center justify-center shadow-sm px-3 truncate z-20 cursor-pointer"
                    >
                      <span className="truncate">Vezi Titlul</span>
                    </Link>

                    <button
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        toggleWatchlist(item.media.id);
                      }}
                      className={`w-9 h-9 rounded-full shrink-0 flex items-center justify-center transition-all duration-200 shadow-sm active:scale-90 z-20 ${
                        savedWatchlistIds.has(item.media.id)
                          ? "bg-accentPrimary text-white shadow-accentPrimary/25"
                          : "bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white border border-borderSubtle hover:border-transparent"
                      }`}
                      aria-label={
                        savedWatchlistIds.has(item.media.id)
                          ? "Elimină din Watchlist"
                          : "Adaugă seria în Watchlist"
                      }
                      title={
                        savedWatchlistIds.has(item.media.id)
                          ? "În Watchlist"
                          : "Adaugă în Watchlist"
                      }
                    >
                      <Bookmark
                        className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(item.media.id) ? "fill-white" : ""}`}
                      />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* SECTION 5: TOP AIRING & TOP UPCOMING DUAL LEADERBOARD */}
      <section className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold font-heading text-textPrimary tracking-tight">
              Top Airing & În Curând
            </h2>
          </div>
        </div>

        {/* Dual Columns on Desktop (lg:grid-cols-2), Stacks on Mobile */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-8">
          {/* COLUMN 1: TOP 3 AIRING (ÎN DIFUZARE) */}
          <div className="space-y-4">
            {/* Column Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="w-2.5 h-2.5 rounded-full bg-signalLive animate-pulse shadow-sm shadow-signalLive/50" />
                <h3 className="text-base sm:text-lg font-bold font-heading text-textPrimary tracking-tight flex items-center gap-2">
                  Top 3 În Difuzare{" "}
                  <span className="text-[10px] font-bold text-signalLive uppercase tracking-wider font-sans bg-signalLive/10 px-2 py-0.5 rounded-full">
                    Live
                  </span>
                </h3>
              </div>
              <span className="text-[11px] font-semibold text-textSecondary">
                Sezonul Activ
              </span>
            </div>

            {/* 3 Large Cinematic Horizontal Cards with Left Art Fade & Radiant Aura */}
            <div className="space-y-4">
              {(homepageData?.topAiring || []).slice(0, 3).map((item, index) => {
                const artColor = getMediaAccentColor(item);
                const rank = index + 1;
                const isTop1 = rank === 1;
                const isTop2 = rank === 2;
                const isTop3 = rank === 3;

                return (
                  <div
                    key={item.id}
                    className="group relative bg-bgSurface rounded-3xl h-44 sm:h-48 md:h-52 border border-borderSubtle hover:border-[var(--hover-border)] transition-all duration-300 flex items-stretch text-left overflow-hidden shadow-md hover:shadow-2xl hover:-translate-y-1.5"
                    style={{ ["--hover-border" as any]: `${artColor}80` }}
                  >
                    {/* Full-Card Background Navigation Overlay */}
                    <Link
                      href={`/media/${item.id}`}
                      className="absolute inset-0 z-0 cursor-pointer"
                      aria-label={getDisplayTitle(item.title)}
                    />

                    {/* Left Full-Height Poster Art with Seamless Gradient Fade */}
                    <div className="absolute inset-y-0 left-0 w-40 sm:w-52 md:w-56 overflow-hidden pointer-events-none">
                      <img
                        src={item.coverImage.extraLarge || item.coverImage.large}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
                        loading="lazy"
                      />
                      {/* Gradient overlays to fade smoothly into card background */}
                      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-bgSurface/70 to-bgSurface" />
                      <div className="absolute inset-0 bg-gradient-to-t from-bgSurface/85 via-transparent to-black/50" />
                    </div>

                    {/* Glowing Radiant Aura for Podium Places */}
                    <div
                      className={`absolute -left-8 -top-8 w-44 h-44 rounded-full blur-3xl pointer-events-none opacity-50 group-hover:opacity-90 transition-opacity duration-500 ${
                        isTop1
                          ? "bg-amber-400/50"
                          : isTop2
                            ? "bg-slate-200/45"
                            : "bg-orange-500/50"
                      }`}
                    />

                    {/* Rank Badge - Signature Kurogane Geometric Pill */}
                    <div
                      className={`absolute top-3 left-3 h-6 rounded-full inline-flex items-center backdrop-blur-sm z-20 overflow-hidden shadow-md pointer-events-none ${
                        isTop1
                          ? "bg-gradient-to-r from-amber-400 to-yellow-300 text-slate-950 font-black shadow-amber-500/30"
                          : isTop2
                            ? "bg-gradient-to-r from-slate-200 to-slate-100 text-slate-950 font-black shadow-slate-300/30"
                            : "bg-gradient-to-r from-amber-600 to-orange-400 text-white font-black shadow-orange-500/30"
                      }`}
                    >
                      <span className="w-6 h-6 flex items-center justify-center shrink-0">
                        <Flame
                          className={`w-3 h-3 ${isTop3 ? "text-white fill-white" : "text-slate-950 fill-slate-950"}`}
                        />
                      </span>
                      <span className="pr-2.5 -ml-1 text-[10px] font-black tracking-tight tabular-nums uppercase">
                        #{rank} TOP AIRING
                      </span>
                    </div>

                    {/* Card Content Area */}
                    <div className="relative z-10 pointer-events-none pl-36 sm:pl-52 md:pl-56 pr-4 sm:pr-5 py-3.5 sm:py-4 flex-1 flex flex-col justify-between min-w-0">
                      {/* Top Row: Meta Tags & Official AniList Score */}
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2 min-w-0">
                          <span
                            className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-bgPrimary text-textPrimary border transition-colors shadow-xs shrink-0"
                            style={{
                              borderColor: `${artColor}50`,
                            }}
                          >
                            {item.format
                              ? formatMediaFormat(item.format, item.type)
                              : item.type}
                          </span>
                          <span className="text-[10px] font-bold text-signalLive flex items-center gap-1.5 shrink-0">
                            <span className="w-1.5 h-1.5 rounded-full bg-signalLive animate-pulse" />
                            Live
                          </span>
                        </div>

                        {item.scores?.averageScore > 0 && (
                          <div className="h-6 px-2.5 rounded-full bg-black/70 backdrop-blur-md border border-white/10 flex items-center gap-1.5 text-[11px] font-bold text-scoreGold shrink-0 shadow-sm">
                            <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                            <span className="tabular-nums">
                              {item.scores.averageScore}
                            </span>
                          </div>
                        )}
                      </div>

                      {/* Middle: Large Title & Genre Badges */}
                      <div className="my-1 space-y-1.5">
                        <h4
                          className="text-base sm:text-lg font-bold text-textPrimary line-clamp-2 group-hover:text-accentPrimary transition-colors font-heading leading-snug tracking-tight"
                          title={getDisplayCardTitle(item.title)}
                        >
                          {getDisplayCardTitle(item.title)}
                        </h4>
                        <div className="flex items-center gap-1.5 overflow-hidden">
                          {item.genres?.slice(0, 3).map((g) => (
                            <span
                              key={g}
                              className="text-[10px] sm:text-[11px] text-textSecondary px-2.5 py-0.5 rounded-full bg-white/5 border border-white/5 font-medium shrink-0"
                            >
                              {g}
                            </span>
                          ))}
                        </div>
                      </div>

                      {/* Bottom Row: Episodes & Action Controls (No inner dividing border) */}
                      <div className="flex items-center justify-between gap-3 pt-1">
                        <div className="flex items-center gap-2 text-xs text-textSecondary font-medium">
                          <span className="tabular-nums font-semibold text-textPrimary">
                            {item.episodes
                              ? `${item.episodes} Episoade`
                              : "În Difuzare"}
                          </span>
                          {item.season && <span>• {item.season} {item.year || ""}</span>}
                        </div>

                        <div className="flex items-center gap-2 shrink-0 z-20 pointer-events-auto">
                          <button
                            type="button"
                            onClick={(e) => {
                              e.preventDefault();
                              e.stopPropagation();
                              toggleWatchlist(item.id);
                            }}
                            className={`w-9 h-9 rounded-full flex items-center justify-center transition-all duration-200 shadow-sm active:scale-90 ${
                              savedWatchlistIds.has(item.id)
                                ? "bg-accentPrimary text-white shadow-accentPrimary/25"
                                : "bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white border border-borderSubtle hover:border-transparent"
                            }`}
                            aria-label={
                              savedWatchlistIds.has(item.id)
                                ? "Elimină din Watchlist"
                                : "Adaugă în Watchlist"
                            }
                            title={
                              savedWatchlistIds.has(item.id)
                                ? "În Watchlist"
                                : "Adaugă în Watchlist"
                            }
                          >
                            <Bookmark
                              className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(item.id) ? "fill-white" : ""}`}
                            />
                          </button>

                          <Link
                            href={`/media/${item.id}`}
                            className="h-9 pl-3.5 pr-0 rounded-full bg-bgSurfaceHover group-hover:bg-accentPrimary text-textSecondary group-hover:text-white transition-colors inline-flex items-center text-xs font-bold border border-borderSubtle group-hover:border-transparent shadow-sm cursor-pointer z-20 pointer-events-auto"
                            title="Vezi Detalii"
                          >
                            <span className="leading-none">Vezi Titlul</span>
                            <span className="w-9 h-9 flex items-center justify-center shrink-0">
                              <ChevronRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                            </span>
                          </Link>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* COLUMN 2: TOP 3 UPCOMING (SEZON VIITOR) */}
          <div className="space-y-4">
            {/* Column Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="w-2.5 h-2.5 rounded-full bg-badgeViolet shadow-sm shadow-badgeViolet/50" />
                <h3 className="text-base sm:text-lg font-bold font-heading text-textPrimary tracking-tight flex items-center gap-2">
                  Top 3 În Curând{" "}
                  <span className="text-[10px] font-bold text-badgeViolet uppercase tracking-wider font-sans bg-badgeViolet/10 px-2 py-0.5 rounded-full">
                    Anticipate
                  </span>
                </h3>
              </div>
              <span className="text-[11px] font-semibold text-textSecondary">
                Sezonul Viitor
              </span>
            </div>

            {/* 3 Large Cinematic Horizontal Cards with Left Art Fade & Radiant Aura */}
            <div className="space-y-4">
              {(homepageData?.topUpcoming || []).slice(0, 3).map((item, index) => {
                const artColor = getMediaAccentColor(item);
                const rank = index + 1;
                const isTop1 = rank === 1;
                const isTop2 = rank === 2;
                const isTop3 = rank === 3;

                return (
                  <div
                    key={item.id}
                    className="group relative bg-bgSurface rounded-3xl h-44 sm:h-48 md:h-52 border border-borderSubtle hover:border-[var(--hover-border)] transition-all duration-300 flex items-stretch text-left overflow-hidden shadow-md hover:shadow-2xl hover:-translate-y-1.5"
                    style={{ ["--hover-border" as any]: `${artColor}80` }}
                  >
                    {/* Full-Card Background Navigation Overlay */}
                    <Link
                      href={`/media/${item.id}`}
                      className="absolute inset-0 z-0 cursor-pointer"
                      aria-label={getDisplayTitle(item.title)}
                    />

                    {/* Left Full-Height Poster Art with Seamless Gradient Fade */}
                    <div className="absolute inset-y-0 left-0 w-40 sm:w-52 md:w-56 overflow-hidden pointer-events-none">
                      <img
                        src={item.coverImage.extraLarge || item.coverImage.large}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
                        loading="lazy"
                      />
                      {/* Gradient overlays to fade smoothly into card background */}
                      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-bgSurface/70 to-bgSurface" />
                      <div className="absolute inset-0 bg-gradient-to-t from-bgSurface/85 via-transparent to-black/50" />
                    </div>

                    {/* Glowing Radiant Aura for Podium Places */}
                    <div
                      className={`absolute -left-8 -top-8 w-44 h-44 rounded-full blur-3xl pointer-events-none opacity-50 group-hover:opacity-90 transition-opacity duration-500 ${
                        isTop1
                          ? "bg-badgeViolet/55"
                          : isTop2
                            ? "bg-slate-200/45"
                            : "bg-orange-500/50"
                      }`}
                    />

                    {/* Rank Badge - Signature Kurogane Geometric Pill */}
                    <div
                      className={`absolute top-3 left-3 h-6 rounded-full inline-flex items-center backdrop-blur-sm z-20 overflow-hidden shadow-md pointer-events-none ${
                        isTop1
                          ? "bg-gradient-to-r from-badgeViolet via-purple-500 to-fuchsia-400 text-white font-black shadow-purple-500/30"
                          : isTop2
                            ? "bg-gradient-to-r from-slate-200 to-slate-100 text-slate-950 font-black shadow-slate-300/30"
                            : "bg-gradient-to-r from-amber-600 to-orange-400 text-white font-black shadow-orange-500/30"
                      }`}
                    >
                      <span className="w-6 h-6 flex items-center justify-center shrink-0">
                        <Clock
                          className={`w-3 h-3 ${isTop2 ? "text-slate-950" : "text-white"}`}
                        />
                      </span>
                      <span className="pr-2.5 -ml-1 text-[10px] font-black tracking-tight tabular-nums uppercase">
                        #{rank} ANTICIPAT
                      </span>
                    </div>

                    {/* Card Content Area */}
                    <div className="relative z-10 pointer-events-none pl-36 sm:pl-52 md:pl-56 pr-4 sm:pr-5 py-3.5 sm:py-4 flex-1 flex flex-col justify-between min-w-0">
                      {/* Top Row: Meta Tags & Status */}
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2 min-w-0">
                          <span
                            className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-bgPrimary text-textPrimary border transition-colors shadow-xs shrink-0"
                            style={{
                              borderColor: `${artColor}50`,
                            }}
                          >
                            {item.format
                              ? formatMediaFormat(item.format, item.type)
                              : item.type}
                          </span>
                          {item.season && (
                            <span className="text-xs font-semibold text-textSecondary truncate hidden sm:inline">
                              {item.season} {item.year || ""}
                            </span>
                          )}
                        </div>

                        <div className="h-6 px-3 rounded-full bg-badgeViolet text-slate-950 flex items-center text-[10px] font-black uppercase tracking-tight shadow-md shrink-0">
                          <span>ÎN CURÂND</span>
                        </div>
                      </div>

                      {/* Middle: Large Title & Genre Badges */}
                      <div className="my-1 space-y-1.5">
                        <h4
                          className="text-base sm:text-lg font-bold text-textPrimary line-clamp-2 group-hover:text-accentPrimary transition-colors font-heading leading-snug tracking-tight"
                          title={getDisplayCardTitle(item.title)}
                        >
                          {getDisplayCardTitle(item.title)}
                        </h4>
                        <div className="flex items-center gap-1.5 overflow-hidden">
                          {item.genres?.slice(0, 3).map((g) => (
                            <span
                              key={g}
                              className="text-[10px] sm:text-[11px] text-textSecondary px-2.5 py-0.5 rounded-full bg-white/5 border border-white/5 font-medium shrink-0"
                            >
                              {g}
                            </span>
                          ))}
                        </div>
                      </div>

                      {/* Bottom Row: Date / Status & Action Controls (No inner dividing border) */}
                      <div className="flex items-center justify-between gap-3 pt-1">
                        <div className="flex items-center gap-2 text-xs text-textSecondary font-medium">
                          <span className="font-semibold text-textPrimary">
                            {item.season ? `${item.season} ${item.year || ""}` : "Sezonul Viitor"}
                          </span>
                          {item.episodes && <span className="tabular-nums">• {item.episodes} Ep</span>}
                        </div>

                        <div className="flex items-center gap-2 shrink-0 z-20 pointer-events-auto">
                          <button
                            type="button"
                            onClick={(e) => {
                              e.preventDefault();
                              e.stopPropagation();
                              toggleWatchlist(item.id);
                            }}
                            className={`w-9 h-9 rounded-full flex items-center justify-center transition-all duration-200 shadow-sm active:scale-90 ${
                              savedWatchlistIds.has(item.id)
                                ? "bg-accentPrimary text-white shadow-accentPrimary/25"
                                : "bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white border border-borderSubtle hover:border-transparent"
                            }`}
                            aria-label={
                              savedWatchlistIds.has(item.id)
                                ? "Elimină din Watchlist"
                                : "Adaugă în Watchlist"
                            }
                            title={
                              savedWatchlistIds.has(item.id)
                                ? "În Watchlist"
                                : "Adaugă în Watchlist"
                            }
                          >
                            <Bookmark
                              className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(item.id) ? "fill-white" : ""}`}
                            />
                          </button>

                          <Link
                            href={`/media/${item.id}`}
                            className="h-9 pl-3.5 pr-0 rounded-full bg-bgSurfaceHover group-hover:bg-accentPrimary text-textSecondary group-hover:text-white transition-colors inline-flex items-center text-xs font-bold border border-borderSubtle group-hover:border-transparent shadow-sm cursor-pointer z-20 pointer-events-auto"
                            title="Vezi Detalii"
                          >
                            <span className="leading-none">Vezi Titlul</span>
                            <span className="w-9 h-9 flex items-center justify-center shrink-0">
                              <ChevronRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                            </span>
                          </Link>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </section>

      {/* SECTION 6: TOP 100 ANIME ALL-TIME (CINEMATIC LEADERBOARD) */}
      <section className="space-y-6">
        {/* Section Header & Interactive Filter Bar */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
              Top 100 Anime All-Time
            </h2>
          </div>

          {/* Search & Format Filter Pills */}
          <div className="flex flex-wrap items-center gap-2.5">
            {/* Search Pill Input */}
            <div className="relative flex items-center">
              <Search className="w-3.5 h-3.5 absolute left-3 text-textSecondary pointer-events-none" />
              <input
                type="text"
                value={top100Search}
                onChange={(e) => setTop100Search(e.target.value)}
                placeholder="Caută în Top 100…"
                className="h-9 pl-9 pr-8 bg-bgSurface text-textPrimary placeholder:text-textMuted border border-borderSubtle focus:border-accentPrimary rounded-full text-xs transition-colors focus:outline-none w-44 sm:w-56"
              />
              {top100Search && (
                <button
                  type="button"
                  onClick={() => setTop100Search("")}
                  className="absolute right-2.5 w-4 h-4 rounded-full bg-textMuted/20 hover:bg-textMuted/40 text-textPrimary flex items-center justify-center text-[10px] transition-colors"
                >
                  <X className="w-2.5 h-2.5" />
                </button>
              )}
            </div>

            {/* Format Pills Toggle */}
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
              {[
                { key: "ALL", label: "Toate" },
                { key: "TV", label: "Serii TV" },
                { key: "MOVIE", label: "Filme" },
                { key: "OVA", label: "OVA / ONA" },
              ].map((tab) => {
                const isActive = top100Format === tab.key;
                return (
                  <button
                    key={tab.key}
                    type="button"
                    onClick={() => setTop100Format(tab.key)}
                    className={`h-9 px-3.5 rounded-full text-xs font-bold transition-all shrink-0 cursor-pointer shadow-xs active:scale-95 ${
                      isActive
                        ? "bg-accentPrimary text-white shadow-accentPrimary/20"
                        : "bg-bgSurface text-textSecondary border border-borderSubtle hover:bg-bgSurfaceHover hover:text-textPrimary"
                    }`}
                  >
                    {tab.label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Leaderboard Cinematic Rows */}
        {filteredTop100.length === 0 ? (
          <div className="p-12 text-center bg-bgSurface rounded-3xl border border-borderSubtle space-y-3">
            <Award className="w-10 h-10 text-textMuted mx-auto opacity-50" />
            <h3 className="text-base font-bold text-textPrimary">Niciun titlu găsit</h3>
            <p className="text-xs text-textSecondary max-w-sm mx-auto">
              Nu am găsit serii care să corespundă filtrelor selectate. Încearcă alt termen sau resetează căutarea.
            </p>
            <button
              type="button"
              onClick={() => {
                setTop100Search("");
                setTop100Format("ALL");
              }}
              className="h-8 px-4 rounded-full bg-bgSurfaceHover hover:bg-accentPrimary hover:text-white text-textSecondary text-xs font-bold transition-all border border-borderSubtle inline-flex items-center cursor-pointer"
            >
              Resetează Filtrele
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredTop100.slice(0, top100Limit).map((item, index) => {
              const artColor = getMediaAccentColor(item);
              const rank = index + 1;
              const isTop1 = rank === 1;
              const isTop2 = rank === 2;
              const isTop3 = rank === 3;

              return (
                <div
                  key={item.id}
                  className="group relative bg-bgSurface rounded-2xl sm:rounded-3xl border border-borderSubtle hover:border-[var(--hover-border)] transition-all duration-300 flex items-center justify-between p-2.5 sm:p-3.5 md:p-4 gap-3 sm:gap-4 overflow-hidden shadow-sm hover:shadow-xl hover:-translate-y-0.5 text-left"
                  style={{ ["--hover-border" as any]: `${artColor}70` }}
                >
                  {/* Full-Card Background Navigation Overlay */}
                  <Link
                    href={`/media/${item.id}`}
                    className="absolute inset-0 z-0 cursor-pointer"
                    aria-label={getDisplayTitle(item.title)}
                  />

                  {/* Dynamic Ambient Glow on Hover */}
                  <div
                    className="absolute -right-12 -bottom-12 w-44 h-44 rounded-full blur-3xl opacity-0 group-hover:opacity-35 dark:group-hover:opacity-25 transition-opacity duration-500 pointer-events-none"
                    style={{ backgroundColor: artColor }}
                  />

                  {/* Left Section: Rank + Poster + Title & Tags */}
                  <div className="flex items-center gap-3 sm:gap-4 min-w-0 pointer-events-none z-10">
                    {/* Rank Badge */}
                    <div
                      className={`w-9 h-9 sm:w-11 sm:h-11 rounded-full flex items-center justify-center shrink-0 tabular-nums shadow-sm ${
                        isTop1
                          ? "bg-gradient-to-r from-amber-400 to-yellow-300 text-slate-950 font-black shadow-amber-500/30 text-xs sm:text-sm"
                          : isTop2
                            ? "bg-gradient-to-r from-slate-200 to-slate-100 text-slate-950 font-black shadow-slate-300/30 text-xs sm:text-sm"
                            : isTop3
                              ? "bg-gradient-to-r from-amber-600 to-orange-400 text-white font-black shadow-orange-500/30 text-xs sm:text-sm"
                              : "bg-bgSurfaceHover text-textSecondary border border-borderSubtle font-bold text-xs sm:text-sm group-hover:text-textPrimary group-hover:border-transparent transition-colors"
                      }`}
                    >
                      #{rank}
                    </div>

                    {/* Poster Thumbnail */}
                    <div className="w-14 h-20 sm:w-16 sm:h-24 md:w-20 md:h-28 rounded-xl sm:rounded-2xl overflow-hidden bg-bgSurfaceHover shrink-0 relative shadow-sm">
                      <img
                        src={item.coverImage.extraLarge || item.coverImage.large || item.coverImage.medium}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-108 transition-transform duration-500 ease-out"
                        loading="lazy"
                      />
                    </div>

                    {/* Meta, Title & Genres */}
                    <div className="min-w-0 space-y-1 sm:space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span
                          className="px-2.5 py-0.5 rounded-full text-[9.5px] sm:text-[10px] font-bold uppercase tracking-wider bg-bgPrimary text-textPrimary border transition-colors shadow-xs shrink-0"
                          style={{
                            borderColor: `${artColor}50`,
                          }}
                        >
                          {item.format
                            ? formatMediaFormat(item.format, item.type)
                            : item.type}
                        </span>
                        {item.year && (
                          <span className="text-[11px] font-semibold text-textSecondary truncate">
                            {item.season ? `${item.season} ${item.year}` : item.year}
                          </span>
                        )}
                        {item.episodes && (
                          <span className="text-[11px] font-medium text-textMuted hidden md:inline truncate">
                            • {item.episodes} Episoade
                          </span>
                        )}
                      </div>

                      <h3
                        className="text-sm sm:text-base font-bold text-textPrimary truncate group-hover:text-accentPrimary transition-colors font-heading leading-snug tracking-tight"
                        title={getDisplayCardTitle(item.title)}
                      >
                        {getDisplayCardTitle(item.title)}
                      </h3>

                      <div className="hidden sm:flex items-center gap-1.5 overflow-hidden">
                        {item.genres?.slice(0, 3).map((g) => (
                          <span
                            key={g}
                            className="text-[10px] text-textSecondary px-2.5 py-0.5 rounded-full bg-white/5 border border-white/5 font-medium shrink-0"
                          >
                            {g}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Right Section: Score Badge + Action Controls */}
                  <div className="flex items-center gap-2.5 sm:gap-3 shrink-0 z-20 pointer-events-auto">
                    {/* Score Badge */}
                    {item.scores?.averageScore > 0 && (
                      <div className="h-7 sm:h-8 px-2.5 sm:px-3 rounded-full bg-black/70 backdrop-blur-md border border-white/10 flex items-center gap-1.5 text-xs sm:text-sm font-bold text-scoreGold shrink-0 shadow-sm">
                        <Star className="w-3.5 h-3.5 fill-scoreGold text-scoreGold shrink-0" />
                        <span className="tabular-nums font-bold">
                          {item.scores.averageScore}
                        </span>
                      </div>
                    )}

                    {/* Bookmark Button */}
                    <button
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        toggleWatchlist(item.id);
                      }}
                      className={`w-9 h-9 rounded-full shrink-0 flex items-center justify-center transition-all duration-200 shadow-sm active:scale-90 ${
                        savedWatchlistIds.has(item.id)
                          ? "bg-accentPrimary text-white shadow-accentPrimary/25"
                          : "bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white border border-borderSubtle hover:border-transparent"
                      }`}
                      aria-label={
                        savedWatchlistIds.has(item.id)
                          ? "Elimină din Watchlist"
                          : "Adaugă în Watchlist"
                      }
                      title={
                        savedWatchlistIds.has(item.id)
                          ? "În Watchlist"
                          : "Adaugă în Watchlist"
                      }
                    >
                      <Bookmark
                        className={`w-4 h-4 transition-colors ${savedWatchlistIds.has(item.id) ? "fill-white" : ""}`}
                      />
                    </button>

                    {/* Vezi Titlul Pill Button with Centered Chevron Geometry */}
                    <Link
                      href={`/media/${item.id}`}
                      className="hidden sm:inline-flex h-9 pl-3.5 pr-0 rounded-full bg-bgSurfaceHover group-hover:bg-accentPrimary text-textSecondary group-hover:text-white transition-colors items-center text-xs font-bold border border-borderSubtle group-hover:border-transparent shadow-sm cursor-pointer"
                      title="Vezi Detalii"
                    >
                      <span className="leading-none">Vezi Titlul</span>
                      <span className="w-9 h-9 flex items-center justify-center shrink-0">
                        <ChevronRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                      </span>
                    </Link>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Load More Top 100 Button */}
        {top100Limit < filteredTop100.length && (
          <div className="flex justify-center pt-4">
            <button
              type="button"
              onClick={() => setTop100Limit((prev) => prev + 20)}
              className="h-11 px-7 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle hover:border-accentPrimary/40 text-textPrimary font-bold text-xs transition-all shadow-sm active:scale-95 flex items-center gap-2 cursor-pointer group"
            >
              <span>Afișează Următoarele 20 de Titluri</span>
              <ChevronRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform text-accentPrimary" />
            </button>
          </div>
        )}
      </section>
    </div>
  );
}

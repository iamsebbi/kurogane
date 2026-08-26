"use client";

import React, { useState, useEffect } from "react";
import { API_BASE_URL } from "../lib/api";
import {
  HomepageData,
  RecentlyAiredEpisode,
} from "@kurogane/shared";
import { HeroFeaturedCarousel } from "../components/home/HeroFeaturedCarousel";
import { SeasonalShelfRow } from "../components/home/SeasonalShelfRow";
import { RecentlyAiredSection } from "../components/home/RecentlyAiredSection";
import { NewsFeedSection } from "../components/home/NewsFeedSection";
import { RecommendationsSection } from "../components/home/RecommendationsSection";
import { TopRankedSection } from "../components/home/TopRankedSection";

export default function Homepage() {
  // Homepage Sections State
  const [homepageData, setHomepageData] = useState<HomepageData | null>(null);
  const [loadingHomepage, setLoadingHomepage] = useState<boolean>(true);

  // Hero Slider Active Index
  const [activeHeroIndex, setActiveHeroIndex] = useState<number>(0);

  // Global Watchlist State
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

    fetch(`${API_BASE_URL}/api/watchlist`, {
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

  // Fetch Homepage Data with User Token for Personalized Recommendations
  useEffect(() => {
    let isMounted = true;
    const token =
      typeof window !== "undefined"
        ? localStorage.getItem("kurogane_token")
        : null;

    fetch(`${API_BASE_URL}/api/homepage`, {
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

  // Automatic hero slider cycle (6 seconds)
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

      await fetch(`${API_BASE_URL}/api/watchlist`, {
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

  return (
    <div className="max-w-[1920px] mx-auto px-4 md:px-12 pt-10 sm:pt-12 md:pt-14 space-y-16 lg:space-y-20 pb-20">
      {/* SECTION 1: TRENDING ANIME HERO CAROUSEL */}
      <HeroFeaturedCarousel
        featuredSeason={homepageData?.featuredSeason}
        activeHeroIndex={activeHeroIndex}
        setActiveHeroIndex={setActiveHeroIndex}
        loading={loadingHomepage}
        savedWatchlistIds={savedWatchlistIds}
        toggleWatchlist={toggleWatchlist}
      />

      {/* SECTION 2: CURRENT SEASONAL LANDSCAPE CAROUSEL */}
      <SeasonalShelfRow
        featuredSeason={homepageData?.featuredSeason}
        topAiring={homepageData?.topAiring}
        loading={loadingHomepage}
        savedWatchlistIds={savedWatchlistIds}
        toggleWatchlist={toggleWatchlist}
      />

      {/* SECTION 3: RECENTLY AIRED EPISODES */}
      <RecentlyAiredSection
        recentlyAired={homepageData?.recentlyAired}
        loading={loadingHomepage}
        savedWatchlistIds={savedWatchlistIds}
        watchedEpisodes={watchedEpisodes}
        toggleWatchlist={toggleWatchlist}
        handleMarkWatched={handleMarkWatched}
      />

      {/* SECTION 4: ANIME & MANGA NEWS */}
      <NewsFeedSection newsBeta={homepageData?.newsBeta} />

      {/* SECTION 5: RECOMMENDED FOR YOU */}
      <RecommendationsSection
        recommendations={homepageData?.recommendations}
        savedWatchlistIds={savedWatchlistIds}
        toggleWatchlist={toggleWatchlist}
      />

      {/* SECTION 6 & 7: TOP AIRING/UPCOMING DUAL LEADERBOARD & TOP 100 ALL-TIME */}
      <TopRankedSection
        topAiring={homepageData?.topAiring}
        topUpcoming={homepageData?.topUpcoming}
        top100={homepageData?.top100}
        savedWatchlistIds={savedWatchlistIds}
        toggleWatchlist={toggleWatchlist}
      />
    </div>
  );
}

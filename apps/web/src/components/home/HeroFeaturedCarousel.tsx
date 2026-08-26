import React from "react";
import Link from "next/link";
import { Play, Bookmark, Flame } from "lucide-react";
import { MediaItem } from "@kurogane/shared";
import {
  getMediaAccentColor,
  getDynamicSeasonLabel,
  getDisplayTitle,
} from "./HomeHelpers";
import { HeroSkeleton } from "./HomeSkeletons";

interface HeroFeaturedCarouselProps {
  featuredSeason?: MediaItem[];
  activeHeroIndex: number;
  setActiveHeroIndex: (index: number) => void;
  loading: boolean;
  savedWatchlistIds: Set<string>;
  toggleWatchlist: (id: string) => void;
}

export function HeroFeaturedCarousel({
  featuredSeason = [],
  activeHeroIndex,
  setActiveHeroIndex,
  loading,
  savedWatchlistIds,
  toggleWatchlist,
}: HeroFeaturedCarouselProps) {
  const currentFeatured = featuredSeason[activeHeroIndex];
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
        {loading ? (
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
              <div className="hero-art-mask absolute inset-y-0 right-0 w-full md:w-[70%] lg:w-[60%] xl:w-[54%] h-full">
                {featuredSeason.map((item, idx) => {
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
              <div className="absolute inset-0 bg-gradient-to-r from-bgSurface via-bgSurface/90 via-25% md:via-35% to-transparent z-20" />
              <div className="absolute inset-0 bg-gradient-to-t from-bgSurface via-bgSurface/40 via-10% to-transparent z-20" />
              <div className="absolute inset-0 bg-gradient-to-b from-bgSurface/30 via-transparent to-transparent z-20" />
            </div>

            {/* Top-Left Badges */}
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

            {/* Content Banner */}
            <div className="relative z-10 max-w-3xl lg:max-w-4xl space-y-3 sm:space-y-4">
              <div
                key={currentFeatured.id}
                className="space-y-2.5 sm:space-y-3.5 animate-hero-fade"
              >
                <h1
                  className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-textPrimary leading-tight font-heading drop-shadow-md line-clamp-2 min-h-[2.5rem] sm:min-h-[3.25rem] lg:min-h-[3.75rem]"
                  title={getDisplayTitle(currentFeatured.title)}
                >
                  {getDisplayTitle(currentFeatured.title)}
                </h1>

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

            {/* Carousel Navigation Controls */}
            <div className="absolute bottom-6 right-6 lg:bottom-10 lg:right-10 z-20 flex items-center gap-2 bg-bgSurface px-3 py-2 rounded-full border border-borderSubtle shadow-xl">
              {featuredSeason.map((_, idx) => {
                const isActive = idx === activeHeroIndex;
                return (
                  <button
                    key={idx}
                    onClick={() => setActiveHeroIndex(idx)}
                    className={`relative h-2 rounded-full overflow-hidden transition-[width,background-color,border-color] duration-700 [transition-timing-function:cubic-bezier(0.25,1,0.5,1)] ${
                      isActive
                        ? "w-10 sm:w-12 bg-bgSurfaceHover border border-borderSubtle"
                        : "w-2 bg-borderSubtle/60 hover:bg-borderSubtle hover:scale-110"
                    }`}
                    aria-label={`Slide ${idx + 1}`}
                  >
                    {isActive && (
                      <span className="absolute inset-0 bg-accentPrimary origin-left animate-progress-fill" />
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
}

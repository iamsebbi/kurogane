import React, { useRef } from "react";
import Link from "next/link";
import { ChevronLeft, ChevronRight, Bookmark } from "lucide-react";
import { MediaItem } from "@kurogane/shared";
import {
  getCurrentSeasonInfo,
  getMediaAccentColor,
  getDisplayTitle,
} from "./HomeHelpers";
import { SeasonalCardsSkeleton } from "./HomeSkeletons";

interface SeasonalShelfRowProps {
  featuredSeason?: MediaItem[];
  topAiring?: MediaItem[];
  loading: boolean;
  savedWatchlistIds: Set<string>;
  toggleWatchlist: (id: string) => void;
}

export function SeasonalShelfRow({
  featuredSeason = [],
  topAiring = [],
  loading,
  savedWatchlistIds,
  toggleWatchlist,
}: SeasonalShelfRowProps) {
  const seasonCarouselRef = useRef<HTMLDivElement>(null);

  const seasonMeta = getCurrentSeasonInfo(
    featuredSeason[0] || topAiring[0]
  );
  const seasonalItems = (
    featuredSeason.length > 0 ? featuredSeason : topAiring
  ).slice(0, 6);

  return (
    <section className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
          {seasonMeta.title}
        </h2>

        <div className="flex items-center gap-3">
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

      {loading ? (
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
                <Link
                  href={`/media/${item.id}`}
                  className="absolute inset-0 z-0 cursor-pointer"
                  aria-label={getDisplayTitle(item.title)}
                />

                <div
                  className="absolute -right-10 -bottom-10 w-64 h-64 rounded-full blur-3xl opacity-30 dark:opacity-20 group-hover:opacity-50 dark:group-hover:opacity-35 transition-opacity duration-700 pointer-events-none"
                  style={{ backgroundColor: artColor }}
                />
                <div
                  className="absolute -left-10 -top-10 w-48 h-48 rounded-full blur-3xl opacity-20 dark:opacity-10 group-hover:opacity-35 dark:group-hover:opacity-20 transition-opacity duration-700 pointer-events-none"
                  style={{ backgroundColor: artColor }}
                />

                <div
                  className="absolute inset-0 rounded-3xl border border-transparent group-hover:border-[var(--hover-border)] transition-colors duration-300 pointer-events-none z-30"
                  style={{ ["--hover-border" as any]: `${artColor}70` }}
                />

                <div className="flex-1 p-5 sm:p-6 flex flex-col justify-between min-w-0 z-10 space-y-2 pointer-events-none">
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

                <div className="landscape-art-mask w-[160px] sm:w-[200px] md:w-[230px] lg:w-[260px] h-full relative shrink-0 overflow-hidden bg-transparent pointer-events-none">
                  <img
                    src={
                      item.coverImage.extraLarge || item.coverImage.large
                    }
                    alt={getDisplayTitle(item.title)}
                    className="w-full h-full object-cover object-center group-hover:scale-105 transition-transform duration-500"
                  />

                  <div
                    className="absolute inset-0 opacity-20 dark:opacity-20 group-hover:opacity-35 transition-opacity duration-500 pointer-events-none"
                    style={{
                      background: `linear-gradient(to right, transparent 10%, ${artColor} 100%)`,
                      mixBlendMode: "multiply",
                    }}
                  />

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
}

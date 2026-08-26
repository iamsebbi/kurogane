import React, { useRef } from "react";
import Link from "next/link";
import { ChevronLeft, ChevronRight, Bookmark, Sparkles, Tv, Star, Clock } from "lucide-react";
import { RecentlyAiredEpisode } from "@kurogane/shared";
import {
  getMediaAccentColor,
  getDisplayTitle,
  getDisplayCardTitle,
  formatMediaFormat,
  isFreshEpisode,
} from "./HomeHelpers";
import { RecentlyAiredSkeleton } from "./HomeSkeletons";

interface RecentlyAiredSectionProps {
  recentlyAired?: RecentlyAiredEpisode[];
  loading: boolean;
  savedWatchlistIds: Set<string>;
  watchedEpisodes: Record<string, number>;
  toggleWatchlist: (id: string) => void;
  handleMarkWatched: (e: React.MouseEvent, item: RecentlyAiredEpisode) => void;
}

export function RecentlyAiredSection({
  recentlyAired = [],
  loading,
  savedWatchlistIds,
  watchedEpisodes,
  toggleWatchlist,
  handleMarkWatched,
}: RecentlyAiredSectionProps) {
  const airedCarouselRef = useRef<HTMLDivElement>(null);

  return (
    <section className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
          Ultimele Episoade Ieșite
        </h2>

        <div className="flex items-center gap-3">
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

      {loading ? (
        <RecentlyAiredSkeleton />
      ) : (
        <div
          ref={airedCarouselRef}
          className="flex gap-4 sm:gap-5 md:gap-6 overflow-x-auto scrollbar-none no-scrollbar scroll-smooth snap-x snap-mandatory pb-4 pt-1"
        >
          {recentlyAired.map((item) => {
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
                <Link
                  href={`/media/${item.media.id}`}
                  className="absolute inset-0 z-0 cursor-pointer"
                  aria-label={getDisplayTitle(item.media.title)}
                />

                <div
                  className="absolute -right-6 -bottom-6 w-36 h-36 rounded-full blur-2xl opacity-20 dark:opacity-0 group-hover:opacity-40 dark:group-hover:opacity-30 transition-opacity duration-500 pointer-events-none"
                  style={{ backgroundColor: artColor }}
                />

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

                  <div className="absolute inset-x-0 top-0 h-16 bg-gradient-to-b from-black/75 via-black/35 to-transparent pointer-events-none z-[4]" />

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

                <div className="p-4 flex flex-col justify-between flex-1 space-y-3 z-10 pointer-events-none">
                  <h3
                    className="text-sm font-bold text-textPrimary line-clamp-2 group-hover:text-accentPrimary transition-colors leading-snug font-heading min-h-[2.5rem] tracking-tight text-balance"
                    title={getDisplayCardTitle(item.media.title)}
                  >
                    {getDisplayCardTitle(item.media.title)}
                  </h3>

                  <div className="flex items-center gap-2 pt-0.5 pointer-events-auto">
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
  );
}

import React, { useState } from "react";
import Link from "next/link";
import {
  Flame,
  Star,
  Clock,
  ChevronRight,
  Bookmark,
  Search,
  X,
  Award,
} from "lucide-react";
import { MediaItem } from "@kurogane/shared";
import {
  getMediaAccentColor,
  getDisplayTitle,
  getDisplayCardTitle,
  formatMediaFormat,
} from "./HomeHelpers";

interface TopRankedSectionProps {
  topAiring?: MediaItem[];
  topUpcoming?: MediaItem[];
  top100?: MediaItem[];
  savedWatchlistIds: Set<string>;
  toggleWatchlist: (id: string) => void;
}

export function TopRankedSection({
  topAiring = [],
  topUpcoming = [],
  top100 = [],
  savedWatchlistIds,
  toggleWatchlist,
}: TopRankedSectionProps) {
  const [top100Search, setTop100Search] = useState<string>("");
  const [top100Format, setTop100Format] = useState<string>("ALL");
  const [top100Limit, setTop100Limit] = useState<number>(20);

  const filteredTop100 = top100.filter((item) => {
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
    <div className="space-y-16 lg:space-y-20">
      {/* SECTION: TOP AIRING & TOP UPCOMING DUAL LEADERBOARD */}
      <section className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold font-heading text-textPrimary tracking-tight">
              Top Airing & În Curând
            </h2>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-8">
          {/* COLUMN 1: TOP 3 AIRING */}
          <div className="space-y-4">
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

            <div className="space-y-4">
              {topAiring.slice(0, 3).map((item, index) => {
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
                    <Link
                      href={`/media/${item.id}`}
                      className="absolute inset-0 z-0 cursor-pointer"
                      aria-label={getDisplayTitle(item.title)}
                    />

                    <div className="absolute inset-y-0 left-0 w-40 sm:w-52 md:w-56 overflow-hidden pointer-events-none">
                      <img
                        src={item.coverImage.extraLarge || item.coverImage.large}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
                        loading="lazy"
                      />
                      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-bgSurface/70 to-bgSurface" />
                      <div className="absolute inset-0 bg-gradient-to-t from-bgSurface/85 via-transparent to-black/50" />
                    </div>

                    <div
                      className={`absolute -left-8 -top-8 w-44 h-44 rounded-full blur-3xl pointer-events-none opacity-50 group-hover:opacity-90 transition-opacity duration-500 ${
                        isTop1
                          ? "bg-amber-400/50"
                          : isTop2
                            ? "bg-slate-200/45"
                            : "bg-orange-500/50"
                      }`}
                    />

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

                    <div className="relative z-10 pointer-events-none pl-36 sm:pl-52 md:pl-56 pr-4 sm:pr-5 py-3.5 sm:py-4 flex-1 flex flex-col justify-between min-w-0">
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

          {/* COLUMN 2: TOP 3 UPCOMING */}
          <div className="space-y-4">
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

            <div className="space-y-4">
              {topUpcoming.slice(0, 3).map((item, index) => {
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
                    <Link
                      href={`/media/${item.id}`}
                      className="absolute inset-0 z-0 cursor-pointer"
                      aria-label={getDisplayTitle(item.title)}
                    />

                    <div className="absolute inset-y-0 left-0 w-40 sm:w-52 md:w-56 overflow-hidden pointer-events-none">
                      <img
                        src={item.coverImage.extraLarge || item.coverImage.large}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
                        loading="lazy"
                      />
                      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-bgSurface/70 to-bgSurface" />
                      <div className="absolute inset-0 bg-gradient-to-t from-bgSurface/85 via-transparent to-black/50" />
                    </div>

                    <div
                      className={`absolute -left-8 -top-8 w-44 h-44 rounded-full blur-3xl pointer-events-none opacity-50 group-hover:opacity-90 transition-opacity duration-500 ${
                        isTop1
                          ? "bg-badgeViolet/55"
                          : isTop2
                            ? "bg-slate-200/45"
                            : "bg-orange-500/50"
                      }`}
                    />

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

                    <div className="relative z-10 pointer-events-none pl-36 sm:pl-52 md:pl-56 pr-4 sm:pr-5 py-3.5 sm:py-4 flex-1 flex flex-col justify-between min-w-0">
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

      {/* SECTION: TOP 100 ANIME ALL-TIME LEADERBOARD */}
      <section className="space-y-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
              Top 100 Anime All-Time
            </h2>
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
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
                  <Link
                    href={`/media/${item.id}`}
                    className="absolute inset-0 z-0 cursor-pointer"
                    aria-label={getDisplayTitle(item.title)}
                  />

                  <div
                    className="absolute -right-12 -bottom-12 w-44 h-44 rounded-full blur-3xl opacity-0 group-hover:opacity-35 dark:group-hover:opacity-25 transition-opacity duration-500 pointer-events-none"
                    style={{ backgroundColor: artColor }}
                  />

                  <div className="flex items-center gap-3 sm:gap-4 min-w-0 pointer-events-none z-10">
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

                    <div className="w-14 h-20 sm:w-16 sm:h-24 md:w-20 md:h-28 rounded-xl sm:rounded-2xl overflow-hidden bg-bgSurfaceHover shrink-0 relative shadow-sm">
                      <img
                        src={item.coverImage.extraLarge || item.coverImage.large || item.coverImage.medium}
                        alt={getDisplayTitle(item.title)}
                        className="w-full h-full object-cover group-hover:scale-108 transition-transform duration-500 ease-out"
                        loading="lazy"
                      />
                    </div>

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

                  <div className="flex items-center gap-2.5 sm:gap-3 shrink-0 z-20 pointer-events-auto">
                    {item.scores?.averageScore > 0 && (
                      <div className="h-7 sm:h-8 px-2.5 sm:px-3 rounded-full bg-black/70 backdrop-blur-md border border-white/10 flex items-center gap-1.5 text-xs sm:text-sm font-bold text-scoreGold shrink-0 shadow-sm">
                        <Star className="w-3.5 h-3.5 fill-scoreGold text-scoreGold shrink-0" />
                        <span className="tabular-nums font-bold">
                          {item.scores.averageScore}
                        </span>
                      </div>
                    )}

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

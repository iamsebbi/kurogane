'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Star,
  ShieldCheck,
  Sparkles,
  Clock,
  Calendar,
  Film,
  Tv,
  Layers,
  ChevronRight,
  Info,
  CheckCircle2,
  AlertTriangle,
  Flame,
  Share2,
  Bookmark,
  RefreshCw,
  Sun,
  Snowflake,
  Flower2,
  Leaf,
  Compass,
} from 'lucide-react';
import {
  MediaItem,
  WatchOrderGuide,
  WatchOrderMode,
  WatchOrderNode,
  SimilarMediaResponse,
} from '@kurogane/shared';
import { AuthModal } from '@/components/AuthModal';

const STATUS_LABELS: Record<string, string> = {
  WATCHING: 'În Curs',
  COMPLETED: 'Completat',
  PLAN_TO_WATCH: 'Planificat',
  ON_HOLD: 'În Pauză',
  DROPPED: 'Renunțat',
};

export default function MediaDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const id = params?.id as string;

  const [media, setMedia] = useState<MediaItem | null>(null);
  const [watchOrderGuide, setWatchOrderGuide] = useState<WatchOrderGuide | null>(null);
  const [similarData, setSimilarData] = useState<SimilarMediaResponse | null>(null);
  const [watchOrderMode, setWatchOrderMode] = useState<WatchOrderMode>('RECOMMENDED');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [userWatchlistStatus, setUserWatchlistStatus] = useState<string | null>(null);
  const [isAuthOpen, setIsAuthOpen] = useState(false);

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

  const checkUserWatchlistStatus = async () => {
    const token = localStorage.getItem('kurogane_token');
    if (!token || !id) return;
    try {
      const res = await fetch(`${API_BASE}/api/watchlist`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        const found = data.items?.find((i: any) => i.mediaId === id);
        if (found) setUserWatchlistStatus(found.status);
      }
    } catch (err) {
      console.error('Error fetching watchlist status:', err);
    }
  };

  const saveWatchlistStatus = async (status: string) => {
    const token = localStorage.getItem('kurogane_token');
    if (!token) {
      setIsAuthOpen(true);
      return;
    }
    try {
      const res = await fetch(`${API_BASE}/api/watchlist`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ mediaId: id, status }),
      });
      if (res.ok) {
        setUserWatchlistStatus(status);
      }
    } catch (err) {
      console.error('Error saving watchlist:', err);
    }
  };

  const handleWatchlistToggle = () => {
    const token = localStorage.getItem('kurogane_token');
    if (!token) {
      setIsAuthOpen(true);
    } else {
      saveWatchlistStatus(userWatchlistStatus ? userWatchlistStatus : 'WATCHING');
    }
  };


  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setError(null);

    const safeId = encodeURIComponent(id);

    // Fetch media details, watch order guide, and similar media in parallel
    Promise.all([
      fetch(`${API_BASE}/api/media/${safeId}`).then((res) => (res.ok ? res.json() : null)),
      fetch(`${API_BASE}/api/media/${safeId}/watch-order`).then((res) => (res.ok ? res.json() : null)),
      fetch(`${API_BASE}/api/media/${safeId}/similar?limit=6`).then((res) => (res.ok ? res.json() : null)),
    ])
      .then(([mediaRes, watchOrderRes, similarRes]) => {
        if (mediaRes) {
          setMedia(mediaRes);
        } else {
          setError('Titlul nu a fost găsit în baza de date.');
        }

        if (watchOrderRes) {
          setWatchOrderGuide(watchOrderRes);
        }

        if (similarRes) {
          setSimilarData(similarRes);
        }
        checkUserWatchlistStatus();
      })
      .catch((err) => {
        console.error('Error fetching media details:', err);
        setError('A apărut o eroare la încărcarea datelor.');
      })
      .finally(() => {
        setLoading(false);
      });
  }, [id]);

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto px-4 py-16 text-center flex flex-col items-center justify-center min-h-[60vh]">
        <RefreshCw className="w-10 h-10 text-blue-400 animate-spin mb-4" />
        <p className="text-slate-300 font-medium">Încărcăm detaliile și ghidul de vizionare...</p>
      </div>
    );
  }

  if (error || !media) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 text-center">
        <div className="glass-card p-8 rounded-2xl max-w-lg mx-auto border border-slate-800">
          <AlertTriangle className="w-12 h-12 text-amber-400 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-white mb-2">Eroare încărcare</h2>
          <p className="text-slate-400 text-sm mb-6">{error || 'Media negăsită.'}</p>
          <Link
            href="/"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold text-xs transition-colors"
          >
            <ArrowLeft className="w-4 h-4" /> Înapoi la Căutare
          </Link>
        </div>
      </div>
    );
  }

  const activeWatchPath = watchOrderGuide?.paths[watchOrderMode] || [];

  const getStatusBadge = (status?: string) => {
    switch (status) {
      case 'RELEASING':
        return (
          <span className="h-7 text-xs font-bold rounded-full bg-emerald-950/80 text-emerald-400 border border-emerald-700/50 inline-flex items-center overflow-hidden">
            <span className="w-7 h-7 flex items-center justify-center shrink-0">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
            </span>
            <span className="pr-3 -ml-1.5">În difuzare (Airing)</span>
          </span>
        );
      case 'UPCOMING':
        return (
          <span className="h-7 text-xs font-bold rounded-full bg-indigo-950/80 text-indigo-400 border border-indigo-700/50 inline-flex items-center overflow-hidden">
            <span className="w-7 h-7 flex items-center justify-center shrink-0">
              <Clock className="w-3.5 h-3.5" />
            </span>
            <span className="pr-3 -ml-1.5">Sezon viitor (Upcoming)</span>
          </span>
        );
      case 'FINISHED':
        return (
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-slate-800/80 text-slate-300 border border-slate-700/50">
            Finalizat (Finished)
          </span>
        );
      default:
        return null;
    }
  };

  const getSeasonIcon = (season?: string) => {
    switch (season) {
      case 'WINTER':
        return <Snowflake className="w-3.5 h-3.5 text-cyan-400" />;
      case 'SPRING':
        return <Flower2 className="w-3.5 h-3.5 text-pink-400" />;
      case 'SUMMER':
        return <Sun className="w-3.5 h-3.5 text-amber-400" />;
      case 'FALL':
        return <Leaf className="w-3.5 h-3.5 text-orange-400" />;
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen pb-16">
      {/* Top Back Navigation Bar */}
      <div className="max-w-6xl mx-auto px-4 pt-6 pb-2">
        <Link
          href="/"
          className="h-8 inline-flex items-center text-xs font-semibold text-textSecondary hover:text-textPrimary transition-colors bg-bgSurface border border-borderSubtle rounded-full shadow-sm overflow-hidden"
        >
          <span className="w-8 h-8 flex items-center justify-center shrink-0">
            <ArrowLeft className="w-4 h-4" />
          </span>
          <span className="pr-3.5 -ml-1.5">Înapoi la Căutare & Descoperire</span>
        </Link>
      </div>

      {/* Hero Header Card */}
      <div className="max-w-6xl mx-auto px-4 mt-4">
        <div className="glass-card relative overflow-hidden rounded-3xl border border-borderSubtle p-6 sm:p-8 bg-bgSurface shadow-xl">
          {/* Subtle Ambient Background Glow */}
          <div className="absolute -top-24 -right-24 w-96 h-96 bg-accentPrimary/10 rounded-full blur-3xl pointer-events-none" />

          <div className="flex flex-col md:flex-row gap-6 lg:gap-8 relative z-10">
            {/* Poster Cover Image */}
            <div className="relative w-44 sm:w-52 h-64 sm:h-76 shrink-0 rounded-2xl overflow-hidden bg-bgSurfaceHover border border-borderSubtle shadow-xl mx-auto md:mx-0">
              <img
                src={media.coverImage.large}
                alt={media.title.userPreferred}
                className="w-full h-full object-cover"
              />
              <span className="absolute top-2 left-2 text-[10px] font-bold px-2 py-0.5 rounded bg-bgPrimary/90 text-accentPrimary backdrop-blur-md border border-accentPrimary/40 uppercase">
                {media.type}
              </span>
              {media.format && (
                <span className="absolute bottom-2 left-2 text-[10px] font-bold px-2 py-0.5 rounded bg-bgPrimary/90 text-badgeViolet backdrop-blur-md border border-badgeViolet/40">
                  {media.format}
                </span>
              )}
            </div>

            {/* Main Info Column */}
            <div className="flex-1 flex flex-col justify-between">
              <div>
                {/* Status & Badges Bar */}
                <div className="flex flex-wrap items-center gap-2 mb-3">
                  {getStatusBadge(media.status)}
                  {media.demographic && (
                    <span className="text-xs font-semibold text-signalLive bg-signalLive/10 border border-signalLive/30 px-3 py-1 rounded-full">
                      {media.demographic}
                    </span>
                  )}
                  {media.season && (
                    <span className="h-7 text-xs font-mono text-textSecondary bg-bgSurfaceHover rounded-full border border-borderSubtle inline-flex items-center overflow-hidden">
                      <span className="w-7 h-7 flex items-center justify-center shrink-0">
                        {getSeasonIcon(media.season)}
                      </span>
                      <span className="pr-3 -ml-1.5">
                        {media.year ? `${media.season} ${media.year}` : media.season}
                      </span>
                    </span>
                  )}
                </div>

                {/* Main Titles */}
                <h1 className="text-2xl sm:text-4xl font-semibold text-textPrimary leading-tight font-heading mb-1">
                  {media.title.userPreferred}
                </h1>
                {media.title.english && media.title.english !== media.title.userPreferred && (
                  <p className="text-sm text-textSecondary font-medium mb-1">{media.title.english}</p>
                )}
                {media.title.romaji && media.title.romaji !== media.title.userPreferred && (
                  <p className="text-xs text-textMuted font-mono mb-3">{media.title.romaji}</p>
                )}

                {/* Scores & Metrics Grid */}
                <div className="flex flex-wrap items-center gap-3 my-4">
                  <div className="flex items-center gap-1.5 bg-amber-500/10 text-amber-300 px-3.5 py-1.5 rounded-xl border border-amber-500/25 text-sm font-bold tabular-nums shadow-sm">
                    <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                    <span>{media.scores.averageScore}</span>
                    <span className="text-xs text-amber-500 font-normal">/10 Scor Mediu</span>
                  </div>

                  <div className="flex items-center gap-1.5 bg-emerald-500/10 text-emerald-300 px-3.5 py-1.5 rounded-xl border border-emerald-500/25 text-sm font-semibold tabular-nums">
                    <ShieldCheck className="w-4 h-4 text-emerald-400" />
                    <span>{media.scores.weightedScore}</span>
                    <span className="text-xs text-emerald-500 font-normal">Ponderat</span>
                  </div>

                  {media.episodes && (
                    <div className="flex items-center gap-1.5 bg-purple-500/10 text-purple-300 px-3.5 py-1.5 rounded-xl border border-purple-500/25 text-sm font-semibold">
                      <Tv className="w-4 h-4 text-purple-400" />
                      <span>{media.episodes} Episoade</span>
                    </div>
                  )}
                </div>

                {/* Micro-Tags Cloud */}
                {media.microTags && media.microTags.length > 0 && (
                  <div className="flex flex-wrap gap-1.5 my-3">
                    {media.microTags.map((tag) => (
                      <span
                        key={tag}
                        className="text-xs font-semibold text-amber-300 bg-amber-950/60 px-2.5 py-1 rounded-lg border border-amber-700/50"
                      >
                        ⚡ {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap items-center gap-3 pt-4 border-t border-slate-800/80 mt-2">
                {watchOrderGuide && (
                  <a
                    href="#watch-order-section"
                    className="px-5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-600/30 flex items-center gap-2 transition-all active:scale-98"
                  >
                    <Sparkles className="w-4 h-4" /> Vezi Ordinea de Vizionare
                  </a>
                )}

                {/* Interactive Watchlist Button */}
                <div className="relative group/wl">
                  <button
                    type="button"
                    onClick={handleWatchlistToggle}
                    className={`px-4 py-2.5 font-bold text-xs rounded-xl border flex items-center gap-2 transition-all ${
                      userWatchlistStatus
                        ? 'bg-blue-600/20 border-blue-500/50 text-blue-300'
                        : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                    }`}
                  >
                    <Bookmark className={`w-4 h-4 ${userWatchlistStatus ? 'text-blue-400 fill-blue-400' : 'text-blue-400'}`} />
                    <span>{userWatchlistStatus ? `Status: ${STATUS_LABELS[userWatchlistStatus] || userWatchlistStatus}` : 'Adaugă în Listă'}</span>
                  </button>

                  {/* Dropdown Options */}
                  <div className="absolute left-0 mt-1 w-44 bg-slate-900 border border-slate-800 rounded-xl shadow-2xl p-1 hidden group-hover/wl:block z-30 animate-in fade-in duration-150">
                    {['WATCHING', 'COMPLETED', 'PLAN_TO_WATCH', 'ON_HOLD', 'DROPPED'].map((st) => (
                      <button
                        key={st}
                        onClick={() => saveWatchlistStatus(st)}
                        className={`w-full text-left px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                          userWatchlistStatus === st
                            ? 'bg-blue-600 text-white'
                            : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                        }`}
                      >
                        {STATUS_LABELS[st] || st}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>


      {/* Main Content Layout: Synopsis & Genres */}
      <div className="max-w-6xl mx-auto px-4 mt-8 grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Column: Synopsis & Story Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Synopsys Box */}
          <div className="glass-card p-6 rounded-2xl border border-borderSubtle bg-bgSurface space-y-3">
            <h2 className="text-lg font-bold text-textPrimary font-heading flex items-center gap-2">
              <Info className="w-5 h-5 text-accentPrimary" /> Sinopsis & Descriere
            </h2>
            <p className="text-textSecondary text-sm leading-relaxed whitespace-pre-line">
              {media.description || 'Descrierea detaliată pentru acest titlu este în curs de actualizare.'}
            </p>
          </div>

          {/* Genres Chips Cloud */}
          <div className="glass-card p-6 rounded-2xl border border-borderSubtle bg-bgSurface space-y-3">
            <h2 className="text-sm font-bold text-textSecondary uppercase tracking-normal">Genuri & Teme</h2>
            <div className="flex flex-wrap gap-2">
              {media.genres.map((g) => (
                <span
                  key={g}
                  className="px-3 py-1 rounded-xl text-xs font-semibold bg-bgSurfaceHover text-accentPrimary border border-borderSubtle"
                >
                  {g}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Right Sidebar: Meta details */}
        <div className="space-y-6">
          <div className="glass-card p-6 rounded-2xl border border-borderSubtle bg-bgSurface space-y-4">
            <h3 className="text-sm font-bold text-textPrimary uppercase tracking-normal border-b border-borderSubtle pb-2">
              Informații Producție
            </h3>

            <div className="space-y-3 text-xs">
              <div className="flex justify-between">
                <span className="text-textSecondary">Origine:</span>
                <span className="font-bold text-textPrimary">{media.type}</span>
              </div>

              <div className="flex justify-between">
                <span className="text-textSecondary">Format Lansare:</span>
                <span className="font-bold text-textPrimary">{media.format || 'TV'}</span>
              </div>

              <div className="flex justify-between">
                <span className="text-textSecondary">Episoade:</span>
                <span className="font-bold text-textPrimary">{media.episodes || 'N/A'}</span>
              </div>

              <div className="flex justify-between">
                <span className="text-textSecondary">Status:</span>
                <span className="font-bold text-signalLive">{media.status}</span>
              </div>

              <div className="flex justify-between">
                <span className="text-textSecondary">Sursă Date:</span>
                <span className="font-mono text-accentPrimary">{media.source}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* MULTI-PATH WATCH ORDER ENGINE SECTION */}
      {watchOrderGuide && (
        <div id="watch-order-section" className="max-w-6xl mx-auto px-4 mt-12">
          <div className="glass-card p-6 sm:p-8 rounded-3xl border border-borderSubtle bg-bgSurface shadow-xl relative overflow-hidden">
            {/* Header Title */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-2xl bg-accentPrimary/10 border border-accentPrimary/20 text-accentPrimary">
                  <Compass className="w-7 h-7" />
                </div>
                <div>
                  <h2 className="text-xl sm:text-2xl font-bold text-textPrimary font-heading flex flex-wrap items-center gap-2">
                    Ghid & Ordine de Vizionare: <span className="text-accentPrimary">{watchOrderGuide.franchiseName}</span>
                    <span className="text-[10px] font-bold font-mono px-2.5 py-0.5 rounded-full bg-scoreGold/20 text-scoreGold border border-scoreGold/40 uppercase tracking-normal">
                      BETA
                    </span>
                  </h2>
                  <p className="text-xs text-textSecondary">{watchOrderGuide.description}</p>
                </div>
              </div>

              {/* Multi-Path View Mode Tabs */}
              <div className="flex items-center p-1 rounded-2xl bg-bgPrimary border border-borderSubtle shrink-0">
                <button
                  type="button"
                  onClick={() => setWatchOrderMode('RECOMMENDED')}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                    watchOrderMode === 'RECOMMENDED'
                      ? 'bg-accentPrimary text-white shadow-md'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                >
                  ✨ Recomandată
                </button>
                <button
                  type="button"
                  onClick={() => setWatchOrderMode('CHRONOLOGICAL')}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                    watchOrderMode === 'CHRONOLOGICAL'
                      ? 'bg-accentPrimary text-white shadow-md'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                >
                  ⏳ Cronologică
                </button>
                <button
                  type="button"
                  onClick={() => setWatchOrderMode('RELEASE')}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                    watchOrderMode === 'RELEASE'
                      ? 'bg-accentPrimary text-white shadow-md'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                >
                  📅 Data Lansării
                </button>
              </div>
            </div>

            {/* Community Tip & Warning Box */}
            {watchOrderGuide.communityTip && (
              <div className="p-4 rounded-2xl bg-blue-950/50 border border-blue-800/60 mb-8 flex gap-3 items-start text-xs sm:text-sm text-blue-200">
                <Sparkles className="w-5 h-5 text-blue-400 shrink-0 mt-0.5" />
                <div className="leading-relaxed">{watchOrderGuide.communityTip}</div>
              </div>
            )}

            {/* Timeline Nodes Chain */}
            <div className="space-y-4 relative">
              <div className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 flex items-center gap-2">
                <span>
                  Traseu de vizionare ({watchOrderMode === 'RECOMMENDED' ? 'Ordinea Recomandată de Comunitate' : watchOrderMode === 'CHRONOLOGICAL' ? 'Ordinea Cronologică din Univers' : 'Ordinea Lansării Studio'}):
                </span>
              </div>

              <div className="grid grid-cols-1 gap-4">
                {activeWatchPath.map((node, index) => {
                  const isCurrent = node.mediaId === id;
                  return (
                    <div
                      key={node.id}
                      className={`p-4 rounded-2xl border transition-all flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 ${
                        isCurrent
                          ? 'bg-blue-950/70 border-blue-500 shadow-lg shadow-blue-500/20 ring-1 ring-blue-500'
                          : 'bg-slate-900/80 border-slate-800 hover:border-slate-700'
                      }`}
                    >
                      <div className="flex items-center gap-4">
                        {/* Order Number Badge */}
                        <div
                          className={`w-9 h-9 rounded-xl font-mono text-sm font-extrabold flex items-center justify-center shrink-0 ${
                            isCurrent
                              ? 'bg-blue-500 text-white shadow-md'
                              : 'bg-slate-800 text-slate-300 border border-slate-700'
                          }`}
                        >
                          #{node.orderIndex}
                        </div>

                        {/* Node Cover Thumbnail */}
                        {node.coverImage && (
                          <img
                            src={node.coverImage}
                            alt={node.title}
                            className="w-12 h-16 object-cover rounded-lg shrink-0 bg-slate-800 border border-slate-700"
                          />
                        )}

                        {/* Node Details */}
                        <div>
                          <div className="flex items-center gap-2 mb-1 flex-wrap">
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-slate-950 text-blue-300 uppercase border border-blue-500/30">
                              {node.type}
                            </span>
                            {node.episodesInfo && (
                              <span className="text-[11px] font-medium text-slate-400">
                                {node.episodesInfo}
                              </span>
                            )}
                            {node.releaseYear && (
                              <span className="text-[11px] font-mono text-slate-500">
                                ({node.releaseYear})
                              </span>
                            )}
                          </div>
                          <h3 className="font-bold text-white text-sm sm:text-base leading-snug">
                            {node.title}
                          </h3>
                          {node.note && (
                            <p className="text-xs text-amber-300/90 mt-1 flex items-center gap-1">
                              <Info className="w-3 h-3 text-amber-400 shrink-0" />
                              {node.note}
                            </p>
                          )}
                        </div>
                      </div>

                      {/* Action to view node details */}
                      {isCurrent ? (
                        <span className="text-xs font-extrabold text-blue-400 bg-blue-900/60 px-3 py-1.5 rounded-xl border border-blue-700/50 self-end sm:self-center shrink-0">
                          Titlul Curent
                        </span>
                      ) : (
                        <Link
                          href={`/media/${node.mediaId}`}
                          className="text-xs font-bold text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 px-4 py-2 rounded-xl border border-slate-700 transition-colors flex items-center gap-1 self-end sm:self-center shrink-0"
                        >
                          Vezi Titlul <ChevronRight className="w-3.5 h-3.5" />
                        </Link>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Spin-offs & Alternate Universes Section */}
            {watchOrderGuide.spinOffs && watchOrderGuide.spinOffs.length > 0 && (
              <div className="mt-10 pt-8 border-t border-slate-800">
                <h3 className="text-sm font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center gap-2">
                  <Layers className="w-4 h-4 text-purple-400" /> Spin-off-uri & Universuri Paralele Opționale
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {watchOrderGuide.spinOffs.map((spinOff) => (
                    <div
                      key={spinOff.id}
                      className="p-3.5 rounded-2xl bg-slate-900/60 border border-slate-800/80 flex gap-3 items-center"
                    >
                      {spinOff.coverImage && (
                        <img
                          src={spinOff.coverImage}
                          alt={spinOff.title}
                          className="w-12 h-16 object-cover rounded-lg shrink-0 bg-slate-800"
                        />
                      )}
                      <div className="flex-1 min-w-0">
                        <span className="text-[9px] font-bold px-2 py-0.5 rounded bg-purple-950 text-purple-300 border border-purple-800/50 uppercase">
                          Spin-off
                        </span>
                        <h4 className="font-bold text-slate-200 text-xs truncate mt-1">{spinOff.title}</h4>
                        {spinOff.note && <p className="text-[11px] text-slate-400 truncate">{spinOff.note}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* SIMILAR RECOMMENDED MEDIA SECTION */}
      {similarData && similarData.similarItems.length > 0 && (
        <div className="max-w-6xl mx-auto px-4 mt-12">
          <h2 className="text-lg sm:text-xl font-bold text-textPrimary font-heading mb-4 flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-accentPrimary" /> Recomandări Similare
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {similarData.similarItems.map(({ item, similarityScore }) => (
              <Link
                key={item.id}
                href={`/media/${item.id}`}
                className="glass-card p-4 rounded-2xl border border-borderSubtle bg-bgSurface flex gap-4 group hover:border-accentPrimary/50 transition-all shadow-sm"
              >
                <img
                  src={item.coverImage.large || item.coverImage.medium}
                  alt={item.title.userPreferred}
                  className="w-20 h-28 object-cover rounded-xl shrink-0 bg-bgSurfaceHover"
                />
                <div className="flex-1 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-signalLive/10 text-signalLive border border-signalLive/30">
                        {similarityScore}% potrivire
                      </span>
                      <span className="text-xs font-bold text-scoreGold flex items-center gap-0.5">
                        <Star className="w-3 h-3 fill-scoreGold" /> {item.scores.averageScore}
                      </span>
                    </div>
                    <h3 className="font-bold text-textPrimary text-sm leading-snug line-clamp-2 group-hover:text-accentPrimary transition-colors">
                      {item.title.userPreferred}
                    </h3>
                  </div>
                  <div className="text-[11px] text-textSecondary truncate mt-1">
                    {item.type} • {item.format || 'TV'}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      <AuthModal
        isOpen={isAuthOpen}
        onClose={() => setIsAuthOpen(false)}
        onSuccess={() => {
          checkUserWatchlistStatus();
        }}
      />
    </div>
  );
}


'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Sparkles,
  Star,
  Flame,
  Zap,
  Heart,
  Compass,
  Bookmark,
  SlidersHorizontal,
} from 'lucide-react';
import { MediaItem } from '@kurogane/shared';

const API_BASE = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000') + '/api';

export default function RecommendationsPage() {
  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedMood, setSelectedMood] = useState('ALL');
  const [savedWatchlistIds, setSavedWatchlistIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    // Load local watchlist
    try {
      const saved = localStorage.getItem('kurogane-watchlist');
      if (saved) {
        const parsed = JSON.parse(saved);
        setSavedWatchlistIds(new Set(parsed.map((item: any) => item.mediaId)));
      }
    } catch (e) {}

    // Fetch recommendations / top rated
    async function fetchRecs() {
      try {
        setLoading(true);
        const res = await fetch(`${API_BASE}/homepage`);
        if (res.ok) {
          const data = await res.json();
          const recMedia = (data.recommendations || []).map((r: any) => r.media).filter(Boolean);
          setItems(recMedia.length > 0 ? recMedia : data.top100?.slice(0, 20) || []);
        }
      } catch (err) {
        console.error('Failed to fetch recommendations:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchRecs();
  }, []);

  const toggleWatchlist = (mediaId: string) => {
    const next = new Set(savedWatchlistIds);
    if (next.has(mediaId)) {
      next.delete(mediaId);
    } else {
      next.add(mediaId);
    }
    setSavedWatchlistIds(next);
  };

  const moods = [
    { id: 'ALL', label: 'Toate Recomandările' },
    { id: 'ACTION', label: '⚔️ Adrenalină & Acțiune' },
    { id: 'EMOTIONAL', label: '💖 Emoție & Dramă' },
    { id: 'MIND', label: '🧠 Psihologic & Mister' },
    { id: 'CHILL', label: '🌿 Relaxare & Slice of Life' },
  ];

  return (
    <div className="max-w-6xl mx-auto px-4 pt-4 sm:pt-8 space-y-8">
      {/* Hero Header */}
      <div className="relative rounded-3xl overflow-hidden bg-bgSurface border border-borderSubtle p-6 sm:p-10 shadow-xl">
        <div className="relative z-10 max-w-2xl space-y-3">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-badgeViolet/10 border border-badgeViolet/20 text-badgeViolet text-xs font-semibold">
            <Sparkles className="w-3.5 h-3.5 text-scoreGold" />
            Algoritm Inteligent de Recomandare
          </div>
          <h1 className="text-2xl sm:text-4xl font-bold font-heading text-textPrimary">
            Recomandări Personalizate & Selecții de Top
          </h1>
          <p className="text-sm text-textSecondary leading-relaxed">
            Descoperă titluri bazate pe calitatea producției, recenzii verificate și compatibilitatea de gen fără algoritmi de promovare plătită.
          </p>
        </div>
      </div>

      {/* Mood Filters */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
        {moods.map((m) => (
          <button
            key={m.id}
            onClick={() => setSelectedMood(m.id)}
            className={`px-4 py-2 rounded-full text-xs font-semibold whitespace-nowrap transition-all border ${
              selectedMood === m.id
                ? 'bg-accentPrimary text-white border-accentPrimary shadow-md'
                : 'bg-bgSurface text-textSecondary border-borderSubtle hover:border-accentPrimary/40 hover:text-textPrimary'
            }`}
          >
            {m.label}
          </button>
        ))}
      </div>

      {/* Media Grid */}
      {loading ? (
        <div className="h-64 flex items-center justify-center text-textSecondary gap-3">
          <div className="w-6 h-6 border-2 border-accentPrimary border-t-transparent rounded-full animate-spin" />
          <span className="text-xs">Se generează recomandările...</span>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {items.map((item) => (
            <div
              key={item.id}
              className="group bg-bgSurface rounded-2xl overflow-hidden border border-borderSubtle hover:border-badgeViolet/50 transition-all duration-300 flex flex-col justify-between shadow-sm"
            >
              <div className="relative aspect-[3/4] bg-bgSurfaceHover overflow-hidden">
                <img
                  src={item.coverImage.large}
                  alt={item.title.userPreferred}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />

                {/* Rating Badge */}
                {item.scores.averageScore > 0 && (
                  <div className="absolute top-2 left-2 px-2 py-0.5 rounded-lg bg-bgPrimary/85 backdrop-blur-md border border-borderSubtle text-scoreGold text-[11px] font-medium flex items-center gap-1 shadow-sm">
                    <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                    {item.scores.averageScore}
                  </div>
                )}

                {/* Quick Watchlist Toggle (Always visible Bookmark Save Button) */}
                <button
                  onClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    toggleWatchlist(item.id);
                  }}
                  className={`absolute top-2 right-2 w-7 h-7 rounded-lg flex items-center justify-center backdrop-blur-md transition-all shadow-md active:scale-90 z-20 ${
                    savedWatchlistIds.has(item.id)
                      ? 'bg-accentPrimary text-white shadow-accentPrimary/25'
                      : 'bg-black/60 hover:bg-accentPrimary text-white/90 hover:text-white border border-white/15'
                  }`}
                  aria-label={savedWatchlistIds.has(item.id) ? 'Elimină din Watchlist' : 'Adaugă în Watchlist'}
                  title={savedWatchlistIds.has(item.id) ? 'În Watchlist' : 'Adaugă în Watchlist'}
                >
                  <Bookmark className={`w-3.5 h-3.5 transition-colors ${savedWatchlistIds.has(item.id) ? 'fill-white' : ''}`} />
                </button>
              </div>

              <div className="p-3 flex flex-col justify-between flex-1 space-y-2">
                <div>
                  <h3 className="text-xs font-semibold text-textPrimary line-clamp-2 group-hover:text-badgeViolet transition-colors leading-snug">
                    {item.title.userPreferred}
                  </h3>
                  {item.genres && item.genres.length > 0 && (
                    <p className="text-[10px] text-textSecondary mt-1 truncate">
                      {item.genres.slice(0, 2).join(' • ')}
                    </p>
                  )}
                </div>

                <Link
                  href={`/media/${item.id}`}
                  className="w-full py-1.5 rounded-xl bg-bgSurfaceHover hover:bg-badgeViolet text-textSecondary hover:text-white text-[11px] font-semibold text-center transition-colors block"
                >
                  Vezi Recomandarea
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

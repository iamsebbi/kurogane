'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import Link from 'next/link';
import {
  Search,
  X,
  Star,
  Film,
  Sparkles,
  ArrowRight,
  TrendingUp,
  Clock,
  Command,
} from 'lucide-react';
import { MediaItem, MediaType } from '@kurogane/shared';

interface SearchModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const QUICK_SUGGESTIONS = [
  'Solo Leveling',
  'Jujutsu Kaisen',
  'Attack on Titan',
  'Frieren',
  'Demon Slayer',
  'Chainsaw Man',
  'One Piece',
];

export function SearchModal({ isOpen, onClose }: SearchModalProps) {
  const [query, setQuery] = useState('');
  const [selectedType, setSelectedType] = useState<string>('ALL');
  const [results, setResults] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const modalRef = useRef<HTMLDivElement>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  // Focus input on open
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => {
        inputRef.current?.focus();
      }, 50);
    } else {
      setQuery('');
      setResults([]);
    }
  }, [isOpen]);

  // Global Escape & Cmd+K handler
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  // Search logic
  const performSearch = useCallback(
    async (searchQuery: string, typeFilter: string) => {
      if (!searchQuery.trim()) {
        setResults([]);
        setLoading(false);
        return;
      }

      if (abortControllerRef.current) abortControllerRef.current.abort();
      const controller = new AbortController();
      abortControllerRef.current = controller;

      setLoading(true);
      try {
        const params = new URLSearchParams({
          q: searchQuery.trim(),
          type: typeFilter,
          limit: '20',
        });
        const res = await fetch(`http://localhost:4000/api/search?${params.toString()}`, {
          signal: controller.signal,
        });
        if (res.ok && !controller.signal.aborted) {
          const data = await res.json();
          setResults(data.results || []);
        }
      } catch (err: any) {
        if (err?.name !== 'AbortError') {
          console.error('Search error:', err);
        }
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    },
    []
  );

  // Debounced search trigger
  useEffect(() => {
    if (query.trim().length > 0) {
      const timer = setTimeout(() => performSearch(query, selectedType), 200);
      return () => clearTimeout(timer);
    } else {
      setResults([]);
    }
  }, [query, selectedType, performSearch]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-16 sm:pt-24 p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200"
      onClick={(e) => {
        if (modalRef.current && !modalRef.current.contains(e.target as Node)) {
          onClose();
        }
      }}
    >
      <div
        ref={modalRef}
        className="w-full max-w-3xl bg-bgSurface border border-borderSubtle rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[80vh] animate-in zoom-in-95 duration-200"
      >
        {/* TOP SEARCH INPUT BAR */}
        <div className="p-4 sm:p-5 border-b border-borderSubtle flex items-center gap-3 bg-bgSurface">
          <Search className="w-5 h-5 text-accentPrimary shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Caută după titlu, acronim (ex: aot, jjk), studio sau gen..."
            className="flex-1 bg-transparent text-sm sm:text-base text-textPrimary placeholder-textMuted focus:outline-none"
          />
          {query && (
            <button
              type="button"
              onClick={() => {
                setQuery('');
                inputRef.current?.focus();
              }}
              className="p-1 rounded-full text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover transition-colors"
              aria-label="Șterge"
            >
              <X className="w-4 h-4" />
            </button>
          )}
          <button
            onClick={onClose}
            className="px-2.5 py-1 rounded-lg bg-bgPrimary text-textSecondary border border-borderSubtle text-[11px] font-medium hidden sm:inline-flex items-center gap-1"
          >
            <kbd>ESC</kbd>
          </button>
        </div>

        {/* TYPE FILTER PILLS */}
        <div className="px-5 py-2.5 bg-bgPrimary/40 border-b border-borderSubtle flex items-center gap-2 overflow-x-auto scrollbar-none">
          {['ALL', 'ANIME', 'MANGA', 'DONGHUA', 'WEBTOON'].map((type) => (
            <button
              key={type}
              type="button"
              onClick={() => setSelectedType(type)}
              className={`px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                selectedType === type
                  ? 'bg-accentPrimary text-white shadow-sm'
                  : 'text-textSecondary hover:text-textPrimary hover:bg-bgSurface'
              }`}
            >
              {type === 'ALL' ? 'Toate Categoriile' : type}
            </button>
          ))}
        </div>

        {/* BODY AREA: RESULTS OR SUGGESTIONS */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4">
          {loading ? (
            <div className="py-12 flex flex-col items-center justify-center text-textSecondary gap-2">
              <div className="w-6 h-6 border-2 border-accentPrimary border-t-transparent rounded-full animate-spin" />
              <span className="text-xs">Se caută în peste 41.500+ titluri...</span>
            </div>
          ) : query.trim().length > 0 && results.length === 0 ? (
            <div className="py-12 text-center text-textSecondary space-y-2">
              <p className="text-sm font-semibold text-textPrimary">Nu am găsit rezultate pentru &quot;{query}&quot;</p>
              <p className="text-xs">Încearcă alte cuvinte cheie, acronime sau verifică ortografia.</p>
            </div>
          ) : results.length > 0 ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {results.map((item) => (
                <Link
                  key={item.id}
                  href={`/media/${item.id}`}
                  onClick={onClose}
                  className="group bg-bgPrimary/60 hover:bg-bgSurfaceHover/80 p-3 rounded-2xl border border-borderSubtle/60 hover:border-accentPrimary/50 transition-all flex items-center gap-3.5 shadow-sm"
                >
                  <img
                    src={item.coverImage.large}
                    alt={item.title.english || item.title.userPreferred || item.title.romaji}
                    className="w-12 h-16 rounded-xl object-cover bg-bgSurface shrink-0 group-hover:scale-105 transition-transform"
                  />
                  <div className="min-w-0 flex-1 space-y-1">
                    <div className="flex items-center gap-1.5">
                      <span className="px-1.5 py-0.5 rounded bg-accentPrimary/10 text-accentPrimary text-[9px] font-semibold uppercase">
                        {item.type}
                      </span>
                      {item.scores?.averageScore > 0 && (
                        <span className="text-scoreGold text-[11px] font-semibold flex items-center gap-0.5">
                          <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                          {item.scores.averageScore}
                        </span>
                      )}
                    </div>
                    <h4 className="text-xs font-semibold text-textPrimary truncate group-hover:text-accentPrimary transition-colors">
                      {item.title.english || item.title.userPreferred || item.title.romaji}
                    </h4>
                    <p className="text-[11px] text-textSecondary truncate">
                      {item.year || '2026'} {item.format ? `• ${item.format}` : ''}
                      {item.genres && item.genres.length > 0 ? ` • ${item.genres[0]}` : ''}
                    </p>
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            /* DEFAULT EMPTY SEARCH: QUICK SUGGESTIONS */
            <div className="space-y-4 py-2">
              <div className="flex items-center gap-2 text-xs font-semibold text-textSecondary">
                <Sparkles className="w-4 h-4 text-scoreGold" /> Căutări Populare
              </div>
              <div className="flex flex-wrap gap-2">
                {QUICK_SUGGESTIONS.map((sug) => (
                  <button
                    key={sug}
                    type="button"
                    onClick={() => {
                      setQuery(sug);
                    }}
                    className="px-3.5 py-1.5 rounded-xl bg-bgPrimary hover:bg-bgSurfaceHover border border-borderSubtle text-xs text-textSecondary hover:text-textPrimary transition-all flex items-center gap-1.5"
                  >
                    <Search className="w-3 h-3 text-accentPrimary" />
                    <span>{sug}</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* FOOTER SHORTCUT HINT */}
        <div className="px-5 py-3 bg-bgPrimary/60 border-t border-borderSubtle text-[11px] text-textSecondary flex items-center justify-between">
          <span className="flex items-center gap-1.5">
            <Command className="w-3.5 h-3.5 text-accentPrimary" />
            <span>Apasă <kbd className="font-mono text-textPrimary">ESC</kbd> pentru a închide</span>
          </span>
          <span className="text-textMuted">Kurogane Inverted Search Engine</span>
        </div>
      </div>
    </div>
  );
}

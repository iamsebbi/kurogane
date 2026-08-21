'use client';

import React, { useState, useEffect, useRef, useCallback, useMemo, Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  Search,
  X,
  Star,
  SlidersHorizontal,
  RotateCcw,
  LayoutGrid,
  List,
  ChevronLeft,
  ChevronRight,
  Compass,
} from 'lucide-react';
import {
  MediaItem,
  SortOption,
} from '@kurogane/shared';
import { gsap, useGSAP } from '@/lib/gsap';
import { API_BASE_URL } from '@/lib/api';

const ALPHABET = [
  'TOATE', '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K',
  'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

const GENRES_LIST = [
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Fantasy',
  'Horror',
  'Mystery',
  'Psychological',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
];

const MICRO_TAGS_LIST = [
  'Isekai',
  'Magic',
  'Martial Arts',
  'Mecha',
  'School',
  'Super Power',
  'Time Travel',
  'Vampire',
  'Cyberpunk',
  'Music',
  'Demons',
  'Military',
];

function MediaCatalogContent() {
  const searchParams = useSearchParams();
  const router = useRouter();

  // Search and Filter States
  const [query, setQuery] = useState(searchParams.get('q') || '');
  const [selectedLetter, setSelectedLetter] = useState<string>('TOATE');
  const [selectedSort, setSelectedSort] = useState<SortOption>('SCORE_DESC'); // Default by RATING / SCORE!
  const [selectedType, setSelectedType] = useState<string>(searchParams.get('type') || 'ALL');
  const [selectedFormat, setSelectedFormat] = useState<string>(searchParams.get('format') || 'ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>(searchParams.get('status') || 'ALL');
  const [selectedDemographic, setSelectedDemographic] = useState<string>('ALL');
  const [selectedSeason, setSelectedSeason] = useState<string>('ALL');
  const [selectedYear, setSelectedYear] = useState<string>('ALL');
  const [selectedGenres, setSelectedGenres] = useState<string[]>([]);
  const [selectedMicroTags, setSelectedMicroTags] = useState<string[]>([]);
  const [minScore, setMinScore] = useState<number>(0);

  // View Mode: Grid or List
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  // Data state
  const [items, setItems] = useState<MediaItem[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(24);
  const [loading, setLoading] = useState(true);

  const gridContainerRef = useRef<HTMLDivElement>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  // Fetch Catalog Media
  const fetchMedia = useCallback(async () => {
    if (abortControllerRef.current) abortControllerRef.current.abort();
    const controller = new AbortController();
    abortControllerRef.current = controller;

    setLoading(true);

    try {
      let effectiveQuery = query.trim();
      if (selectedLetter !== 'TOATE' && !effectiveQuery) {
        if (selectedLetter !== '#') {
          effectiveQuery = selectedLetter;
        }
      }

      const params = new URLSearchParams({
        q: effectiveQuery,
        type: selectedType,
        format: selectedFormat,
        status: selectedStatus,
        demographic: selectedDemographic,
        season: selectedSeason,
        year: selectedYear,
        sortBy: selectedSort,
        limit: String(pageSize),
        page: String(page),
      });

      if (selectedGenres.length > 0) {
        params.set('genres', selectedGenres.join(','));
      }
      if (selectedMicroTags.length > 0) {
        params.set('microTags', selectedMicroTags.join(','));
      }
      if (minScore > 0) {
        params.set('minScore', String(minScore));
      }

      const res = await fetch(`${API_BASE_URL}/api/search?${params.toString()}`, {
        signal: controller.signal,
      });

      if (res.ok) {
        const data = await res.json();
        setItems(data.items || []);
        setTotal(data.total || 0);
      }
    } catch (err: any) {
      if (err?.name !== 'AbortError') {
        console.error('Fetch catalog error:', err);
      }
    } finally {
      if (!controller.signal.aborted) {
        setLoading(false);
      }
    }
  }, [
    query,
    selectedLetter,
    selectedType,
    selectedFormat,
    selectedStatus,
    selectedDemographic,
    selectedSeason,
    selectedYear,
    selectedSort,
    selectedGenres,
    selectedMicroTags,
    minScore,
    page,
    pageSize,
  ]);

  // Trigger search on filter changes
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchMedia();
    }, 150);
    return () => clearTimeout(timer);
  }, [fetchMedia]);

  // GSAP animation for staggered card entry
  useGSAP(
    () => {
      if (!loading && items.length > 0 && gridContainerRef.current) {
        gsap.from('.catalog-card', {
          opacity: 0,
          y: 20,
          stagger: 0.03,
          duration: 0.4,
          ease: 'power2.out',
        });
      }
    },
    { dependencies: [items, loading, viewMode], scope: gridContainerRef }
  );

  const toggleGenre = (genre: string) => {
    setPage(1);
    setSelectedGenres((prev) =>
      prev.includes(genre) ? prev.filter((g) => g !== genre) : [...prev, genre]
    );
  };

  const toggleMicroTag = (tag: string) => {
    setPage(1);
    setSelectedMicroTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const handleResetFilters = () => {
    setQuery('');
    setSelectedLetter('TOATE');
    setSelectedSort('SCORE_DESC');
    setSelectedType('ALL');
    setSelectedFormat('ALL');
    setSelectedStatus('ALL');
    setSelectedDemographic('ALL');
    setSelectedSeason('ALL');
    setSelectedYear('ALL');
    setSelectedGenres([]);
    setSelectedMicroTags([]);
    setMinScore(0);
    setPage(1);
  };

  const activeFiltersCount = useMemo(() => {
    let count = 0;
    if (query.trim()) count++;
    if (selectedLetter !== 'TOATE') count++;
    if (selectedType !== 'ALL') count++;
    if (selectedFormat !== 'ALL') count++;
    if (selectedStatus !== 'ALL') count++;
    if (selectedDemographic !== 'ALL') count++;
    if (selectedSeason !== 'ALL') count++;
    if (selectedYear !== 'ALL') count++;
    if (selectedGenres.length > 0) count += selectedGenres.length;
    if (selectedMicroTags.length > 0) count += selectedMicroTags.length;
    if (minScore > 0) count++;
    return count;
  }, [
    query,
    selectedLetter,
    selectedType,
    selectedFormat,
    selectedStatus,
    selectedDemographic,
    selectedSeason,
    selectedYear,
    selectedGenres,
    selectedMicroTags,
    minScore,
  ]);

  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="min-h-screen bg-bgPrimary text-textPrimary font-sans pb-24">
      {/* 1. HEADER SECTION (MAX-W-1920PX & PADDING) */}
      <div className="border-b border-borderSubtle bg-bgSurface pt-10 sm:pt-12 md:pt-14 pb-6 px-4 md:px-12">
        <div className="max-w-[1920px] mx-auto space-y-5">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 text-accentPrimary text-xs font-bold uppercase tracking-wider mb-1">
                <Compass className="w-4 h-4" />
                <span>Catalog Complet & Explorator</span>
              </div>
              <h1 className="text-2xl sm:text-3xl font-extrabold font-heading tracking-tight text-textPrimary">
                Toate Titlurile Anime & Manga
              </h1>
              <p className="text-xs sm:text-sm text-textSecondary mt-1">
                Explorează întreaga bază de date ordonată după cele mai mari scoruri și recenzii, cu filtre avansate.
              </p>
            </div>

            {/* Quick stats badge */}
            <div className="flex items-center gap-3 self-start md:self-auto">
              <div className="px-4 py-2 rounded-full bg-bgSurfaceHover border border-borderSubtle text-xs font-semibold flex items-center gap-2 shadow-sm">
                <span className="w-2 h-2 rounded-full bg-signalLive animate-pulse" />
                <span>
                  {loading ? 'Se caută...' : `${total.toLocaleString()} Titluri Găsite`}
                </span>
              </div>

              {/* View Mode Toggle */}
              <div className="flex items-center bg-bgSurfaceHover border border-borderSubtle rounded-full p-1">
                <button
                  type="button"
                  onClick={() => setViewMode('grid')}
                  className={`p-1.5 rounded-full transition-all ${
                    viewMode === 'grid'
                      ? 'bg-accentPrimary text-white shadow-sm'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                  aria-label="Vizualizare Grilă"
                  title="Grilă"
                >
                  <LayoutGrid className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setViewMode('list')}
                  className={`p-1.5 rounded-full transition-all ${
                    viewMode === 'list'
                      ? 'bg-accentPrimary text-white shadow-sm'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                  aria-label="Vizualizare Listă"
                  title="Listă"
                >
                  <List className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>

          {/* 2. ALPHABET JUMP BAR (A-Z) */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 pt-1 scrollbar-none">
            {ALPHABET.map((letter) => (
              <button
                key={letter}
                type="button"
                onClick={() => {
                  setSelectedLetter(letter);
                  setPage(1);
                }}
                className={`h-8 px-2.5 sm:px-3 text-xs font-bold rounded-full transition-all duration-200 shrink-0 ${
                  selectedLetter === letter
                    ? 'bg-accentPrimary text-white shadow-md scale-105'
                    : 'bg-bgSurfaceHover hover:bg-bgSurface text-textSecondary hover:text-textPrimary border border-borderSubtle'
                }`}
              >
                {letter}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* MAIN CONTAINER (SIDEBAR FILTERS + RESULTS GRID) */}
      <div className="max-w-[1920px] mx-auto px-4 md:px-12 pt-8">
        <div className="grid grid-cols-1 md:grid-cols-8 lg:grid-cols-12 gap-5 md:gap-6 lg:gap-8">
          
          {/* LEFT SIDEBAR: FILTERS */}
          <aside className="md:col-span-3 lg:col-span-3 space-y-6">
            <div className="bg-bgSurface border border-borderSubtle rounded-3xl p-5 sm:p-6 shadow-sm space-y-6 sticky top-24">
              {/* Top Filter Header */}
              <div className="flex items-center justify-between pb-3 border-b border-borderSubtle">
                <div className="flex items-center gap-2 font-bold text-sm text-textPrimary">
                  <SlidersHorizontal className="w-4 h-4 text-accentPrimary" />
                  <span>Filtre Avansate</span>
                  {activeFiltersCount > 0 && (
                    <span className="px-2 py-0.5 rounded-full bg-accentPrimary text-white text-[10px] font-extrabold">
                      {activeFiltersCount}
                    </span>
                  )}
                </div>
                {activeFiltersCount > 0 && (
                  <button
                    type="button"
                    onClick={handleResetFilters}
                    className="text-xs text-textSecondary hover:text-accentPrimary flex items-center gap-1 transition-colors"
                  >
                    <RotateCcw className="w-3 h-3" /> Resetează
                  </button>
                )}
              </div>

              {/* SEARCH INPUT */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-textSecondary block">Căutare Text / Titlu</label>
                <div className="relative flex items-center">
                  <Search className="absolute left-3.5 w-4 h-4 text-textSecondary pointer-events-none" />
                  <input
                    type="text"
                    value={query}
                    onChange={(e) => {
                      setQuery(e.target.value);
                      setPage(1);
                    }}
                    placeholder="ex: Jujutsu, Solo, Titan..."
                    className="w-full pl-10 pr-9 py-2.5 bg-bgPrimary text-textPrimary placeholder-textMuted rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary transition-all shadow-inner"
                  />
                  {query && (
                    <button
                      type="button"
                      onClick={() => setQuery('')}
                      className="absolute right-3 p-0.5 text-textSecondary hover:text-textPrimary"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>
              </div>

              {/* SORT DROPDOWN */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-textSecondary block">Sortare</label>
                <select
                  value={selectedSort}
                  onChange={(e) => {
                    setSelectedSort(e.target.value as SortOption);
                    setPage(1);
                  }}
                  className="w-full px-3.5 py-2.5 bg-bgPrimary text-textPrimary rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary transition-all font-semibold"
                >
                  <option value="SCORE_DESC">⭐ Scor / Rating (Cel mai Mare)</option>
                  <option value="POPULARITY_DESC">🔥 Popularitate (Cele mai Urmărite)</option>
                  <option value="TITLE_ASC">🔤 Alfabetic (A-Z)</option>
                  <option value="YEAR_DESC">📅 Anul Lansării (Nou → Vechi)</option>
                  <option value="YEAR_ASC">⏳ Anul Lansării (Vechi → Nou)</option>
                  <option value="RELEVANCE">🎯 Relevanță Căutare</option>
                </select>
              </div>

              {/* MEDIA TYPE & FORMAT */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-textSecondary block">Tip Media</label>
                  <select
                    value={selectedType}
                    onChange={(e) => {
                      setSelectedType(e.target.value);
                      setPage(1);
                    }}
                    className="w-full px-3 py-2 bg-bgPrimary text-textPrimary rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary"
                  >
                    <option value="ALL">Toate</option>
                    <option value="ANIME">Anime</option>
                    <option value="MANGA">Manga</option>
                    <option value="DONGHUA">Donghua</option>
                    <option value="MANHWA">Manhwa</option>
                    <option value="NOVEL">Light Novel</option>
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-textSecondary block">Format</label>
                  <select
                    value={selectedFormat}
                    onChange={(e) => {
                      setSelectedFormat(e.target.value);
                      setPage(1);
                    }}
                    className="w-full px-3 py-2 bg-bgPrimary text-textPrimary rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary"
                  >
                    <option value="ALL">Toate</option>
                    <option value="TV">Serial TV</option>
                    <option value="MOVIE">Film (Movie)</option>
                    <option value="OVA">OVA</option>
                    <option value="ONA">ONA</option>
                    <option value="SPECIAL">Special</option>
                  </select>
                </div>
              </div>

              {/* STATUS & SEASON */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-textSecondary block">Stare (Status)</label>
                  <select
                    value={selectedStatus}
                    onChange={(e) => {
                      setSelectedStatus(e.target.value);
                      setPage(1);
                    }}
                    className="w-full px-3 py-2 bg-bgPrimary text-textPrimary rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary"
                  >
                    <option value="ALL">Toate</option>
                    <option value="RELEASING">În Difuzare</option>
                    <option value="FINISHED">Finalizat</option>
                    <option value="UPCOMING">Viitor</option>
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-textSecondary block">Sezon</label>
                  <select
                    value={selectedSeason}
                    onChange={(e) => {
                      setSelectedSeason(e.target.value);
                      setPage(1);
                    }}
                    className="w-full px-3 py-2 bg-bgPrimary text-textPrimary rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary"
                  >
                    <option value="ALL">Toate</option>
                    <option value="WINTER">Iarnă</option>
                    <option value="SPRING">Primăvară</option>
                    <option value="SUMMER">Vară</option>
                    <option value="FALL">Toamnă</option>
                  </select>
                </div>
              </div>

              {/* DEMOGRAPHIC & MIN SCORE */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-textSecondary block">Demografie</label>
                  <select
                    value={selectedDemographic}
                    onChange={(e) => {
                      setSelectedDemographic(e.target.value);
                      setPage(1);
                    }}
                    className="w-full px-3 py-2 bg-bgPrimary text-textPrimary rounded-full text-xs border border-borderSubtle focus:outline-none focus:ring-2 focus:ring-accentPrimary"
                  >
                    <option value="ALL">Toate</option>
                    <option value="Shounen">Shounen</option>
                    <option value="Seinen">Seinen</option>
                    <option value="Shoujo">Shoujo</option>
                    <option value="Josei">Josei</option>
                    <option value="Kids">Kids</option>
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-textSecondary block">
                    Scor minim: {minScore > 0 ? `${minScore}★` : 'Toate'}
                  </label>
                  <input
                    type="range"
                    min={0}
                    max={9}
                    step={1}
                    value={minScore}
                    onChange={(e) => {
                      setMinScore(Number(e.target.value));
                      setPage(1);
                    }}
                    className="w-full accent-accentPrimary cursor-pointer"
                  />
                </div>
              </div>

              {/* GENRES MULTI-SELECT */}
              <div className="space-y-2 pt-2 border-t border-borderSubtle">
                <label className="text-xs font-semibold text-textSecondary flex items-center justify-between">
                  <span>Genuri ({selectedGenres.length})</span>
                  {selectedGenres.length > 0 && (
                    <button
                      type="button"
                      onClick={() => setSelectedGenres([])}
                      className="text-[10px] text-accentPrimary hover:underline"
                    >
                      Șterge
                    </button>
                  )}
                </label>
                <div className="flex flex-wrap gap-1.5 max-h-36 overflow-y-auto pr-1 scrollbar-none">
                  {GENRES_LIST.map((genre) => {
                    const isSelected = selectedGenres.includes(genre);
                    return (
                      <button
                        key={genre}
                        type="button"
                        onClick={() => toggleGenre(genre)}
                        className={`px-2.5 py-1 rounded-full text-[11px] font-medium transition-all ${
                          isSelected
                            ? 'bg-accentPrimary text-white shadow-sm'
                            : 'bg-bgPrimary hover:bg-bgSurfaceHover text-textSecondary border border-borderSubtle'
                        }`}
                      >
                        {genre}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* MICRO-TAGS MULTI-SELECT */}
              <div className="space-y-2 pt-2 border-t border-borderSubtle">
                <label className="text-xs font-semibold text-textSecondary flex items-center justify-between">
                  <span>Teme & Tropuri ({selectedMicroTags.length})</span>
                  {selectedMicroTags.length > 0 && (
                    <button
                      type="button"
                      onClick={() => setSelectedMicroTags([])}
                      className="text-[10px] text-accentPrimary hover:underline"
                    >
                      Șterge
                    </button>
                  )}
                </label>
                <div className="flex flex-wrap gap-1.5 max-h-28 overflow-y-auto pr-1 scrollbar-none">
                  {MICRO_TAGS_LIST.map((tag) => {
                    const isSelected = selectedMicroTags.includes(tag);
                    return (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => toggleMicroTag(tag)}
                        className={`px-2.5 py-1 rounded-full text-[11px] font-medium transition-all ${
                          isSelected
                            ? 'bg-purple-600 text-white shadow-sm'
                            : 'bg-bgPrimary hover:bg-bgSurfaceHover text-textSecondary border border-borderSubtle'
                        }`}
                      >
                        {tag}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          </aside>

          {/* RIGHT MAIN AREA: RESULTS */}
          <main className="md:col-span-5 lg:col-span-9 space-y-6">
            {/* Active Filters Pill Bar */}
            {activeFiltersCount > 0 && (
              <div className="flex flex-wrap items-center gap-2 p-3 rounded-2xl bg-bgSurface border border-borderSubtle text-xs">
                <span className="text-textSecondary font-semibold">Filtre active:</span>
                {query && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    &quot;{query}&quot;
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setQuery('')} />
                  </span>
                )}
                {selectedLetter !== 'TOATE' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    Litera: {selectedLetter}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedLetter('TOATE')} />
                  </span>
                )}
                {selectedType !== 'ALL' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    Tip: {selectedType}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedType('ALL')} />
                  </span>
                )}
                {selectedFormat !== 'ALL' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    Format: {selectedFormat}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedFormat('ALL')} />
                  </span>
                )}
                {selectedStatus !== 'ALL' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    Stare: {selectedStatus}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedStatus('ALL')} />
                  </span>
                )}
                {selectedSeason !== 'ALL' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    Sezon: {selectedSeason}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedSeason('ALL')} />
                  </span>
                )}
                {selectedYear !== 'ALL' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    An: {selectedYear}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedYear('ALL')} />
                  </span>
                )}
                {selectedDemographic !== 'ALL' && (
                  <span className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1">
                    Demografie: {selectedDemographic}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => setSelectedDemographic('ALL')} />
                  </span>
                )}
                {selectedGenres.map((genre) => (
                  <span
                    key={genre}
                    className="px-2.5 py-1 rounded-full bg-accentPrimary/15 text-accentPrimary border border-accentPrimary/30 flex items-center gap-1"
                  >
                    {genre}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => toggleGenre(genre)} />
                  </span>
                ))}
                {selectedMicroTags.map((tag) => (
                  <span
                    key={tag}
                    className="px-2.5 py-1 rounded-full bg-purple-500/15 text-purple-400 border border-purple-500/30 flex items-center gap-1"
                  >
                    #{tag}
                    <X className="w-3 h-3 cursor-pointer" onClick={() => toggleMicroTag(tag)} />
                  </span>
                ))}
              </div>
            )}

            {/* RESULTS CONTAINER */}
            <div ref={gridContainerRef}>
              {loading ? (
                <div className="py-24 flex flex-col items-center justify-center text-textSecondary gap-3 bg-bgSurface rounded-3xl border border-borderSubtle">
                  <div className="w-8 h-8 border-2 border-accentPrimary border-t-transparent rounded-full animate-spin" />
                  <span className="text-sm font-semibold">Se încarcă lista de anime-uri...</span>
                </div>
              ) : items.length === 0 ? (
                <div className="py-24 text-center bg-bgSurface rounded-3xl border border-borderSubtle p-8 space-y-4">
                  <div className="w-12 h-12 rounded-2xl bg-bgSurfaceHover flex items-center justify-center mx-auto text-textSecondary">
                    <Search className="w-6 h-6" />
                  </div>
                  <h3 className="text-base font-bold text-textPrimary">Nu am găsit rezultate conform filtrelor selectate</h3>
                  <p className="text-xs text-textSecondary max-w-md mx-auto">
                    Încearcă să resetezi o parte din filtre sau alege altă literă din bara alfabetică.
                  </p>
                  <button
                    type="button"
                    onClick={handleResetFilters}
                    className="px-5 py-2.5 rounded-full bg-accentPrimary text-white text-xs font-semibold hover:opacity-90 transition-opacity"
                  >
                    Resetează Toate Filtrele
                  </button>
                </div>
              ) : viewMode === 'grid' ? (
                /* GRID VIEW */
                <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-5 md:gap-6 lg:gap-8">
                  {items.map((item) => (
                    <div
                      key={item.id}
                      className="catalog-card group bg-bgSurface rounded-2xl overflow-hidden border border-borderSubtle hover:border-accentPrimary/60 transition-all duration-300 flex flex-col shadow-sm hover:shadow-xl hover:-translate-y-1"
                    >
                      {/* Thumbnail with score badge */}
                      <Link href={`/media/${item.id}`} className="relative aspect-[3/4] bg-bgSurfaceHover overflow-hidden block">
                        <img
                          src={item.coverImage.large}
                          alt={item.title.userPreferred}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          loading="lazy"
                        />
                        <div className="absolute top-2.5 right-2.5 bg-bgPrimary px-2 py-0.5 rounded-full text-[11px] font-bold text-scoreGold border border-borderSubtle flex items-center gap-1 shadow-md">
                          <Star className="w-3 h-3 fill-scoreGold text-scoreGold" />
                          <span>{item.scores.averageScore > 0 ? item.scores.averageScore : 'N/A'}</span>
                        </div>
                        {item.status === 'RELEASING' && (
                          <div className="absolute bottom-2.5 left-2.5 bg-bgSurface text-signalLive px-2.5 py-0.5 rounded-full text-[9px] font-bold uppercase flex items-center gap-1 shadow-md">
                            <span className="w-1.5 h-1.5 rounded-full bg-signalLive animate-pulse" />
                            Live
                          </div>
                        )}
                      </Link>

                      {/* Info & Metadata */}
                      <div className="p-3.5 flex flex-col justify-between flex-1 space-y-2">
                        <div>
                          <div className="flex items-center gap-1.5 text-[10px] text-textSecondary font-semibold uppercase mb-1">
                            <span className="text-accentPrimary">{item.type}</span>
                            <span>•</span>
                            <span>{item.format}</span>
                            {item.year ? (
                              <>
                                <span>•</span>
                                <span>{item.year}</span>
                              </>
                            ) : null}
                          </div>

                          <Link
                            href={`/media/${item.id}`}
                            className="text-xs sm:text-sm font-bold text-textPrimary line-clamp-2 group-hover:text-accentPrimary transition-colors leading-snug"
                            title={item.title.userPreferred}
                          >
                            {item.title.userPreferred}
                          </Link>
                        </div>

                        {/* Genres */}
                        <div className="flex flex-wrap gap-1 pt-1">
                          {item.genres.slice(0, 2).map((genre) => (
                            <span
                              key={genre}
                              className="px-2 py-0.5 rounded-full bg-bgPrimary text-[10px] text-textSecondary border border-borderSubtle"
                            >
                              {genre}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                /* LIST VIEW */
                <div className="space-y-3">
                  {items.map((item) => (
                    <div
                      key={item.id}
                      className="catalog-card group bg-bgSurface rounded-2xl p-3 border border-borderSubtle hover:border-accentPrimary/50 transition-all duration-300 flex items-center justify-between gap-4 shadow-sm"
                    >
                      <div className="flex items-center gap-3.5 min-w-0">
                        <Link href={`/media/${item.id}`} className="w-14 h-20 rounded-xl overflow-hidden bg-bgSurfaceHover shrink-0 relative block">
                          <img
                            src={item.coverImage.large}
                            alt={item.title.userPreferred}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                            loading="lazy"
                          />
                        </Link>

                        <div className="min-w-0 space-y-1">
                          <div className="flex items-center gap-2 text-[10px] text-textSecondary font-semibold uppercase">
                            <span className="text-accentPrimary">{item.type}</span>
                            <span>•</span>
                            <span>{item.format}</span>
                            {item.year && (
                              <>
                                <span>•</span>
                                <span>{item.year}</span>
                              </>
                            )}
                            {item.status === 'RELEASING' && (
                              <span className="text-signalLive font-bold">● LIVE</span>
                            )}
                          </div>

                          <Link
                            href={`/media/${item.id}`}
                            className="text-sm font-bold text-textPrimary truncate block group-hover:text-accentPrimary transition-colors"
                            title={item.title.userPreferred}
                          >
                            {item.title.userPreferred}
                          </Link>

                          {item.genres.length > 0 && (
                            <div className="flex flex-wrap gap-1 pt-0.5">
                              {item.genres.slice(0, 3).map((g) => (
                                <span
                                  key={g}
                                  className="px-2 py-0.5 rounded-full bg-bgPrimary text-[10px] text-textSecondary border border-borderSubtle"
                                >
                                  {g}
                                </span>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center gap-4 shrink-0">
                        <div className="text-right hidden sm:block">
                          <div className="text-sm font-extrabold text-scoreGold flex items-center gap-1 justify-end">
                            <Star className="w-4 h-4 fill-scoreGold text-scoreGold" />
                            <span>{item.scores.averageScore > 0 ? item.scores.averageScore : 'N/A'}</span>
                          </div>
                          <span className="text-[10px] text-textSecondary">
                            {item.scores.reviewCount ? `${item.scores.reviewCount} recenzii` : 'Scor comunitar'}
                          </span>
                        </div>

                        <Link
                          href={`/media/${item.id}`}
                          className="px-4 py-2 rounded-full bg-bgSurfaceHover hover:bg-accentPrimary text-textSecondary hover:text-white text-xs font-semibold transition-colors"
                        >
                          Detalii
                        </Link>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* PAGINATION CONTROLS */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between pt-6 border-t border-borderSubtle">
                <button
                  type="button"
                  disabled={page <= 1}
                  onClick={() => {
                    setPage((prev) => Math.max(1, prev - 1));
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                  className="px-4 py-2.5 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle text-xs font-semibold text-textSecondary hover:text-textPrimary disabled:opacity-40 disabled:pointer-events-none transition-all flex items-center gap-1.5"
                >
                  <ChevronLeft className="w-4 h-4" /> Înapoi
                </button>

                <div className="text-xs font-semibold text-textSecondary">
                  Pagina <span className="text-textPrimary font-bold">{page}</span> din{' '}
                  <span className="text-textPrimary font-bold">{totalPages}</span>
                </div>

                <button
                  type="button"
                  disabled={page >= totalPages}
                  onClick={() => {
                    setPage((prev) => Math.min(totalPages, prev + 1));
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                  className="px-4 py-2.5 rounded-full bg-bgSurface hover:bg-bgSurfaceHover border border-borderSubtle text-xs font-semibold text-textSecondary hover:text-textPrimary disabled:opacity-40 disabled:pointer-events-none transition-all flex items-center gap-1.5"
                >
                  Următoarea <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            )}
          </main>
        </div>
      </div>
    </div>
  );
}

export default function MediaCatalogPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-bgPrimary text-textSecondary">
          <div className="w-8 h-8 border-2 border-accentPrimary border-t-transparent rounded-full animate-spin mr-3" />
          <span>Se încarcă catalogul...</span>
        </div>
      }
    >
      <MediaCatalogContent />
    </Suspense>
  );
}

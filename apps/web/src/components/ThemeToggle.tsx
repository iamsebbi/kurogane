'use client';

import React, { useEffect, useState } from 'react';
import { Sun, Moon, LayoutGrid } from 'lucide-react';

export default function ThemeToggle() {
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const [showGrid, setShowGrid] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const savedTheme = localStorage.getItem('kurogane-theme') as 'dark' | 'light' | null;
    if (savedTheme) {
      setTheme(savedTheme);
      document.documentElement.setAttribute('data-theme', savedTheme);
      if (savedTheme === 'light') {
        document.documentElement.classList.remove('dark');
      } else {
        document.documentElement.classList.add('dark');
      }
    } else {
      document.documentElement.setAttribute('data-theme', 'dark');
    }

    const savedGrid = localStorage.getItem('kurogane-grid-overlay');
    if (savedGrid === 'true') {
      setShowGrid(true);
    }
  }, []);

  // Keyboard shortcut Ctrl+G or Cmd+G to toggle grid
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'g') {
        e.preventDefault();
        toggleGrid();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showGrid]);

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    localStorage.setItem('kurogane-theme', newTheme);
    document.documentElement.setAttribute('data-theme', newTheme);
    if (newTheme === 'light') {
      document.documentElement.classList.remove('dark');
    } else {
      document.documentElement.classList.add('dark');
    }
  };

  const toggleGrid = () => {
    const nextState = !showGrid;
    setShowGrid(nextState);
    localStorage.setItem('kurogane-grid-overlay', String(nextState));
  };

  if (!mounted) return null;

  return (
    <>
      {/* 1. VISUAL 12-COLUMN DESIGN GRID OVERLAY (MAX-W-[1920px], GAPS: 20px / 24px / 32px, PADDING: 16px / 48px) */}
      {showGrid && (
        <div className="fixed inset-0 z-40 pointer-events-none flex flex-col justify-start">
          {/* Top Info Badge */}
          <div className="w-full max-w-[1920px] mx-auto px-4 md:px-12 pt-2 flex justify-between items-center text-[10px] font-mono font-bold tracking-wider text-rose-500 uppercase">
            <span className="bg-rose-500/20 px-2.5 py-1 rounded-md border border-rose-500/40">
              Grid: max-w-[1920px] • 4 col (Mobil) / 8 col (md) / 12 col (lg)
            </span>
            <span className="bg-rose-500/20 px-2.5 py-1 rounded-md border border-rose-500/40">
              Gutters: 20px (Mobil) | 24px (md) | 32px (lg) • Padding: 16px | 48px
            </span>
          </div>

          {/* Grid Columns */}
          <div className="w-full h-full max-w-[1920px] mx-auto px-4 md:px-12 grid grid-cols-4 md:grid-cols-8 lg:grid-cols-12 gap-5 md:gap-6 lg:gap-8">
            {Array.from({ length: 12 }).map((_, index) => (
              <div
                key={index}
                className={`h-full bg-rose-500/10 border-x border-rose-500/20 flex flex-col justify-between items-center py-2 ${
                  index >= 4 ? 'hidden md:flex' : ''
                } ${index >= 8 ? 'md:hidden lg:flex' : ''}`}
              >
                <span className="text-[10px] font-mono font-bold text-rose-500 bg-rose-500/20 px-1.5 py-0.5 rounded">
                  {index + 1}
                </span>
                <span className="text-[9px] font-mono text-rose-500/70 font-semibold">
                  col-{index + 1}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 2. FLOATING CONTROL BUTTONS (BOTTOM-RIGHT) */}
      <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3">
        {/* Design Grid Toggle Button */}
        <button
          onClick={toggleGrid}
          type="button"
          className={`w-12 h-12 rounded-full shadow-2xl flex items-center justify-center transition-all duration-300 hover:scale-110 active:scale-95 group border ${
            showGrid
              ? 'bg-rose-600 text-white border-rose-500 ring-4 ring-rose-500/30'
              : 'bg-bgSurface hover:bg-bgSurfaceHover text-textSecondary hover:text-textPrimary border-borderSubtle/60'
          }`}
          title={showGrid ? 'Ascunde Grid-ul de 12 Coloane (Ctrl+G)' : 'Afișează Grid-ul de 12 Coloane (Ctrl+G)'}
          aria-label="Toggle 12-Column Design Grid"
        >
          <LayoutGrid className={`w-5 h-5 transition-transform duration-200 ${showGrid ? 'scale-110' : 'group-hover:scale-110'}`} />
        </button>

        {/* Theme Toggle Button */}
        <button
          onClick={toggleTheme}
          type="button"
          className="w-12 h-12 rounded-full bg-bgSurface hover:bg-bgSurfaceHover shadow-2xl flex items-center justify-center text-textSecondary hover:text-textPrimary transition-all duration-300 hover:scale-110 active:scale-95 group border border-borderSubtle/60"
          title={theme === 'dark' ? 'Comută pe Modul Luminos (Light)' : 'Comută pe Modul Întunecat (Dark)'}
          aria-label="Toggle Theme"
        >
          {theme === 'dark' ? (
            <Sun className="w-5 h-5 text-scoreGold transition-transform duration-300 group-hover:rotate-45" />
          ) : (
            <Moon className="w-5 h-5 text-badgeViolet transition-transform duration-300 group-hover:-rotate-12" />
          )}
        </button>
      </div>
    </>
  );
}

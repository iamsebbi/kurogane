'use client';

import React from 'react';
import Link from 'next/link';
import { ArrowUp, Github, Disc as Discord, Tv, BookOpen, Compass, ShieldCheck, Film, Layers } from 'lucide-react';

export default function Footer() {
  const scrollToTop = () => {
    if (typeof window !== 'undefined') {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  return (
    <footer className="border-t border-borderSubtle bg-bgSurface/60 backdrop-blur-md text-textPrimary relative overflow-hidden">
      {/* Ambient subtle glow in footer background */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-96 h-40 bg-accentPrimary/5 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-16 pb-8 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10 lg:gap-8 pb-12">
          
          {/* Brand & Description Column (2 cols width on large screens) */}
          <div className="lg:col-span-2 space-y-4">
            <Link
              href="/"
              className="inline-block text-2xl font-black tracking-widest text-textPrimary font-heading focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded"
            >
              KUROGANE
            </Link>
            <p className="text-xs sm:text-sm text-textSecondary leading-relaxed max-w-sm">
              Platformă modernă de media tracking dedicată comunității anime, donghua și manga.
              Scoruri rezistente la review-bombing și ordine cronologice canoane de vizionare.
            </p>

            {/* Social & Community Links */}
            <div className="flex items-center gap-2.5 pt-2">
              <a
                href="https://github.com"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Vizitează profilul GitHub Kurogane"
                className="w-9 h-9 rounded-full bg-bgPrimary border border-borderSubtle hover:border-accentPrimary hover:text-accentPrimary text-textSecondary flex items-center justify-center transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer"
              >
                <Github className="w-4 h-4" />
              </a>
              <a
                href="https://discord.com"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Alătură-te comunității Discord Kurogane"
                className="w-9 h-9 rounded-full bg-bgPrimary border border-borderSubtle hover:border-accentPrimary hover:text-accentPrimary text-textSecondary flex items-center justify-center transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer"
              >
                <Discord className="w-4 h-4" />
              </a>
              <a
                href="https://anilist.co"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Integrare AniList API"
                className="w-9 h-9 rounded-full bg-bgPrimary border border-borderSubtle hover:border-accentPrimary hover:text-accentPrimary text-textSecondary flex items-center justify-center transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer"
              >
                <Compass className="w-4 h-4" />
              </a>
            </div>
          </div>

          {/* Col 1: Explorare */}
          <div className="space-y-3.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-textPrimary flex items-center gap-1.5">
              <Tv className="w-3.5 h-3.5 text-accentPrimary" aria-hidden="true" />
              Explorare
            </h3>
            <ul className="space-y-2.5 text-xs text-textSecondary">
              <li>
                <Link href="/explore?filter=airing" className="hover:text-textPrimary transition-colors">
                  Anime Sezonier
                </Link>
              </li>
              <li>
                <Link href="/#top-100" className="hover:text-textPrimary transition-colors">
                  Top 100 All-Time
                </Link>
              </li>
              <li>
                <Link href="/explore?format=MOVIE" className="hover:text-textPrimary transition-colors">
                  Filme Anime
                </Link>
              </li>
              <li>
                <Link href="/explore?type=DONGHUA" className="hover:text-textPrimary transition-colors">
                  Donghua Trending
                </Link>
              </li>
              <li>
                <Link href="/explore?type=MANGA" className="hover:text-textPrimary transition-colors">
                  Manga &amp; Manhwa
                </Link>
              </li>
            </ul>
          </div>

          {/* Col 2: Funcționalități */}
          <div className="space-y-3.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-textPrimary flex items-center gap-1.5">
              <Layers className="w-3.5 h-3.5 text-accentPrimary" aria-hidden="true" />
              Funcționalități
            </h3>
            <ul className="space-y-2.5 text-xs text-textSecondary">
              <li>
                <Link href="/watchlist" className="hover:text-textPrimary transition-colors">
                  Watchlist Inteligent
                </Link>
              </li>
              <li>
                <Link href="/explore" className="hover:text-textPrimary transition-colors">
                  Ordine de Vizionare (Franchise)
                </Link>
              </li>
              <li>
                <Link href="/profile" className="hover:text-textPrimary transition-colors">
                  Profil &amp; Statistici Personale
                </Link>
              </li>
              <li>
                <Link href="/explore" className="hover:text-textPrimary transition-colors">
                  Filtre Avansate &amp; Căutare
                </Link>
              </li>
            </ul>
          </div>

          {/* Col 3: Legal & Platformă */}
          <div className="space-y-3.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-textPrimary flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 text-accentPrimary" aria-hidden="true" />
              Platformă &amp; Legal
            </h3>
            <ul className="space-y-2.5 text-xs text-textSecondary">
              <li>
                <span className="text-textMuted cursor-default">Termeni de Utilizare</span>
              </li>
              <li>
                <span className="text-textMuted cursor-default">Politică de Confidențialitate</span>
              </li>
              <li>
                <a
                  href="https://github.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-textPrimary transition-colors"
                >
                  Raportează o Problemă
                </a>
              </li>
              <li>
                <span className="text-textMuted cursor-default">AniList GraphQL API</span>
              </li>
            </ul>
          </div>

        </div>

        {/* Bottom Bar: Copyright, Disclaimers, Scroll-to-Top */}
        <div className="border-t border-borderSubtle pt-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-textSecondary">
          <p className="text-center sm:text-left">
            © {new Date().getFullYear()} <strong className="text-textPrimary font-semibold">Kurogane</strong>. Creat pentru entuziaștii de anime și manga.
          </p>

          <div className="flex items-center gap-4">
            <span className="text-textMuted hidden md:inline text-[11px]">
              Date furnizate de AniList &amp; Kurogane Local Database
            </span>
            <button
              type="button"
              onClick={scrollToTop}
              aria-label="Revenire la începutul paginii"
              className="h-9 px-4 rounded-full bg-bgPrimary hover:bg-bgSurfaceHover border border-borderSubtle hover:border-accentPrimary text-textSecondary hover:text-textPrimary flex items-center gap-1.5 text-xs font-semibold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer shadow-xs active:scale-[0.98]"
            >
              <span>Sus</span>
              <ArrowUp className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

      </div>
    </footer>
  );
}

'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  Search,
  Users,
  Sparkles,
  User,
  Bell,
  Menu,
  X,
  Bookmark,
  LogOut,
} from 'lucide-react';
import { AuthModal } from './AuthModal';
import { UserProfile } from '@kurogane/shared';
import { gsap, useGSAP } from '@/lib/gsap';
import { firebaseAuth } from '@/lib/firebase';

export default function Navbar() {
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [user, setUser] = useState<UserProfile | null>(null);
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [authMode, setAuthMode] = useState<'SIGN_IN' | 'SIGN_UP'>('SIGN_IN');

  const linksContainerRef = useRef<HTMLDivElement>(null);
  const linkRefs = useRef<(HTMLAnchorElement | null)[]>([]);
  const pillRef = useRef<HTMLDivElement>(null);
  const isInitialMount = useRef(true);

  const checkUserAuth = useCallback(() => {
    try {
      const token = localStorage.getItem('kurogane_token');
      const storedUser = localStorage.getItem('kurogane_user');
      if (token && storedUser) {
        setUser(JSON.parse(storedUser));
      } else {
        setUser(null);
      }
    } catch (e) {
      setUser(null);
    }
  }, []);

  useEffect(() => {
    checkUserAuth();

    // Firebase Auth native listener as single source of truth across tabs
    const unsubscribeFirebase = firebaseAuth.onAuthStateChange((fbUser, idToken) => {
      if (fbUser) {
        setUser(fbUser);
        if (idToken) localStorage.setItem('kurogane_token', idToken);
        localStorage.setItem('kurogane_user', JSON.stringify(fbUser));
      } else {
        // If Firebase is signed out and no token exists in localStorage, clear user state
        const token = localStorage.getItem('kurogane_token');
        if (!token) {
          setUser(null);
        }
      }
    });

    const handleAuthChange = () => checkUserAuth();
    window.addEventListener('kurogane_auth_changed', handleAuthChange);
    window.addEventListener('storage', handleAuthChange);

    return () => {
      unsubscribeFirebase();
      window.removeEventListener('kurogane_auth_changed', handleAuthChange);
      window.removeEventListener('storage', handleAuthChange);
    };
  }, [checkUserAuth]);

  // Close mobile menu on route change
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [pathname]);

  const navLinks = [
    {
      name: 'Acasă',
      href: '/',
      icon: Home,
      isActive: pathname === '/',
    },
    {
      name: 'Căutare',
      href: '/media',
      icon: Search,
      isActive: pathname === '/media' || pathname.startsWith('/media/'),
    },
    {
      name: 'Comunitate',
      href: '/community',
      icon: Users,
      isActive: pathname === '/community',
    },
    {
      name: 'Recomandări',
      href: '/recommendations',
      icon: Sparkles,
      isActive: pathname === '/recommendations',
    },
  ];

  const activeIndex = navLinks.findIndex((l) => l.isActive);

  // GSAP Sliding Pill Animation
  useGSAP(
    () => {
      if (activeIndex === -1 || !linkRefs.current[activeIndex] || !pillRef.current) {
        if (pillRef.current) {
          gsap.to(pillRef.current, { opacity: 0, duration: 0.2 });
        }
        return;
      }

      const activeEl = linkRefs.current[activeIndex]!;
      const targetX = activeEl.offsetLeft;
      const targetWidth = activeEl.offsetWidth;

      if (isInitialMount.current) {
        gsap.set(pillRef.current, {
          x: targetX,
          width: targetWidth,
          opacity: 1,
        });
        isInitialMount.current = false;
      } else {
        gsap.to(pillRef.current, {
          x: targetX,
          width: targetWidth,
          opacity: 1,
          duration: 0.35,
          ease: 'power3.out',
        });
      }
    },
    { dependencies: [pathname, activeIndex], scope: linksContainerRef }
  );

  // Reposition on window resize
  useEffect(() => {
    const handleResize = () => {
      if (activeIndex !== -1 && linkRefs.current[activeIndex] && pillRef.current) {
        const activeEl = linkRefs.current[activeIndex]!;
        gsap.set(pillRef.current, {
          x: activeEl.offsetLeft,
          width: activeEl.offsetWidth,
        });
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [activeIndex]);

  const handleOpenAuth = (mode: 'SIGN_IN' | 'SIGN_UP') => {
    setAuthMode(mode);
    setIsAuthOpen(true);
  };

  const handleAuthSuccess = (authUser: any) => {
    setUser(authUser);
    setIsAuthOpen(false);
  };

  return (
    <>
      <header className="sticky top-4 sm:top-5 z-50 px-4 md:px-12 w-full max-w-[1920px] mx-auto flex items-center justify-center gap-3.5 pointer-events-none">
        {/* 1. MAIN FLOATING ISLAND NAVBAR */}
        <nav
          className="pointer-events-auto h-14 w-full max-w-3xl lg:max-w-4xl xl:max-w-5xl rounded-full bg-bgSurface border border-white/[0.07] shadow-[0_16px_36px_-8px_rgba(0,0,0,0.45),inset_0_1px_0_0_rgba(255,255,255,0.08)] px-6 sm:px-8 flex items-center justify-between gap-4 sm:gap-8 transition-all"
          aria-label="Main Navigation"
        >
          {/* LOGO (Monochrome, Capslock, Tight Letter Spacing) */}
          <Link
            href="/"
            className="flex items-center group py-1 px-1 rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary shrink-0"
          >
            <span className="text-lg sm:text-xl font-black font-heading tracking-tighter uppercase text-textPrimary group-hover:opacity-80 transition-opacity">
              KUROGANE
            </span>
          </Link>

          {/* DESKTOP NAVIGATION LINKS WITH GSAP SLIDING PILL */}
          <div
            ref={linksContainerRef}
            className="relative hidden md:flex items-center gap-1.5 lg:gap-2"
          >
            {/* THE SLIDING SOLID PILL (Uses exact Kurogane design tokens) */}
            <div
              ref={pillRef}
              className="absolute top-0 left-0 h-10 rounded-full bg-textPrimary shadow-md pointer-events-none opacity-0"
              style={{ willChange: 'transform, width' }}
            />

            {navLinks.map((link, idx) => {
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  ref={(el) => {
                    linkRefs.current[idx] = el;
                  }}
                  href={link.href}
                  className={`relative z-10 h-10 text-sm sm:text-[15px] font-semibold rounded-full inline-flex items-center transition-colors duration-200 overflow-hidden ${
                    link.isActive
                      ? 'text-bgPrimary'
                      : 'text-textSecondary hover:text-textPrimary'
                  }`}
                >
                  <span className="w-10 h-10 flex items-center justify-center shrink-0">
                    <Icon
                      className={`w-4 h-4 transition-colors duration-200 ${
                        link.isActive ? 'text-bgPrimary' : 'text-textSecondary'
                      }`}
                    />
                  </span>
                  <span className="pr-4 sm:pr-5 -ml-1.5">{link.name}</span>
                </Link>
              );
            })}
          </div>

          {/* IF NOT LOGGED IN: LOG IN & SIGN UP BUTTONS INSIDE NAVBAR */}
          {!user && (
            <div className="flex items-center gap-2 sm:gap-3 shrink-0">
              <button
                type="button"
                onClick={() => handleOpenAuth('SIGN_IN')}
                className="px-4 py-2 rounded-full text-xs sm:text-sm font-semibold text-textSecondary hover:text-textPrimary transition-colors"
              >
                Log in
              </button>

              <button
                type="button"
                onClick={() => handleOpenAuth('SIGN_UP')}
                className="px-5 py-2 rounded-full text-xs sm:text-sm font-semibold bg-accentPrimary hover:opacity-90 text-white shadow-md hover:shadow-lg transition-all active:scale-95"
              >
                Sign up
              </button>
            </div>
          )}

          {/* Mobile Hamburger Toggle Button (when screen is smaller) */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            type="button"
            className="md:hidden p-2.5 rounded-full bg-bgSurfaceHover text-textSecondary hover:text-textPrimary border border-white/[0.06] transition-colors flex items-center justify-center"
            aria-label={mobileMenuOpen ? 'Închide meniul' : 'Deschide meniul'}
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </nav>

        {/* 2. NOTIFICATION & AVATAR ICONS NEXT TO NAVBAR */}
        {user && (
          <div className="pointer-events-auto flex items-center gap-3 shrink-0">
            {/* Notification Circle Button */}
            <button
              type="button"
              className="h-14 w-14 rounded-full bg-bgSurface border border-white/[0.07] hover:bg-bgSurfaceHover shadow-[0_16px_36px_-8px_rgba(0,0,0,0.45),inset_0_1px_0_0_rgba(255,255,255,0.08)] flex items-center justify-center text-textSecondary hover:text-textPrimary hover:scale-105 active:scale-95 transition-all relative group"
              title="Notificări"
              aria-label="Notificări"
            >
              <Bell className="w-5 h-5 text-textSecondary group-hover:text-textPrimary transition-colors" />
              <span className="absolute top-3.5 right-3.5 w-2.5 h-2.5 bg-signalLive rounded-full ring-2 ring-bgSurface animate-pulse" />
            </button>

            {/* Account Avatar Circle Button */}
            <Link
              href="/profile"
              className="h-14 w-14 rounded-full bg-bgSurface border border-white/[0.07] hover:bg-bgSurfaceHover shadow-[0_16px_36px_-8px_rgba(0,0,0,0.45),inset_0_1px_0_0_rgba(255,255,255,0.08)] flex items-center justify-center overflow-hidden hover:scale-105 hover:ring-2 hover:ring-accentPrimary active:scale-95 transition-all"
              title={user.username ? `Profil: ${user.username}` : 'Profilul Meu'}
              aria-label="Profilul Meu"
            >
              {user.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt={user.username || 'Avatar'}
                  className="w-full h-full object-cover rounded-full"
                />
              ) : (
                <User className="w-6 h-6 text-accentPrimary" />
              )}
            </Link>
          </div>
        )}
      </header>

      {/* MOBILE MENU */}
      {mobileMenuOpen && (
        <div className="fixed top-20 inset-x-4 z-50 p-4 rounded-3xl bg-bgSurface border border-white/[0.07] shadow-[0_20px_40px_-10px_rgba(0,0,0,0.6),inset_0_1px_0_0_rgba(255,255,255,0.08)] space-y-2 max-w-md mx-auto">
          {navLinks.map((link) => {
            const Icon = link.icon;
            return (
              <Link
                key={link.href}
                href={link.href}
                className={`w-full px-4 py-3 rounded-2xl text-sm font-semibold flex items-center gap-3 transition-colors ${
                  link.isActive
                    ? 'bg-textPrimary text-bgPrimary font-bold'
                    : 'text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover'
                }`}
              >
                <Icon
                  className={`w-4 h-4 ${
                    link.isActive ? 'text-bgPrimary' : 'text-textSecondary'
                  }`}
                />
                <span>{link.name}</span>
              </Link>
            );
          })}

          {user ? (
            <div className="pt-3 mt-3 space-y-2 border-t border-borderSubtle/40">
              <Link
                href="/profile"
                onClick={() => setMobileMenuOpen(false)}
                className="w-full px-4 py-3 rounded-2xl text-sm font-semibold flex items-center gap-3 text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover transition-colors"
              >
                <User className="w-4 h-4 text-accentPrimary" />
                <span>Profilul Meu ({user.username})</span>
              </Link>
              <Link
                href="/watchlist"
                onClick={() => setMobileMenuOpen(false)}
                className="w-full px-4 py-3 rounded-2xl text-sm font-semibold flex items-center gap-3 text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover transition-colors"
              >
                <Bookmark className="w-4 h-4 text-scoreGold" />
                <span>Watchlist</span>
              </Link>
              <button
                type="button"
                onClick={async () => {
                  try {
                    await firebaseAuth.signOut();
                  } catch (e) {
                    console.error('Error signing out from Firebase:', e);
                  }
                  localStorage.removeItem('kurogane_token');
                  localStorage.removeItem('kurogane_user');
                  window.dispatchEvent(new Event('kurogane_auth_changed'));
                  setUser(null);
                  setMobileMenuOpen(false);
                }}
                className="w-full px-4 py-3 rounded-2xl text-sm font-semibold flex items-center gap-3 text-red-400 hover:bg-red-500/10 transition-colors text-left cursor-pointer"
              >
                <LogOut className="w-4 h-4" />
                <span>Deconectare</span>
              </button>
            </div>
          ) : (
            <div className="pt-3 mt-3 flex items-center justify-between px-3 text-xs sm:text-sm text-textSecondary border-t border-borderSubtle/40">
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  handleOpenAuth('SIGN_IN');
                }}
                className="py-2 text-textSecondary hover:text-textPrimary font-semibold cursor-pointer"
              >
                Log in
              </button>
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  handleOpenAuth('SIGN_UP');
                }}
                className="px-4 py-2 rounded-full bg-accentPrimary text-white font-semibold cursor-pointer"
              >
                Sign up
              </button>
            </div>
          )}
        </div>
      )}

      {/* AUTH MODAL */}
      <AuthModal
        isOpen={isAuthOpen}
        onClose={() => setIsAuthOpen(false)}
        onSuccess={handleAuthSuccess}
        initialMode={authMode}
      />
    </>
  );
}

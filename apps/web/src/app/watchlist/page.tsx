'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { Bookmark, Plus, Star, CheckCircle, Clock, Trash2, ArrowLeft, UserCheck } from 'lucide-react';
import { WatchlistItemRecord, WatchlistStatus } from '@kurogane/shared';
import { AuthModal } from '@/components/AuthModal';

const STATUS_LABELS: Record<string, string> = {
  ALL: 'Toate',
  WATCHING: 'În Curs',
  COMPLETED: 'Completat',
  PLAN_TO_WATCH: 'Planificat',
  ON_HOLD: 'În Pauză',
  DROPPED: 'Renunțat',
};

export default function WatchlistPage() {
  const [items, setItems] = useState<WatchlistItemRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<string>('ALL');
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [user, setUser] = useState<any>(null);

  const fetchWatchlist = async () => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('kurogane_token') : null;
    const storedUser = typeof window !== 'undefined' ? localStorage.getItem('kurogane_user') : null;

    if (!token) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('kurogane_user');
      }
      setUser(null);
      setItems([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const res = await fetch('http://localhost:4000/api/watchlist', {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        if (res.status === 401) {
          localStorage.removeItem('kurogane_token');
          localStorage.removeItem('kurogane_user');
          setUser(null);
        }
        throw new Error('Autentifică-te pentru a-ți vedea lista salvată.');
      }

      const data = await res.json();
      setItems(data.items || []);

      if (storedUser) {
        try {
          setUser(JSON.parse(storedUser));
        } catch (e) {}
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWatchlist();
  }, []);

  const handleRemove = async (mediaId: string) => {
    const token = localStorage.getItem('kurogane_token');
    if (!token) return;

    try {
      await fetch(`http://localhost:4000/api/watchlist/${mediaId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
      setItems((prev) => prev.filter((i) => i.mediaId !== mediaId));
    } catch (err) {
      console.error('Error removing item:', err);
    }
  };

  const handleUpdateEpisodes = async (item: WatchlistItemRecord, newProgress: number) => {
    const token = localStorage.getItem('kurogane_token');
    if (!token) return;

    try {
      const res = await fetch('http://localhost:4000/api/watchlist', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          mediaId: item.mediaId,
          status: item.status,
          score: item.score,
          progressEpisodes: newProgress,
        }),
      });

      if (res.ok) {
        setItems((prev) =>
          prev.map((i) => (i.id === item.id ? { ...i, progressEpisodes: newProgress } : i))
        );
      }
    } catch (err) {
      console.error('Error updating progress:', err);
    }
  };

  const filteredItems = activeTab === 'ALL' ? items : items.filter((i) => i.status === activeTab);

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8">
      {/* Header Bar */}
      <div className="flex items-center justify-between gap-4 mb-8">
        <div>
          <Link
            href="/"
            className="inline-flex items-center gap-1.5 text-xs text-textSecondary hover:text-accentPrimary mb-2 transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" /> Înapoi la Descoperire
          </Link>
          <h1 className="text-3xl font-semibold font-heading bg-gradient-to-r from-blue-400 via-indigo-300 to-purple-400 bg-clip-text text-transparent flex items-center gap-3">
            <Bookmark className="w-7 h-7 text-accentPrimary" /> Lista Mea de Vizionare
          </h1>
          <p className="text-sm text-textSecondary mt-1">
            Colecția ta personală de Anime, Donghua și Manga sincronizată în baza de date Kurogane.
          </p>
        </div>

        {user ? (
          <div className="flex items-center gap-3 bg-bgSurface border border-borderSubtle rounded-xl px-4 py-2 shadow-sm">
            <Link href="/profile" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
              <img src={user.avatarUrl} alt={user.username} className="w-8 h-8 rounded-full border border-accentPrimary/40" />
              <div>
                <p className="text-xs font-semibold text-textPrimary flex items-center gap-1">
                  <UserCheck className="w-3.5 h-3.5 text-signalLive" /> {user.username}
                </p>
                <p className="text-[10px] text-accentPrimary hover:underline">Vezi Profilul Complet →</p>
              </div>
            </Link>
            <button
              onClick={() => {
                localStorage.removeItem('kurogane_token');
                localStorage.removeItem('kurogane_user');
                setUser(null);
                setItems([]);
              }}
              className="ml-2 px-2.5 py-1 rounded-lg bg-bgSurfaceHover hover:bg-red-500/20 text-textSecondary hover:text-red-400 border border-borderSubtle text-xs font-medium transition-colors"
              title="Deconectare"
            >
              Deconectare
            </button>
          </div>
        ) : (
          <button
            onClick={() => setIsAuthOpen(true)}
            className="px-5 py-2.5 rounded-xl bg-accentPrimary hover:bg-accentPrimary/90 text-white font-semibold text-xs shadow-md transition-all flex items-center gap-2"
          >
            Autentificare / Înregistrare
          </button>
        )}

      </div>

      {!user && (
        <div className="bg-bgSurface border border-borderSubtle rounded-2xl p-8 text-center mb-8 shadow-sm">
          <Bookmark className="w-12 h-12 text-accentPrimary mx-auto mb-3 opacity-80" />
          <h3 className="text-lg font-semibold text-textPrimary">Autentifică-te pentru a-ți accesa colecția</h3>
          <p className="text-xs text-textSecondary max-w-md mx-auto mt-1 mb-4">
            Creează-ți un cont gratuit pentru a-ți salva seriile vizionate, a-ți marca episoadele parcurse și a primi recomandări personalizate.
          </p>
          <button
            onClick={() => setIsAuthOpen(true)}
            className="px-6 py-2.5 rounded-xl bg-accentPrimary hover:bg-accentPrimary/90 text-white font-semibold text-xs shadow-md transition-all inline-flex items-center gap-2"
          >
            Autentificare / Înregistrare
          </button>
        </div>
      )}

      {user && (
        <>
          {/* Status Tabs */}
          <div className="flex items-center gap-2 overflow-x-auto pb-3 mb-6 no-scrollbar">
            {Object.keys(STATUS_LABELS).map((key) => {
              const count = key === 'ALL' ? items.length : items.filter((i) => i.status === key).length;
              return (
                <button
                  key={key}
                  onClick={() => setActiveTab(key)}
                  className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all whitespace-nowrap flex items-center gap-2 ${
                    activeTab === key
                      ? 'bg-accentPrimary text-white shadow-md'
                      : 'bg-bgSurface border border-borderSubtle text-textSecondary hover:text-textPrimary hover:border-borderSubtle'
                  }`}
                >
                  <span>{STATUS_LABELS[key]}</span>
                  <span
                    className={`px-1.5 py-0.5 rounded-full text-[10px] ${
                      activeTab === key ? 'bg-white/20 text-white' : 'bg-bgSurfaceHover text-textSecondary'
                    }`}
                  >
                    {count}
                  </span>
                </button>
              );
            })}
          </div>

          {/* List Content */}
          {loading ? (
            <div className="py-16 text-center text-textMuted text-sm">Se încarcă lista personală...</div>
          ) : filteredItems.length === 0 ? (
            <div className="bg-bgSurface border border-borderSubtle rounded-2xl p-12 text-center text-textMuted text-sm shadow-sm">
              Nu ai nicio serie în această categorie. Explorează catalogul și adaugă titluri favorite!
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredItems.map((record) => {
                const media = record.mediaItem;
                return (
                  <div
                    key={record.id}
                    className="bg-bgSurface border border-borderSubtle hover:border-accentPrimary/50 rounded-2xl p-4 flex gap-4 transition-all group shadow-sm"
                  >
                    {media?.coverImage?.large && (
                      <Link href={`/media/${record.mediaId}`} className="shrink-0">
                        <img
                          src={media.coverImage.large}
                          alt={media.title?.userPreferred}
                          className="w-20 h-28 object-cover rounded-xl shadow-md group-hover:scale-105 transition-transform"
                        />
                      </Link>
                    )}

                    <div className="flex-1 flex flex-col justify-between min-w-0">
                      <div>
                        <div className="flex items-start justify-between gap-2">
                          <Link
                            href={`/media/${record.mediaId}`}
                            className="font-semibold text-sm text-textPrimary hover:text-accentPrimary transition-colors truncate"
                          >
                            {media?.title?.userPreferred || record.mediaId}
                          </Link>
                          <button
                            onClick={() => handleRemove(record.mediaId)}
                            className="text-textMuted hover:text-alertCoral p-1 rounded-lg hover:bg-bgSurfaceHover transition-colors"
                            title="Șterge din listă"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>

                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-accentPrimary/10 text-accentPrimary border border-accentPrimary/20 font-medium">
                            {STATUS_LABELS[record.status] || record.status}
                          </span>
                          {record.score && (
                            <span className="text-xs font-semibold text-scoreGold flex items-center gap-1">
                              <Star className="w-3 h-3 fill-scoreGold" /> {record.score} / 10
                            </span>
                          )}
                        </div>
                      </div>

                      {/* Episode Counter Controls */}
                      <div className="flex items-center justify-between gap-2 mt-3 pt-3 border-t border-borderSubtle text-xs">
                        <span className="text-textSecondary">
                          Episoade: <strong className="text-textPrimary">{record.progressEpisodes}</strong>
                          {media?.episodes ? ` / ${media.episodes}` : ''}
                        </span>

                        <div className="flex items-center gap-1">
                          <button
                            onClick={() =>
                              handleUpdateEpisodes(record, Math.max(0, record.progressEpisodes - 1))
                            }
                            className="px-2.5 py-1 rounded bg-bgSurfaceHover hover:bg-accentPrimary hover:text-white text-textPrimary font-semibold text-xs transition-colors"
                          >
                            -
                          </button>
                          <button
                            onClick={() => handleUpdateEpisodes(record, record.progressEpisodes + 1)}
                            className="px-2.5 py-1 rounded bg-bgSurfaceHover hover:bg-accentPrimary hover:text-white text-textPrimary font-semibold text-xs transition-colors"
                          >
                            +
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </>
      )}

      <AuthModal
        isOpen={isAuthOpen}
        onClose={() => setIsAuthOpen(false)}
        onSuccess={(u) => {
          setUser(u);
          fetchWatchlist();
        }}
      />
    </div>
  );
}

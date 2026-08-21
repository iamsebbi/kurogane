'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  User,
  Edit3,
  CheckCircle,
  Clock,
  Bookmark,
  Star,
  Trash2,
  ArrowLeft,
  UserCheck,
  Sparkles,
  Shield,
  Plus,
  Minus,
  Settings,
  X,
  Camera,
  Heart,
  Share2,
  Tv,
  BookOpen,
  LogOut,
  Info,
} from 'lucide-react';
import { UserProfile, WatchlistItemRecord, WatchlistStatus } from '@kurogane/shared';
import { AuthModal } from '@/components/AuthModal';
import { firebaseAuth } from '@/lib/firebase';
import { API_BASE_URL } from '@/lib/api';

const STATUS_LABELS: Record<string, string> = {
  ALL: 'Toate',
  WATCHING: 'În Curs',
  COMPLETED: 'Completate',
  PLAN_TO_WATCH: 'Planificate',
  ON_HOLD: 'În Pauză',
  DROPPED: 'Renunțat',
};

const PRONOUN_PRESETS = ['he/him', 'she/her', 'they/them', 'otaku/senpai', 'ze/zir'];

const AVATAR_PRESETS = [
  'https://api.dicebear.com/7.x/bottts/svg?seed=KuroganeStar',
  'https://api.dicebear.com/7.x/bottts/svg?seed=OtakuNinja',
  'https://api.dicebear.com/7.x/bottts/svg?seed=CyberSamurai',
  'https://api.dicebear.com/7.x/bottts/svg?seed=MechaZero',
  'https://api.dicebear.com/7.x/bottts/svg?seed=SakuraVibe',
  'https://api.dicebear.com/7.x/bottts/svg?seed=LunaGhost',
];

const BANNER_PRESETS = [
  'linear-gradient(135deg, #0f172a 0%, #1e1b4b 50%, #312e81 100%)',
  'linear-gradient(135deg, #1e1b4b 0%, #4338ca 50%, #6366f1 100%)',
  'linear-gradient(135deg, #064e3b 0%, #047857 50%, #10b981 100%)',
  'linear-gradient(135deg, #701a75 0%, #a21caf 50%, #e879f9 100%)',
  'linear-gradient(135deg, #7c2d12 0%, #c2410c 50%, #f97316 100%)',
];

export default function ProfilePage() {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [items, setItems] = useState<WatchlistItemRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  // Edit form state
  const [editUsername, setEditUsername] = useState('');
  const [editBio, setEditBio] = useState('');
  const [editPronouns, setEditPronouns] = useState('');
  const [editAvatarUrl, setEditAvatarUrl] = useState('');
  const [editBannerUrl, setEditBannerUrl] = useState('');
  const [saveLoading, setSaveLoading] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  const fetchUserData = async () => {
    // Check if returning from external OAuth redirect (#access_token=...)
    if (typeof window !== 'undefined' && window.location.hash.includes('access_token=')) {
      try {
        const hashParams = new URLSearchParams(window.location.hash.substring(1));
        const accessToken = hashParams.get('access_token');
        if (accessToken) {
          localStorage.setItem('kurogane_token', accessToken);
          window.history.replaceState(null, '', window.location.pathname);
        }
      } catch (err) {
        console.error('Error parsing OAuth hash token:', err);
      }
    }

    let token = typeof window !== 'undefined' ? localStorage.getItem('kurogane_token') : null;
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

      // Verify token & fetch latest profile from API
      const profileRes = await fetch(`${API_BASE_URL}/api/user/profile`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (profileRes.ok) {
        const profileData = await profileRes.json();
        if (profileData.profile) {
          setUser(profileData.profile);
          localStorage.setItem('kurogane_user', JSON.stringify(profileData.profile));
        }
      } else if (profileRes.status === 401) {
        localStorage.removeItem('kurogane_token');
        localStorage.removeItem('kurogane_user');
        setUser(null);
        setItems([]);
        setLoading(false);
        return;
      } else if (storedUser) {
        try {
          setUser(JSON.parse(storedUser));
        } catch (e) {}
      }

      // Fetch watchlist
      const watchlistRes = await fetch(`${API_BASE_URL}/api/watchlist`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (watchlistRes.ok) {
        const data = await watchlistRes.json();
        setItems(data.items || []);
      } else if (watchlistRes.status === 401) {
        localStorage.removeItem('kurogane_token');
        localStorage.removeItem('kurogane_user');
        setUser(null);
        setItems([]);
      }
    } catch (err) {
      console.error('Error loading profile page data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUserData();
  }, []);

  const openEditModal = () => {
    if (!user) return;
    setEditUsername(user.username || '');
    setEditBio(user.bio || '');
    setEditPronouns(user.pronouns || 'he/him');
    setEditAvatarUrl(user.avatarUrl || AVATAR_PRESETS[0]);
    setEditBannerUrl(user.bannerUrl || BANNER_PRESETS[0]);
    setIsEditModalOpen(true);
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    const token = localStorage.getItem('kurogane_token');
    if (!token || !user) return;

    setSaveLoading(true);
    setSaveSuccess(false);

    try {
      const res = await fetch(`${API_BASE_URL}/api/user/profile`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          username: editUsername.trim() || user.username,
          bio: editBio.trim(),
          pronouns: editPronouns.trim(),
          avatarUrl: editAvatarUrl.trim(),
          bannerUrl: editBannerUrl.trim(),
        }),
      });

      if (res.ok) {
        const data = await res.json();
        const updated = data.profile;
        setUser(updated);
        localStorage.setItem('kurogane_user', JSON.stringify(updated));
        setSaveSuccess(true);
        setTimeout(() => {
          setIsEditModalOpen(false);
          setSaveSuccess(false);
        }, 600);
      }
    } catch (err) {
      console.error('Error updating profile:', err);
    } finally {
      setSaveLoading(false);
    }
  };

  const handleRemoveItem = async (mediaId: string) => {
    const token = localStorage.getItem('kurogane_token');
    if (!token) return;

    try {
      await fetch(`${API_BASE_URL}/api/watchlist/${mediaId}`, {
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
    if (!token || newProgress < 0) return;

    try {
      const res = await fetch(`${API_BASE_URL}/api/watchlist`, {
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

  const handleLogout = async () => {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      console.error('Error signing out from Firebase:', e);
    }
    localStorage.removeItem('kurogane_token');
    localStorage.removeItem('kurogane_user');
    window.dispatchEvent(new Event('kurogane_auth_changed'));
    setUser(null);
    setItems([]);
  };

  // Stats calculation
  const totalEntries = items.length;
  const completedEntries = items.filter((i) => i.status === 'COMPLETED').length;
  const watchingEntries = items.filter((i) => i.status === 'WATCHING').length;
  const totalEpisodesWatched = items.reduce((acc, curr) => acc + (curr.progressEpisodes || 0), 0);
  const ratedItems = items.filter((i) => i.score && i.score > 0);
  const averageScore =
    ratedItems.length > 0
      ? (ratedItems.reduce((acc, curr) => acc + (curr.score || 0), 0) / ratedItems.length).toFixed(1)
      : 'N/A';

  const filteredItems = items
    .filter((i) => (activeTab === 'ALL' ? true : i.status === activeTab))
    .filter((i) => {
      if (!searchQuery) return true;
      const title = i.mediaItem?.title?.userPreferred || i.mediaItem?.title?.romaji || '';
      return title.toLowerCase().includes(searchQuery.toLowerCase());
    });

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 flex flex-col items-center justify-center min-h-[400px]">
        <div className="w-12 h-12 rounded-full border-4 border-amber-500/20 border-t-amber-500 animate-spin mb-4" />
        <p className="text-xs text-slate-400 font-mono animate-pulse">Se încarcă profilul Kurogane…</p>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 text-center">
        <div className="bg-[#0f172a]/90 border border-slate-800 rounded-3xl p-8 sm:p-12 shadow-2xl relative overflow-hidden">
          <div className="absolute -top-24 -right-24 w-72 h-72 bg-blue-600/10 rounded-full blur-3xl pointer-events-none" />
          <div className="w-16 h-16 rounded-2xl bg-blue-500/10 border border-blue-500/20 text-blue-400 mx-auto flex items-center justify-center mb-4">
            <User className="w-8 h-8" />
          </div>
          <h1 className="text-3xl font-bold font-heading bg-gradient-to-r from-blue-400 via-indigo-300 to-purple-400 bg-clip-text text-transparent mb-2">
            Profilul Tău Kurogane
          </h1>
          <p className="text-sm text-slate-400 max-w-md mx-auto mb-6">
            Conectează-te pentru a-ți personaliza profilul (avatar, descriere, pronume), a monitoriza episoadele vizionate și a accesa lista ta sincronizată.
          </p>
          <button
            onClick={() => setIsAuthOpen(true)}
            className="px-6 py-3 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-semibold text-sm shadow-lg shadow-blue-600/30 transition-all inline-flex items-center gap-2"
          >
            <Sparkles className="w-4 h-4" /> Autentificare Instantanee Pe Loc
          </button>
        </div>
        <AuthModal isOpen={isAuthOpen} onClose={() => setIsAuthOpen(false)} onSuccess={fetchUserData} />
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-6 pb-20">
      {/* Top Breadcrumb */}
      <div className="mb-4">
        <Link
          href="/"
          className="inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-blue-400 transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" /> Înapoi la Descoperire
        </Link>
      </div>

      {/* Hero Profile Card */}
      <div className="bg-bgSurface border border-borderSubtle rounded-3xl overflow-hidden shadow-xl relative mb-8">
        {/* Banner */}
        <div
          className="h-40 sm:h-52 w-full relative transition-all duration-300"
          style={{
            background: user?.bannerUrl || BANNER_PRESETS[0],
            backgroundSize: 'cover',
            backgroundPosition: 'center',
          }}
        >
          <div className="absolute inset-0 bg-gradient-to-t from-bgSurface via-bgSurface/40 to-transparent" />
          <button
            onClick={openEditModal}
            className="absolute top-4 right-4 px-3 py-1.5 rounded-xl bg-bgPrimary/80 hover:bg-bgPrimary border border-borderSubtle backdrop-blur-md text-textPrimary text-xs font-semibold flex items-center gap-1.5 transition-all shadow-md"
          >
            <Camera className="w-3.5 h-3.5 text-accentPrimary" /> Schimbă Banner / Profil
          </button>
        </div>

        {/* User Info Bar */}
        <div className="px-6 sm:px-8 pb-6 pt-0 relative -mt-16 sm:-mt-20">
          <div className="flex flex-col sm:flex-row items-start sm:items-end justify-between gap-4">
            <div className="flex flex-col sm:flex-row items-center sm:items-end gap-4 text-center sm:text-left w-full sm:w-auto">
              {/* Avatar Picture with Glow & Online Status */}
              <div className="relative group">
                <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-2xl p-1 bg-bgSurface border-2 border-accentPrimary/50 shadow-xl overflow-hidden relative">
                  <img
                    src={user?.avatarUrl || AVATAR_PRESETS[0]}
                    alt={user?.username}
                    className="w-full h-full rounded-xl object-cover bg-bgPrimary"
                  />
                </div>
                <span className="absolute bottom-1 right-1 w-4 h-4 rounded-full bg-signalLive border-2 border-bgSurface shadow-md" title="Cont Activ" />
              </div>

              {/* Username & Metadata */}
              <div className="space-y-1">
                <div className="flex items-center justify-center sm:justify-start gap-2 flex-wrap">
                  <h1 className="text-2xl sm:text-3xl font-semibold text-textPrimary font-heading">
                    {user?.username}
                  </h1>
                  {user?.pronouns && (
                    <span className="px-2.5 py-0.5 rounded-full bg-badgeViolet/20 border border-badgeViolet/30 text-badgeViolet text-[11px] font-semibold">
                      {user.pronouns}
                    </span>
                  )}
                  <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-signalLive/10 border border-signalLive/20 text-signalLive text-[11px] font-medium">
                    <UserCheck className="w-3 h-3" /> Membru Verificat
                  </span>
                </div>
                <p className="text-xs text-textSecondary">{user?.email}</p>
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2 w-full sm:w-auto justify-center sm:justify-end border-t sm:border-t-0 border-borderSubtle pt-4 sm:pt-0">
              <button
                onClick={openEditModal}
                className="px-4 py-2 rounded-xl bg-bgSurfaceHover hover:bg-bgSurfaceHover/80 border border-borderSubtle text-xs font-semibold text-textPrimary flex items-center gap-2 transition-all shadow-sm"
              >
                <Edit3 className="w-3.5 h-3.5 text-accentPrimary" /> Editează Profilul
              </button>

              <button
                onClick={handleLogout}
                className="px-3.5 py-2 rounded-xl bg-alertCoral/10 hover:bg-alertCoral/20 border border-alertCoral/30 text-xs font-semibold text-alertCoral flex items-center gap-1.5 transition-all"
                title="Deconectare"
              >
                <LogOut className="w-3.5 h-3.5" /> Deconectare
              </button>
            </div>
          </div>

          {/* Bio / Description */}
          <div className="mt-5 p-4 rounded-2xl bg-bgSurfaceHover/60 border border-borderSubtle text-xs text-textSecondary leading-relaxed relative">
            <p className="font-sans">
              {user?.bio ||
                'Entuziast Anime & Manga pe Kurogane. Colecționez serii epice, monitorizez episoadele și analizez ordine de vizionare!'}
            </p>
          </div>
        </div>
      </div>

      {/* Stats Cards Dashboard */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 mb-8">
        <div className="bg-bgSurface border border-borderSubtle rounded-2xl p-4 flex items-center gap-3.5 shadow-sm">
          <div className="p-3 rounded-xl bg-accentPrimary/10 border border-accentPrimary/20 text-accentPrimary">
            <Bookmark className="w-5 h-5" />
          </div>
          <div>
            <p className="text-[11px] text-textSecondary font-medium">Total Titluri</p>
            <p className="text-xl font-semibold text-textPrimary">{totalEntries}</p>
          </div>
        </div>

        <div className="bg-bgSurface border border-borderSubtle rounded-2xl p-4 flex items-center gap-3.5 shadow-sm">
          <div className="p-3 rounded-xl bg-signalLive/10 border border-signalLive/20 text-signalLive">
            <CheckCircle className="w-5 h-5" />
          </div>
          <div>
            <p className="text-[11px] text-textSecondary font-medium">Completate</p>
            <p className="text-xl font-semibold text-textPrimary">{completedEntries}</p>
          </div>
        </div>

        <div className="bg-bgSurface border border-borderSubtle rounded-2xl p-4 flex items-center gap-3.5 shadow-sm">
          <div className="p-3 rounded-xl bg-badgeViolet/10 border border-badgeViolet/20 text-badgeViolet">
            <Tv className="w-5 h-5" />
          </div>
          <div>
            <p className="text-[11px] text-textSecondary font-medium">Episoade Vizionate</p>
            <p className="text-xl font-semibold text-textPrimary">{totalEpisodesWatched}</p>
          </div>
        </div>

        <div className="bg-bgSurface border border-borderSubtle rounded-2xl p-4 flex items-center gap-3.5 shadow-sm">
          <div className="p-3 rounded-xl bg-scoreGold/10 border border-scoreGold/20 text-scoreGold">
            <Star className="w-5 h-5 fill-scoreGold/20" />
          </div>
          <div>
            <p className="text-[11px] text-slate-400 font-medium">Nota Medie</p>
            <p className="text-xl font-bold text-slate-100">{averageScore}</p>
          </div>
        </div>
      </div>

      {/* Watchlist Section */}
      <div className="bg-[#0f172a] border border-slate-800 rounded-3xl p-6 shadow-xl">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6 pb-4 border-b border-slate-800">
          <div>
            <h2 className="text-xl font-bold text-slate-100 flex items-center gap-2 font-heading">
              <Bookmark className="w-5 h-5 text-blue-400" /> Colecția Ta & Watchlist
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Gestionează progresul episoadelor, statusul și notele pentru seriile tale salvate.
            </p>
          </div>

          <div className="w-full sm:w-64">
            <input
              type="text"
              placeholder="Caută în watchlist-ul tău..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus:outline-none focus:border-blue-500 transition-all"
            />
          </div>
        </div>

        {/* Tab Filters */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 mb-6 scrollbar-none">
          {Object.entries(STATUS_LABELS).map(([key, label]) => {
            const count = key === 'ALL' ? items.length : items.filter((i) => i.status === key).length;
            return (
              <button
                key={key}
                onClick={() => setActiveTab(key)}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all whitespace-nowrap flex items-center gap-1.5 ${
                  activeTab === key
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                    : 'bg-slate-900 text-slate-400 hover:text-slate-200 border border-slate-800 hover:border-slate-700'
                }`}
              >
                <span>{label}</span>
                <span className={`px-1.5 py-0.2 rounded-md text-[10px] ${activeTab === key ? 'bg-white/20 text-white' : 'bg-slate-800 text-slate-400'}`}>
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Items Grid / List */}
        {filteredItems.length === 0 ? (
          <div className="text-center py-12 border border-dashed border-borderSubtle rounded-2xl bg-bgSurface/40">
            <Bookmark className="w-10 h-10 text-textSecondary mx-auto mb-2" />
            <p className="text-sm font-semibold text-textPrimary">Niciun titlu în această categorie</p>
            <p className="text-xs text-textSecondary mt-1 max-w-sm mx-auto">
              Adaugă serii anime sau manga din pagina de căutare pentru a le monitoriza în profilul tău.
            </p>
            <Link
              href="/"
              className="mt-4 px-4 py-2 rounded-xl bg-accentPrimary hover:opacity-90 text-white text-xs font-semibold inline-flex items-center gap-1.5 transition-all shadow-sm"
            >
              <Plus className="w-4 h-4" /> Explorează Anime & Manga
            </Link>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredItems.map((item) => {
              const media = item.mediaItem;
              if (!media) return null;

              return (
                <div
                  key={item.id}
                  className="bg-bgSurface border border-borderSubtle hover:border-accentPrimary/50 rounded-2xl p-3.5 sm:p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 transition-all shadow-sm"
                >
                  <div className="flex items-center gap-3.5 w-full sm:w-auto">
                    <Link href={`/media/${media.id}`} className="shrink-0 group relative overflow-hidden rounded-xl">
                      <img
                        src={media.coverImage?.large || media.coverImage?.medium}
                        alt={media.title.userPreferred}
                        className="w-14 h-20 object-cover rounded-xl group-hover:scale-105 transition-transform"
                      />
                    </Link>

                    <div className="space-y-1 min-w-0 flex-1">
                      <Link
                        href={`/media/${media.id}`}
                        className="font-bold text-sm text-textPrimary hover:text-accentPrimary transition-colors line-clamp-1"
                      >
                        {media.title.userPreferred}
                      </Link>
                      <div className="flex items-center gap-2 text-[11px] text-textSecondary flex-wrap">
                        <span className="px-2 py-0.5 rounded-md bg-bgSurfaceHover text-textPrimary font-medium">{media.type}</span>
                        {media.format && <span>• {media.format}</span>}
                        {media.year && <span>• {media.year}</span>}
                      </div>

                      <div className="flex items-center gap-2 pt-1 text-xs">
                        <span className="inline-flex items-center gap-1 text-scoreGold font-semibold text-[11px]">
                          <Star className="w-3 h-3 fill-scoreGold" /> {(media.scores?.weightedScore || 8.0).toFixed(1)}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Actions & Progress */}
                  <div className="flex items-center justify-between sm:justify-end gap-4 w-full sm:w-auto border-t sm:border-t-0 border-borderSubtle pt-3 sm:pt-0">
                    {/* Episodes Progress Control */}
                    <div className="flex items-center gap-1.5 bg-bgPrimary border border-borderSubtle rounded-xl px-2 py-1">
                      <button
                        onClick={() => handleUpdateEpisodes(item, (item.progressEpisodes || 0) - 1)}
                        disabled={item.progressEpisodes <= 0}
                        className="p-1 rounded-lg hover:bg-bgSurfaceHover text-textSecondary hover:text-textPrimary disabled:opacity-30 transition-colors"
                      >
                        <Minus className="w-3.5 h-3.5" />
                      </button>
                      <span className="text-xs font-semibold text-textPrimary min-w-[3.5rem] text-center">
                        Ep. {item.progressEpisodes || 0}
                        {media.episodes ? ` / ${media.episodes}` : ''}
                      </span>
                      <button
                        onClick={() => handleUpdateEpisodes(item, (item.progressEpisodes || 0) + 1)}
                        className="p-1 rounded-lg hover:bg-bgSurfaceHover text-textSecondary hover:text-textPrimary transition-colors"
                      >
                        <Plus className="w-3.5 h-3.5" />
                      </button>
                    </div>

                    <button
                      onClick={() => handleRemoveItem(item.mediaId)}
                      className="p-2 rounded-xl text-textSecondary hover:text-alertCoral hover:bg-alertCoral/10 border border-transparent hover:border-alertCoral/20 transition-all"
                      title="Șterge din Watchlist"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Edit Profile Modal */}
      {isEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200">
          <div className="bg-bgSurface border border-borderSubtle rounded-3xl w-full max-w-lg p-6 sm:p-8 shadow-2xl relative max-h-[90vh] overflow-y-auto text-textPrimary">
            <button
              onClick={() => setIsEditModalOpen(false)}
              className="absolute top-4 right-4 p-2 rounded-xl text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="mb-6">
              <h3 className="text-xl font-bold text-textPrimary flex items-center gap-2 font-heading">
                <Edit3 className="w-5 h-5 text-accentPrimary" /> Editează Profilul Tău
              </h3>
              <p className="text-xs text-textSecondary mt-1">
                Personalizează-ți numele de utilizator, pronumele, avatarul și descrierea publică.
              </p>
            </div>

            {saveSuccess && (
              <div className="mb-4 p-3 rounded-xl bg-signalLive/10 border border-signalLive/30 text-signalLive text-xs flex items-center gap-2">
                <CheckCircle className="w-4 h-4" /> Profilul a fost salvat cu succes!
              </div>
            )}

            <form onSubmit={handleSaveProfile} className="space-y-4">
              {/* Username */}
              <div>
                <label className="block text-xs font-semibold text-textSecondary mb-1">Nume Utilizator</label>
                <input
                  type="text"
                  required
                  value={editUsername}
                  onChange={(e) => setEditUsername(e.target.value)}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl px-3.5 py-2.5 text-xs text-textPrimary focus:outline-none focus:border-accentPrimary transition-all"
                />
              </div>

              {/* Pronouns */}
              <div>
                <label className="block text-xs font-semibold text-textSecondary mb-1">Pronume (opțional)</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {PRONOUN_PRESETS.map((p) => (
                    <button
                      type="button"
                      key={p}
                      onClick={() => setEditPronouns(p)}
                      className={`px-2.5 py-1 rounded-lg text-xs font-medium border transition-all ${
                        editPronouns === p
                          ? 'bg-accentPrimary text-white border-accentPrimary shadow-sm'
                          : 'bg-bgPrimary text-textSecondary border-borderSubtle hover:border-accentPrimary/50'
                      }`}
                    >
                      {p}
                    </button>
                  ))}
                </div>
                <input
                  type="text"
                  placeholder="Sau introdu pronume personalizate..."
                  value={editPronouns}
                  onChange={(e) => setEditPronouns(e.target.value)}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl px-3.5 py-2 text-xs text-textPrimary focus:outline-none focus:border-accentPrimary transition-all"
                />
              </div>

              {/* Bio / Description */}
              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="block text-xs font-semibold text-textSecondary">Descriere / Bio</label>
                  <span className="text-[10px] text-textSecondary">{editBio.length} / 280 caractere</span>
                </div>
                <textarea
                  rows={3}
                  maxLength={280}
                  placeholder="Scrie câteva cuvinte despre pasiunea ta pentru anime & manga..."
                  value={editBio}
                  onChange={(e) => setEditBio(e.target.value)}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl p-3 text-xs text-textPrimary focus:outline-none focus:border-accentPrimary transition-all resize-none"
                />
              </div>

              {/* Avatar Selector */}
              <div>
                <label className="block text-xs font-semibold text-textSecondary mb-2">Alege Poză de Profil (Avatar)</label>
                <div className="grid grid-cols-6 gap-2 mb-3">
                  {AVATAR_PRESETS.map((preset, idx) => (
                    <button
                      type="button"
                      key={idx}
                      onClick={() => setEditAvatarUrl(preset)}
                      className={`relative rounded-xl p-1 border transition-all overflow-hidden bg-bgPrimary ${
                        editAvatarUrl === preset
                          ? 'border-accentPrimary ring-2 ring-accentPrimary/40'
                          : 'border-borderSubtle hover:border-textSecondary'
                      }`}
                    >
                      <img src={preset} alt="preset" className="w-full h-10 object-cover rounded-lg" />
                    </button>
                  ))}
                </div>
                <input
                  type="url"
                  placeholder="Sau lipește un URL cu poză personalizată (https://...)"
                  value={editAvatarUrl}
                  onChange={(e) => setEditAvatarUrl(e.target.value)}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl px-3.5 py-2 text-xs text-textPrimary focus:outline-none focus:border-accentPrimary transition-all"
                />
              </div>

              {/* Banner Selector */}
              <div>
                <label className="block text-xs font-semibold text-textSecondary mb-2">Alege Fundal / Banner Cover</label>
                <div className="grid grid-cols-5 gap-2">
                  {BANNER_PRESETS.map((preset, idx) => (
                    <button
                      type="button"
                      key={idx}
                      onClick={() => setEditBannerUrl(preset)}
                      className={`h-8 rounded-lg border transition-all ${
                        editBannerUrl === preset ? 'border-accentPrimary ring-2 ring-accentPrimary/40 scale-105' : 'border-borderSubtle'
                      }`}
                      style={{ background: preset }}
                    />
                  ))}
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-borderSubtle">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-4 py-2 rounded-xl bg-bgSurfaceHover text-textSecondary text-xs font-semibold transition-colors"
                >
                  Renunță
                </button>
                <button
                  type="submit"
                  disabled={saveLoading}
                  className="px-5 py-2 rounded-xl bg-accentPrimary hover:opacity-90 text-white text-xs font-bold shadow-md transition-all disabled:opacity-50 flex items-center gap-1.5"
                >
                  {saveLoading ? 'Se salvează...' : 'Salvează Profilul'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

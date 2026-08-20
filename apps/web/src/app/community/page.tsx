'use client';

import React from 'react';
import Link from 'next/link';
import {
  Users,
  MessageSquare,
  Sparkles,
  Flame,
  Award,
  Heart,
  TrendingUp,
  Share2,
  CheckCircle2,
  Compass,
} from 'lucide-react';

export default function CommunityPage() {
  const discussions = [
    {
      id: '1',
      title: 'Care este cel mai bun anime din sezonul curent și de ce?',
      author: 'KuroSlayer',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
      category: 'Discuție Sezon',
      replies: 42,
      likes: 128,
      time: 'acum 2 ore',
      tags: ['Sezonul Curent', 'Dezbateri'],
    },
    {
      id: '2',
      title: 'Top 5 francize cu cea mai complicată ordine de vizionare (Ghid Kurogane)',
      author: 'OtakuMaster_RO',
      authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80',
      category: 'Ghiduri & Cronologie',
      replies: 87,
      likes: 310,
      time: 'acum 5 ore',
      tags: ['Fate Series', 'Monogatari', 'Ghid'],
    },
    {
      id: '3',
      title: 'Anti-Review Bombing: Cum calculează Kurogane scorul ponderat real?',
      author: 'DevKurogane',
      authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&auto=format&fit=crop&q=80',
      category: 'Anunțuri Oficiale',
      replies: 64,
      likes: 254,
      time: 'ieri',
      tags: ['Algoritm', 'Transparență'],
    },
  ];

  return (
    <div className="max-w-6xl mx-auto px-4 pt-4 sm:pt-8 space-y-8">
      {/* Community Hero Header */}
      <div className="relative rounded-3xl overflow-hidden bg-bgSurface border border-borderSubtle p-6 sm:p-10 shadow-xl">
        <div className="relative z-10 max-w-2xl space-y-3">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-accentPrimary/10 border border-accentPrimary/20 text-accentPrimary text-xs font-semibold">
            <Users className="w-3.5 h-3.5" />
            Comunitatea Kurogane
          </div>
          <h1 className="text-2xl sm:text-4xl font-bold font-heading text-textPrimary">
            Locul unde fanii de anime & manga discută fără bias
          </h1>
          <p className="text-sm text-textSecondary leading-relaxed">
            Alătură-te dezbaterilor săptămânale, împărtășește liste de vizionare și descoperă recomandări autentice de la comunitate.
          </p>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Discussions */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold font-heading text-textPrimary flex items-center gap-2">
              <Flame className="w-4 h-4 text-highlightEmber" /> Discuții Populare
            </h2>
            <button className="px-3.5 py-1.5 rounded-xl bg-accentPrimary hover:opacity-90 text-white text-xs font-semibold shadow-sm transition-all">
              + Subiect Nou
            </button>
          </div>

          <div className="space-y-3">
            {discussions.map((disc) => (
              <div
                key={disc.id}
                className="bg-bgSurface rounded-2xl p-4 sm:p-5 border border-borderSubtle hover:border-accentPrimary/40 transition-all duration-200 shadow-sm space-y-3"
              >
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-0.5 rounded-full bg-bgPrimary text-accentPrimary border border-borderSubtle text-[10px] font-semibold">
                    {disc.category}
                  </span>
                  <span className="text-[11px] text-textSecondary">{disc.time}</span>
                </div>

                <h3 className="text-sm sm:text-base font-semibold text-textPrimary hover:text-accentPrimary transition-colors cursor-pointer leading-snug">
                  {disc.title}
                </h3>

                <div className="flex flex-wrap items-center justify-between pt-2 border-t border-borderSubtle/60 gap-2">
                  <div className="flex items-center gap-2">
                    <img
                      src={disc.authorAvatar}
                      alt={disc.author}
                      className="w-5 h-5 rounded-full object-cover"
                    />
                    <span className="text-xs text-textSecondary font-medium">{disc.author}</span>
                  </div>

                  <div className="flex items-center gap-4 text-xs text-textSecondary">
                    <span className="flex items-center gap-1">
                      <MessageSquare className="w-3.5 h-3.5" /> {disc.replies}
                    </span>
                    <span className="flex items-center gap-1 text-alertCoral">
                      <Heart className="w-3.5 h-3.5 fill-alertCoral/20" /> {disc.likes}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right Col: Community Stats & Discord Card */}
        <div className="space-y-4">
          <div className="bg-bgSurface rounded-2xl p-5 border border-borderSubtle shadow-sm space-y-4">
            <h3 className="text-sm font-bold font-heading text-textPrimary flex items-center gap-2">
              <Award className="w-4 h-4 text-scoreGold" /> Regulile Comunității
            </h3>
            <ul className="text-xs text-textSecondary space-y-2.5">
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-3.5 h-3.5 text-signalLive shrink-0 mt-0.5" />
                Fără spoilere fără tag-ul dedicat de spoiler.
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-3.5 h-3.5 text-signalLive shrink-0 mt-0.5" />
                Fără review bombing sau voturi masive de spam.
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-3.5 h-3.5 text-signalLive shrink-0 mt-0.5" />
                Respect reciproc și dezbateri constructive.
              </li>
            </ul>
          </div>

          <div className="bg-gradient-to-br from-indigo-950/60 to-purple-950/60 rounded-2xl p-5 border border-indigo-700/40 shadow-sm space-y-3">
            <div className="flex items-center gap-2 text-indigo-300 text-xs font-semibold">
              <Sparkles className="w-4 h-4 text-badgeViolet" /> Discord Kurogane
            </div>
            <p className="text-xs text-slate-300 leading-relaxed">
              Vrei să discuți live despre episoadele noi la fiecare oră de difuzare? Intră pe serverul nostru!
            </p>
            <button className="w-full py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs transition-colors shadow-md">
              Alătură-te pe Discord
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

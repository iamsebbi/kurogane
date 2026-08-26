import React from "react";

export function HeroSkeleton() {
  return (
    <div className="relative h-full flex flex-col justify-end p-6 sm:p-10 lg:p-14 pb-16 sm:pb-20 lg:pb-24 xl:pb-26 animate-skeleton-blur">
      {/* Top-Left Badges Skeleton */}
      <div className="absolute top-6 left-6 lg:top-8 lg:left-10 z-30 flex items-center gap-2.5">
        <div className="h-7 w-44 rounded-full bg-bgSurfaceHover animate-skeleton-shimmer" />
        <div className="h-4 w-20 rounded-full bg-bgSurfaceHover/60 hidden sm:block" />
      </div>

      {/* Right-Side Silhouette placeholder */}
      <div className="hero-art-mask absolute inset-y-0 right-0 w-full md:w-[70%] lg:w-[60%] xl:w-[54%] h-full pointer-events-none overflow-hidden">
        <div className="w-full h-full bg-gradient-to-l from-bgSurfaceHover/50 via-bgSurfaceHover/20 to-transparent animate-skeleton-shimmer" />
      </div>

      {/* Blending Gradients Overlay (same as real hero) */}
      <div className="absolute inset-0 bg-gradient-to-r from-bgSurface via-bgSurface/90 via-25% md:via-35% to-transparent z-20 pointer-events-none" />

      {/* Content Banner Skeleton */}
      <div className="relative z-20 max-w-3xl lg:max-w-4xl space-y-4">
        {/* Title skeleton */}
        <div className="space-y-2.5">
          <div className="h-9 sm:h-11 md:h-12 w-[80%] sm:w-[65%] rounded-2xl bg-bgSurfaceHover animate-skeleton-shimmer" />
          <div className="h-9 sm:h-11 md:h-12 w-[55%] sm:w-[40%] rounded-2xl bg-bgSurfaceHover/80 animate-skeleton-shimmer" />
        </div>

        {/* Synopsis skeleton */}
        <div className="space-y-2 max-w-2xl pt-1">
          <div className="h-3.5 sm:h-4 w-full rounded-full bg-bgSurfaceHover/70" />
          <div className="h-3.5 sm:h-4 w-[92%] rounded-full bg-bgSurfaceHover/70" />
          <div className="h-3.5 sm:h-4 w-[65%] rounded-full bg-bgSurfaceHover/70" />
        </div>

        {/* Genre Chips skeleton */}
        <div className="flex flex-wrap gap-2 pt-1">
          <div className="h-7 w-20 rounded-full bg-bgSurfaceHover/80" />
          <div className="h-7 w-24 rounded-full bg-bgSurfaceHover/80" />
          <div className="h-7 w-16 rounded-full bg-bgSurfaceHover/80" />
          <div className="h-7 w-28 rounded-full bg-bgSurfaceHover/80" />
        </div>

        {/* Action Buttons skeleton */}
        <div className="flex items-center gap-3 pt-2">
          <div className="h-11 sm:h-12 w-48 rounded-full bg-accentPrimary/50 animate-skeleton-shimmer" />
          <div className="h-11 sm:h-12 w-44 rounded-full bg-bgSurfaceHover/80" />
        </div>
      </div>

      {/* Dots skeleton at bottom-right */}
      <div className="absolute bottom-6 right-6 lg:bottom-10 lg:right-10 z-30 flex items-center gap-2 bg-bgSurface px-3 py-2 rounded-full border border-borderSubtle">
        <div className="w-10 sm:w-12 h-2 rounded-full bg-accentPrimary/40" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
        <div className="w-2 h-2 rounded-full bg-borderSubtle" />
      </div>
    </div>
  );
}

export function SeasonalCardsSkeleton() {
  return (
    <div className="flex gap-5 md:gap-6 lg:gap-8 overflow-hidden pb-3 pt-1">
      {[1, 2, 3].map((n) => (
        <div
          key={n}
          className="relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle flex flex-row shrink-0 w-full md:w-[calc((100%-24px)/2)] lg:w-[calc((100%-64px)/3)] h-[250px] sm:h-[270px] md:h-[285px] lg:h-[295px] shadow-md animate-skeleton-blur"
        >
          <div className="flex-1 p-5 sm:p-6 flex flex-col justify-between min-w-0 z-10 space-y-2">
            <div className="flex items-center gap-2">
              <div className="h-5 w-16 rounded-full bg-bgSurfaceHover" />
              <div className="h-4 w-20 rounded-full bg-bgSurfaceHover/60" />
            </div>

            <div className="space-y-2 my-auto">
              <div className="h-6 w-[85%] rounded-xl bg-bgSurfaceHover animate-skeleton-shimmer" />
              <div className="h-6 w-[55%] rounded-xl bg-bgSurfaceHover/80 animate-skeleton-shimmer" />
              <div className="h-3.5 w-full rounded-full bg-bgSurfaceHover/50 mt-2" />
              <div className="h-3.5 w-[75%] rounded-full bg-bgSurfaceHover/50" />
            </div>

            <div className="flex items-center gap-1.5 pt-1">
              <div className="h-6 w-16 rounded-full bg-bgSurfaceHover/80" />
              <div className="h-6 w-14 rounded-full bg-bgSurfaceHover/80" />
              <div className="h-6 w-20 rounded-full bg-bgSurfaceHover/80" />
            </div>
          </div>

          <div className="landscape-art-mask w-[160px] sm:w-[200px] md:w-[230px] lg:w-[260px] h-full relative shrink-0 overflow-hidden bg-bgSurfaceHover/40 animate-skeleton-shimmer" />
        </div>
      ))}
    </div>
  );
}

export function RecentlyAiredSkeleton() {
  return (
    <div className="flex gap-4 sm:gap-5 md:gap-6 overflow-hidden pb-4 pt-1">
      {[1, 2, 3, 4, 5, 6].map((n) => (
        <div
          key={n}
          className="relative bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle flex flex-col shrink-0 w-[170px] sm:w-[195px] md:w-[215px] lg:w-[225px] shadow-md animate-skeleton-blur"
        >
          <div className="relative aspect-[3/4] overflow-hidden rounded-t-3xl bg-bgSurfaceHover/50 animate-skeleton-shimmer">
            <div className="absolute top-3 left-3 h-6 w-16 rounded-full bg-bgSurface/80" />
            <div className="absolute top-3 right-3 h-6 w-10 rounded-full bg-bgSurface/80" />
          </div>

          <div className="p-4 sm:p-5 flex flex-col justify-between flex-1 space-y-3">
            <div className="space-y-1.5">
              <div className="h-4 w-[90%] rounded-lg bg-bgSurfaceHover" />
              <div className="h-4 w-[60%] rounded-lg bg-bgSurfaceHover/80" />
            </div>
            <div className="h-3 w-20 rounded-full bg-bgSurfaceHover/60" />
          </div>
        </div>
      ))}
    </div>
  );
}

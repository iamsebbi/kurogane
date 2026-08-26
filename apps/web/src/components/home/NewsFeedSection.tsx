import React from "react";
import { NewsArticle } from "@kurogane/shared";
import { Calendar, Layers, ExternalLink } from "lucide-react";
import { getNewsBadgeConfig } from "./HomeHelpers";

interface NewsFeedSectionProps {
  newsBeta?: NewsArticle[];
}

export function NewsFeedSection({ newsBeta = [] }: NewsFeedSectionProps) {
  if (newsBeta.length === 0) return null;

  return (
    <section className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl sm:text-3xl lg:text-[32px] font-bold font-heading text-textPrimary tracking-tight">
          Noutăți Anime & Manga
        </h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {newsBeta.map((news) => {
          const badgeConfig = getNewsBadgeConfig(
            news.tagBadge,
            news.category,
          );
          const BadgeIcon = badgeConfig.icon;

          return (
            <a
              key={news.id}
              href={news.url || "#"}
              target="_blank"
              rel="noopener noreferrer"
              className="group bg-bgSurface rounded-3xl overflow-hidden border border-borderSubtle hover:border-accentPrimary/50 transition-all duration-300 flex flex-col justify-between p-4 sm:p-5 space-y-4 shadow-md hover:shadow-xl hover:-translate-y-1 text-left h-full"
            >
              <div className="space-y-3.5 flex-1 flex flex-col">
                <div className="flex items-center justify-between">
                  <span
                    className={`h-6 rounded-full text-[10px] font-bold shadow-sm inline-flex items-center overflow-hidden tracking-tight ${badgeConfig.className}`}
                  >
                    <span className="w-6 h-6 flex items-center justify-center shrink-0">
                      <BadgeIcon className="w-3 h-3" />
                    </span>
                    <span className="pr-2.5 -ml-1 uppercase">
                      {badgeConfig.label}
                    </span>
                  </span>
                  <span className="text-[11px] text-textSecondary font-medium flex items-center gap-1.5">
                    <Calendar className="w-3 h-3 text-textMuted" />{" "}
                    {news.date}
                  </span>
                </div>

                {news.imageUrl && (
                  <div className="aspect-[16/9] rounded-2xl overflow-hidden bg-bgSurfaceHover relative shrink-0">
                    <img
                      src={news.imageUrl}
                      alt={news.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                  </div>
                )}

                <h3 className="text-sm sm:text-[15px] font-bold text-textPrimary group-hover:text-accentPrimary transition-colors leading-snug line-clamp-2 min-h-[2.6rem] font-heading tracking-tight">
                  {news.title}
                </h3>

                <p className="text-xs sm:text-[13px] text-textSecondary line-clamp-2 min-h-[2.4rem] leading-relaxed">
                  {(news.summary || "").replace(/<[^>]*>?/gm, "")}
                </p>
              </div>

              <div className="pt-2 flex items-center justify-between text-xs text-textSecondary font-medium mt-auto">
                <span className="text-textSecondary flex items-center gap-1.5 truncate">
                  <Layers className="w-3 h-3 text-accentPrimary shrink-0" />{" "}
                  {news.source}
                </span>
                <span className="text-accentPrimary font-bold group-hover:translate-x-0.5 transition-transform flex items-center gap-1 shrink-0">
                  Citește știrea <ExternalLink className="w-3.5 h-3.5" />
                </span>
              </div>
            </a>
          );
        })}
      </div>
    </section>
  );
}

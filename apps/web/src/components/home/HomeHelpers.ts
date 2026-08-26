import { MediaItem } from "@kurogane/shared";
import { Sun, Snowflake, Flower2, Leaf, Tv, BookOpen, Film, Newspaper } from "lucide-react";

export const MAJOR_GENRES = [
  "Action",
  "Adventure",
  "Comedy",
  "Drama",
  "Fantasy",
  "Sci-Fi",
  "Mystery",
  "Horror",
  "Romance",
  "Slice of Life",
  "Sports",
  "Supernatural",
  "Thriller",
  "Mecha",
  "Psychological",
];

export const MICRO_TAGS = [
  { tag: "Overpowered MC", label: "⚡ Overpowered MC" },
  { tag: "Isekai", label: "🌀 Isekai" },
  { tag: "Anti-Hero", label: "🗡️ Anti-hero" },
  { tag: "Xianxia", label: "🥋 Xianxia / Cultivare" },
  { tag: "Cyberpunk", label: "🌃 Cyberpunk" },
  { tag: "Post-Apocalyptic", label: "☣️ Post-Apocaliptic" },
  { tag: "High Fantasy", label: "🏰 High Fantasy" },
  { tag: "Time Travel", label: "⏳ Time travel" },
  { tag: "Revenge", label: "🔥 Revenge" },
  { tag: "Female Protagonist", label: "👑 Protagonistă feminină" },
  { tag: "School Life", label: "🎓 Viață școlară" },
  { tag: "Virtual Reality", label: "🥽 Realitate virtuală" },
];

export const getDynamicSeasonLabel = (item?: MediaItem): string => {
  if (item?.season) {
    const map: Record<string, string> = {
      WINTER: "Winter",
      SPRING: "Spring",
      SUMMER: "Summer",
      FALL: "Autumn",
      AUTUMN: "Autumn",
    };
    const s = map[item.season.toUpperCase()] || item.season;
    return item.year ? `${s} ${item.year}` : s;
  }
  const now = new Date();
  const m = now.getMonth();
  const year = now.getFullYear();
  let s = "Winter";
  if (m >= 2 && m <= 4) s = "Spring";
  else if (m >= 5 && m <= 7) s = "Summer";
  else if (m >= 8 && m <= 10) s = "Autumn";
  return `${s} ${year}`;
};

export const getCurrentSeasonInfo = (item?: MediaItem) => {
  const label = getDynamicSeasonLabel(item);
  const upper = label.toUpperCase();
  const yearMatch = label.match(/\d{4}/);
  const year = yearMatch ? yearMatch[0] : new Date().getFullYear().toString();

  if (upper.includes("SUMMER") || upper.includes("VARĂ")) {
    return {
      title: `Anime • Sezonul de Vară ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de vară ${year}`,
      Icon: Sun,
      iconColor: "text-amber-400",
      iconBox: "bg-amber-500/10 border-amber-500/20 text-amber-400",
    };
  }
  if (upper.includes("WINTER") || upper.includes("IARNĂ")) {
    return {
      title: `Anime • Sezonul de Iarnă ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de iarnă ${year}`,
      Icon: Snowflake,
      iconColor: "text-sky-400",
      iconBox: "bg-sky-500/10 border-sky-500/20 text-sky-400",
    };
  }
  if (upper.includes("SPRING") || upper.includes("PRIMĂVARĂ")) {
    return {
      title: `Anime • Sezonul de Primăvară ${year}`,
      subtitle: `Cele mai populare titluri lansate în sezonul de primăvară ${year}`,
      Icon: Flower2,
      iconColor: "text-emerald-400",
      iconBox: "bg-emerald-500/10 border-emerald-500/20 text-emerald-400",
    };
  }
  return {
    title: `Anime • Sezonul de Toamnă ${year}`,
    subtitle: `Cele mai populare titluri lansate în sezonul de toamnă ${year}`,
    Icon: Leaf,
    iconColor: "text-orange-400",
    iconBox: "bg-orange-500/10 border-orange-500/20 text-orange-400",
  };
};

export const getMediaAccentColor = (item?: MediaItem): string => {
  if (item?.coverImage?.color && item.coverImage.color.startsWith("#")) {
    return item.coverImage.color;
  }
  const g = (item?.genres?.[0] || "").toLowerCase();
  if (g.includes("action") || g.includes("adventure")) return "#f43f5e"; // rose red
  if (
    g.includes("fantasy") ||
    g.includes("supernatural") ||
    g.includes("magic")
  )
    return "#a855f7"; // purple
  if (g.includes("comedy") || g.includes("slice of life")) return "#f59e0b"; // amber
  if (g.includes("romance") || g.includes("drama")) return "#ec4899"; // pink
  if (g.includes("sci-fi") || g.includes("mecha") || g.includes("cyberpunk"))
    return "#06b6d4"; // cyan
  return "#3b82f6"; // blue
};

export const getDisplayTitle = (title?: {
  english?: string;
  romaji?: string;
  native?: string;
  userPreferred?: string;
}): string => {
  if (!title) return "";
  return (
    title.english?.trim() ||
    title.userPreferred?.trim() ||
    title.romaji?.trim() ||
    ""
  );
};

export const getDisplayCardTitle = (title?: {
  english?: string;
  romaji?: string;
  native?: string;
  userPreferred?: string;
}): string => {
  const raw = getDisplayTitle(title);
  if (!raw) return "";
  return raw
    .replace(/\s*:\s*/g, ": ")
    .replace(/\s*-\s*/g, " - ")
    .replace(/\s*—\s*/g, " — ");
};

export const formatMediaFormat = (format?: string, type?: string): string => {
  if (!format && !type) return "Anime";
  const val = (format || type || "").toUpperCase();
  const formatMap: Record<string, string> = {
    TV_SHORT: "TV Short",
    TV: "TV",
    MOVIE: "Movie",
    OVA: "OVA",
    ONA: "ONA",
    SPECIAL: "Special",
    MUSIC: "Music",
    MANGA: "Manga",
    NOVEL: "Novel",
    ONE_SHOT: "One Shot",
    DONGHUA: "Donghua",
    AENI: "Aeni",
    MANHWA: "Manhwa",
    MANHUA: "Manhua",
    WEBTOON: "Webtoon",
  };
  return formatMap[val] || val.replace(/_/g, " ");
};

export const isFreshEpisode = (
  airDateExact?: string,
  airDateRelative?: string,
): boolean => {
  if (airDateExact) {
    const timestamp = new Date(airDateExact).getTime();
    if (!isNaN(timestamp)) {
      const diffHours = (Date.now() - timestamp) / (1000 * 60 * 60);
      if (diffHours >= 0 && diffHours < 24) return true;
      if (diffHours >= 24) return false;
    }
  }
  if (airDateRelative) {
    const isHoursOrMinutes = /oră|ore|minut|secund/i.test(airDateRelative);
    const isDaysOrWeeks = /zi|zile|săpt|luni|ani/i.test(airDateRelative);
    if (isHoursOrMinutes && !isDaysOrWeeks) return true;
  }
  return false;
};

export const getNewsBadgeConfig = (tagBadge?: string, category?: string) => {
  const tag = (tagBadge || category || "").toUpperCase();
  if (
    tag.includes("SEZON") ||
    tag.includes("ANIME") ||
    tag.includes("SERIE") ||
    tag.includes("TV")
  ) {
    return {
      label: tagBadge || "SEZON NOU",
      className: "bg-accentPrimary text-white shadow-sm",
      icon: Tv,
    };
  }
  if (
    tag.includes("CAPITOL") ||
    tag.includes("MANGA") ||
    tag.includes("MANHWA") ||
    tag.includes("MANHUA") ||
    tag.includes("NOVEL")
  ) {
    return {
      label: tagBadge || "CAPITOL NOU",
      className: "bg-badgeViolet text-slate-950 font-bold shadow-sm",
      icon: BookOpen,
    };
  }
  if (tag.includes("FILM") || tag.includes("MOVIE") || tag.includes("CINEMA")) {
    return {
      label: tagBadge || "FILM CINEMA",
      className: "bg-amber-500 text-slate-950 font-bold shadow-sm",
      icon: Film,
    };
  }
  return {
    label: tagBadge || "ANUNȚ OFICIAL",
    className: "bg-cyan-500 text-slate-950 font-bold shadow-sm",
    icon: Newspaper,
  };
};

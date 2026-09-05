import { Bindings } from '../types';

export interface NewsArticle {
  id: string;
  title: string;
  category: 'ANIME' | 'MANGA' | 'STUDIO' | 'MOVIE' | 'GAME';
  tagBadge: string;
  summary: string;
  content?: string;
  imageUrl: string;
  date: string;
  readTime: string;
  source: string;
  url?: string;
  // Aliases for cross-platform tolerance
  link?: string;
  pubDate?: string;
  thumbnailUrl?: string;
  contentSnippet?: string;
}

const CATEGORY_FALLBACK_IMAGES: Record<string, string[]> = {
  ANIME: [
    'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
  ],
  MANGA: [
    'https://images.unsplash.com/photo-1563089145-599997674d42?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80',
  ],
  MOVIE: [
    'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80',
  ],
  STUDIO: [
    'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop&q=80',
  ],
};

function decodeHTMLEntities(text: string): string {
  if (!text) return '';
  return text
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&#8217;/g, '’')
    .replace(/&#8216;/g, '‘')
    .replace(/&#8220;/g, '“')
    .replace(/&#8221;/g, '”')
    .replace(/&#8211;/g, '–')
    .replace(/&#8212;/g, '—')
    .replace(/&#8230;/g, '…')
    .replace(/&nbsp;/g, ' ')
    .trim();
}

function stripHTML(html: string): string {
  if (!html) return '';
  let clean = html.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/gi, '$1');
  clean = clean.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  clean = clean.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '');
  clean = clean.replace(/<[^>]+>/g, ' ');
  clean = decodeHTMLEntities(clean);
  return clean.replace(/\s+/g, ' ').trim();
}

function extractImageUrl(itemXml: string, rawDesc: string): string | null {
  const mediaContentMatch =
    itemXml.match(/<media:content[^>]+url=["']([^"']+\.(?:jpe?g|png|webp|gif|avif)[^"']*)["']/i) ||
    itemXml.match(/<media:content[^>]+url=["']([^"']+)["']/i);
  if (mediaContentMatch && mediaContentMatch[1] && mediaContentMatch[1].startsWith('http')) {
    return mediaContentMatch[1];
  }

  const mediaThumbMatch = itemXml.match(/<media:thumbnail[^>]+url=["']([^"']+)["']/i);
  if (mediaThumbMatch && mediaThumbMatch[1] && mediaThumbMatch[1].startsWith('http')) {
    return mediaThumbMatch[1];
  }

  const enclosureMatch = itemXml.match(/<enclosure[^>]+url=["']([^"']+)["']/i);
  if (enclosureMatch && enclosureMatch[1] && enclosureMatch[1].startsWith('http')) {
    return enclosureMatch[1];
  }

  const imgMatch =
    itemXml.match(/<img[^>]+src=["']([^"']+)["']/i) ||
    rawDesc.match(/<img[^>]+src=["']([^"']+)["']/i);
  if (imgMatch && imgMatch[1] && imgMatch[1].startsWith('http')) {
    return imgMatch[1];
  }

  const imageTagMatch = itemXml.match(/<image>\s*<url>([^<]+)<\/url>\s*<\/image>/i);
  if (imageTagMatch && imageTagMatch[1] && imageTagMatch[1].startsWith('http')) {
    return imageTagMatch[1].trim();
  }

  return null;
}

function getFallbackImage(id: string, category: string): string {
  const pool = CATEGORY_FALLBACK_IMAGES[category] || CATEGORY_FALLBACK_IMAGES.ANIME;
  let sum = 0;
  for (let i = 0; i < id.length; i++) {
    sum += id.charCodeAt(i);
  }
  return pool[sum % pool.length];
}

function formatRomanianDate(dateString: string): string {
  try {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return 'Recent';
    const months = [
      'Ianuarie',
      'Februarie',
      'Martie',
      'Aprilie',
      'Mai',
      'Iunie',
      'Iulie',
      'August',
      'Septembrie',
      'Octombrie',
      'Noiembrie',
      'Decembrie',
    ];
    return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;
  } catch {
    return 'Recent';
  }
}

function determineCategoryAndBadge(
  title: string,
  summary: string,
  sourceDefault: 'ANIME' | 'MANGA' | 'STUDIO' | 'MOVIE' | 'GAME'
): { category: 'ANIME' | 'MANGA' | 'STUDIO' | 'MOVIE' | 'GAME'; tagBadge: string } {
  const combined = `${title} ${summary}`.toLowerCase();
  if (/\b(movie|film|theatrical|cinema|filmul|trilogy)\b/i.test(combined)) {
    return { category: 'MOVIE', tagBadge: 'FILM CINEMA' };
  }
  if (/\b(manga|chapter|capitol|manhwa|manhua|webtoon|novel|light novel|illustrator|author|volume)\b/i.test(combined)) {
    return { category: 'MANGA', tagBadge: 'CAPITOL NOU' };
  }
  if (/\b(season|sezon|premiere|broadcast|air date|trailer|teaser|anime series|adaptation|cast|staff|promo)\b/i.test(combined)) {
    return { category: 'ANIME', tagBadge: 'SEZON NOU' };
  }
  return { category: sourceDefault, tagBadge: 'ANUNȚ OFICIAL' };
}

function parseRssFeed(xml: string, sourceName: string, defaultCategory: 'ANIME' | 'MANGA'): NewsArticle[] {
  const items: NewsArticle[] = [];
  const itemRegex = /<item\b[^>]*>([\s\S]*?)<\/item>/gi;
  let match: RegExpExecArray | null;

  while ((match = itemRegex.exec(xml)) !== null) {
    const itemContent = match[1];

    const titleMatch = itemContent.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i);
    const rawTitle = titleMatch ? titleMatch[1] : '';
    const title = stripHTML(rawTitle);
    if (!title) continue;

    const linkMatch = itemContent.match(/<link\b[^>]*>([\s\S]*?)<\/link>/i);
    const rawLink = linkMatch ? linkMatch[1].replace(/<!\[CDATA\[([\s\S]*?)\]\]>/gi, '$1').trim() : '';

    const dateMatch = itemContent.match(/<pubDate\b[^>]*>([\s\S]*?)<\/pubDate>/i);
    const pubDate = dateMatch ? dateMatch[1].trim() : new Date().toISOString();

    const descMatch =
      itemContent.match(/<content:encoded\b[^>]*>([\s\S]*?)<\/content:encoded>/i) ||
      itemContent.match(/<description\b[^>]*>([\s\S]*?)<\/description>/i);
    const rawDesc = descMatch ? descMatch[1] : '';
    const summary = stripHTML(rawDesc).slice(0, 300);

    const hashStr = `${title}-${rawLink}`;
    let hash = 0;
    for (let i = 0; i < hashStr.length; i++) {
      hash = ((hash << 5) - hash) + hashStr.charCodeAt(i);
      hash |= 0;
    }
    const id = `news-rss-${Math.abs(hash).toString(16)}`;

    const { category, tagBadge } = determineCategoryAndBadge(title, summary, defaultCategory);
    const extractedImg = extractImageUrl(itemContent, rawDesc);
    const imageUrl = extractedImg || getFallbackImage(id, category);

    const wordCount = (summary ? summary.split(/\s+/).length : 0) + (title ? title.split(/\s+/).length : 0);
    const readTimeMinutes = Math.max(1, Math.ceil(wordCount / 180));
    const readTime = `${readTimeMinutes} min lectură`;
    const formattedDate = formatRomanianDate(pubDate);

    items.push({
      id,
      title,
      category,
      tagBadge,
      summary,
      content: summary,
      imageUrl,
      date: formattedDate,
      readTime,
      source: sourceName,
      url: rawLink,
      link: rawLink,
      pubDate,
      thumbnailUrl: imageUrl,
      contentSnippet: summary,
    });
  }

  return items;
}

export async function fetchLiveRssNews(): Promise<NewsArticle[]> {
  const sources = [
    {
      name: 'Anime News Network',
      url: 'https://www.animenewsnetwork.com/all/rss.xml?ann-edition=us',
      category: 'ANIME' as const,
    },
    {
      name: 'Otaku USA Magazine',
      url: 'https://otakuusamagazine.com/feed/',
      category: 'ANIME' as const,
    },
  ];

  const results: NewsArticle[] = [];

  for (const src of sources) {
    try {
      const resp = await fetch(src.url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) KuroganeNews/1.0',
          'Accept': 'application/rss+xml, application/xml, text/xml; q=0.9, */*; q=0.8',
        },
      });
      if (resp.ok) {
        const text = await resp.text();
        const parsed = parseRssFeed(text, src.name, src.category);
        results.push(...parsed);
      }
    } catch (e: any) {
      console.warn(`[News RSS] Failed to fetch feed from ${src.name}:`, e.message);
    }
  }

  // Deduplicate by URL or title
  const seen = new Set<string>();
  const unique: NewsArticle[] = [];
  for (const item of results) {
    const key = (item.url || item.title).toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      unique.push(item);
    }
  }

  return unique;
}

export async function getNewsArticles(env: Bindings, limit: number = 20): Promise<NewsArticle[]> {
  try {
    const cached: any = await env.CACHE_KV.get('news:items', 'json');
    if (cached) {
      const list: NewsArticle[] = Array.isArray(cached) ? cached : (cached.items || cached.articles || []);
      if (list.length > 0) {
        return list.slice(0, limit);
      }
    }

    // Cache miss or empty: fetch live RSS feeds dynamically (zero hardcoded)
    const fresh = await fetchLiveRssNews();
    if (fresh.length > 0) {
      await env.CACHE_KV.put('news:items', JSON.stringify(fresh), { expirationTtl: 1800 });
      return fresh.slice(0, limit);
    }
  } catch (err: any) {
    console.error('[News Service] Error in getNewsArticles:', err.message);
  }

  return [];
}

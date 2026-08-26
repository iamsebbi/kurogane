import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { NewsArticle } from '@kurogane/shared';

const DATA_DIR = path.join(__dirname, '../../data');
const NEWS_FILE = path.join(DATA_DIR, 'news-db.json');

export interface RSSSource {
  name: string;
  url: string;
  categoryDefault: 'ANIME' | 'MANGA' | 'STUDIO' | 'MOVIE' | 'GAME';
}

export const RSS_SOURCES: RSSSource[] = [
  {
    name: 'Anime News Network',
    url: 'https://www.animenewsnetwork.com/all/rss.xml?ann-edition=us',
    categoryDefault: 'ANIME',
  },
  {
    name: 'Otaku USA Magazine',
    url: 'https://otakuusamagazine.com/feed/',
    categoryDefault: 'ANIME',
  },
  {
    name: 'Anime News Network (News)',
    url: 'https://www.animenewsnetwork.com/news/rss.xml?ann-edition=us',
    categoryDefault: 'ANIME',
  },
];

// Curated high-resolution aesthetic editorial imagery grouped by category
const CATEGORY_FALLBACK_IMAGES: Record<string, string[]> = {
  ANIME: [
    'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80', // Tokyo neon skyline
    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&auto=format&fit=crop&q=80', // Cyberpunk neon alley
    'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80', // Gaming anime setup
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80', // Sakura Japanese garden
  ],
  MANGA: [
    'https://images.unsplash.com/photo-1563089145-599997674d42?w=800&auto=format&fit=crop&q=80', // Graphic neon illustration
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&auto=format&fit=crop&q=80', // Manga volume shelf
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80', // Ink brush sketch
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800&auto=format&fit=crop&q=80', // Creative studio library
  ],
  MOVIE: [
    'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800&auto=format&fit=crop&q=80', // Cinema camera lens
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80', // Theatrical cinema seats
    'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800&auto=format&fit=crop&q=80', // Movie screen hall
  ],
  STUDIO: [
    'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800&auto=format&fit=crop&q=80', // Studio audio equipment
    'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop&q=80', // Digital animation matrix
    'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&auto=format&fit=crop&q=80', // Tech studio neon
  ],
};

function ensureDataDir(): void {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

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

/**
 * Robust two-pass HTML stripper + entity decoder
 */
export function stripHTML(html: string): string {
  if (!html) return '';
  // 1. Unwrap CDATA wrappers
  let clean = html.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/gi, '$1');
  // 2. Remove script and style elements
  clean = clean.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  clean = clean.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '');
  // 3. Strip all HTML / XML tags
  clean = clean.replace(/<[^>]+>/g, ' ');
  // 4. Decode HTML entities (e.g. &lt;cite&gt; -> <cite>)
  clean = decodeHTMLEntities(clean);
  // 5. Second pass in case decoded entities revealed new tags
  clean = clean.replace(/<[^>]+>/g, ' ');
  // 6. Clean whitespace
  return clean.replace(/\s+/g, ' ').trim();
}

/**
 * Extract image URL from XML item with comprehensive priority fallbacks
 */
function extractImageUrl(itemXml: string, rawDesc: string): string | null {
  // 1. Check <media:content url="..." />
  const mediaContentMatch =
    itemXml.match(/<media:content[^>]+url=["']([^"']+\.(?:jpe?g|png|webp|gif|avif)[^"']*)["']/i) ||
    itemXml.match(/<media:content[^>]+url=["']([^"']+)["']/i);
  if (mediaContentMatch && mediaContentMatch[1] && mediaContentMatch[1].startsWith('http')) {
    return mediaContentMatch[1];
  }

  // 2. Check <media:thumbnail url="..." />
  const mediaThumbMatch = itemXml.match(/<media:thumbnail[^>]+url=["']([^"']+)["']/i);
  if (mediaThumbMatch && mediaThumbMatch[1] && mediaThumbMatch[1].startsWith('http')) {
    return mediaThumbMatch[1];
  }

  // 3. Check <enclosure url="..." />
  const enclosureMatch = itemXml.match(/<enclosure[^>]+url=["']([^"']+)["']/i);
  if (enclosureMatch && enclosureMatch[1] && enclosureMatch[1].startsWith('http')) {
    return enclosureMatch[1];
  }

  // 4. Check <img src="..." /> inside itemXml or description
  const imgMatch =
    itemXml.match(/<img[^>]+src=["']([^"']+)["']/i) ||
    rawDesc.match(/<img[^>]+src=["']([^"']+)["']/i);
  if (imgMatch && imgMatch[1] && imgMatch[1].startsWith('http')) {
    return imgMatch[1];
  }

  // 5. Check <image><url>...</url></image>
  const imageTagMatch = itemXml.match(/<image>\s*<url>([^<]+)<\/url>\s*<\/image>/i);
  if (imageTagMatch && imageTagMatch[1] && imageTagMatch[1].startsWith('http')) {
    return imageTagMatch[1].trim();
  }

  return null;
}

function getFallbackImage(hashId: string, category: string): string {
  const pool = CATEGORY_FALLBACK_IMAGES[category] || CATEGORY_FALLBACK_IMAGES.ANIME;
  const sum = hashId.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
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
  sourceCategoryDefault: 'ANIME' | 'MANGA' | 'STUDIO' | 'MOVIE' | 'GAME'
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

  return { category: sourceCategoryDefault, tagBadge: 'ANUNȚ OFICIAL' };
}

class NewsAggregationService {
  private newsArticles: Map<string, NewsArticle> = new Map(); // id/link -> NewsArticle
  private isRefreshing: boolean = false;
  private intervalTimer: NodeJS.Timeout | null = null;

  constructor() {
    ensureDataDir();
    this.loadPersistedNews();
    // Fetch RSS updates on startup
    this.refreshAllFeeds().catch((err) => {
      console.error('[News RSS] Startup refresh error:', err);
    });

    // Schedule background periodic fetch every 60 minutes
    this.intervalTimer = setInterval(() => {
      this.refreshAllFeeds().catch((err) => {
        console.error('[News RSS] Periodic refresh error:', err);
      });
    }, 60 * 60 * 1000);
    this.intervalTimer.unref();
  }

  private loadPersistedNews(): void {
    try {
      if (fs.existsSync(NEWS_FILE)) {
        const content = fs.readFileSync(NEWS_FILE, 'utf-8');
        const list: NewsArticle[] = JSON.parse(content);
        for (const item of list) {
          // Re-sanitize any existing persisted data
          item.title = stripHTML(item.title);
          item.summary = stripHTML(item.summary);
          item.content = stripHTML(item.content || item.summary);

          const hashId = crypto.createHash('md5').update(item.url || item.title).digest('hex').substring(0, 12);
          if (!item.imageUrl || item.imageUrl.includes('photo-1563089145-599997674d42')) {
            item.imageUrl = getFallbackImage(hashId, item.category);
          }
          this.newsArticles.set(item.id, item);
        }
        console.log(`[News RSS] Loaded & sanitized ${this.newsArticles.size} persistent news articles from disk.`);
      }
    } catch (err) {
      console.error('[News RSS] Error loading news-db.json:', err);
    }
  }

  private savePersistedNews(): void {
    try {
      ensureDataDir();
      const articles = this.getAllArticles();
      const compactList = articles.slice(0, 100);
      fs.writeFileSync(NEWS_FILE, JSON.stringify(compactList, null, 2), 'utf-8');
    } catch (err) {
      console.error('[News RSS] Error saving news-db.json:', err);
    }
  }

  /**
   * Parse single XML item or entry into NewsArticle
   */
  private parseItem(itemXml: string, source: RSSSource): NewsArticle | null {
    try {
      // 1. Extract Title
      const titleMatch = itemXml.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
      const rawTitle = titleMatch ? stripHTML(titleMatch[1]) : '';
      if (!rawTitle || rawTitle.length < 5) return null;

      // 2. Extract Link / GUID
      const linkMatch =
        itemXml.match(/<link[^>]*href=["']([^"']+)["']/i) ||
        itemXml.match(/<link[^>]*>([\s\S]*?)<\/link>/i) ||
        itemXml.match(/<guid[^>]*>([\s\S]*?)<\/guid>/i);
      const url = linkMatch ? decodeHTMLEntities(linkMatch[1] || linkMatch[0]).trim() : '';

      // Create unique deterministic ID based on URL
      const hashId = crypto.createHash('md5').update(url || rawTitle).digest('hex').substring(0, 12);
      const id = `news-rss-${hashId}`;

      // 3. Extract Description / Content
      const descMatch =
        itemXml.match(/<description[^>]*>([\s\S]*?)<\/description>/i) ||
        itemXml.match(/<summary[^>]*>([\s\S]*?)<\/summary>/i) ||
        itemXml.match(/<content[^>]*>([\s\S]*?)<\/content>/i);
      const rawDesc = descMatch ? descMatch[1] : '';
      const cleanSummary = stripHTML(rawDesc).slice(0, 240);

      // 4. Extract Date
      const dateMatch =
        itemXml.match(/<pubDate[^>]*>([\s\S]*?)<\/pubDate>/i) ||
        itemXml.match(/<published[^>]*>([\s\S]*?)<\/published>/i) ||
        itemXml.match(/<updated[^>]*>([\s\S]*?)<\/updated>/i) ||
        itemXml.match(/<dc:date[^>]*>([\s\S]*?)<\/dc:date>/i);
      const rawDate = dateMatch ? stripHTML(dateMatch[1]) : new Date().toISOString();
      const formattedDate = formatRomanianDate(rawDate);

      // 5. Categorization
      const { category, tagBadge } = determineCategoryAndBadge(rawTitle, cleanSummary, source.categoryDefault);

      // 6. Extract Image with Priority Hierarchy & Categorized Fallback
      let imageUrl = extractImageUrl(itemXml, rawDesc);
      if (!imageUrl || !imageUrl.startsWith('http')) {
        imageUrl = getFallbackImage(hashId, category);
      }

      // Calculate approximate read time
      const wordCount = (cleanSummary || '').split(/\s+/).length + 30;
      const readTime = `${Math.max(1, Math.ceil(wordCount / 65))} min lectură`;

      return {
        id,
        title: rawTitle,
        category,
        tagBadge,
        summary: cleanSummary || 'Informații complete disponibile în articolul oficial.',
        content: cleanSummary || rawTitle,
        imageUrl,
        date: formattedDate,
        readTime,
        source: source.name,
        url: url || undefined,
        isBeta: true,
      };
    } catch (err) {
      return null;
    }
  }

  /**
   * Fetch and parse a single RSS Feed with timeout
   */
  public async fetchFeed(source: RSSSource): Promise<NewsArticle[]> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000); // 8s timeout

    try {
      const res = await fetch(source.url, {
        signal: controller.signal,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) KuroganeApp/1.0',
          Accept: 'application/rss+xml, application/xml, text/xml, application/atom+xml, text/plain;q=0.9, */*;q=0.8',
        },
      });

      if (!res.ok) {
        console.warn(`[News RSS] Feed responded with status ${res.status}: ${source.name}`);
        return [];
      }

      const xmlText = await res.text();
      const items: NewsArticle[] = [];

      // Split XML by <item> or <entry>
      const itemBlocks = xmlText.split(/<item[\s>]/i).slice(1);
      const entryBlocks = xmlText.split(/<entry[\s>]/i).slice(1);
      const rawBlocks = itemBlocks.length > 0 ? itemBlocks : entryBlocks;

      for (const block of rawBlocks.slice(0, 15)) {
        const parsed = this.parseItem(block, source);
        if (parsed) {
          items.push(parsed);
        }
      }

      return items;
    } catch (error: any) {
      console.warn(`[News RSS] Failed to fetch feed ${source.name}:`, error.message);
      return [];
    } finally {
      clearTimeout(timeout);
    }
  }

  /**
   * Refresh all registered RSS feeds, deduplicate and save
   */
  public async refreshAllFeeds(): Promise<NewsArticle[]> {
    if (this.isRefreshing) return this.getAllArticles();
    this.isRefreshing = true;

    try {
      console.log(`[News RSS] Refreshing ${RSS_SOURCES.length} RSS feeds...`);
      const results = await Promise.allSettled(RSS_SOURCES.map((s) => this.fetchFeed(s)));

      let addedCount = 0;
      for (const res of results) {
        if (res.status === 'fulfilled' && res.value && res.value.length > 0) {
          for (const item of res.value) {
            // Upsert / refresh sanitized version
            this.newsArticles.set(item.id, item);
            addedCount++;
          }
        }
      }

      if (addedCount > 0) {
        console.log(`[News RSS] Synced ${addedCount} articles. Total in database: ${this.newsArticles.size}`);
        this.savePersistedNews();
      }
    } catch (err) {
      console.error('[News RSS] Error refreshing feeds:', err);
    } finally {
      this.isRefreshing = false;
    }

    return this.getAllArticles();
  }

  /**
   * Return all articles sorted by recency
   */
  public getAllArticles(): NewsArticle[] {
    return Array.from(this.newsArticles.values());
  }

  /**
   * Get latest N news articles
   */
  public getLatest(limit: number = 4, category?: string): NewsArticle[] {
    let list = this.getAllArticles();
    if (category && category !== 'ALL') {
      list = list.filter((a) => a.category === category || a.tagBadge === category);
    }
    return list.slice(0, limit);
  }
}

export const newsAggregationService = new NewsAggregationService();

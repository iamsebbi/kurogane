import { Bindings } from '../types';

export interface NewsArticle {
  id: string;
  title: string;
  link: string;
  pubDate: string;
  source: string;
  contentSnippet?: string;
  thumbnailUrl?: string;
}

export async function getNewsArticles(env: Bindings, limit: number = 20): Promise<NewsArticle[]> {
  const cached: any = await env.CACHE_KV.get('news:items', 'json');
  if (cached) {
    const list: NewsArticle[] = Array.isArray(cached) ? cached : (cached.items || []);
    return list.slice(0, limit);
  }
  return [];
}

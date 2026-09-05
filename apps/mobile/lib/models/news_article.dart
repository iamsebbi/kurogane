class NewsArticle {
  final String id;
  final String title;
  final String category;
  final String tagBadge;
  final String summary;
  final String? content;
  final String imageUrl;
  final String date;
  final String readTime;
  final String source;
  final String? url;

  NewsArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.tagBadge,
    required this.summary,
    this.content,
    required this.imageUrl,
    required this.date,
    required this.readTime,
    required this.source,
    this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'ANIME',
      tagBadge: json['tagBadge'] as String? ?? 'HOT',
      summary: (json['summary'] ?? json['contentSnippet'] ?? json['description'] ?? '') as String,
      content: (json['content'] ?? json['summary'] ?? json['contentSnippet']) as String?,
      imageUrl: (json['imageUrl'] ?? json['thumbnailUrl'] ?? '') as String,
      date: (json['date'] ?? json['pubDate'] ?? '') as String,
      readTime: json['readTime'] as String? ?? '2 min',
      source: json['source'] as String? ?? 'Kurogane News',
      url: (json['url'] ?? json['link']) as String?,
    );
  }
}

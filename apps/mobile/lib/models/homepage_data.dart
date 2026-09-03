import 'media_item.dart';
import 'news_article.dart';

class RecentlyAiredEpisode {
  final MediaItem media;
  final int episodeNumber;
  final String? episodeTitle;
  final String airDateRelative;
  final String airDateExact;
  final String? thumbnailUrl;

  RecentlyAiredEpisode({
    required this.media,
    required this.episodeNumber,
    this.episodeTitle,
    required this.airDateRelative,
    required this.airDateExact,
    this.thumbnailUrl,
  });

  factory RecentlyAiredEpisode.fromJson(Map<String, dynamic> json) {
    return RecentlyAiredEpisode(
      media: MediaItem.fromJson(json['media'] as Map<String, dynamic>),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 1,
      episodeTitle: json['episodeTitle'] as String?,
      airDateRelative: json['airDateRelative'] as String? ?? 'Recent',
      airDateExact: json['airDateExact'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class RecommendedMediaItem {
  final MediaItem media;
  final String recommendationReason;
  final double? matchPercentage;
  final bool? isPersonalized;
  final String? badgeLabel;

  RecommendedMediaItem({
    required this.media,
    required this.recommendationReason,
    this.matchPercentage,
    this.isPersonalized,
    this.badgeLabel,
  });

  factory RecommendedMediaItem.fromJson(Map<String, dynamic> json) {
    return RecommendedMediaItem(
      media: MediaItem.fromJson(json['media'] as Map<String, dynamic>),
      recommendationReason: json['recommendationReason'] as String? ?? 'Recommended for you',
      matchPercentage: (json['matchPercentage'] as num?)?.toDouble(),
      isPersonalized: json['isPersonalized'] as bool? ?? false,
      badgeLabel: json['badgeLabel'] as String?,
    );
  }
}

class HomepageData {
  final List<MediaItem> featuredSeason;
  final List<RecentlyAiredEpisode> recentlyAired;
  final List<NewsArticle> newsBeta;
  final List<RecommendedMediaItem> recommendations;
  final List<MediaItem> topAiring;
  final List<MediaItem> topUpcoming;
  final List<MediaItem> top100;

  HomepageData({
    this.featuredSeason = const [],
    this.recentlyAired = const [],
    this.newsBeta = const [],
    this.recommendations = const [],
    this.topAiring = const [],
    this.topUpcoming = const [],
    this.top100 = const [],
  });

  // Aliases for view convenience
  List<MediaItem> get heroItems => featuredSeason;
  List<MediaItem> get trendingSeason => topAiring.isNotEmpty ? topAiring : featuredSeason;
  List<NewsArticle> get news => newsBeta;

  factory HomepageData.fromJson(Map<String, dynamic> json) {
    return HomepageData(
      featuredSeason: (json['featuredSeason'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentlyAired: (json['recentlyAired'] as List<dynamic>?)
              ?.map((e) => RecentlyAiredEpisode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      newsBeta: (json['newsBeta'] as List<dynamic>?)
              ?.map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => RecommendedMediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topAiring: (json['topAiring'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topUpcoming: (json['topUpcoming'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      top100: (json['top100'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

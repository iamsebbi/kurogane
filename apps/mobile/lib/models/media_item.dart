import 'score_metrics.dart';

class MediaTitle {
  final String? romaji;
  final String? english;
  final String? native;
  final String userPreferred;

  MediaTitle({
    this.romaji,
    this.english,
    this.native,
    required this.userPreferred,
  });

  factory MediaTitle.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MediaTitle(userPreferred: 'Unknown Title');
    }
    return MediaTitle(
      romaji: json['romaji'] as String?,
      english: json['english'] as String?,
      native: json['native'] as String?,
      userPreferred: json['userPreferred'] as String? ?? json['romaji'] ?? json['english'] ?? 'Unknown Title',
    );
  }
}

class CoverImage {
  final String? extraLarge;
  final String large;
  final String? medium;
  final String? color;

  CoverImage({
    this.extraLarge,
    required this.large,
    this.medium,
    this.color,
  });

  factory CoverImage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CoverImage(large: '');
    }
    return CoverImage(
      extraLarge: json['extraLarge'] as String?,
      large: json['large'] as String? ?? json['medium'] ?? '',
      medium: json['medium'] as String?,
      color: json['color'] as String?,
    );
  }
}

class MediaItem {
  final String id;
  final int? anilistId;
  final MediaTitle title;
  final String type; // ANIME, DONGHUA, AENI, MANGA, MANHWA, MANHUA, WEBTOON
  final String? format; // TV, MOVIE, OVA, ONA, SPECIAL, etc.
  final String? status;
  final String? demographic;
  final List<String> microTags;
  final int? episodes;
  final int? chapters;
  final List<String> genres;
  final String? description;
  final CoverImage coverImage;
  final String? bannerImage;
  final int? year;
  final String? season;
  final List<String> studios;
  final String? trailerUrl;
  final String? franchiseId;
  final ScoreMetrics scores;

  MediaItem({
    required this.id,
    this.anilistId,
    required this.title,
    required this.type,
    this.format,
    this.status,
    this.demographic,
    this.microTags = const [],
    this.episodes,
    this.chapters,
    this.genres = const [],
    this.description,
    required this.coverImage,
    this.bannerImage,
    this.year,
    this.season,
    this.studios = const [],
    this.trailerUrl,
    this.franchiseId,
    required this.scores,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id']?.toString() ?? '',
      anilistId: json['anilistId'] as int?,
      title: MediaTitle.fromJson(json['title'] as Map<String, dynamic>?),
      type: json['type'] as String? ?? 'ANIME',
      format: json['format'] as String?,
      status: json['status'] as String?,
      demographic: json['demographic'] as String?,
      microTags: (json['microTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      episodes: json['episodes'] as int?,
      chapters: json['chapters'] as int?,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] as String?,
      coverImage: CoverImage.fromJson(json['coverImage'] as Map<String, dynamic>?),
      bannerImage: json['bannerImage'] as String?,
      year: json['year'] as int?,
      season: json['season'] as String?,
      studios: (json['studios'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      trailerUrl: json['trailerUrl'] as String?,
      franchiseId: json['franchiseId'] as String?,
      scores: ScoreMetrics.fromJson(json['scores'] as Map<String, dynamic>?),
    );
  }
}

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

class MediaRelation {
  final String id;
  final int? anilistId;
  final String relationType; // PREQUEL, SEQUEL, SIDE_STORY, SPIN_OFF, ALTERNATIVE, SUMMARY, SOURCE, OTHER, CHARACTER, ADAPTATION
  final String title;
  final String? format; // TV, MOVIE, OVA, SPECIAL, etc.
  final String? type; // ANIME, MANGA
  final String? status;
  final String? season; // WINTER, SPRING, SUMMER, FALL
  final int? episodes;
  final int? releaseYear;
  final String? coverImage;

  MediaRelation({
    required this.id,
    this.anilistId,
    required this.relationType,
    required this.title,
    this.format,
    this.type,
    this.status,
    this.season,
    this.episodes,
    this.releaseYear,
    this.coverImage,
  });

  factory MediaRelation.fromJson(Map<String, dynamic> json) {
    return MediaRelation(
      id: json['id']?.toString() ?? '',
      anilistId: json['anilistId'] as int?,
      relationType: json['relationType'] as String? ?? 'OTHER',
      title: json['title'] as String? ?? 'Titlu Conex',
      format: json['format'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      season: json['season'] as String?,
      episodes: json['episodes'] as int?,
      releaseYear: (json['releaseYear'] ?? json['seasonYear']) as int?,
      coverImage: json['coverImage'] as String?,
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
  final List<MediaCharacter> characters;
  final List<MediaStaff> staff;
  final List<MediaThemeSong> themes;
  final CommunityMetrics? communityMetrics;
  final FuzzyDate? startDate;
  final FuzzyDate? endDate;
  final String? adaptationSource;
  final List<MediaRelation> relations;

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
    this.characters = const [],
    this.staff = const [],
    this.themes = const [],
    this.communityMetrics,
    this.startDate,
    this.endDate,
    this.adaptationSource,
    this.relations = const [],
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
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => MediaCharacter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      staff: (json['staff'] as List<dynamic>?)
              ?.map((e) => MediaStaff.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      themes: (json['themes'] as List<dynamic>?)
              ?.map((e) => MediaThemeSong.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      communityMetrics: json['communityMetrics'] != null
          ? CommunityMetrics.fromJson(json['communityMetrics'] as Map<String, dynamic>?)
          : null,
      startDate: json['startDate'] != null
          ? FuzzyDate.fromJson(json['startDate'] as Map<String, dynamic>?)
          : null,
      endDate: json['endDate'] != null
          ? FuzzyDate.fromJson(json['endDate'] as Map<String, dynamic>?)
          : null,
      adaptationSource: json['adaptationSource'] as String?,
      relations: (json['relations'] as List<dynamic>?)
              ?.map((e) => MediaRelation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class FuzzyDate {
  final int? year;
  final int? month;
  final int? day;

  FuzzyDate({this.year, this.month, this.day});

  factory FuzzyDate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return FuzzyDate();
    return FuzzyDate(
      year: json['year'] as int?,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
      };

  bool get isEmpty => year == null && month == null && day == null;
  bool get isNotEmpty => !isEmpty;

  String formatDisplay() {
    if (year == null) return 'Unspecified';
    const monthsEn = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (day != null && month != null && month! >= 1 && month! <= 12) {
      return '${monthsEn[month!]} $day, $year';
    } else if (month != null && month! >= 1 && month! <= 12) {
      return '${monthsEn[month!]} $year';
    }
    return '$year';
  }

  String formatRomanian() => formatDisplay();
}

class VoiceActor {
  final int id;
  final String name;
  final String? image;
  final String? language;

  VoiceActor({
    required this.id,
    required this.name,
    this.image,
    this.language,
  });

  factory VoiceActor.fromJson(Map<String, dynamic> json) {
    return VoiceActor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      language: json['language'] as String?,
    );
  }
}

class MediaCharacter {
  final int id;
  final String name;
  final String? image;
  final String role;
  final VoiceActor? voiceActor;

  MediaCharacter({
    required this.id,
    required this.name,
    this.image,
    required this.role,
    this.voiceActor,
  });

  factory MediaCharacter.fromJson(Map<String, dynamic> json) {
    return MediaCharacter(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      role: json['role'] as String? ?? 'SUPPORTING',
      voiceActor: json['voiceActor'] != null
          ? VoiceActor.fromJson(json['voiceActor'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MediaStaff {
  final int id;
  final String name;
  final String? image;
  final String role;

  MediaStaff({
    required this.id,
    required this.name,
    this.image,
    required this.role,
  });

  factory MediaStaff.fromJson(Map<String, dynamic> json) {
    return MediaStaff(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      role: json['role'] as String? ?? '',
    );
  }
}

class MediaThemeSong {
  final String type;
  final String title;
  final List<String> artists;
  final String? episodes;

  MediaThemeSong({
    required this.type,
    required this.title,
    required this.artists,
    this.episodes,
  });

  factory MediaThemeSong.fromJson(Map<String, dynamic> json) {
    return MediaThemeSong(
      type: json['type'] as String? ?? 'OP',
      title: json['title'] as String? ?? '',
      artists: (json['artists'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      episodes: json['episodes'] as String?,
    );
  }
}

class CommunityRanking {
  final int rank;
  final String type;
  final String context;
  final bool allTime;

  CommunityRanking({
    required this.rank,
    required this.type,
    required this.context,
    required this.allTime,
  });

  factory CommunityRanking.fromJson(Map<String, dynamic> json) {
    return CommunityRanking(
      rank: json['rank'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      context: json['context'] as String? ?? '',
      allTime: json['allTime'] as bool? ?? false,
    );
  }
}

class StatusDistributionItem {
  final String status;
  final int amount;

  StatusDistributionItem({
    required this.status,
    required this.amount,
  });

  factory StatusDistributionItem.fromJson(Map<String, dynamic> json) {
    return StatusDistributionItem(
      status: json['status'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
    );
  }
}

class ScoreDistributionItem {
  final int score;
  final int amount;

  ScoreDistributionItem({
    required this.score,
    required this.amount,
  });

  factory ScoreDistributionItem.fromJson(Map<String, dynamic> json) {
    return ScoreDistributionItem(
      score: json['score'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }
}

class CommunityMetrics {
  final List<CommunityRanking> rankings;
  final List<ScoreDistributionItem> scoreDistribution;
  final List<StatusDistributionItem> statusDistribution;

  CommunityMetrics({
    required this.rankings,
    required this.scoreDistribution,
    required this.statusDistribution,
  });

  factory CommunityMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CommunityMetrics(
        rankings: const [],
        scoreDistribution: const [],
        statusDistribution: const [],
      );
    }
    return CommunityMetrics(
      rankings: (json['rankings'] as List<dynamic>?)
              ?.map((e) => CommunityRanking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      scoreDistribution: (json['scoreDistribution'] as List<dynamic>?)
              ?.map((e) => ScoreDistributionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      statusDistribution: (json['statusDistribution'] as List<dynamic>?)
              ?.map((e) => StatusDistributionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

import 'media_item.dart';

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? pronouns;
  final String? bannerUrl;
  final List<String> favoriteGenres;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.pronouns,
    this.bannerUrl,
    this.favoriteGenres = const [],
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? 'Otaku Explorer',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      pronouns: json['pronouns'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      favoriteGenres: (json['favoriteGenres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] as String?,
    );
  }
}

class WatchlistItemRecord {
  final String id;
  final String userId;
  final String mediaId;
  final String status; // WATCHING, COMPLETED, PLAN_TO_WATCH, ON_HOLD, DROPPED
  final double? score;
  final int progressEpisodes;
  final String? notes;
  final MediaItem? mediaItem;
  final String createdAt;
  final String updatedAt;

  MediaItem? get media => mediaItem;

  WatchlistItemRecord({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.status,
    this.score,
    required this.progressEpisodes,
    this.notes,
    this.mediaItem,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WatchlistItemRecord.fromJson(Map<String, dynamic> json) {
    return WatchlistItemRecord(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      mediaId: json['mediaId']?.toString() ?? '',
      status: json['status'] as String? ?? 'WATCHING',
      score: (json['score'] as num?)?.toDouble(),
      progressEpisodes: (json['progressEpisodes'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      mediaItem: json['mediaItem'] != null ? MediaItem.fromJson(json['mediaItem'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

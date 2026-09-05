class WatchOrderNode {
  final String id;
  final String mediaId;
  final String title;
  final String type; // TV, MOVIE, OVA, SPECIAL
  final String? episodesInfo;
  final int? releaseYear;
  final String? coverImage;
  final int orderIndex;
  final String? note;
  final bool isCanon;

  WatchOrderNode({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.type,
    this.episodesInfo,
    this.releaseYear,
    this.coverImage,
    required this.orderIndex,
    this.note,
    required this.isCanon,
  });

  factory WatchOrderNode.fromJson(Map<String, dynamic> json) {
    return WatchOrderNode(
      id: json['id']?.toString() ?? '',
      mediaId: json['mediaId']?.toString() ?? '',
      title: json['title'] as String? ?? 'Episode / Movie',
      type: json['type'] as String? ?? 'TV',
      episodesInfo: json['episodesInfo'] as String?,
      releaseYear: json['releaseYear'] as int?,
      coverImage: json['coverImage'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 1,
      note: json['note'] as String?,
      isCanon: json['isCanon'] as bool? ?? true,
    );
  }
}

class WatchOrderPresetItem {
  final String? id;
  final String? presetId;
  final String mediaId;
  final int position;
  final bool isCanon;
  final String? note;
  final String? title;
  final String? coverImage;
  final String? format;
  final int? year;

  WatchOrderPresetItem({
    this.id,
    this.presetId,
    required this.mediaId,
    required this.position,
    this.isCanon = true,
    this.note,
    this.title,
    this.coverImage,
    this.format,
    this.year,
  });

  factory WatchOrderPresetItem.fromJson(Map<String, dynamic> json) {
    final mediaMap = (json['mediaItem'] ?? json['media']) as Map<String, dynamic>?;
    final rawTitle = mediaMap?['title'];
    final title = rawTitle is Map
        ? (rawTitle['userPreferred'] ?? rawTitle['romaji'] ?? rawTitle['english'])
        : (rawTitle is String ? rawTitle : null);

    final rawCover = mediaMap?['coverImage'];
    final coverImage = rawCover is Map
        ? (rawCover['large'] ?? rawCover['medium'] ?? rawCover['extraLarge'])
        : (rawCover is String ? rawCover : null);

    return WatchOrderPresetItem(
      id: json['id']?.toString(),
      presetId: json['presetId']?.toString(),
      mediaId: json['mediaId']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt() ?? 1,
      isCanon: json['isCanon'] as bool? ?? true,
      note: json['note'] as String?,
      title: title,
      coverImage: coverImage,
      format: mediaMap?['format'] as String?,
      year: mediaMap?['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'position': position,
      'isCanon': isCanon,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}

class WatchOrderPreset {
  final String id;
  final String franchiseRoot;
  final String title;
  final String? description;
  final String? submittedBy;
  final String submitterUsername;
  final String? submitterAvatarUrl;
  final String status; // 'pending_review', 'community_verified', 'flagged'
  int upvotes;
  int downvotes;
  final int reportCount;
  final bool isSelectiveCurated;
  final bool isPossiblyOutdated;
  final int missingItemsCount;
  final List<String> missingTitles;
  int? userVote; // 1, -1, or null
  final List<WatchOrderPresetItem> items;
  final String createdAt;

  WatchOrderPreset({
    required this.id,
    required this.franchiseRoot,
    required this.title,
    this.description,
    this.submittedBy,
    required this.submitterUsername,
    this.submitterAvatarUrl,
    required this.status,
    required this.upvotes,
    required this.downvotes,
    this.reportCount = 0,
    this.isSelectiveCurated = false,
    this.isPossiblyOutdated = false,
    this.missingItemsCount = 0,
    this.missingTitles = const [],
    this.userVote,
    required this.items,
    required this.createdAt,
  });

  factory WatchOrderPreset.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((it) => WatchOrderPresetItem.fromJson(it as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final rawMissing = json['missingTitles'] as List<dynamic>? ?? [];

    return WatchOrderPreset(
      id: json['id']?.toString() ?? '',
      franchiseRoot: json['franchiseRoot'] as String? ?? '',
      title: json['title'] as String? ?? 'Ghid Comunitar',
      description: json['description'] as String?,
      submittedBy: json['submittedBy'] as String?,
      submitterUsername: json['submitterUsername'] as String? ?? 'Membru Kurogane',
      submitterAvatarUrl: json['submitterAvatarUrl'] as String?,
      status: json['status'] as String? ?? 'pending_review',
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
      isSelectiveCurated: json['isSelectiveCurated'] as bool? ?? false,
      isPossiblyOutdated: json['isPossiblyOutdated'] as bool? ?? false,
      missingItemsCount: (json['missingItemsCount'] as num?)?.toInt() ?? 0,
      missingTitles: rawMissing.map((m) => m.toString()).toList(),
      userVote: (json['userVote'] as num?)?.toInt(),
      items: items,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class WatchOrderGuide {
  final String franchiseId;
  final String franchiseName;
  final String? description;
  final String? communityTip;
  final String authority; // 'editorial', 'community_verified', 'algorithmic'
  final Map<String, List<WatchOrderNode>> paths;
  final List<WatchOrderNode> spinOffs;
  final List<WatchOrderPreset> communityPresets;

  WatchOrderGuide({
    required this.franchiseId,
    required this.franchiseName,
    this.description,
    this.communityTip,
    this.authority = 'algorithmic',
    required this.paths,
    this.spinOffs = const [],
    this.communityPresets = const [],
  });

  factory WatchOrderGuide.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['paths'] as Map<String, dynamic>? ?? {};
    final parsedPaths = <String, List<WatchOrderNode>>{};

    rawPaths.forEach((key, value) {
      if (value is List) {
        parsedPaths[key] = value.map((item) => WatchOrderNode.fromJson(item as Map<String, dynamic>)).toList();
      }
    });

    final rawSpinOffs = json['spinOffs'] as List<dynamic>? ?? [];
    final parsedSpinOffs = rawSpinOffs.map((e) => WatchOrderNode.fromJson(e as Map<String, dynamic>)).toList();

    final rawPresets = json['communityPresets'] as List<dynamic>? ?? [];
    final parsedPresets = rawPresets.map((e) => WatchOrderPreset.fromJson(e as Map<String, dynamic>)).toList();

    return WatchOrderGuide(
      franchiseId: json['franchiseId'] as String? ?? '',
      franchiseName: json['franchiseName'] as String? ?? 'Franchise Guide',
      description: json['description'] as String?,
      communityTip: json['communityTip'] as String?,
      authority: json['authority'] as String? ?? 'algorithmic',
      paths: parsedPaths,
      spinOffs: parsedSpinOffs,
      communityPresets: parsedPresets,
    );
  }
}

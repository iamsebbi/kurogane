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

class WatchOrderGuide {
  final String franchiseId;
  final String franchiseName;
  final String? description;
  final String? communityTip;
  final Map<String, List<WatchOrderNode>> paths;
  final List<WatchOrderNode> spinOffs;

  WatchOrderGuide({
    required this.franchiseId,
    required this.franchiseName,
    this.description,
    this.communityTip,
    required this.paths,
    this.spinOffs = const [],
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

    return WatchOrderGuide(
      franchiseId: json['franchiseId'] as String? ?? '',
      franchiseName: json['franchiseName'] as String? ?? 'Franchise Guide',
      description: json['description'] as String?,
      communityTip: json['communityTip'] as String?,
      paths: parsedPaths,
      spinOffs: parsedSpinOffs,
    );
  }
}

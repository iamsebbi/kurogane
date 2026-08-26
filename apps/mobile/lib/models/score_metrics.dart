class ScoreMetrics {
  final double averageScore;
  final int reviewCount;
  final double weightedScore;

  ScoreMetrics({
    required this.averageScore,
    required this.reviewCount,
    required this.weightedScore,
  });

  factory ScoreMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ScoreMetrics(averageScore: 0.0, reviewCount: 0, weightedScore: 0.0);
    }
    return ScoreMetrics(
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      weightedScore: (json['weightedScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'averageScore': averageScore,
    'reviewCount': reviewCount,
    'weightedScore': weightedScore,
  };
}

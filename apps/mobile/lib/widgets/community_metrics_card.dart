import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/media_item.dart';

class CommunityMetricsCard extends StatelessWidget {
  final CommunityMetrics metrics;
  final double? averageScore;

  const CommunityMetricsCard({
    super.key,
    required this.metrics,
    this.averageScore,
  });

  String _formatCount(int number) {
    if (number >= 1000000) {
      final val = (number / 1000000).toStringAsFixed(1);
      return '${val.endsWith(".0") ? val.substring(0, val.length - 2) : val}M';
    }
    if (number >= 1000) {
      final val = (number / 1000).toStringAsFixed(1);
      return '${val.endsWith(".0") ? val.substring(0, val.length - 2) : val}k';
    }
    return number.toString();
  }

  String _formatContext(String rawContext) {
    var c = rawContext.trim();
    if (c.startsWith('#')) {
      c = c.substring(1).trim();
    }
    return c;
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'CURRENT':
        return context.statusWatching;
      case 'COMPLETED':
        return context.statusCompleted;
      case 'PLANNING':
        return context.statusPlanToWatch;
      case 'PAUSED':
        return context.statusOnHold;
      case 'DROPPED':
        return context.statusDropped;
      default:
        return context.textMuted;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CURRENT':
        return AppStrings.statusWatching;
      case 'COMPLETED':
        return AppStrings.statusCompleted;
      case 'PLANNING':
        return AppStrings.statusPlanToWatch;
      case 'PAUSED':
        return AppStrings.statusOnHold;
      case 'DROPPED':
        return AppStrings.statusDropped;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWatchers = metrics.statusDistribution.fold<int>(0, (sum, item) => sum + item.amount);
    final validRankings = metrics.rankings.take(2).toList();
    final scores = metrics.scoreDistribution;
    final int maxScoreAmount = scores.isNotEmpty
        ? scores.map((e) => e.amount).reduce((a, b) => a > b ? a : b)
        : 1;

    // Doar dacă avem date utile afișăm secțiunea
    if (totalWatchers == 0 && validRankings.isEmpty && scores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Secțiune (Flat, fără card)
          Row(
            children: [
              Icon(
                PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
                size: 18,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Community Stats',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (totalWatchers > 0)
                Text(
                  '${_formatCount(totalWatchers)} users',
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),

          // 2. Clasamente Globale (#1 Popularitate, #3 Scor)
          if (validRankings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: validRankings.map((rk) {
                final isRated = rk.type.toUpperCase() == 'RATED';
                final badgeColor = isRated ? context.scoreGold : context.accentPrimary;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRated
                            ? PhosphorIcons.trophy(PhosphorIconsStyle.bold)
                            : PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                        size: 12,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '#${rk.rank} ${_formatContext(rk.context)}',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // 3. Metrica Watchlist (Bară suplă de 6px + agendă minimalistă)
          if (totalWatchers > 0) ...[
            const SizedBox(height: 14),

            // Bară segmentată suplă
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: metrics.statusDistribution.map((item) {
                    if (item.amount == 0) return const SizedBox.shrink();
                    final flex = ((item.amount / totalWatchers) * 1000).round();
                    if (flex == 0) return const SizedBox.shrink();

                    return Expanded(
                      flex: flex,
                      child: Container(
                        color: _getStatusColor(context, item.status),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Agendă minimalistă: doar bulină colorată + procent + status
            Wrap(
              spacing: 12,
              runSpacing: 5,
              children: metrics.statusDistribution.map((item) {
                if (item.amount == 0) return const SizedBox.shrink();
                final pct = (item.amount / totalWatchers * 100).toStringAsFixed(0);
                final color = _getStatusColor(context, item.status);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$pct% ${_getStatusLabel(item.status)}',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],

          // 4. Histograma Notelor (Micro-chart discret)
          if (scores.isNotEmpty && maxScoreAmount > 0) ...[
            const SizedBox(height: 22),
            Container(
              height: 1,
              color: context.borderSubtle.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score Distribution',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (averageScore != null && averageScore! > 0)
                  Text(
                    'Average: ${averageScore!.toStringAsFixed(1)} / 10',
                    style: TextStyle(
                      color: context.scoreGold,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Micro-bare verticale suple (înălțime 38px)
            SizedBox(
              height: 38,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: scores.map((sc) {
                  final double ratio = (sc.amount / maxScoreAmount).clamp(0.08, 1.0);
                  final isPeak = sc.amount == maxScoreAmount;
                  final barColor = isPeak ? context.scoreGold : context.accentPrimary.withValues(alpha: 0.25);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: ratio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(sc.score / 10).round()}',
                            style: TextStyle(
                              color: isPeak ? context.scoreGold : context.textMuted,
                              fontSize: 9,
                              fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

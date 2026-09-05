import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../views/media_detail_screen.dart';
import 'blur_fade_route.dart';
import 'glass_score_badge.dart';
import 'pill_badge.dart';

/// Cardul Orizontal Standard (Explore / HomeScreen)
/// Dimensiune standardizată: înălțime 126px, poster portret 82x110px decupat GPU 12px.
/// Conține titlu mărit (16px bold), metadate curate fără traducere sub titlu,
/// GlassScoreBadge în dreapta sus și badge-uri de genuri (PillBadge) la bază.
class StandardHorizontalCard extends StatefulWidget {
  final String title;
  final String coverUrl;
  final String? score;
  final String? format;
  final int? year;
  final String? season;
  final int? episodes;
  final List<String> genres;
  final VoidCallback? onTap;
  final MediaItem? mediaItem;

  const StandardHorizontalCard({
    super.key,
    required this.title,
    required this.coverUrl,
    required this.score,
    this.format,
    this.year,
    this.season,
    this.episodes,
    this.genres = const [],
    this.onTap,
    this.mediaItem,
  });

  /// Constructor comod pentru instanțiere din API / MediaItem
  StandardHorizontalCard.fromMediaItem({
    super.key,
    required MediaItem item,
    this.onTap,
  })  : mediaItem = item,
        title = item.title.userPreferred,
        coverUrl = item.coverImage.bestImageUrl.isNotEmpty
            ? item.coverImage.bestImageUrl
            : (item.bannerImage ?? ''),
        score = _resolveScore(item),
        format = item.format,
        year = item.year,
        season = item.season,
        episodes = item.episodes,
        genres = item.genres;

  static String? _resolveScore(MediaItem item) {
    final rawScore = item.scores.weightedScore > 0
        ? item.scores.weightedScore
        : item.scores.averageScore;
    if (rawScore > 0) {
      return rawScore > 10 ? (rawScore / 10).toStringAsFixed(1) : rawScore.toStringAsFixed(1);
    }
    return null;
  }

  @override
  State<StandardHorizontalCard> createState() => _StandardHorizontalCardState();
}

class _StandardHorizontalCardState extends State<StandardHorizontalCard> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.mediaItem != null) {
      Navigator.of(context).push(
        BlurFadePageRoute(
          child: MediaDetailScreen(
            mediaId: widget.mediaItem!.id,
            initialItem: widget.mediaItem,
          ),
        ),
      );
    }
  }

  String? _formatSeasonYear(String? season, int? year) {
    String seasonName = '';
    if (season != null && season.trim().isNotEmpty) {
      final s = season.trim().toUpperCase();
      switch (s) {
        case 'WINTER':
          seasonName = 'Winter';
          break;
        case 'SPRING':
          seasonName = 'Spring';
          break;
        case 'SUMMER':
          seasonName = 'Summer';
          break;
        case 'FALL':
          seasonName = 'Fall';
          break;
        default:
          seasonName = season[0].toUpperCase() + season.substring(1).toLowerCase();
      }
    }

    if (year != null && year > 0) {
      if (seasonName.isNotEmpty) {
        return '$seasonName $year';
      }
      return '$year';
    } else if (seasonName.isNotEmpty) {
      return seasonName;
    }
    return null;
  }

  List<String> _buildMetadataItems() {
    final List<String> items = [];
    if (widget.format != null && widget.format!.trim().isNotEmpty) {
      items.add(widget.format!.trim().toUpperCase());
    }
    final seasonYear = _formatSeasonYear(widget.season, widget.year);
    if (seasonYear != null) {
      items.add(seasonYear);
    }
    if (widget.episodes != null && widget.episodes! > 0) {
      items.add('${widget.episodes} eps');
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final metadataItems = _buildMetadataItems();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            height: 126,
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Poster decupat GPU 12px (raport portret ~1:1.35)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 82,
                    height: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: widget.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: context.bgSurfaceHover),
                      errorWidget: (_, __, ___) => Container(
                        color: context.bgSurfaceHover,
                        child: Icon(
                          PhosphorIcons.imageBroken(PhosphorIconsStyle.bold),
                          color: context.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Conținut dreapta structurat logic pe rânduri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rândul 1 (sus): Doar Badge-ul de scor aliniat la dreapta
                      if (widget.score != null && widget.score!.isNotEmpty)
                        Align(
                          alignment: Alignment.topRight,
                          child: GlassScoreBadge(score: widget.score!),
                        )
                      else
                        const SizedBox.shrink(),

                      // Rândul 2 & 3 (mijloc): Titlu + Metadate pe toată lățimea
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          if (metadataItems.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              metadataItems.join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                color: context.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Rândul 4 (jos): Badge-uri dinamice de genuri pe toată lățimea
                      if (widget.genres.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: widget.genres
                              .take(3)
                              .map((genre) => PillBadge(label: genre))
                              .toList(),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/media_progress_formatter.dart';
import '../models/media_item.dart';
import '../models/watch_order.dart';
import '../views/media_detail_screen.dart';
import 'blur_fade_route.dart';
import 'pill_badge.dart';

/// Cardul Orizontal pentru Franciză & Relații Univers (MediaRelationsView / WatchOrder)
/// Dimensiune standardizată identică cu StandardHorizontalCard:
/// - Înălțime 126px, padding (8, 8, 12, 8), border-radius 18px.
/// - Poster generos 82x110px decupat GPU 12px la stânga.
/// - Conținut la dreapta centrat: Titlu serie (15px bold, maxLines 2),
///   Metadate: format, sezon + an, nr episoade, al câtelea sezon (S3) cu spacing normal,
///   Badge tip relație la bază (SEQUEL, PREQUEL, SIDE STORY etc.), săgeată la mijloc.
class FranchiseHorizontalCard extends StatefulWidget {
  final String title;
  final String coverUrl;
  final String? relationLabel;
  final Color? relationBgColor;
  final Color? relationTextColor;
  final String? metadataText;
  final VoidCallback? onTap;
  final bool canNavigate;
  final String? mediaId;

  const FranchiseHorizontalCard({
    super.key,
    required this.title,
    required this.coverUrl,
    this.relationLabel,
    this.relationBgColor,
    this.relationTextColor,
    this.metadataText,
    this.onTap,
    this.canNavigate = true,
    this.mediaId,
  });

  static String? _formatSeasonYear(String? season, int? year) {
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

  static String? _resolveSeasonIndicator(String title, String? format, String? type) {
    final fmt = (format ?? '').toUpperCase();
    final t = (type ?? '').toUpperCase();
    if (fmt == 'MOVIE' || t == 'MOVIE' || t == 'MANGA') return null;

    final s = MediaProgressFormatter.extractSeasonNumber(title: title);
    return 'S$s';
  }

  /// Constructor comod pentru instanțiere din MediaRelation
  factory FranchiseHorizontalCard.fromRelation({
    Key? key,
    required BuildContext context,
    required MediaRelation relation,
    bool isMainStory = false,
    bool isSequel = false,
    VoidCallback? onTap,
  }) {
    final metaItems = <String>[];

    // 1. Format (TV, MOVIE, OVA, ONA, SPECIAL, etc.)
    if (relation.format != null && relation.format!.trim().isNotEmpty) {
      metaItems.add(relation.format!.trim().toUpperCase());
    }

    // 2. Sezon + An (ex: Fall 2024 sau 2024)
    final seasonYear = _formatSeasonYear(relation.season, relation.releaseYear);
    if (seasonYear != null && seasonYear.isNotEmpty) {
      metaItems.add(seasonYear);
    }

    // 3. Nr episoade (ex: 12 ep.)
    if (relation.episodes != null && relation.episodes! > 0) {
      metaItems.add('${relation.episodes} ep.');
    }

    // 4. Al câtelea sezon (ex: S3, S2, S1)
    final seasonIndicator = _resolveSeasonIndicator(relation.title, relation.format, relation.type);
    if (seasonIndicator != null && seasonIndicator.isNotEmpty) {
      metaItems.add(seasonIndicator);
    }

    String? badgeLabel;
    Color? badgeBg;
    Color? badgeText;

    if (isMainStory) {
      badgeLabel = isSequel ? 'SEQUEL' : 'PREQUEL';
      badgeBg = isSequel ? context.accentPrimary : context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.16 : 0.10);
      badgeText = isSequel ? context.onPrimary : context.accentPrimary;
    } else {
      switch (relation.relationType.toUpperCase()) {
        case 'SIDE_STORY':
          badgeLabel = 'SIDE STORY';
          badgeBg = context.bgSurfaceHover;
          badgeText = context.textSecondary;
          break;
        case 'SPIN_OFF':
          badgeLabel = 'SPIN-OFF';
          badgeBg = context.bgSurfaceHover;
          badgeText = context.textSecondary;
          break;
        case 'ALTERNATIVE':
          badgeLabel = 'ALTERNATIVE';
          badgeBg = context.bgSurfaceHover;
          badgeText = context.textSecondary;
          break;
        case 'SUMMARY':
          badgeLabel = 'SUMMARY';
          badgeBg = context.bgSurfaceHover;
          badgeText = context.textSecondary;
          break;
        case 'SOURCE':
        case 'ADAPTATION':
          badgeLabel = 'SOURCE';
          badgeBg = context.bgSurfaceHover;
          badgeText = context.textSecondary;
          break;
        default:
          if (relation.relationType.isNotEmpty && relation.relationType != 'OTHER') {
            badgeLabel = relation.relationType.replaceAll('_', ' ');
            badgeBg = context.bgSurfaceHover;
            badgeText = context.textSecondary;
          }
          break;
      }
    }

    return FranchiseHorizontalCard(
      key: key,
      title: relation.title,
      coverUrl: relation.coverImage ?? '',
      relationLabel: badgeLabel,
      relationBgColor: badgeBg,
      relationTextColor: badgeText,
      metadataText: metaItems.isNotEmpty ? metaItems.join(' • ') : null,
      canNavigate: relation.type != 'MANGA',
      mediaId: relation.id,
      onTap: onTap,
    );
  }

  /// Constructor comod pentru instanțiere din WatchOrderNode
  factory FranchiseHorizontalCard.fromWatchOrderNode({
    Key? key,
    required BuildContext context,
    required WatchOrderNode node,
    VoidCallback? onTap,
  }) {
    final metaItems = <String>[];
    if (node.type.isNotEmpty) {
      metaItems.add(node.type.toUpperCase());
    }
    if (node.releaseYear != null && node.releaseYear! > 0) {
      metaItems.add('${node.releaseYear}');
    }
    if (node.episodesInfo != null && node.episodesInfo!.isNotEmpty) {
      metaItems.add(node.episodesInfo!);
    }
    final seasonIndicator = _resolveSeasonIndicator(node.title, node.type, null);
    if (seasonIndicator != null && seasonIndicator.isNotEmpty) {
      metaItems.add(seasonIndicator);
    }

    final String badgeLabel = node.isCanon ? 'CANON' : 'OPTIONAL';
    final Color badgeBg = node.isCanon
        ? context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.18 : 0.15)
        : context.statusPlanToWatch.withValues(alpha: 0.15);
    final Color badgeText = node.isCanon
        ? (context.isDarkMode ? context.accentPrimary : context.textPrimary)
        : context.statusPlanToWatch;

    return FranchiseHorizontalCard(
      key: key,
      title: node.title,
      coverUrl: node.coverImage ?? '',
      relationLabel: badgeLabel,
      relationBgColor: badgeBg,
      relationTextColor: badgeText,
      metadataText: metaItems.isNotEmpty ? metaItems.join(' • ') : null,
      mediaId: node.mediaId,
      onTap: onTap,
    );
  }

  @override
  State<FranchiseHorizontalCard> createState() => _FranchiseHorizontalCardState();
}

class _FranchiseHorizontalCardState extends State<FranchiseHorizontalCard> {
  bool _isPressed = false;

  void _handleTap() {
    if (!widget.canNavigate) return;
    HapticFeedback.selectionClick();
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.mediaId != null && widget.mediaId!.isNotEmpty) {
      Navigator.of(context).push(
        BlurFadePageRoute(
          child: MediaDetailScreen(mediaId: widget.mediaId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.canNavigate) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.canNavigate) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (widget.canNavigate) setState(() => _isPressed = false);
      },
      onTap: widget.canNavigate ? _handleTap : null,
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
                // Poster decupat GPU 12px (82x110px raport ~1:1.35)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 82,
                    height: double.infinity,
                    child: widget.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.coverUrl,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 140),
                            placeholder: (_, __) => Container(color: context.bgSurfaceHover),
                            errorWidget: (_, __, ___) => Container(
                              color: context.bgSurfaceHover,
                              child: Icon(
                                PhosphorIcons.filmStrip(PhosphorIconsStyle.bold),
                                color: context.textMuted,
                              ),
                            ),
                          )
                        : Container(
                            color: context.bgSurfaceHover,
                            child: Icon(
                              PhosphorIcons.filmStrip(PhosphorIconsStyle.bold),
                              color: context.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Conținut dreapta: Săgeată mijloc dreapta, Badge jos, Titlu + Metadate centrate vertical
                Expanded(
                  child: Stack(
                    children: [
                      // 1. Extremitate dreapta mijloc: Săgeată navigare
                      if (widget.canNavigate)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          child: Center(
                            child: Icon(
                              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                              size: 16,
                              color: context.textMuted,
                            ),
                          ),
                        ),

                      // 2. CENTRAT VERTICAL: Titlu + Metadate
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: widget.canNavigate ? 24 : 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Google Sans',
                                    color: context.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
                                if (widget.metadataText != null && widget.metadataText!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.metadataText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      color: context.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                                if (widget.relationLabel != null && widget.relationLabel!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  PillBadge(
                                    label: widget.relationLabel!,
                                    backgroundColor: widget.relationBgColor ?? context.bgSurfaceHover,
                                    textColor: widget.relationTextColor ?? context.textSecondary,
                                    fontSize: 11.0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
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

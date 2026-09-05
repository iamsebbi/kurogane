import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/media_progress_formatter.dart';
import '../models/watchlist_item.dart';
import '../views/media_detail_screen.dart';
import 'blur_fade_route.dart';
import 'pill_badge.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Cardul Orizontal pentru Activitate Recentă (Recent Activity / Profil / Feed)
/// Dimensiune standardizată: înălțime 126px, poster portret 82x110px decupat GPU 12px.
/// - Top: Titlu serie (stânga) + Timestamp relativ (dreapta).
/// - Mijloc: Formatare dinamică Sezon & Episod (ex: S3 E5, Movie, Ch. 12).
/// - Bottom: Badge-ul standard PillBadge cu starea activității (ex: Episod vizionat, Serie abandonată).
class RecentActivityHorizontalCard extends StatefulWidget {
  final String title;
  final String coverUrl;
  final String activityType;
  final String activityDetail;
  final String timeAgo;
  final Color? activityColor;
  final VoidCallback? onTap;

  const RecentActivityHorizontalCard({
    super.key,
    required this.title,
    required this.coverUrl,
    required this.activityType,
    required this.activityDetail,
    required this.timeAgo,
    this.activityColor,
    this.onTap,
  });

  /// Constructor comod pentru instanțiere din API / WatchlistItemRecord
  factory RecentActivityHorizontalCard.fromWatchlistRecord({
    Key? key,
    required BuildContext context,
    required WatchlistItemRecord record,
    VoidCallback? onTap,
  }) {
    final media = record.media;
    final title = media?.title.userPreferred ?? 'Anime #${record.mediaId}';
    final coverUrl = (media?.coverImage.bestImageUrl.isNotEmpty == true)
        ? media!.coverImage.bestImageUrl
        : (media?.bannerImage ?? '');

    // Subtitlu: Formatare dinamică Sezon & Episod (ex: S3 E5, Movie, Ch. 12) fără hardcodare
    final String activityDetail = MediaProgressFormatter.formatSeasonEpisode(
      media: media,
      episodeProgress: record.progressEpisodes,
      fallbackTitle: title,
    );

    // Stare & Culoare semantice conform design system
    final String activityType;
    final Color activityColor;
    switch (record.status.toUpperCase()) {
      case 'COMPLETED':
        activityType = AppStrings.activityCompletedSeries;
        activityColor = context.statusCompleted;
        break;
      case 'DROPPED':
        activityType = AppStrings.activityDroppedSeries;
        activityColor = context.statusDropped;
        break;
      case 'ON_HOLD':
        activityType = AppStrings.activityPausedSeries;
        activityColor = context.statusOnHold;
        break;
      case 'PLAN_TO_WATCH':
        activityType = AppStrings.activityPlanToWatch;
        activityColor = context.statusPlanToWatch;
        break;
      case 'WATCHING':
      default:
        activityType = AppStrings.activityWatchedEpisode;
        activityColor = context.statusWatching;
        break;
    }

    final String timeAgo = _formatRelativeTime(
      record.updatedAt.isNotEmpty ? record.updatedAt : record.createdAt,
    );

    return RecentActivityHorizontalCard(
      key: key,
      title: title,
      coverUrl: coverUrl,
      activityType: activityType,
      activityDetail: activityDetail,
      timeAgo: timeAgo,
      activityColor: activityColor,
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              BlurFadePageRoute(
                child: MediaDetailScreen(
                  mediaId: record.mediaId,
                  initialItem: media,
                ),
              ),
            );
          },
    );
  }

  static String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return AppStrings.recent;
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return AppStrings.recent;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return AppStrings.justNow;
    } else if (diff.inMinutes < 60) {
      return AppStrings.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return AppStrings.hoursAgo(diff.inHours);
    } else if (diff.inDays == 1) {
      return AppStrings.yesterday;
    } else if (diff.inDays < 7) {
      return AppStrings.daysAgo(diff.inDays);
    } else {
      return '${dt.day} ${AppStrings.shortMonths[dt.month - 1]}';
    }
  }

  @override
  State<RecentActivityHorizontalCard> createState() => _RecentActivityHorizontalCardState();
}

class _RecentActivityHorizontalCardState extends State<RecentActivityHorizontalCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color resolvedActivityColor = widget.activityColor ?? context.statusWatching;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
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
                // Poster compact decupat GPU 12px (raport portret ~1:1.35)
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
                      // Rândul 1 (sus): Doar Timpul relativ aliniat la dreapta
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          widget.timeAgo,
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: context.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Rândul 2 & 3 (mijloc): Titlu + Subtitlu episod pe toată lățimea
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.activityDetail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: context.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Rândul 4 (jos): Badge de status al activității pe toată lățimea
                      PillBadge(
                        label: widget.activityType,
                        statusDotColor: resolvedActivityColor,
                        variant: PillVariant.status,
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

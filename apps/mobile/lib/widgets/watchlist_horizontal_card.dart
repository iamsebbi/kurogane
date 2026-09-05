import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/media_progress_formatter.dart';
import '../core/utils/media_status_helper.dart';
import '../models/media_item.dart';
import '../models/watchlist_item.dart';
import 'pill_badge.dart';

/// Cardul Orizontal pentru Watchlist (Watchlist Screen)
/// Dimensiune standardizată: înălțime 126px, poster portret 82x110px decupat GPU 12px.
/// - Top: Titlu serie (stânga) + Episoade (dreapta) așezate compact chiar deasupra barei de progres.
/// - Subtitlu: Formatare dinamică Sezon & Episod (ex: S3 E5, Movie, Ch. 12).
/// - Mijloc: Bară de progres suplă (4px) colorată în nuanța semantică a seriei.
/// - Bottom: Badge-ul de status al seriei (stânga, interactiv cu onStatusTap) + Butoanele rapide [-] și [+] cu tap target de 44px (dreapta).
class WatchlistHorizontalCard extends StatefulWidget {
  final String title;
  final String coverUrl;
  final String status;
  final String? statusLabel;
  final Color? statusColor;
  final int progressEpisodes;
  final int totalEpisodes;
  final MediaItem? media;
  final String? seasonEpisodeLabel;
  final ValueChanged<int>? onProgressChanged;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final VoidCallback? onLongPress;

  const WatchlistHorizontalCard({
    super.key,
    required this.title,
    required this.coverUrl,
    this.status = 'WATCHING',
    this.statusLabel,
    this.statusColor,
    required this.progressEpisodes,
    required this.totalEpisodes,
    this.media,
    this.seasonEpisodeLabel,
    this.onProgressChanged,
    this.onIncrement,
    this.onDecrement,
    this.onTap,
    this.onStatusTap,
    this.onLongPress,
  });

  WatchlistHorizontalCard.fromWatchlistRecord({
    super.key,
    required WatchlistItemRecord record,
    this.onIncrement,
    this.onDecrement,
    this.onProgressChanged,
    this.onTap,
    this.onStatusTap,
    this.onLongPress,
  })  : title = record.media?.title.userPreferred ?? 'Anime #${record.mediaId}',
        coverUrl = (record.media?.coverImage.bestImageUrl.isNotEmpty == true)
            ? record.media!.coverImage.bestImageUrl
            : (record.media?.bannerImage ?? ''),
        status = record.status,
        statusLabel = null,
        statusColor = null,
        progressEpisodes = record.progressEpisodes,
        totalEpisodes = record.media?.episodes ?? 0,
        media = record.media,
        seasonEpisodeLabel = null;

  @override
  State<WatchlistHorizontalCard> createState() => _WatchlistHorizontalCardState();
}

class _WatchlistHorizontalCardState extends State<WatchlistHorizontalCard> {
  bool _isPressed = false;
  late int _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.progressEpisodes;
  }

  @override
  void didUpdateWidget(covariant WatchlistHorizontalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressEpisodes != widget.progressEpisodes) {
      _progress = widget.progressEpisodes;
    }
  }

  void _handleIncrement() {
    if (widget.totalEpisodes == 0 || _progress < widget.totalEpisodes) {
      HapticFeedback.lightImpact();
      setState(() => _progress++);
      widget.onIncrement?.call();
      widget.onProgressChanged?.call(_progress);
    }
  }

  void _handleDecrement() {
    if (_progress > 0) {
      HapticFeedback.lightImpact();
      setState(() => _progress--);
      widget.onDecrement?.call();
      widget.onProgressChanged?.call(_progress);
    }
  }

  Color _resolveStatusColor(BuildContext context) {
    if (widget.statusColor != null) return widget.statusColor!;
    return MediaStatusHelper.getColor(context, widget.status);
  }

  String _resolveStatusLabel() {
    if (widget.statusLabel != null && widget.statusLabel!.isNotEmpty) {
      return widget.statusLabel!;
    }
    return MediaStatusHelper.getLabel(widget.status);
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    required BuildContext context,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? context.bgSurfaceHover
                  : context.bgSurfaceHover.withValues(alpha: 0.35),
              border: Border.all(
                color: enabled
                    ? context.borderSubtle
                    : context.borderSubtle.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: enabled ? context.textPrimary : context.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fraction = widget.totalEpisodes > 0
        ? (_progress / widget.totalEpisodes).clamp(0.0, 1.0)
        : 0.0;
    final statusColor = _resolveStatusColor(context);
    final statusLabel = _resolveStatusLabel();
    final String seasonEpisodeText = widget.seasonEpisodeLabel ??
        MediaProgressFormatter.formatSeasonEpisode(
          media: widget.media,
          episodeProgress: _progress,
          fallbackTitle: widget.title,
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
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

                // Conținut dreapta aerisit: Titlu+Episoade deasupra progress bar-ului, Badge+Butoane jos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. ZONA DE SUS: Titlu (stânga) + Episoade (dreapta), Subtitlu dinamic (S3 E5) CHIAR DEASUPRA progress bar-ului
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
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
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.episodeProgressDisplay(_progress, widget.totalEpisodes),
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: context.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            seasonEpisodeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 4,
                              child: LinearProgressIndicator(
                                value: fraction,
                                backgroundColor: context.bgSurfaceHover,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 2. ZONA DE JOS: Stânga Badge-ul de status (tapabil pentru deschidere modal editare), Dreapta butoanele de - și + (44px tap target)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onStatusTap,
                            child: PillBadge(
                              label: statusLabel,
                              statusDotColor: statusColor,
                              variant: PillVariant.status,
                            ),
                          ),

                          const Spacer(),

                          // Butoanele de acțiune rapidă cu 44px tap target
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStepButton(
                                icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                onTap: _handleDecrement,
                                enabled: _progress > 0,
                                context: context,
                              ),
                              _buildStepButton(
                                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                onTap: _handleIncrement,
                                enabled: widget.totalEpisodes == 0 || _progress < widget.totalEpisodes,
                                context: context,
                              ),
                            ],
                          ),
                        ],
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

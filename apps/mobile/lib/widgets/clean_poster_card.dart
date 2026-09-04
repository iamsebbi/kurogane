import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../views/media_detail_screen.dart';
import 'blur_fade_route.dart';
import 'glass_score_badge.dart';

/// Cardul Minimalist Vertical (Clean Poster) ce utilizează GlassScoreBadge integrat.
/// Folosește decupaj concentric GPU (18px), micro-scale la apăsare și titlu aerisit.
/// Suportă instanțiere directă cu atribute sau via `CleanPosterCard.fromMediaItem(item: ...)`.
class CleanPosterCard extends StatefulWidget {
  final String title;
  final String? score;
  final String coverUrl;
  final double? width;
  final double? height;
  final double posterAspectRatio;
  final VoidCallback? onTap;
  final MediaItem? mediaItem;
  final int? rank;

  const CleanPosterCard({
    super.key,
    required this.title,
    required this.score,
    required this.coverUrl,
    this.width = 175,
    this.height = 255,
    this.posterAspectRatio = 1 / 1.42,
    this.onTap,
    this.mediaItem,
    this.rank,
  });

  /// Constructor comod și sigur pentru instanțiere din API / MediaItem
  CleanPosterCard.fromMediaItem({
    super.key,
    required MediaItem item,
    this.width,
    this.height,
    this.posterAspectRatio = 1 / 1.42,
    this.onTap,
    this.rank,
  })  : mediaItem = item,
        title = item.title.userPreferred,
        score = _resolveScore(item),
        coverUrl = item.coverImage.extraLarge ?? item.coverImage.large;

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
  State<CleanPosterCard> createState() => _CleanPosterCardState();
}

class _CleanPosterCardState extends State<CleanPosterCard> {
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

  @override
  Widget build(BuildContext context) {
    final posterContent = Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.coverUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          fadeInDuration: const Duration(milliseconds: 140),
          placeholder: (_, __) => Container(color: context.bgSurfaceHover),
          errorWidget: (_, __, ___) => Container(
            color: context.bgSurfaceHover,
            child: Icon(
              PhosphorIcons.imageBroken(PhosphorIconsStyle.bold),
              color: context.textSecondary.withValues(alpha: 0.3),
            ),
          ),
        ),
        if (widget.rank != null) ...[
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8C000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 9,
            child: Text(
              '${widget.rank}',
              style: const TextStyle(
                fontFamily: 'Zalando Sans Expanded',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.0,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Color(0xCC000000),
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (widget.score != null && widget.score!.isNotEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: GlassScoreBadge(score: widget.score!),
          ),
      ],
    );

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: widget.height != null
              ? SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: posterContent,
                )
              : AspectRatio(
                  aspectRatio: widget.posterAspectRatio,
                  child: posterContent,
                ),
        ),
        const SizedBox(height: 7),
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Google Sans',
            color: context.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.0,
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: widget.width != null
              ? SizedBox(
                  width: widget.width,
                  child: cardContent,
                )
              : cardContent,
        ),
      ),
    );
  }
}

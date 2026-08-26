import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../views/media_detail_screen.dart';

class MediaCard extends StatefulWidget {
  final MediaItem item;
  final double? width;
  final double? height;
  final bool showRank;
  final int? rank;

  const MediaCard({
    super.key,
    required this.item,
    this.width = 175,
    this.height,
    this.showRank = false,
    this.rank,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _isPressed = false;

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(
          mediaId: widget.item.id,
          initialItem: widget.item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawScore = widget.item.scores.weightedScore > 0
        ? widget.item.scores.weightedScore
        : widget.item.scores.averageScore;
    final scoreDisplay = rawScore > 0
        ? (rawScore > 10 ? (rawScore / 10).toStringAsFixed(1) : rawScore.toStringAsFixed(1))
        : null;

    final coverUrl = widget.item.coverImage.extraLarge ?? widget.item.coverImage.large;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _openDetail,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isPressed ? context.accentPrimary.withValues(alpha: 0.5) : context.borderSubtle,
                width: 1,
              ),
              boxShadow: [
                if (!context.isDarkMode)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isPressed ? 0.02 : 0.06),
                    blurRadius: _isPressed ? 4 : 8,
                    offset: Offset(0, _isPressed ? 1 : 3),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Artwork Poster Area with Vignette, Fade, and Top-Right Score Badge
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) => Container(color: context.bgSurfaceHover),
                        errorWidget: (context, url, error) => Container(
                          color: context.bgSurfaceHover,
                          child: Icon(
                            PhosphorIcons.imageBroken(PhosphorIconsStyle.bold),
                            color: context.textMuted,
                          ),
                        ),
                      ),

                      // Top Vignette Gradient
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Gradient Fade (Transition into card body)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                context.bgSurface.withValues(alpha: 0.4),
                                context.bgSurface.withValues(alpha: 0.85),
                                context.bgSurface,
                              ],
                              stops: const [0.0, 0.45, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Optional Rank Badge — Top-Left
                      if (widget.showRank && widget.rank != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '#${widget.rank}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Score Badge — Top-Right Corner (Exact style of Episoade Noi)
                      if (scoreDisplay != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xE60F1419),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                                  size: 11,
                                  color: AppColors.scoreGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  scoreDisplay,
                                  style: const TextStyle(
                                    color: AppColors.scoreGold,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. Body Container (Title & Secondary Year Info)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title.userPreferred,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          color: context.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      if (widget.item.year != null && widget.item.year! > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${widget.item.year}',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: context.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

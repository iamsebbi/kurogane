import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/homepage_data.dart';
import '../views/media_detail_screen.dart';

class AiringEpisodeCard extends StatefulWidget {
  final RecentlyAiredEpisode item;
  final double width;

  const AiringEpisodeCard({
    super.key,
    required this.item,
    this.width = 180.0,
  });

  @override
  State<AiringEpisodeCard> createState() => _AiringEpisodeCardState();
}

class _AiringEpisodeCardState extends State<AiringEpisodeCard> {
  bool _isPressed = false;

  String _sanitizeTitle(String title) {
    var cleaned = title.trim();
    // Prevent awkward punctuation before truncation (e.g. ":...")
    cleaned = cleaned.replaceAll(RegExp(r'[:;,—\-]\s*$'), '').trim();
    return cleaned;
  }

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(
          mediaId: widget.item.media.id,
          initialItem: widget.item.media,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.item.media;
    final coverUrl = widget.item.thumbnailUrl ?? media.coverImage.extraLarge ?? media.coverImage.large;
    final score = media.scores.averageScore;
    final formattedScore = score > 10 ? (score / 10).toStringAsFixed(1) : (score > 0 ? score.toStringAsFixed(1) : null);

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
                    blurRadius: _isPressed ? 4 : 10,
                    offset: Offset(0, _isPressed ? 1 : 3),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Artwork Poster Area with Badges & Gradient
                AspectRatio(
                  aspectRatio: 3 / 3.9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image (BoxFit.cover)
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) => Container(color: context.bgSurfaceHover),
                        errorWidget: (context, url, error) => Container(
                          color: context.bgSurfaceHover,
                          child: Icon(PhosphorIcons.imageBroken(PhosphorIconsStyle.bold), color: context.textMuted),
                        ),
                      ),

                      // Top Vignette Mask (Protejează badge-urile de contrast)
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

                      // Bottom Gradient Fade (Tranziție lină spre corpul cardului)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
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

                      // 1. Badge Combinat "NOU | EP {număr}" — Colț sus-stânga
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.signalLive,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon Sparkle centrat geometric în semicercul stâng
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: Icon(
                                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                    size: 11.5,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              // Text "NOU"
                              const Padding(
                                padding: EdgeInsets.only(left: 1),
                                child: Text(
                                  'NOU',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              // Separator vertical subtil
                              Container(
                                width: 1,
                                height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                color: const Color(0x330F172A),
                              ),
                              // Text "EP {număr}" cu padding simetric la capătul drept
                              Padding(
                                padding: const EdgeInsets.only(right: 9),
                                child: Text(
                                  'EP ${widget.item.episodeNumber}',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Badge de Scor — Colț sus-dreapta
                      if (formattedScore != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xE60F1419),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 24,
                                  child: Center(
                                    child: Icon(
                                      PhosphorIcons.star(PhosphorIconsStyle.fill),
                                      size: 11,
                                      color: AppColors.scoreGold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    formattedScore,
                                    style: const TextStyle(
                                      color: AppColors.scoreGold,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 4. Floating Pill Info (STRICT Ceas + Timp Relativ) — Colț jos-stânga
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          height: 23,
                          padding: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.7,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 23,
                                child: Center(
                                  child: Icon(
                                    PhosphorIcons.clock(PhosphorIconsStyle.bold),
                                    size: 11.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.item.airDateRelative,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
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

                // 5. Body Container (Titlu Anime)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: SizedBox(
                    height: 36,
                    child: Text(
                      _sanitizeTitle(media.title.userPreferred),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        color: context.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
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

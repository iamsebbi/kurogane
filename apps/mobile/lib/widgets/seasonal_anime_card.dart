import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../views/media_detail_screen.dart';
import 'blur_fade_route.dart';

/// Card orizontal cinematic dedicat trailerelor anime populare.
///
/// Afișează thumbnail-ul video (YouTube HQ sau Banner oficial), buton central de Play
/// din sticlă mată (frosted glass), badge tematic de trailer și trimitere directă
/// către vizualizarea trailerului la apăsare.
class AnimeTrailerCard extends StatefulWidget {
  final MediaItem item;
  final double? width;
  final double height;

  const AnimeTrailerCard({
    super.key,
    required this.item,
    this.width,
    this.height = 185.0,
  });

  @override
  State<AnimeTrailerCard> createState() => _AnimeTrailerCardState();
}

class _AnimeTrailerCardState extends State<AnimeTrailerCard> {
  bool _isPressed = false;

  static String? _extractYouTubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      if (uri.pathSegments.contains('watch')) {
        return uri.queryParameters['v'];
      }
      if (uri.pathSegments.contains('embed') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } else if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return null;
  }

  String _resolveThumbnail(MediaItem item) {
    // 1. Dacă are ID de YouTube, folosim thumbnail-ul oficial de trailer
    final ytId = _extractYouTubeId(item.trailerUrl);
    if (ytId != null && ytId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }
    // 2. Banner peisaj oficial
    if (item.bannerImage != null && item.bannerImage!.isNotEmpty) {
      return item.bannerImage!;
    }
    // 3. Fallback pe cover-ul anime-ului
    return item.coverImage.extraLarge ?? item.coverImage.large;
  }

  Future<void> _openTrailer(BuildContext context) async {
    HapticFeedback.mediumImpact();

    String targetUrl = widget.item.trailerUrl ?? '';
    if (targetUrl.isEmpty) {
      // Fallback: căutare YouTube pentru trailerul oficial al anime-ului
      final query = Uri.encodeComponent('${widget.item.title.userPreferred} official anime trailer');
      targetUrl = 'https://www.youtube.com/results?search_query=$query';
    }

    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        debugPrint('[AnimeTrailerCard] Could not launch trailer: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nu s-a putut deschide trailerul pentru ${widget.item.title.userPreferred}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _openDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      BlurFadePageRoute(
        child: MediaDetailScreen(
          mediaId: widget.item.id,
          initialItem: widget.item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = _resolveThumbnail(widget.item);
    final hasDirectTrailer = widget.item.trailerUrl != null && widget.item.trailerUrl!.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _openTrailer(context),
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.40 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Thumbnail-ul Video (Banner sau YouTube HQ)
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (_, __) => Container(color: context.bgSurfaceHover),
                  errorWidget: (_, __, ___) => Container(
                    color: context.bgSurfaceHover,
                    child: Center(
                      child: Icon(
                        PhosphorIcons.videoCameraSlash(PhosphorIconsStyle.bold),
                        color: context.textSecondary.withValues(alpha: 0.35),
                        size: 36,
                      ),
                    ),
                  ),
                ),

                // 2. Gradient cinematic superior și inferior pentru contrast impecabil
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x73000000), // ~45% black sus
                        Colors.transparent,
                        Color(0x33000000), // ~20% black mijloc
                        Color(0xE6000000), // ~90% black jos
                      ],
                      stops: [0.0, 0.28, 0.62, 1.0],
                    ),
                  ),
                ),

                // 3. Buton Central de PLAY cu sticlă mată (Frosted Glass)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.42),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Icon(
                              PhosphorIcons.play(PhosphorIconsStyle.fill),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Badge "OFFICIAL TRAILER" în stânga sus
                Positioned(
                  top: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xB3000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.youtubeLogo(PhosphorIconsStyle.fill),
                              color: const Color(0xFFFF0000),
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              hasDirectTrailer ? 'TRAILER' : 'TEASER',
                              style: const TextStyle(
                                fontFamily: 'Zalando Sans Expanded',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Buton Informații / Detalii în dreapta sus
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openDetail(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x99000000),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.info(PhosphorIconsStyle.bold),
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Conținut Text la baza Cardului (Titlu anime + Genuri + Call to action)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title.userPreferred,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.genres.isNotEmpty
                                  ? widget.item.genres.take(2).join(' • ').toUpperCase()
                                  : 'ANIME TRAILER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.bold),
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Watch',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.90),
                                ),
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

/// Alias retrocompatibil pentru componente existente
typedef SeasonalAnimeCard = AnimeTrailerCard;

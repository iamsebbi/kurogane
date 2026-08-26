import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../providers/api_providers.dart';
import '../views/media_detail_screen.dart';

class SeasonalAnimeCard extends ConsumerStatefulWidget {
  final MediaItem item;
  final double? width;
  final double height;

  const SeasonalAnimeCard({
    super.key,
    required this.item,
    this.width,
    this.height = 195.0,
  });

  @override
  ConsumerState<SeasonalAnimeCard> createState() => _SeasonalAnimeCardState();
}

class _SeasonalAnimeCardState extends ConsumerState<SeasonalAnimeCard> {
  bool _isPressed = false;
  bool _isBookmarkPressed = false;

  static final ImageFilter _glassFilter = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    inner: const ColorFilter.matrix(<double>[
      1.6296, -0.5720, -0.0576, 0, 0,
     -0.1704,  1.2280, -0.0576, 0, 0,
     -0.1704, -0.5720,  1.7424, 0, 0,
      0,       0,       0,      1, 0,
    ]),
  );

  String _sanitizeTitle(String title) {
    var cleaned = title.trim();
    // Previne punctuațiile urâte la finalul textului trunchiat (ex: ":...", "-...")
    cleaned = cleaned.replaceAll(RegExp(r'[:;,—\-]\s*$'), '').trim();
    return cleaned;
  }

  String _cleanDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      if (widget.item.genres.isNotEmpty) {
        return widget.item.genres.take(3).join(' • ');
      }
      return 'Sezon nou în difuzare pe Kurogane.';
    }
    // Curățare tag-uri HTML din descriere dacă există
    final unescaped = raw
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return unescaped;
  }

  Color _getAccentColor() {
    if (widget.item.coverImage.color != null &&
        widget.item.coverImage.color!.startsWith('#')) {
      try {
        final hex = widget.item.coverImage.color!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    final g = (widget.item.genres.isNotEmpty ? widget.item.genres.first : '')
        .toLowerCase();
    if (g.contains('action') || g.contains('adventure')) {
      return const Color(0xFFF43F5E);
    }
    if (g.contains('fantasy') ||
        g.contains('supernatural') ||
        g.contains('magic')) {
      return const Color(0xFFA855F7);
    }
    if (g.contains('comedy') || g.contains('slice of life')) {
      return const Color(0xFFF59E0B);
    }
    if (g.contains('romance') || g.contains('drama')) {
      return const Color(0xFFEC4899);
    }
    if (g.contains('sci-fi') || g.contains('mecha')) {
      return const Color(0xFF06B6D4);
    }
    return AppColors.accentPrimary;
  }

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

  Future<void> _toggleWatchlist(bool isInWatchlist) async {
    try {
      if (isInWatchlist) {
        await ref.read(watchlistProvider.notifier).removeItem(widget.item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eliminat din Watchlist'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await ref.read(watchlistProvider.notifier).updateItem(
              mediaId: widget.item.id,
              status: 'PLAN_TO_WATCH',
              progressEpisodes: 0,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Adăugat în Watchlist: ${_sanitizeTitle(widget.item.title.userPreferred)}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.accentPrimary,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare la salvarea în Watchlist'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.item;
    final coverUrl = media.coverImage.extraLarge ??
        media.coverImage.large.replaceAll(RegExp(r'medium'), 'large');
    final accentColor = _getAccentColor();
    final formatText = (media.format ?? media.type).toUpperCase().replaceAll('_', ' ');
    final isReleasing = media.status == 'RELEASING' || media.status == 'AIRING';

    // Watchlist State
    final watchlistAsync = ref.watch(watchlistProvider);
    final isInWatchlist = watchlistAsync.value?.any((w) => w.mediaId == media.id) ?? false;

    final cardWidth = widget.width ?? double.infinity;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _openDetail,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            width: cardWidth,
            height: widget.height,
            decoration: BoxDecoration(
              color: context.bgSurface, // Charcoal Navy (#1E293B)
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isPressed
                    ? accentColor.withValues(alpha: 0.6)
                    : context.borderSubtle,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.35 : 0.08),
                  blurRadius: _isPressed ? 6 : 14,
                  offset: Offset(0, _isPressed ? 2 : 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ZONA STÂNGA: Text & Metadata (~58%)
                Expanded(
                  flex: 58,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Badge-uri sus: Format (TV) + Indicator Sezon Nou
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Pill Format: Înălțime exactă de 24px (identică cu badge-urile de la Episoade Noi)
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1419),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                formatText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Indicator "Sezon Nou" (Punct verde Emerald + text verde, fără fundal)
                            if (isReleasing)
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6.5,
                                      height: 6.5,
                                      decoration: BoxDecoration(
                                        color: AppColors.signalLive,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.signalLive
                                                .withValues(alpha: 0.6),
                                            blurRadius: 4,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Flexible(
                                      child: Text(
                                        'Sezon Nou',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.signalLive,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // 2. Titlu & Descriere (Clamped 2 linii, trunchiere aware de punctuație)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _sanitizeTitle(media.title.userPreferred),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Zalando Sans Expanded',
                                color: context.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _cleanDescription(media.description),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // 3. Pill-uri de gen, jos (Fix overflow garantat: max 2 genuri + "+N")
                        _buildGenrePills(context, media.genres),
                      ],
                    ),
                  ),
                ),

                // ZONA DREAPTA: Imagine Artwork cu Gradient Fade Orizontal (~42%)
                Expanded(
                  flex: 42,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagine Cover
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) =>
                            Container(color: context.bgSurfaceHover),
                        errorWidget: (context, url, error) => Container(
                          color: context.bgSurfaceHover,
                          child: Icon(
                            PhosphorIcons.imageBroken(PhosphorIconsStyle.bold),
                            color: context.textMuted,
                          ),
                        ),
                      ),

                      // Dynamic subtle color highlight over image (ca pe web)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              accentColor.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                      ),

                      // Gradient Fade Orizontal (Tranziție stânga-dreapta în Charcoal Navy)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: const [0.0, 0.28, 0.7, 1.0],
                            colors: [
                              context.bgSurface,
                              context.bgSurface.withValues(alpha: 0.82),
                              context.bgSurface.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Buton Bookmark (Watchlist) — Consecvent 1:1 cu Hero (44px, ClipOval + _glassFilter + Phosphor bookmark 22px, fără border)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => setState(() => _isBookmarkPressed = true),
                          onTapUp: (_) => setState(() => _isBookmarkPressed = false),
                          onTapCancel: () => setState(() => _isBookmarkPressed = false),
                          onTap: () => _toggleWatchlist(isInWatchlist),
                          child: AnimatedScale(
                            scale: _isBookmarkPressed ? 0.88 : 1.0,
                            duration: const Duration(milliseconds: 110),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: _glassFilter,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isInWatchlist
                                        ? context.accentPrimary
                                        : context.bgSurface.withValues(
                                            alpha: context.isDarkMode ? 0.75 : 0.88),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isInWatchlist
                                          ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                                          : PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                                      size: 22,
                                      color: isInWatchlist ? Colors.white : context.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
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

  /// Construiește pill-urile de gen cu garanție strictă de zero-overflow:
  /// Afișează maximum 2 genuri complete, urmate de un indicator "+N" discret dacă există mai multe.
  Widget _buildGenrePills(BuildContext context, List<String> genres) {
    if (genres.isEmpty) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: context.bgSurfaceHover,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          'Anime',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      );
    }

    final visibleGenres = genres.take(2).toList();
    final remainingCount = genres.length - visibleGenres.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final g in visibleGenres)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8.5),
              decoration: BoxDecoration(
                color: context.bgSurfaceHover,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: context.borderSubtle.withValues(alpha: 0.5),
                  width: 0.6,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                g,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        if (remainingCount > 0)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: context.bgSurfaceHover.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: context.borderSubtle.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
      ],
    );
  }
}

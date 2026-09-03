import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/media_item.dart';
import '../views/media_detail_screen.dart';

class HeroCarousel extends StatefulWidget {
  final List<MediaItem> items;

  const HeroCarousel({super.key, required this.items});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  int _currentPage = 0;
  Timer? _autoTimer;

  static final ImageFilter _glassFilter = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    inner: const ColorFilter.matrix(<double>[
      1.6296, -0.5720, -0.0576, 0, 0,
     -0.1704,  1.2280, -0.0576, 0, 0,
     -0.1704, -0.5720,  1.7424, 0, 0,
      0,       0,       0,      1, 0,
    ]),
  );

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    if (widget.items.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % widget.items.length;
        });
      }
    });
  }

  void _nextPage() {
    if (widget.items.length <= 1) return;
    setState(() {
      _currentPage = (_currentPage + 1) % widget.items.length;
    });
    _startAutoPlay();
  }

  void _prevPage() {
    if (widget.items.length <= 1) return;
    setState(() {
      _currentPage = (_currentPage - 1 + widget.items.length) % widget.items.length;
    });
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  String _getCurrentSeasonText() {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    String season;
    if (month >= 3 && month <= 5) {
      season = AppStrings.seasonSpring;
    } else if (month >= 6 && month <= 8) {
      season = AppStrings.seasonSummer;
    } else if (month >= 9 && month <= 11) {
      season = AppStrings.seasonFall;
    } else {
      season = AppStrings.seasonWinter;
    }
    return AppStrings.trendingSeasonTitle(season, year);
  }

  bool _isNewSeason(MediaItem item) {
    final now = DateTime.now();
    final currentYear = now.year;
    final month = now.month;
    String currentSeason;
    if (month >= 3 && month <= 5) {
      currentSeason = 'SPRING';
    } else if (month >= 6 && month <= 8) {
      currentSeason = 'SUMMER';
    } else if (month >= 9 && month <= 11) {
      currentSeason = 'FALL';
    } else {
      currentSeason = 'WINTER';
    }

    final isCurrentSeasonYear = item.year == currentYear &&
        (item.season?.toUpperCase() == currentSeason || item.season == null);
    final isReleasingOrNew = item.status == 'RELEASING' || item.status == 'NOT_YET_RELEASED';

    return isCurrentSeasonYear && isReleasingOrNew;
  }

  void _openDetail(BuildContext context, MediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(mediaId: item.id, initialItem: item),
      ),
    );
  }

  Widget _buildBlurFadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, animChild) {
          final blur = (1.0 - animation.value) * 6.0;
          if (blur <= 0.1) return animChild!;
          return ClipRect(
            clipBehavior: Clip.hardEdge,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: animChild,
            ),
          );
        },
        child: child,
      ),
    );
  }

  Widget _buildScalingDotsIndicator(BuildContext context, int totalCount, int currentIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final distance = (index - currentIndex).abs();

        double dotSize;
        double opacity;
        if (distance == 0) {
          dotSize = 7.0;
          opacity = 1.0;
        } else if (distance == 1) {
          dotSize = 5.0;
          opacity = 0.65;
        } else if (distance == 2) {
          dotSize = 3.5;
          opacity = 0.35;
        } else {
          dotSize = 0.0;
          opacity = 0.0;
        }

        if (dotSize == 0.0) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.46).clamp(380.0, 430.0);
    final safeCurrentIndex = _currentPage.clamp(0, widget.items.length - 1);
    final item = widget.items[safeCurrentIndex];
    final bannerUrl = item.bannerImage ?? item.coverImage.large;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: heroHeight,
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(26),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openDetail(context, item),
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -120) {
                  _nextPage();
                } else if (details.primaryVelocity! > 120) {
                  _prevPage();
                }
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Image with synchronized Blur-Fade transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: _buildBlurFadeTransition,
                  child: SizedBox(
                    key: ValueKey<String>('hero_bg_${item.id}_$safeCurrentIndex'),
                    width: double.infinity,
                    height: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: bannerUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(color: context.bgSurface),
                      errorWidget: (context, url, error) => Container(color: context.bgSurface),
                    ),
                  ),
                ),

                // 2. Cinematic Vertical Gradient Overlay inside the bounded card
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.94),
                        ],
                        stops: const [0.0, 0.40, 0.72, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Content Block inside the Card
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badges Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Badge Trending (Frosted glass over card)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter: _glassFilter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                                    const SizedBox(width: 4.5),
                                    Text(
                                      _getCurrentSeasonText(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Google Sans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Text "Sezon Nou"
                          if (_isNewSeason(item)) ...[
                            const SizedBox(width: 10),
                            const Text(
                              'Sezon Nou',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Google Sans',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title & Subtitle with smooth blur-fade transition
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        transitionBuilder: _buildBlurFadeTransition,
                        child: KeyedSubtree(
                          key: ValueKey<String>('hero_text_${item.id}_$safeCurrentIndex'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title with fixed reserved height
                              SizedBox(
                                height: 50,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.title.userPreferred,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Zalando Sans Expanded',
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Formats & Genres
                              SizedBox(
                                height: 18,
                                child: Text(
                                  [
                                    item.format ?? item.type,
                                    if (item.year != null) '${item.year}',
                                    ...item.genres.take(3),
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12,
                                    fontFamily: 'Google Sans',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Action Buttons Row
                      Row(
                        children: [
                          // "Vezi Serie" Button (Warm Beige CTA with high contrast dark text)
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => _openDetail(context, item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5EFE6),
                                foregroundColor: const Color(0xFF181614),
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Vezi Serie',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF181614),
                                  fontSize: 13.5,
                                  fontFamily: 'Google Sans',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Bookmark Button
                          InkWell(
                            onTap: () => _openDetail(context, item),
                            borderRadius: BorderRadius.circular(999),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: _glassFilter,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Scaling dots indicator at the bottom of the Card
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildScalingDotsIndicator(
                      context,
                      widget.items.length,
                      safeCurrentIndex,
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

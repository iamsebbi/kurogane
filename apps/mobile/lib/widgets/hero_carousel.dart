import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
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
      season = 'Primăvară';
    } else if (month >= 6 && month <= 8) {
      season = 'Vară';
    } else if (month >= 9 && month <= 11) {
      season = 'Toamnă';
    } else {
      season = 'Iarnă';
    }
    return 'Trending • $season $year';
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

        final activeColor = context.textPrimary;
        final inactiveColor = context.isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: distance == 0 ? activeColor : inactiveColor.withValues(alpha: opacity),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.sizeOf(context).height;
    // Înălțime maximă 50% din viewport height
    final heroHeight = (screenHeight * 0.46).clamp(390.0, 440.0);
    final safeCurrentIndex = _currentPage.clamp(0, widget.items.length - 1);
    final item = widget.items[safeCurrentIndex];
    final bannerUrl = item.bannerImage ?? item.coverImage.large;

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: heroHeight,
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
              // 1. Imagine cu Tranziție Sincronizată Blur-Fade stil iOS și ClipRect strict
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: _buildBlurFadeTransition,
                child: SizedBox(
                  key: ValueKey<String>('bg_${item.id}_$safeCurrentIndex'),
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

              // 2. Vertical Gradient Mask static deasupra fundalului (fără scurgeri vizuale)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        context.bgPrimary.withValues(alpha: 0.2),
                        context.bgPrimary.withValues(alpha: 0.8),
                        context.bgPrimary,
                      ],
                      stops: const [0.0, 0.35, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Blocul de Conținut: Poziție Fixă, Badges Statice, Tranziție Blur-Fade pe Titlu & Subtitlu
              Positioned(
                left: 16,
                right: 16,
                bottom: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badges Row (Complet static — fără nicio tranziție de blur)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Badge Trending (fără border, blur saturat)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: _glassFilter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: context.bgSurface.withValues(
                                    alpha: context.isDarkMode ? 0.75 : 0.88),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: context.textPrimary),
                                  const SizedBox(width: 4.5),
                                  Text(
                                    _getCurrentSeasonText(),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Text "Sezon Nou" plasat direct lângă badge în culoare deschisă
                        if (_isNewSeason(item)) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Sezon Nou',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Titlu & Genuri (Animat fluid cu Blur-Fade sincronizat cu imaginea)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: _buildBlurFadeTransition,
                      child: KeyedSubtree(
                        key: ValueKey<String>('text_${item.id}_$safeCurrentIndex'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Titlu cu înălțime rezervată fixă
                            SizedBox(
                              height: 52,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.title.userPreferred,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Zalando Sans Expanded',
                                    color: context.textPrimary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Genuri, Format și An
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
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Butoane de Acțiune (Complet Statice — Nu se re-animează între slide-uri)
                    Row(
                      children: [
                        // Buton Principal: "Vezi Serie" (Doar text, Pill shape, 44px)
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => _openDetail(context, item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.accentPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Vezi Serie',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Buton Secundar: Watchlist (Cerc complet de 44px, fără border, blur saturat)
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
                                  color: context.bgSurface.withValues(
                                      alpha: context.isDarkMode ? 0.75 : 0.88),
                                  boxShadow: [
                                    if (!context.isDarkMode)
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                                    size: 22,
                                    color: context.textPrimary,
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

              // 4. Indicator Puncte cu Scaling Dinamic (Punctul activ e cel mai mare, adiacentele medii, exterioarele mici)
              Positioned(
                bottom: 12,
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
    );
  }
}

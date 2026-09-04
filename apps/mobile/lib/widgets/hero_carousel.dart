import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../views/auth/login_screen.dart';
import '../views/media_detail_screen.dart';
import 'floating_circle_button.dart';
import 'tactile_scale_button.dart';

class HeroCarousel extends ConsumerStatefulWidget {
  final List<MediaItem> items;
  final ScrollController? scrollController;

  const HeroCarousel({
    super.key,
    required this.items,
    this.scrollController,
  });

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _progressController;

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
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextPage();
      }
    });
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.items.length <= 1) return;
    _progressController.reset();
    _progressController.forward();
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
    _progressController.dispose();
    super.dispose();
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

  Widget _buildAppleTvPageControl(BuildContext context, int totalCount, int currentIndex) {
    if (totalCount <= 1) return const SizedBox.shrink();

    const dotColor = Colors.white;

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(totalCount, (index) {
            final isActive = index == currentIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              width: isActive ? 28.0 : 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                color: dotColor.withValues(alpha: isActive ? 0.35 : 0.22),
              ),
              child: isActive
                  ? FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressController.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3.0),
                          color: dotColor,
                        ),
                      ),
                    )
                  : null,
            );
          }),
        );
      },
    );
  }

  Widget _buildElasticBackgroundImage({
    required BuildContext context,
    required double heroHeight,
    required String bannerUrl,
    required int safeCurrentIndex,
    required MediaItem item,
  }) {
    final imageWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: _buildBlurFadeTransition,
      child: SizedBox(
        key: ValueKey<String>('hero_bg_${item.id}_$safeCurrentIndex'),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Poster clar original
            CachedNetworkImage(
              imageUrl: bannerUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (context, url) => Container(color: context.bgSurface),
              errorWidget: (context, url, error) => Container(color: context.bgSurface),
            ),

            // 2. Progressive Blur la partea de jos a posterului (bokeh sub titlu, butoane și tranziție)
            ClipRect(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black,
                    ],
                    stops: [0.0, 0.42, 0.80],
                  ).createShader(bounds);
                },
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 22,
                    sigmaY: 22,
                    tileMode: TileMode.mirror,
                  ),
                  child: SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: bannerUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.scrollController == null) {
      return ClipRect(
        clipper: const _HeroStretchClipper(overscroll: 0.0),
        child: imageWidget,
      );
    }

    return AnimatedBuilder(
      animation: widget.scrollController!,
      builder: (context, _) {
        final offset = widget.scrollController!.hasClients
            ? widget.scrollController!.offset
            : 0.0;
        final overscroll = (-offset).clamp(0.0, 300.0);

        Widget transformed = imageWidget;

        if (overscroll > 0.0) {
          final blurSigma = (overscroll / 9.0).clamp(0.0, 16.0);
          final scale = 1.0 + (overscroll / heroHeight);

          transformed = Transform.translate(
            offset: Offset(0, -overscroll),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: imageWidget,
            ),
          );

          if (blurSigma > 0.1) {
            transformed = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: transformed,
            );
          }
        }

        return ClipRect(
          clipper: _HeroStretchClipper(overscroll: overscroll),
          child: transformed,
        );
      },
    );
  }

  Widget _buildProgressiveTopScrimContent() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000), // ~80% black la marginea de sus pentru status bar
            Color(0x66000000), // ~40% black în dreptul logo-ului
            Color(0x18000000), // ~10% black tranziție
            Colors.transparent,
          ],
          stops: [0.0, 0.40, 0.70, 1.0],
        ),
      ),
    );
  }

  Widget _buildElasticTopScrim() {
    const double baseHeight = 150.0;

    if (widget.scrollController == null) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: baseHeight,
        child: _buildProgressiveTopScrimContent(),
      );
    }

    return AnimatedBuilder(
      animation: widget.scrollController!,
      builder: (context, _) {
        final offset = widget.scrollController!.hasClients
            ? widget.scrollController!.offset
            : 0.0;
        final overscroll = (-offset).clamp(0.0, 300.0);

        return Positioned(
          top: -overscroll,
          left: 0,
          right: 0,
          height: baseHeight + overscroll,
          child: _buildProgressiveTopScrimContent(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.65).clamp(520.0, 620.0);
    final safeCurrentIndex = _currentPage.clamp(0, widget.items.length - 1);
    final item = widget.items[safeCurrentIndex];
    final bannerUrl = item.bannerImage ?? item.coverImage.large;

    final watchlistAsync = ref.watch(watchlistProvider);
    final isInWatchlist = watchlistAsync.valueOrNull?.any((w) => w.mediaId == item.id) ?? false;

    return SizedBox(
      width: double.infinity,
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
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            // 1. Background Image with synchronized Blur-Fade transition & Elastic Zoom/Blur pe Pull
            _buildElasticBackgroundImage(
              context: context,
              heroHeight: heroHeight,
              bannerUrl: bannerUrl,
              safeCurrentIndex: safeCurrentIndex,
              item: item,
            ),

            // 2. Scrim Superior (Protejează Logo Kurogane + Butoane Profil/Notificări)
            _buildElasticTopScrim(),

            // 3. Scrim Inferior Cinematic (Curat pe poster, fără fuziune în bgPrimary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 310,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.68),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.0, 0.40, 0.72, 1.0],
                  ),
                ),
              ),
            ),

            // 4. Content Block inside the Hero (Centrat Orizontal)
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Badge "Trending" (Fuziune cu paleta bottom bar)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.25 : 0.06,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: _glassFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: context.bgSurface.withValues(
                              alpha: context.isDarkMode ? 0.75 : 0.88,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.fire(PhosphorIconsStyle.fill),
                                size: 13,
                                color: AppColors.alertCoral,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Trending',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Titlu & Metadate cu Blur-Fade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: _buildBlurFadeTransition,
                    child: KeyedSubtree(
                      key: ValueKey<String>('hero_text_${item.id}_$safeCurrentIndex'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Titlul seriei (centrat, bold)
                          SizedBox(
                            height: 60,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                item.title.userPreferred,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Zalando Sans Expanded',
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // 3. Metadate serie (Format • An • Genuri • Airing ca text simplu)
                          Text(
                            [
                              item.format ?? item.type,
                              if (item.year != null) '${item.year}',
                              ...item.genres.take(2),
                              if (item.status == 'RELEASING') 'Airing',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontFamily: 'Google Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Butoane "Vezi Serie" + "Adaugă în Watchlist" — centrate orizontal, unul lângă altul
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Butonul "Vezi Serie" (CTA principal, stadium pill cald)
                      TactileScaleButton(
                        onTap: () => _openDetail(context, item),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EFE6), // Warm Beige / Apple TV white
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: context.isDarkMode ? 0.35 : 0.08,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIconsFill.play,
                                color: Color(0xFF181614),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Vezi Serie',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF181614),
                                  fontSize: 14.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Butonul "+" / Watchlist (cerc sticlă mată 48x48 conform design system)
                      FloatingCircleButton(
                        size: 48,
                        onTap: () async {
                          final user = ref.read(currentUserProvider);
                          if (user == null) {
                            LoginScreen.show(context);
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          if (isInWatchlist) {
                            await ref.read(watchlistProvider.notifier).removeItem(item.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Eliminat din Watchlist"),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            await ref.read(watchlistProvider.notifier).updateItem(
                                  mediaId: item.id,
                                  status: 'PLAN_TO_WATCH',
                                  progressEpisodes: 0,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Adăugat în Watchlist!"),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          isInWatchlist
                              ? PhosphorIcons.check(PhosphorIconsStyle.bold)
                              : PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          color: context.textPrimary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 5. Page control (dots cu loading pill progresiv sincronizat la 6s)
                  _buildAppleTvPageControl(
                    context,
                    widget.items.length,
                    safeCurrentIndex,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStretchClipper extends CustomClipper<Rect> {
  final double overscroll;

  const _HeroStretchClipper({required this.overscroll});

  @override
  Rect getClip(Size size) {
    // Permite desenarea în sus până la -overscroll (acoperă y=0 la marginea de sus),
    // dar taie ferm la size.height la bază, împiedicând orice scurgere de blur sau poster!
    return Rect.fromLTRB(
      -size.width * 0.5,
      -overscroll - 50.0,
      size.width * 1.5,
      size.height,
    );
  }

  @override
  bool shouldReclip(covariant _HeroStretchClipper oldClipper) {
    return oldClipper.overscroll != overscroll;
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../providers/api_providers.dart';
import '../models/homepage_data.dart';
import '../models/news_article.dart';
import '../widgets/airing_episode_card.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/media_card.dart';
import '../widgets/pill_badge.dart';
import '../widgets/seasonal_anime_section.dart';
import '../widgets/blur_fade_route.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDataAsync = ref.watch(homepageDataProvider);
    final topInset = MediaQuery.paddingOf(context).top;
    final headerTotalHeight = topInset + 68.0;

    final HomepageData? data = homeDataAsync.valueOrNull;

    // 1. Initial Loading Screen (Doar când nu există niciun fel de date în cache)
    if (data == null && homeDataAsync.isLoading) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
      );
    }

    // 2. Error Screen (Doar când nu există date și a apărut o eroare)
    if (data == null && homeDataAsync.hasError) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                  size: 48,
                  color: AppColors.alertCoral,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nu s-au putut încărca datele',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifică conexiunea la serverul Kurogane.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.invalidate(homepageDataProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                  ),
                  child: const Text('Reîncearcă', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. UI Principal cu Pull-to-Refresh poziționat natural sub Header
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Stack(
        children: [
          // Conținutul Scrollable cu RefreshIndicator calibrat sub Header
          RefreshIndicator(
            color: context.accentPrimary,
            backgroundColor: context.bgSurface,
            edgeOffset: headerTotalHeight,
            displacement: 36.0,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              ref.invalidate(homepageDataProvider);
              try {
                await ref.read(homepageDataProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Spacing top dedicat pentru header-ul Frosted Glass
                SliverToBoxAdapter(
                  child: SizedBox(height: headerTotalHeight + 6.0),
                ),

                // Hero Featured Carousel (Card delimitat cu margini laterale de 16px)
                if (data!.heroItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: HeroCarousel(items: data.heroItems),
                  ),

                // Live Airing Section
                if (data.recentlyAired.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context: context,
                      title: 'Episoade Noi',
                      icon: PhosphorIcons.broadcast(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 295,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.recentlyAired.length,
                        itemBuilder: (context, index) {
                          final ep = data.recentlyAired[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: AiringEpisodeCard(item: ep, width: 180),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Seasonal Anime Section
                if ((data.featuredSeason.isNotEmpty ? data.featuredSeason : data.topAiring).isNotEmpty)
                  SliverToBoxAdapter(
                    child: SeasonalAnimeSection(
                      items: data.featuredSeason.isNotEmpty ? data.featuredSeason : data.topAiring,
                    ),
                  ),

                // Trending This Season Section
                if (data.trendingSeason.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context: context,
                      title: 'Trending în acest sezon',
                      icon: PhosphorIcons.fire(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.trendingSeason.length,
                        itemBuilder: (context, index) {
                          final item = data.trendingSeason[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: MediaCard(item: item, width: 155),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Top Rated of All Time (Top 100)
                if (data.top100.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context: context,
                      title: 'Capodopere din Toate Timpurile',
                      icon: PhosphorIcons.trophy(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.top100.length,
                        itemBuilder: (context, index) {
                          final item = data.top100[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: MediaCard(item: item, width: 155),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // News Section
                if (data.news.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context: context,
                      title: 'Știri & Articole Recente',
                      icon: PhosphorIcons.newspaper(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final article = data.news[index];
                          return _buildNewsCard(context, article);
                        },
                        childCount: data.news.length.clamp(0, 5),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // 2. Persistent Frosted Glass Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: context.bgPrimary.withValues(
                    alpha: context.isDarkMode ? 0.78 : 0.86,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Typographic Logo "KUROGANE"
                          Text(
                            'KUROGANE',
                            style: TextStyle(
                              fontFamily: 'Zalando Sans Expanded',
                              color: context.textPrimary,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),

                          // Floating Actions (52px Circles)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Notificări Circle Button (52px)
                              _FloatingCircleButton(
                                size: 52,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nu ai notificări noi în acest moment.'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIcons.bell(PhosphorIconsStyle.bold),
                                      color: context.textPrimary,
                                      size: 22,
                                    ),
                                    Positioned(
                                      top: 11,
                                      right: 11,
                                      child: Container(
                                        width: 8.5,
                                        height: 8.5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.alertCoral,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 2. Profil Circle Button (52px)
                              _FloatingCircleButton(
                                size: 52,
                                onTap: () {
                                  Navigator.of(context).push(
                                    BlurFadePageRoute(
                                      child: const ProfileScreen(),
                                    ),
                                  );
                                },
                                child: Icon(
                                  PhosphorIcons.user(PhosphorIconsStyle.bold),
                                  color: context.textPrimary,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    String? badge,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.accentPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Zalando Sans Expanded',
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (badge != null) PillBadge(label: badge),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 70,
                    height: 70,
                    color: context.bgPrimary,
                    child: Icon(
                      PhosphorIcons.newspaper(PhosphorIconsStyle.bold),
                      color: context.textMuted,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: TextStyle(
                          color: context.accentPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (article.date.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•  ${article.date}',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
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

/// Floating Circle Button in Liquid Glass Style (52px)
class _FloatingCircleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const _FloatingCircleButton({
    required this.child,
    required this.onTap,
    this.size = 52,
  });

  @override
  State<_FloatingCircleButton> createState() => _FloatingCircleButtonState();
}

class _FloatingCircleButtonState extends State<_FloatingCircleButton> {
  bool _isPressed = false;
  static final _glassFilter = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: ClipOval(
          child: BackdropFilter(
            filter: _glassFilter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPressed
                    ? context.bgSurfaceHover
                    : context.bgSurface.withValues(alpha: context.isDarkMode ? 0.75 : 0.88),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode
                          ? (_isPressed ? 0.45 : 0.28)
                          : (_isPressed ? 0.12 : 0.06),
                    ),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

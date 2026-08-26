import 'dart:ui';
import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: RefreshIndicator(
        color: context.accentPrimary,
        backgroundColor: context.bgSurface,
        onRefresh: () async {
          ref.invalidate(homepageDataProvider);
        },
        child: homeDataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                      size: 48, color: AppColors.alertCoral),
                  const SizedBox(height: 16),
                  const Text(
                    'Nu s-au putut încărca datele',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verifică conexiunea la serverul Kurogane.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(homepageDataProvider),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary),
                    child: const Text('Reîncearcă',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => Stack(
            children: [
              // Conținutul principal (începe complet de sus)
              _buildHomeContent(context, data),

              // Doar cele 2 Icon-uri Plutitoare în Dreapta Sus (Fără niciun navbar)
              Positioned(
                top: 0,
                right: 16,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Icon Circle Notificări Plutitor (52px)
                        _FloatingCircleButton(
                          size: 52,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Nu ai notificări noi în acest moment.'),
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
                                size: 23,
                              ),
                              Positioned(
                                top: 11,
                                right: 11,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppColors.alertCoral,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 2. Icon Circle Profil Plutitor (52px)
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
                            size: 23,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomepageData data) {
    return CustomScrollView(
      slivers: [
        // Hero Featured Carousel (începe din vârf sub status bar)
        if (data.heroItems.isNotEmpty)
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

        // Seasonal Anime Section (Layout Orizontal • Card Anime Sezon)
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
              title: 'Top Sezonul Curent',
              badge: 'TRENDING',
              icon: PhosphorIcons.fire(PhosphorIconsStyle.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 295,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.trendingSeason.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: MediaCard(item: data.trendingSeason[index]),
                  );
                },
              ),
            ),
          ),
        ],

        // Top 100 All Time Section
        if (data.top100.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context: context,
              title: 'Top 100 Toate Timpurile',
              badge: 'HALL OF FAME',
              icon: PhosphorIcons.trophy(PhosphorIconsStyle.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 295,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.top100.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: MediaCard(
                      item: data.top100[index],
                      showRank: true,
                      rank: index + 1,
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // News & RSS Section
        if (data.news.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context: context,
              title: 'Știri & Actualizări Anime',
              badge: 'RSS FEEDS',
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
          if (badge != null && badge.isNotEmpty)
            PillBadge(
              label: badge,
              fontSize: 9,
              backgroundColor: context.accentPrimary.withValues(alpha: 0.12),
              textColor: context.accentPrimary,
              borderColor: context.accentPrimary.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }



  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          if (!context.isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppColors.bgSurfaceHover),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PillBadge(
                      label: article.category,
                      fontSize: 8,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                    ),
                    Text(
                      article.date,
                      style: TextStyle(
                          color: context.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const _FloatingCircleButton({
    required this.onTap,
    required this.child,
    this.size = 52.0,
  });

  @override
  State<_FloatingCircleButton> createState() => _FloatingCircleButtonState();
}

class _FloatingCircleButtonState extends State<_FloatingCircleButton> {
  bool _isPressed = false;

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 1.15 : 1.0,
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
                        alpha: context.isDarkMode ? (_isPressed ? 0.5 : 0.35) : (_isPressed ? 0.12 : 0.08)),
                    blurRadius: _isPressed ? 14 : 10,
                    offset: const Offset(0, 4),
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

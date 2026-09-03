import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/api_providers.dart';
import '../models/homepage_data.dart';
import '../widgets/airing_episode_card.dart';
import '../widgets/floating_circle_button.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/horizontal_poster_carousel.dart';
import '../widgets/news_article_card.dart';
import '../widgets/section_header.dart';
import '../widgets/seasonal_anime_section.dart';
import '../widgets/blur_fade_route.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDataAsync = ref.watch(homepageDataProvider);
    final unreadNotificationsCount = ref.watch(unreadNotificationsCountProvider);
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
                  AppStrings.homeUnableToLoad,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.homeCheckConnection,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.invalidate(homepageDataProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                  ),
                  child: const Text(AppStrings.retry, style: TextStyle(color: Colors.white)),
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
                    child: SectionHeader(
                      title: AppStrings.homeNewEpisodes,
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

                // Recommended For You Section (Personalizat / Guest)
                if (data.recommendations.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: AppStrings.homeRecommendedForYou,
                      icon: PhosphorIcons.sparkle(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HorizontalPosterCarousel(
                      items: data.recommendations.map((r) => r.media).toList(),
                    ),
                  ),
                ],

                // Trending This Season Section
                if (data.trendingSeason.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: AppStrings.homeTrendingSeason,
                      icon: PhosphorIcons.fire(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HorizontalPosterCarousel(
                      items: data.trendingSeason,
                    ),
                  ),
                ],

                // Top Upcoming Section (Coming Soon)
                if (data.topUpcoming.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: AppStrings.homeUpcomingSeason,
                      icon: PhosphorIcons.calendarPlus(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HorizontalPosterCarousel(
                      items: data.topUpcoming,
                    ),
                  ),
                ],

                // Top Rated of All Time (Top 100)
                if (data.top100.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: AppStrings.homeAllTimeMasterpieces,
                      icon: PhosphorIcons.trophy(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HorizontalPosterCarousel(
                      items: data.top100,
                    ),
                  ),
                ],

                // News Section
                if (data.news.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: AppStrings.homeRecentNews,
                      icon: PhosphorIcons.newspaper(PhosphorIconsStyle.bold),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return NewsArticleCard(
                            article: data.news[index],
                          );
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
                              FloatingCircleButton(
                                size: 52,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push(
                                    BlurFadePageRoute(
                                      child: const NotificationsScreen(),
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
                                    if (unreadNotificationsCount > 0)
                                      Positioned(
                                        top: 11,
                                        right: 11,
                                        child: Container(
                                          width: 8.5,
                                          height: 8.5,
                                          decoration: BoxDecoration(
                                            color: context.error,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 2. Profil Circle Button (52px)
                              FloatingCircleButton(
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
}

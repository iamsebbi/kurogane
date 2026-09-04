import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/api_providers.dart';
import '../models/homepage_data.dart';
import '../models/media_item.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ScrollController _scrollController;
  bool _isPastHero = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.65).clamp(520.0, 620.0);
    final topInset = MediaQuery.paddingOf(context).top;
    final isPast = _scrollController.offset > (heroHeight - (topInset + 60.0));
    if (isPast != _isPastHero) {
      setState(() {
        _isPastHero = isPast;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homepageDataProvider);
    final unreadNotificationsCount = ref.watch(unreadNotificationsCountProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    final HomepageData? data = homeDataAsync.valueOrNull;

    // 1. Initial Loading Screen
    if (data == null && homeDataAsync.isLoading) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
      );
    }

    // 2. Error Screen
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

    // 3. UI Principal Full-Bleed cu Header Overlay stil Apple TV
    final isDarkStatusIcons = _isPastHero && !context.isDarkMode;
    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkStatusIcons ? Brightness.dark : Brightness.light,
      statusBarBrightness: isDarkStatusIcons ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: context.bgPrimary,
      systemNavigationBarIconBrightness: context.isDarkMode ? Brightness.light : Brightness.dark,
    );

    final seasonalList = data != null && data.featuredSeason.isNotEmpty
        ? data.featuredSeason
        : (data?.topAiring ?? const <MediaItem>[]);
    final top10Items = seasonalList.take(10).toList();
    final trailersList = [
      ...seasonalList.where((i) => i.trailerUrl != null && i.trailerUrl!.isNotEmpty),
      ...seasonalList.where((i) => i.trailerUrl == null || i.trailerUrl!.isEmpty),
    ].take(10).toList();

    String seasonTitle = 'Top 10 • Sezon Curent';
    if (seasonalList.isNotEmpty) {
      final first = seasonalList.first;
      if (first.season != null && first.season!.isNotEmpty) {
        final seasonName = first.season![0].toUpperCase() + first.season!.substring(1).toLowerCase();
        final year = first.year ?? DateTime.now().year;
        seasonTitle = 'Top 10 • $seasonName $year';
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        body: Stack(
          children: [
            // Conținutul Scrollable Edge-to-Edge
            RefreshIndicator(
              color: context.accentPrimary,
              backgroundColor: context.bgSurface,
              edgeOffset: topInset + 58.0,
            displacement: 36.0,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              ref.invalidate(homepageDataProvider);
              try {
                await ref.read(homepageDataProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // 1. Hero Featured Carousel (Full-Bleed, de la marginea superioară y=0)
                if (data!.heroItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: HeroCarousel(
                      items: data.heroItems,
                      scrollController: _scrollController,
                    ),
                  ),

                // 2. Top 10 • Sezon Curent (Carusel cu Rank Number Zalando și buton 'See all')
                if (top10Items.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: seasonTitle,
                      icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                      trailing: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.seeAll,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.accentPrimary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                              size: 13,
                              color: context.accentPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HorizontalPosterCarousel(
                      items: top10Items,
                      width: 145,
                      height: 210,
                      containerHeight: 250,
                      showRank: true,
                    ),
                  ),
                ],

                // 3. Live Airing Section
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

                // 4. Popular Anime Trailers Section (Refactorizat complet din fostul Seasonal Anime)
                if (trailersList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: PopularTrailersSection(
                      items: trailersList,
                    ),
                  ),

                // 4. Recommended For You Section
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

                // 5. Trending This Season Section
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

                // 6. Top Upcoming Section
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

                // 7. Top Rated of All Time (Top 100)
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

                // 8. News Section
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

          // 2. Header Overlay Adaptiv (Activat la ieșirea din Hero: Frosted Bar, Centrare Logo, Slide-Up/Down pe Acțiuni)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                // Frosted Glass Background activat fluid când ieși din Hero
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    opacity: _isPastHero ? 1.0 : 0.0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.bgPrimary.withValues(
                              alpha: context.isDarkMode ? 0.80 : 0.88,
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: context.borderSubtle.withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Conținut Header (Logo centrat + iconițe animate)
                SafeArea(
                  bottom: false,
                  child: _buildHeaderContent(context, unreadNotificationsCount),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildHeaderContent(
    BuildContext context,
    int unreadNotificationsCount,
  ) {
    const animationDuration = Duration(milliseconds: 280);
    const animationCurve = Curves.easeOutCubic;

    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Logo "KUROGANE" centrat fluid la ieșirea din Hero (FĂRĂ SHADOW)
          AnimatedAlign(
            duration: animationDuration,
            curve: animationCurve,
            alignment: _isPastHero ? Alignment.center : Alignment.centerLeft,
            child: AnimatedPadding(
              duration: animationDuration,
              curve: animationCurve,
              padding: EdgeInsets.only(left: _isPastHero ? 0.0 : 18.0),
              child: AnimatedDefaultTextStyle(
                duration: animationDuration,
                curve: animationCurve,
                style: TextStyle(
                  fontFamily: 'Zalando Sans Expanded',
                  color: _isPastHero ? context.textPrimary : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                child: const Text('KUROGANE'),
              ),
            ),
          ),

          // 2. Floating Actions: Slide UP cu Fade Out la ieșire, Slide DOWN cu Fade In la revenire
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: AnimatedSlide(
                duration: animationDuration,
                curve: animationCurve,
                offset: _isPastHero ? const Offset(0.0, -0.6) : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: animationCurve,
                  opacity: _isPastHero ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _isPastHero,
                    child: Row(
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

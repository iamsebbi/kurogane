import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import '../models/media_item.dart';
import '../models/score_metrics.dart';
import '../widgets/clean_poster_card.dart';
import '../widgets/floating_circle_button.dart';
import '../widgets/franchise_horizontal_card.dart';
import '../widgets/glass_score_badge.dart';
import '../widgets/pill_badge.dart';
import '../widgets/recent_activity_horizontal_card.dart';
import '../widgets/standard_horizontal_card.dart';
import '../widgets/watchlist_horizontal_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static final MediaItem demoItem = MediaItem(
    id: '154587',
    title: MediaTitle(
      userPreferred: 'Sousou no Frieren',
      romaji: 'Sousou no Frieren',
      english: "Frieren: Beyond Journey's End",
      native: '葬送のフリーレン',
    ),
    type: 'ANIME',
    format: 'TV',
    status: 'FINISHED',
    episodes: 28,
    season: 'FALL',
    year: 2023,
    genres: const ['Adventure', 'Drama', 'Fantasy'],
    coverImage: CoverImage(
      large: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-qQTzQnEJJ3oB.jpg',
    ),
    scores: ScoreMetrics(
      averageScore: 91.0,
      reviewCount: 14200,
      weightedScore: 9.1,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER PRINCIPAL SANDBOX ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  FloatingCircleButton(
                    size: 52,
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                      size: 22,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Component Sandbox',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Duplicate & Standardized Components',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FloatingCircleButton(
                    size: 52,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(themeModeProvider.notifier).toggleTheme(!isDarkMode);
                    },
                    child: Icon(
                      isDarkMode
                          ? PhosphorIcons.sun(PhosphorIconsStyle.bold)
                          : PhosphorIcons.moon(PhosphorIconsStyle.bold),
                      size: 22,
                      color: isDarkMode ? AppColors.scoreGold : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // --- CANVAS DE COMPONENTE ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 0. SWITCH TEMĂ ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDarkMode
                                ? PhosphorIcons.moon(PhosphorIconsStyle.bold)
                                : PhosphorIcons.sun(PhosphorIconsStyle.bold),
                            color: isDarkMode ? AppColors.scoreGold : context.accentPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isDarkMode ? 'Dark Theme' : 'Light Theme',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: isDarkMode,
                            activeTrackColor: context.accentPrimary,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              ref.read(themeModeProvider.notifier).toggleTheme(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================================
                    // 1. SCORE BADGE REUTILIZABIL (GLASSSCOREBADGE)
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '1. REUSABLE COMPONENT: GLASS SCORE BADGE',
                      subtitle:
                          'Standardized rating badge in Glassmorphism style with blur and tabular numerals.',
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildLabel(context, 'Badge Preview:'),
                          const Spacer(),
                          const GlassScoreBadge(score: '9.1'),
                          const SizedBox(width: 8),
                          const GlassScoreBadge(score: '8.5'),
                          const SizedBox(width: 8),
                          const GlassScoreBadge(score: '10'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =========================================================
                    // 2. DUPLICAT: BUTOANE PLUTITOARE 52px
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '2. CIRCULAR BUTTONS: FLOATINGCIRCLEBUTTON',
                      subtitle:
                          'Unified standard 52px FloatingCircleButton across all screens.',
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          FloatingCircleButton(
                            size: 52,
                            onTap: () {},
                            child: Icon(
                              PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                              size: 22,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingCircleButton(
                            size: 52,
                            onTap: () {},
                            child: Icon(
                              PhosphorIcons.gear(PhosphorIconsStyle.bold),
                              size: 22,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingCircleButton(
                            size: 52,
                            onTap: () {},
                            child: Icon(
                              PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                              size: 22,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingCircleButton(
                            size: 52,
                            onTap: () {},
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.bell(PhosphorIconsStyle.bold),
                                  size: 22,
                                  color: context.textPrimary,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.alertCoral,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =========================================================
                    // 3. PASTILE METADATE & GENURI (PILLBADGE)
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '3. METADATA PILLS & GENRES (PILLBADGE)',
                      subtitle: 'Unified component for tags, filters, airing status and properties.',
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              PillBadge(label: 'Adventure', onTap: () {}),
                              PillBadge(label: 'Fantasy', onTap: () {}),
                              PillBadge(label: 'Drama', onTap: () {}),
                              const PillBadge(
                                label: 'Airing',
                                statusDotColor: AppColors.signalLive,
                                variant: PillVariant.status,
                              ),
                              PillBadge(
                                label: '28 Episodes',
                                icon: PhosphorIcons.filmStrip(PhosphorIconsStyle.bold),
                              ),
                              const PillBadge(label: 'Shounen', variant: PillVariant.accent),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =========================================================
                    // 4. CARD MINIMALIST (CLEAN POSTER)
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '4. MINIMALIST CARD (CLEAN POSTER)',
                      subtitle:
                          'Clean poster without borders, 18px rounded corners, integrated GlassScoreBadge and title.',
                    ),
                    const SizedBox(height: 12),

                    const Center(
                      child: CleanPosterCard(
                        title: 'Sousou no Frieren',
                        score: '9.1',
                        coverUrl:
                            'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-qQTzQnEJJ3oB.jpg',
                        width: 175,
                        height: 255,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =========================================================
                    // 5. CARDURI ORIZONTALE: 3 ITERAȚII DEDICATE
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '5. HORIZONTAL CARDS: 3 DEDICATED ITERATIONS',
                      subtitle:
                          'A. Standard (Explore / Home) • B. Watchlist (Progress & +1) • C. Recent Activity (History & Feed).',
                    ),
                    const SizedBox(height: 12),

                    // Iterația A: Standard (Explore / Home)
                    _buildLabel(context, 'A. Standard Horizontal Card (Explore / Home):'),
                    const SizedBox(height: 8),
                    StandardHorizontalCard(
                      title: demoItem.title.userPreferred,
                      coverUrl: demoItem.coverImage.large,
                      format: demoItem.format,
                      year: demoItem.year,
                      season: demoItem.season,
                      episodes: demoItem.episodes,
                      score: '9.1',
                      genres: demoItem.genres,
                      onTap: () {},
                    ),

                    const SizedBox(height: 16),

                    // Iterația B: Watchlist
                    _buildLabel(context, 'B. Watchlist Horizontal Card (Progress & Quick Action):'),
                    const SizedBox(height: 8),
                    WatchlistHorizontalCard(
                      title: demoItem.title.userPreferred,
                      coverUrl: demoItem.coverImage.large,
                      status: 'WATCHING',
                      progressEpisodes: 18,
                      totalEpisodes: 28,
                      media: demoItem,
                      onTap: () {},
                    ),

                    const SizedBox(height: 16),

                    // Iterația C: Recent Activity
                    _buildLabel(context, 'C. Recent Activity Horizontal Card (History & Log):'),
                    const SizedBox(height: 8),
                    RecentActivityHorizontalCard(
                      title: demoItem.title.userPreferred,
                      coverUrl: demoItem.coverImage.large,
                      activityType: 'Watched episode',
                      activityDetail: 'S1 E18',
                      timeAgo: '2h ago',
                      activityColor: context.statusWatching,
                      onTap: () {},
                    ),

                    const SizedBox(height: 16),

                    // Iterația D: Franchise Horizontal Card
                    _buildLabel(context, 'D. Franchise Horizontal Card (Relations & Universe):'),
                    const SizedBox(height: 8),
                    FranchiseHorizontalCard(
                      title: 'Frieren: Beyond Journey\'s End Season 2',
                      coverUrl: demoItem.coverImage.large,
                      relationLabel: 'SEQUEL',
                      relationBgColor: context.accentPrimary,
                      relationTextColor: context.onPrimary,
                      metadataText: 'TV • Fall 2024 • 12 ep. • S2',
                      onTap: () {},
                    ),

                    const SizedBox(height: 28),

                    // =========================================================
                    // 6. DUPLICAT: ANTETE DE SECȚIUNI (SECTION HEADERS)
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '6. SECTION HEADERS',
                      subtitle:
                          'Consistent typography and actions across Home, Detail, and Profile:',
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSectionHeaderDemo(
                            context,
                            title: 'New Episodes',
                            icon: PhosphorIcons.broadcast(PhosphorIconsStyle.bold),
                            onSeeAll: () {},
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildSectionHeaderDemo(
                            context,
                            title: 'Trending this season',
                            icon: PhosphorIcons.fire(PhosphorIconsStyle.fill),
                            onSeeAll: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =========================================================
                    // 7. DUPLICAT: BADGE-URI SPECIALIZATE (AIRING & FORMAT)
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '7. SPECIALIZED BADGES (AIRING & FORMAT)',
                      subtitle:
                          'Combined badge "NEW | EP 12" and format pill "TV".',
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // 1. Badge "NEW | EP 12" din AiringEpisodeCard
                          _buildAiringEpisodeBadgeDemo('NEW', 12),
                          const SizedBox(width: 12),
                          _buildAiringEpisodeBadgeDemo('LIVE', 28),
                          const SizedBox(width: 14),

                          // 2. Format Pill din SeasonalAnimeCard
                          _buildFormatPillDemo('TV'),
                          const SizedBox(width: 8),
                          _buildFormatPillDemo('MOVIE'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =========================================================
                    // 8. DUPLICAT: STĂRI DE SISTEM (EMPTY & ERROR)
                    // =========================================================
                    _buildSectionBanner(
                      context,
                      title: '8. SYSTEM STATES: EMPTY & ERROR STATES',
                      subtitle:
                          'Unified empty and error states across Explore, Watchlist, and Home.',
                    ),
                    const SizedBox(height: 10),

                    // Empty State din Explore / Watchlist
                    _buildEmptyStateDemo(context),
                    const SizedBox(height: 14),

                    // Error State din Explore / Home
                    _buildErrorStateDemo(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET-URI AJUTĂTOARE PENTRU TITLURI ȘI SECȚIUNI ---
  Widget _buildSectionBanner(BuildContext context, {required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.accentPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // --- 6. SECTION HEADER DIN HOME SCREEN ---
  Widget _buildSectionHeaderDemo(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: context.accentPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Zalando Sans Expanded',
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      color: context.accentPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
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
      ],
    );
  }

  // --- 7. BADGE-URI COMBINATE (NOU / LIVE & TV FORMAT) ---
  Widget _buildAiringEpisodeBadgeDemo(String label, int ep) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                height: 1.0,
              ),
            ),
          ),
          Container(
            height: 10,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'EP $ep',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatPillDemo(String format) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        format,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          height: 1.0,
        ),
      ),
    );
  }

  // --- 8. EMPTY & ERROR STATES DIN EXPLORE & HOME ---
  Widget _buildEmptyStateDemo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.bgSurfaceHover,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.folders(PhosphorIconsStyle.bold),
              size: 24,
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No titles found',
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your filters or search query.',
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStateDemo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.alertCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.alertCoral.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
            size: 32,
            color: AppColors.alertCoral,
          ),
          const SizedBox(height: 8),
          const Text(
            'Error loading content',
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: AppColors.alertCoral,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection to the Kurogane server.',
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}



import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/watchlist_item.dart';
import '../models/media_item.dart';
import '../models/score_metrics.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/blur_fade_route.dart';
import '../widgets/tactile_scale_button.dart';
import '../widgets/watchlist_horizontal_card.dart';
import '../widgets/watchlist_edit_modal.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'media_detail_screen.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _statusTabs = const [
    {'status': 'ALL', 'label': AppStrings.statusAll},
    {'status': 'WATCHING', 'label': AppStrings.statusWatching},
    {'status': 'PLAN_TO_WATCH', 'label': AppStrings.statusPlanToWatch},
    {'status': 'COMPLETED', 'label': AppStrings.statusCompleted},
    {'status': 'ON_HOLD', 'label': AppStrings.statusOnHold},
    {'status': 'DROPPED', 'label': AppStrings.statusDropped},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    // Show loading while Firebase determines auth state
    if (authState.isLoading && !isLoggedIn) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: context.accentPrimary),
        ),
      );
    }

    if (!isLoggedIn) {
      return _buildGuestWatchlistPrompt(context);
    }

    final watchlistAsync = ref.watch(watchlistProvider);
    final topInset = MediaQuery.of(context).padding.top;
    final headerTotalHeight = topInset + 106.0;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Stack(
        children: [
          // 1. Scrollable Watchlist Content (Scrolls smoothly underneath the Frosted Glass Header)
          Positioned.fill(
            child: watchlistAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.only(top: headerTotalHeight),
                  child: CircularProgressIndicator(color: context.accentPrimary),
                ),
              ),
              error: (e, st) => Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, headerTotalHeight + 20, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold), size: 48, color: context.error),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.errorLoadingWatchlist,
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Google Sans'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(watchlistProvider.notifier).fetchWatchlist(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.accentPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text(AppStrings.retry, style: TextStyle(color: context.onPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (watchlist) {
                return TabBarView(
                  controller: _tabController,
                  children: _statusTabs.map((tab) {
                    final statusFilter = tab['status']!;
                    final filteredItems = statusFilter == 'ALL'
                        ? watchlist
                        : watchlist.where((item) => item.status == statusFilter).toList();

                    if (filteredItems.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => ref.read(watchlistProvider.notifier).fetchWatchlist(),
                        color: context.accentPrimary,
                        backgroundColor: context.bgSurface,
                        edgeOffset: headerTotalHeight,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(24, headerTotalHeight + 20, 24, 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                                      size: 54,
                                      color: context.textMuted,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      AppStrings.watchlistEmptyTab(tab['label']!),
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Google Sans',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.watchlistExploreCatalog,
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 13,
                                        fontFamily: 'Google Sans',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    ElevatedButton.icon(
                                      onPressed: () => ref.read(watchlistProvider.notifier).fetchWatchlist(),
                                      icon: Icon(
                                        PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                                        size: 16,
                                        color: context.onPrimary,
                                      ),
                                      label: Text(
                                        AppStrings.refresh,
                                        style: TextStyle(
                                          color: context.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.accentPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref.read(watchlistProvider.notifier).fetchWatchlist(),
                      color: context.accentPrimary,
                      backgroundColor: context.bgSurface,
                      edgeOffset: headerTotalHeight,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, headerTotalHeight + 10, 16, 90),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildWatchlistTile(context, item);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // 2. Frosted Glass Header (Blur 20, Semi-transparent background)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: context.bgPrimary.withValues(alpha: context.isDarkMode ? 0.76 : 0.84),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Header: Title (Identical positioning & padding to Explore Screen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppStrings.navWatchlist,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontFamily: 'Zalando Sans Expanded',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(watchlistProvider.notifier).fetchWatchlist();
                                },
                                icon: Icon(
                                  PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                                  color: context.textSecondary,
                                  size: 20,
                                ),
                                tooltip: AppStrings.refresh,
                              ),
                            ],
                          ),
                        ),

                        // TabBar (Filter categories)
                        Container(
                          height: 44,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: context.accentPrimary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            labelColor: context.onPrimary,
                            labelStyle: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelColor: context.textSecondary,
                            unselectedLabelStyle: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            tabs: _statusTabs.map((tab) {
                              final statusKey = tab['status']!;
                              final label = tab['label']!;
                              final count = watchlistAsync.maybeWhen(
                                data: (list) => statusKey == 'ALL'
                                    ? list.length
                                    : list.where((item) => item.status == statusKey).length,
                                orElse: () => 0,
                              );
                              return Tab(
                                height: 34,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('$label ($count)'),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 8),
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

  Widget _buildWatchlistTile(BuildContext context, WatchlistItemRecord item) {
    final media = item.media ??
        MediaItem(
          id: item.mediaId,
          type: 'ANIME',
          title: MediaTitle(userPreferred: 'Media #${item.mediaId}'),
          coverImage: CoverImage(large: ''),
          scores: ScoreMetrics(averageScore: 0.0, reviewCount: 0, weightedScore: 0.0),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WatchlistHorizontalCard.fromWatchlistRecord(
        record: item,
        onTap: () {
          Navigator.of(context).push(
            BlurFadePageRoute(
              child: MediaDetailScreen(mediaId: item.mediaId, initialItem: item.media),
            ),
          );
        },
        onStatusTap: () {
          showWatchlistEditModal(
            context,
            ref,
            item: media,
            existingRecord: item,
          );
        },
        onLongPress: () {
          showWatchlistEditModal(
            context,
            ref,
            item: media,
            existingRecord: item,
          );
        },
        onIncrement: () => ref.read(watchlistProvider.notifier).incrementProgress(item),
        onDecrement: () {
          if (item.progressEpisodes > 0) {
            final nextProgress = item.progressEpisodes - 1;
            final totalEpisodes = item.media?.episodes;
            final isNoLongerCompleted = (item.status == 'COMPLETED' &&
                totalEpisodes != null &&
                totalEpisodes > 0 &&
                nextProgress < totalEpisodes);
            ref.read(watchlistProvider.notifier).updateItem(
                  mediaId: item.mediaId,
                  status: isNoLongerCompleted ? 'WATCHING' : item.status,
                  score: item.score,
                  progressEpisodes: nextProgress,
                  notes: item.notes,
                );
          }
        },
      ),
    );
  }

  Widget _buildGuestWatchlistPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Icon Phosphor
                Icon(
                  PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.regular),
                  size: 72,
                  color: context.textPrimary,
                ),

                const SizedBox(height: 24),

                // Titlu
                Text(
                  AppStrings.watchlistAuthRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Zalando Sans Expanded',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitlu
                Text(
                  AppStrings.watchlistAuthSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                    fontFamily: 'Google Sans',
                  ),
                ),

                const SizedBox(height: 36),

                // 3 Proof Points specifice Watchlist
                _buildWatchlistFeatureItem(
                  context: context,
                  icon: PhosphorIcons.devices(PhosphorIconsStyle.bold),
                  title: AppStrings.watchlistFeatureSync,
                ),
                const SizedBox(height: 18),
                _buildWatchlistFeatureItem(
                  context: context,
                  icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                  title: AppStrings.watchlistFeatureProgress,
                ),
                const SizedBox(height: 18),
                _buildWatchlistFeatureItem(
                  context: context,
                  icon: PhosphorIcons.folders(PhosphorIconsStyle.bold),
                  title: AppStrings.watchlistFeatureCategories,
                ),

                const SizedBox(height: 42),

                // Buton Principal Conectare (Full Rounded Stadium, Fără Border)
                TactileScaleButton(
                  onTap: () => LoginScreen.show(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: context.accentPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppStrings.watchlistSignIn,
                      style: TextStyle(
                        color: context.onPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Google Sans',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Buton Secundar Înregistrare (Full Rounded Stadium, Fără Border)
                TactileScaleButton(
                  onTap: () => RegisterScreen.show(context),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppStrings.watchlistCreateAccount,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Google Sans',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.bgSurfaceHover,
          ),
          child: Center(
            child: Icon(
              icon,
              color: context.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Google Sans',
            ),
          ),
        ),
      ],
    );
  }
}

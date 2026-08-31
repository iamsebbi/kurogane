import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/watchlist_item.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/blur_fade_route.dart';
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
    {'status': 'ALL', 'label': 'Toate'},
    {'status': 'WATCHING', 'label': 'Vizionare'},
    {'status': 'PLAN_TO_WATCH', 'label': 'De Văzut'},
    {'status': 'COMPLETED', 'label': 'Finalizate'},
    {'status': 'ON_HOLD', 'label': 'În Pauză'},
    {'status': 'DROPPED', 'label': 'Abandonate'},
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
                        'Eroare la încărcare',
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
                        child: Text('Reîncearcă', style: TextStyle(color: context.onPrimary, fontWeight: FontWeight.bold)),
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
                                      'Niciun anime în ${tab['label']}',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Google Sans',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Explorează catalogul și adaugă titluri în listă!',
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
                                        'Reîmprospătează',
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
                                  'Watchlist',
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
                                tooltip: 'Reîmprospătează',
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
    final media = item.media;
    final coverUrl = media?.coverImage.large ?? '';
    final title = media?.title.userPreferred ?? 'Media #${item.mediaId}';
    final totalEpisodes = media?.episodes;
    final progress = item.progressEpisodes;
    final progressFraction = (totalEpisodes != null && totalEpisodes > 0)
        ? (progress / totalEpisodes).clamp(0.0, 1.0)
        : 0.0;
    final statusColor = _getStatusColor(item.status);
    final statusLabel = _getStatusLabel(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _WatchlistScaleTile(
        onTap: () {
          Navigator.of(context).push(
            BlurFadePageRoute(
              child: MediaDetailScreen(mediaId: item.mediaId, initialItem: media),
            ),
          );
        },
        child: Container(
          height: 128,
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (!context.isDarkMode)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Poster Thumbnail with Rounded Corners (Fixed 76x108)
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 108,
                    child: coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: context.bgSurfaceHover),
                            errorWidget: (context, url, err) => Container(
                              color: context.bgSurfaceHover,
                              child: Icon(PhosphorIcons.imageBroken(PhosphorIconsStyle.bold), color: context.textMuted),
                            ),
                          )
                        : Container(
                            color: context.bgSurfaceHover,
                            child: Icon(PhosphorIcons.imageBroken(PhosphorIconsStyle.bold), color: context.textMuted),
                          ),
                  ),
                ),
              ),

              // 2. Info & Episode Controls (Uniform vertical distribution)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Status Badge + Score Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Pill Badge (Full Rounded, Zero Border)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Google Sans',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          // Score Badge
                          if (item.score != null && item.score! > 0)
                            Container(
                              height: 22,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xE60F1419),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                                    size: 10.5,
                                    color: AppColors.scoreGold,
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    item.score!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppColors.scoreGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Title (Single or two lines with ellipsis)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          color: context.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),

                      // Progress Bar (Linear full-rounded bar)
                      if (totalEpisodes != null && totalEpisodes > 0)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            minHeight: 4,
                            backgroundColor: context.bgPrimary,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        )
                      else
                        const SizedBox(height: 4),

                      // Bottom Row: Episode Counter & Quick + / - Buttons (36px Visual, 44px Hit Target)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ep. $progress / ${totalEpisodes != null && totalEpisodes > 0 ? totalEpisodes : "?"}',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Google Sans',
                            ),
                          ),

                          // Quick Action Buttons (+ and -) calling real Provider
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQuickActionButton(
                                context: context,
                                icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                enabled: progress > 0,
                                onTap: () {
                                  if (progress > 0) {
                                    final nextProgress = progress - 1;
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
                              _buildQuickActionButton(
                                context: context,
                                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                enabled: (totalEpisodes == null || totalEpisodes == 0 || progress < totalEpisodes),
                                onTap: () {
                                  if (totalEpisodes != null && totalEpisodes > 0 && progress >= totalEpisodes) {
                                    return;
                                  }
                                  final nextProgress = progress + 1;
                                  final isCompleted = (totalEpisodes != null && totalEpisodes > 0 && nextProgress >= totalEpisodes);
                                  ref.read(watchlistProvider.notifier).updateItem(
                                        mediaId: item.mediaId,
                                        status: isCompleted ? 'COMPLETED' : item.status,
                                        score: item.score,
                                        progressEpisodes: nextProgress,
                                        notes: item.notes,
                                      );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1.0 : 0.35,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.bgPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 15.5,
                color: enabled ? context.textPrimary : context.textMuted,
              ),
            ),
          ),
        ),
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
                  'Autentificare Necesară',
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
                  'Conectează-te pentru a-ți salva anime-urile și progresul la zi.',
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
                  title: 'Sincronizare Multi-Dispozitiv',
                ),
                const SizedBox(height: 18),
                _buildWatchlistFeatureItem(
                  context: context,
                  icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                  title: 'Evidență Episoade & Progres',
                ),
                const SizedBox(height: 18),
                _buildWatchlistFeatureItem(
                  context: context,
                  icon: PhosphorIcons.folders(PhosphorIconsStyle.bold),
                  title: 'Organizare pe Categorii',
                ),

                const SizedBox(height: 42),

                // Buton Principal Conectare (Full Rounded Stadium, Fără Border)
                _WatchlistScaleButton(
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
                      'Conectează-te la cont',
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
                _WatchlistScaleButton(
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
                      'Creează un cont nou',
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'WATCHING':
        return 'Vizionare';
      case 'COMPLETED':
        return 'Finalizat';
      case 'PLAN_TO_WATCH':
        return 'De Văzut';
      case 'ON_HOLD':
        return 'În Pauză';
      case 'DROPPED':
        return 'Abandonat';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WATCHING':
        return AppColors.signalLive;
      case 'COMPLETED':
        return const Color(0xFF60A5FA); // Sky Blue
      case 'PLAN_TO_WATCH':
        return AppColors.scoreGold;
      case 'ON_HOLD':
        return const Color(0xFFFB923C); // Warm Orange
      case 'DROPPED':
        return AppColors.alertCoral;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Scale tile interaction for Watchlist cards
class _WatchlistScaleTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _WatchlistScaleTile({
    required this.child,
    required this.onTap,
  });

  @override
  State<_WatchlistScaleTile> createState() => _WatchlistScaleTileState();
}

class _WatchlistScaleTileState extends State<_WatchlistScaleTile> {
  bool _isPressed = false;

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
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _WatchlistScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _WatchlistScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_WatchlistScaleButton> createState() => _WatchlistScaleButtonState();
}

class _WatchlistScaleButtonState extends State<_WatchlistScaleButton> {
  bool _isPressed = false;

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
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

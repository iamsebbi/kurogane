import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../providers/api_providers.dart';
import '../widgets/media_card.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/blur_fade_route.dart';
import 'media_detail_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchFiltersProvider.notifier).state =
          ref.read(searchFiltersProvider).copyWith(query: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    final bool hasActiveFilters = filters.genres.isNotEmpty ||
        filters.microTags.isNotEmpty ||
        filters.type != 'ALL' ||
        filters.format != 'ALL' ||
        (filters.minScore != null && filters.minScore! > 0);

    final topInset = MediaQuery.of(context).padding.top;
    final headerTotalHeight = topInset + 176.0;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Stack(
        children: [
          // 1. Scrollable Results (Scrolls smoothly underneath the Frosted Glass Header)
          Positioned.fill(
            child: searchResultsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accentPrimary),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, headerTotalHeight + 20, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold), size: 48, color: AppColors.alertCoral),
                      const SizedBox(height: 16),
                      Text(
                        'Eroare la căutare',
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Google Sans'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$err',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, headerTotalHeight + 20, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold), size: 48, color: context.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'Niciun rezultat găsit',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // AnimatedSwitcher for Grid <-> List toggle
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _isGridView
                      ? GridView.builder(
                          key: const ValueKey('explore_grid_view'),
                          padding: EdgeInsets.fromLTRB(16, headerTotalHeight + 6, 16, 90),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.63,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            return MediaCard(item: results[index], width: double.infinity);
                          },
                        )
                      : ListView.builder(
                          key: const ValueKey('explore_list_view'),
                          padding: EdgeInsets.fromLTRB(16, headerTotalHeight + 6, 16, 90),
                          physics: const BouncingScrollPhysics(),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            return _buildExploreListItem(context, results[index]);
                          },
                        ),
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
                        // Top Header: Title + Floating Glass Filter Circle Button (iOS Style)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 16, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Explorează',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontFamily: 'Zalando Sans Expanded',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),

                              // Floating Filter Button (52px, Glass Blur 18, iOS Floating Design)
                              _ExploreFloatingCircleButton(
                                size: 52,
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => const SearchFilterSheet(),
                                  );
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold),
                                      color: hasActiveFilters ? context.accentPrimary : context.textPrimary,
                                      size: 22,
                                    ),
                                    if (hasActiveFilters)
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
                            ],
                          ),
                        ),

                        // Search Bar (iOS Stadium Style without border)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: context.bgSurface.withValues(alpha: context.isDarkMode ? 0.85 : 0.95),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Google Sans',
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Caută titlu, gen sau acronim (ex: aot, jjk)...',
                                hintStyle: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 13,
                                  fontFamily: 'Google Sans',
                                ),
                                prefixIcon: Icon(
                                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                                  color: context.textSecondary,
                                  size: 20,
                                ),
                                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _searchController,
                                  builder: (context, val, _) {
                                    if (val.text.isEmpty) return const SizedBox.shrink();
                                    return GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0, left: 6.0),
                                        child: Icon(
                                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                                          color: context.textSecondary,
                                          size: 21,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                        ),

                        // Sub-bar: Info / Active Filters count + iOS Sliding Grid / List Switch
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Result count or filter label
                              searchResultsAsync.maybeWhen(
                                data: (list) => Text(
                                  '${list.length} ${list.length == 1 ? "rezultat" : "rezultate"}',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Google Sans',
                                  ),
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),

                              // Sliding Segmented Toggle (Grid / List)
                              _buildSlidingViewSwitch(context),
                            ],
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

  Widget _buildSlidingViewSwitch(BuildContext context) {
    const double switchWidth = 74.0;
    const double switchHeight = 36.0;
    const double thumbPadding = 3.0;
    const double thumbSize = switchHeight - (thumbPadding * 2); // 30.0

    return Container(
      width: switchWidth,
      height: switchHeight,
      decoration: BoxDecoration(
        color: context.bgSurface.withValues(alpha: context.isDarkMode ? 0.75 : 0.90),
        borderRadius: BorderRadius.circular(switchHeight / 2),
      ),
      child: Stack(
        children: [
          // Sliding Bubble Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: _isGridView ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: thumbPadding),
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: context.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 2 Interactive Icons on top of the track
          Row(
            children: [
              // Grid Icon
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isGridView) setState(() => _isGridView = true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Icon(
                      PhosphorIcons.squaresFour(PhosphorIconsStyle.bold),
                      size: 17,
                      color: _isGridView ? context.onPrimary : context.textSecondary,
                    ),
                  ),
                ),
              ),

              // List Icon
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isGridView) setState(() => _isGridView = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Icon(
                      PhosphorIcons.listBullets(PhosphorIconsStyle.bold),
                      size: 17,
                      color: !_isGridView ? context.onPrimary : context.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatYearSeason(MediaItem item) {
    String seasonStr = '';
    if (item.season != null && item.season!.isNotEmpty) {
      final s = item.season!.toUpperCase();
      if (s == 'WINTER') {
        seasonStr = 'Winter';
      } else if (s == 'SPRING') {
        seasonStr = 'Spring';
      } else if (s == 'SUMMER') {
        seasonStr = 'Summer';
      } else if (s == 'FALL') {
        seasonStr = 'Fall';
      } else {
        seasonStr = item.season![0].toUpperCase() + item.season!.substring(1).toLowerCase();
      }
    }

    if (item.year != null && item.year! > 0) {
      if (seasonStr.isNotEmpty) {
        return '${item.year} $seasonStr';
      }
      return '${item.year}';
    } else if (seasonStr.isNotEmpty) {
      return seasonStr;
    }
    return '';
  }

  Widget _buildExploreListItem(BuildContext context, MediaItem item) {
    final title = item.title.userPreferred;
    final rawScore = item.scores.weightedScore > 0 ? item.scores.weightedScore : item.scores.averageScore;
    final formattedScore = rawScore > 0 ? (rawScore > 10 ? (rawScore / 10).toStringAsFixed(1) : rawScore.toStringAsFixed(1)) : null;
    final yearSeasonText = _formatYearSeason(item);
    final coverUrl = item.coverImage.large.isNotEmpty
        ? item.coverImage.large
        : (item.coverImage.extraLarge ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ExploreCardScaleTile(
        onTap: () {
          Navigator.of(context).push(
            BlurFadePageRoute(
              child: MediaDetailScreen(mediaId: item.id, initialItem: item),
            ),
          );
        },
        child: Container(
          height: 98,
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
            children: [
              // 1. Left Poster with Gradient Blending into Card Body
              SizedBox(
                width: 78,
                height: 98,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(color: context.bgSurfaceHover),
                      errorWidget: (context, url, error) => Container(
                        color: context.bgSurfaceHover,
                        child: Icon(
                          PhosphorIcons.imageBroken(PhosphorIconsStyle.bold),
                          color: context.textMuted,
                        ),
                      ),
                    ),

                    // Horizontal Right Gradient Fade (Blends poster smoothly into card background)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              context.bgSurface.withValues(alpha: 0.05),
                              context.bgSurface.withValues(alpha: 0.70),
                              context.bgSurface,
                            ],
                            stops: const [0.25, 0.60, 0.88, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Right Content Area: Title + Year/Season & Top-Right Score Badge
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Subtitle Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Zalando Sans Expanded',
                                color: context.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            if (yearSeasonText.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                yearSeasonText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: context.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Top-Right Score Badge (Exact match with Grid View badge)
                      if (formattedScore != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                size: 11,
                                color: AppColors.scoreGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedScore,
                                style: const TextStyle(
                                  color: AppColors.scoreGold,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

/// Scale tile interaction for Explore View cards
class _ExploreCardScaleTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ExploreCardScaleTile({
    required this.child,
    required this.onTap,
  });

  @override
  State<_ExploreCardScaleTile> createState() => _ExploreCardScaleTileState();
}

class _ExploreCardScaleTileState extends State<_ExploreCardScaleTile> {
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
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Floating Circle Button in iOS Liquid Glass Style (Matching Home Screen)
class _ExploreFloatingCircleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const _ExploreFloatingCircleButton({
    required this.child,
    required this.onTap,
    this.size = 52,
  });

  @override
  State<_ExploreFloatingCircleButton> createState() => _ExploreFloatingCircleButtonState();
}

class _ExploreFloatingCircleButtonState extends State<_ExploreFloatingCircleButton> {
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

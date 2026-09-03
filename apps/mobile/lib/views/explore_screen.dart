import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/api_providers.dart';
import '../widgets/clean_poster_card.dart';
import '../widgets/floating_circle_button.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/standard_horizontal_card.dart';

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
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchFiltersProvider.notifier).state =
          ref.read(searchFiltersProvider).copyWith(query: query);
    });
  }

  void _resetAllFilters() {
    HapticFeedback.mediumImpact();
    _searchController.clear();
    ref.read(searchFiltersProvider.notifier).state = SearchFilterState();
  }

  void _changeSort(String newSort) {
    HapticFeedback.selectionClick();
    ref.read(searchFiltersProvider.notifier).state =
        ref.read(searchFiltersProvider).copyWith(sortBy: newSort);
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'SCORE_DESC':
        return AppStrings.sortScore;
      case 'POPULARITY_DESC':
        return AppStrings.sortPopularity;
      case 'YEAR_DESC':
        return AppStrings.sortYear;
      case 'TITLE_ASC':
        return AppStrings.sortTitleAz;
      case 'RELEVANCE':
      default:
        return AppStrings.sortRelevance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    final bool hasActiveFilters = filters.genres.isNotEmpty ||
        filters.microTags.isNotEmpty ||
        filters.type != 'ALL' ||
        filters.format != 'ALL';

    final bool isUserFiltering = hasActiveFilters || filters.query.trim().isNotEmpty;

    final topInset = MediaQuery.of(context).padding.top;
    final headerTotalHeight = topInset + 180.0;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Stack(
        children: [
          // 1. Scrollable Results Area
          Positioned.fill(
            child: searchResultsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.only(top: headerTotalHeight / 2),
                  child: const CircularProgressIndicator(color: AppColors.accentPrimary),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, headerTotalHeight + 20, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                          size: 48, color: AppColors.alertCoral),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.exploreLoadError,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$err',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(searchResultsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(AppStrings.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.accentPrimary,
                          foregroundColor: context.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (results) {
                // Honest Empty State when user searches / filters and nothing matches
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, headerTotalHeight + 20, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: context.bgSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                              size: 42,
                              color: context.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            isUserFiltering ? AppStrings.exploreNoResultsTitle : 'Catalog is empty',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Zalando Sans Expanded',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUserFiltering
                                ? AppStrings.exploreNoResultsSubtitle
                                : 'Check your connection to Kurogane server.',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Google Sans',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isUserFiltering) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 17),
                              label: const Text(AppStrings.exploreResetFilters),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.accentPrimary,
                                foregroundColor: context.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                // Show subtle honest banner if user applied specific filters and results are few (<= 5)
                final bool showFewResultsBanner = isUserFiltering && results.length <= 5;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: CustomScrollView(
                    key: ValueKey('explore_scroll_${_isGridView ? "grid" : "list"}'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Top Spacing for frosted header
                      SliverToBoxAdapter(
                        child: SizedBox(height: headerTotalHeight + 8),
                      ),

                      // Optional Honest Information Banner for few matches
                      if (showFewResultsBanner)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.accentPrimary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: context.accentPrimary.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.info(PhosphorIconsStyle.bold),
                                    size: 18,
                                    color: context.accentPrimary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Only ${results.length} ${results.length == 1 ? "result found" : "results found"} for your selection. Try broadening your filters for more titles.',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 12,
                                        fontFamily: 'Google Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Main Results (Grid or List)
                      if (_isGridView)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.63,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return CleanPosterCard.fromMediaItem(
                                  item: results[index],
                                );
                              },
                              childCount: results.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: StandardHorizontalCard.fromMediaItem(
                                    item: results[index],
                                  ),
                                );
                              },
                              childCount: results.length,
                            ),
                          ),
                        ),
                    ],
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
                  color: context.bgPrimary.withValues(alpha: context.isDarkMode ? 0.78 : 0.86),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Header: Title + Floating Glass Filter Circle Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppStrings.exploreTitle,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontFamily: 'Zalando Sans Expanded',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),

                              // Floating Filter Button
                              FloatingCircleButton(
                                size: 48,
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
                                      size: 21,
                                    ),
                                    if (hasActiveFilters)
                                      Positioned(
                                        top: 9,
                                        right: 9,
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
                            ],
                          ),
                        ),

                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: context.bgSurface.withValues(alpha: context.isDarkMode ? 0.85 : 0.95),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13.5,
                                fontFamily: 'Google Sans',
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: AppStrings.exploreSearchHint,
                                hintStyle: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 13,
                                  fontFamily: 'Google Sans',
                                ),
                                prefixIcon: Icon(
                                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                                  color: context.textSecondary,
                                  size: 19,
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
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),

                        // Sub-bar: Dedicated Sort Dropdown (Left) & Grid/List Switch (Right)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left: Dedicated Sort Selector Menu
                              _buildSortSelector(context, filters.sortBy),

                              // Right: Sliding Segmented Toggle (Grid / List)
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

  IconData _getSortPhosphorIcon(String sortBy) {
    switch (sortBy) {
      case 'SCORE_DESC':
        return PhosphorIcons.star(PhosphorIconsStyle.fill);
      case 'POPULARITY_DESC':
        return PhosphorIcons.fire(PhosphorIconsStyle.fill);
      case 'YEAR_DESC':
        return PhosphorIcons.calendar(PhosphorIconsStyle.bold);
      case 'TITLE_ASC':
        return PhosphorIcons.sortAscending(PhosphorIconsStyle.bold);
      case 'RELEVANCE':
      default:
        return PhosphorIcons.target(PhosphorIconsStyle.bold);
    }
  }

  Widget _buildSortSelector(BuildContext context, String currentSort) {
    return PopupMenuButton<String>(
      onSelected: _changeSort,
      color: context.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      itemBuilder: (context) => [
        _buildSortMenuItem(context, 'RELEVANCE', AppStrings.sortRelevance, PhosphorIcons.target(PhosphorIconsStyle.bold), currentSort),
        _buildSortMenuItem(context, 'SCORE_DESC', AppStrings.sortScore, PhosphorIcons.star(PhosphorIconsStyle.fill), currentSort),
        _buildSortMenuItem(context, 'POPULARITY_DESC', AppStrings.sortPopularity, PhosphorIcons.fire(PhosphorIconsStyle.fill), currentSort),
        _buildSortMenuItem(context, 'YEAR_DESC', AppStrings.sortYear, PhosphorIcons.calendar(PhosphorIconsStyle.bold), currentSort),
        _buildSortMenuItem(context, 'TITLE_ASC', AppStrings.sortTitleAz, PhosphorIcons.sortAscending(PhosphorIconsStyle.bold), currentSort),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.bgSurface.withValues(alpha: context.isDarkMode ? 0.80 : 0.92),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSortPhosphorIcon(currentSort),
              size: 15,
              color: context.accentPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              _getSortLabel(currentSort),
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Google Sans',
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 13,
              color: context.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    String currentSort,
  ) {
    final isSelected = value == currentSort;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? context.accentPrimary : context.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? context.accentPrimary : context.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 13,
                fontFamily: 'Google Sans',
              ),
            ),
          ),
          if (isSelected)
            Icon(
              PhosphorIcons.check(PhosphorIconsStyle.bold),
              size: 16,
              color: context.accentPrimary,
            ),
        ],
      ),
    );
  }

  Widget _buildSlidingViewSwitch(BuildContext context) {
    const double switchWidth = 148.0;
    const double switchHeight = 38.0;
    const double thumbPadding = 3.5;
    const double thumbWidth = (switchWidth - (thumbPadding * 2)) / 2;
    const double thumbHeight = switchHeight - (thumbPadding * 2);

    return Container(
      width: switchWidth,
      height: switchHeight,
      decoration: BoxDecoration(
        color: context.bgSurface.withValues(alpha: context.isDarkMode ? 0.80 : 0.92),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Stack(
        children: [
          // Sliding Capsule Indicator without glow/shadow
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: _isGridView ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: thumbPadding),
              child: Container(
                width: thumbWidth,
                height: thumbHeight,
                decoration: BoxDecoration(
                  color: context.accentPrimary,
                  borderRadius: BorderRadius.circular(thumbHeight / 2),
                ),
              ),
            ),
          ),

          // Interactive Tabs (Icon + Text)
          Row(
            children: [
              // Grilă Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (!_isGridView) setState(() => _isGridView = true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.squaresFour(PhosphorIconsStyle.bold),
                          size: 15,
                          color: _isGridView ? context.onPrimary : context.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppStrings.viewGrid,
                          style: TextStyle(
                            color: _isGridView ? context.onPrimary : context.textSecondary,
                            fontWeight: _isGridView ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12.5,
                            fontFamily: 'Google Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // List Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (_isGridView) setState(() => _isGridView = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.listBullets(PhosphorIconsStyle.bold),
                          size: 15,
                          color: !_isGridView ? context.onPrimary : context.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppStrings.viewList,
                          style: TextStyle(
                            color: !_isGridView ? context.onPrimary : context.textSecondary,
                            fontWeight: !_isGridView ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12.5,
                            fontFamily: 'Google Sans',
                          ),
                        ),
                      ],
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
}

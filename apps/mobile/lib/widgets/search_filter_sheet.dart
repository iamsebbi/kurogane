import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../providers/api_providers.dart';

class SearchFilterSheet extends ConsumerStatefulWidget {
  const SearchFilterSheet({super.key});

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _MicroTagItem {
  final String tag;
  final String label;
  final IconData icon;

  const _MicroTagItem({
    required this.tag,
    required this.label,
    required this.icon,
  });
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  late String _selectedType;
  late String _selectedFormat;
  late List<String> _selectedGenres;
  late List<String> _selectedMicroTags;
  late String _sortBy;

  bool _showAllMicroTags = false;

  static const List<String> _mediaTypes = [
    'ALL',
    'ANIME',
    'DONGHUA',
    'AENI',
    'MANGA',
    'MANHWA',
    'WEBTOON',
  ];

  static const List<String> _formats = [
    'ALL',
    'TV',
    'MOVIE',
    'OVA',
    'ONA',
    'SPECIAL',
  ];

  static const List<String> _genresList = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Sci-Fi',
    'Mystery',
    'Horror',
    'Romance',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
    'Mecha',
    'Psychological',
  ];

  static final List<_MicroTagItem> _allMicroTags = [
    _MicroTagItem(tag: 'Overpowered MC', label: 'Overpowered MC', icon: PhosphorIcons.lightning(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Isekai', label: 'Isekai', icon: PhosphorIcons.spiral(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Anti-Hero', label: 'Anti-Hero', icon: PhosphorIcons.sword(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Xianxia', label: 'Xianxia', icon: PhosphorIcons.yinYang(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Cyberpunk', label: 'Cyberpunk', icon: PhosphorIcons.robot(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Post-Apocalyptic', label: 'Post-Apocaliptic', icon: PhosphorIcons.skull(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Time Travel', label: 'Time Travel', icon: PhosphorIcons.hourglass(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'High Fantasy', label: 'High Fantasy', icon: PhosphorIcons.castleTurret(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Revenge', label: 'Revenge', icon: PhosphorIcons.fire(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'System', label: 'System', icon: PhosphorIcons.cpu(PhosphorIconsStyle.bold)),
    // Progressive disclosure extended list
    _MicroTagItem(tag: 'Female Protagonist', label: 'Female Lead', icon: PhosphorIcons.user(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'School Life', label: 'School Life', icon: PhosphorIcons.graduationCap(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Virtual Reality', label: 'VR & Gaming', icon: PhosphorIcons.gameController(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Murim', label: 'Murim', icon: PhosphorIcons.shieldChevron(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Regression', label: 'Regression', icon: PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Mecha', label: 'Mecha', icon: PhosphorIcons.gear(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Psychological', label: 'Psychological', icon: PhosphorIcons.brain(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Survival', label: 'Survival', icon: PhosphorIcons.shield(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Romance', label: 'Romance', icon: PhosphorIcons.heart(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Harem', label: 'Harem', icon: PhosphorIcons.usersThree(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Slice of Life', label: 'Slice of Life', icon: PhosphorIcons.coffee(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Sports', label: 'Sports', icon: PhosphorIcons.trophy(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Music', label: 'Music', icon: PhosphorIcons.musicNotes(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Horror', label: 'Horror', icon: PhosphorIcons.ghost(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Military', label: 'Military', icon: PhosphorIcons.target(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Historical', label: 'Historical', icon: PhosphorIcons.scroll(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Mythology', label: 'Mythology', icon: PhosphorIcons.sparkle(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Martial Arts', label: 'Martial Arts', icon: PhosphorIcons.handFist(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Detective', label: 'Detective', icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Super Power', label: 'Super Power', icon: PhosphorIcons.star(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Space', label: 'Space', icon: PhosphorIcons.planet(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Gore', label: 'Gore', icon: PhosphorIcons.drop(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Vampire', label: 'Vampire', icon: PhosphorIcons.moon(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Demons', label: 'Demons', icon: PhosphorIcons.maskHappy(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Magic', label: 'Magic', icon: PhosphorIcons.magicWand(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Tower', label: 'Tower', icon: PhosphorIcons.buildings(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Solo Player', label: 'Solo Player', icon: PhosphorIcons.userFocus(PhosphorIconsStyle.bold)),
  ];

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(searchFiltersProvider);
    _selectedType = currentFilters.type;
    _selectedFormat = currentFilters.format;
    _selectedGenres = List.from(currentFilters.genres);
    _selectedMicroTags = List.from(currentFilters.microTags);
    _sortBy = currentFilters.sortBy;
  }

  void _resetFilters() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedType = 'ALL';
      _selectedFormat = 'ALL';
      _selectedGenres.clear();
      _selectedMicroTags.clear();
      _sortBy = 'RELEVANCE';
    });
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();
    ref.read(searchFiltersProvider.notifier).state = SearchFilterState(
      query: ref.read(searchFiltersProvider).query,
      type: _selectedType,
      format: _selectedFormat,
      genres: List.from(_selectedGenres),
      microTags: List.from(_selectedMicroTags),
      sortBy: _sortBy,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final visibleMicroTags = _showAllMicroTags ? _allMicroTags : _allMicroTags.take(10).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Fixed Header: Drag Handle & Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              children: [
                // Full Rounded Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: context.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header Title
                Row(
                  children: [
                    Text(
                      'Filtre Avansate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Zalando Sans Expanded',
                        color: context.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 2. Scrollable Body (Clean Whitespace Hierarchy, Zero Shadows/Glows)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: Tip Media (Segmented Control - Full Rounded Stadium) ---
                  _buildSectionTitle(context, 'Tip Media'),
                  const SizedBox(height: 8),
                  _buildSegmentedControl(
                    context: context,
                    options: _mediaTypes,
                    selectedOption: _selectedType,
                    onSelected: (val) => setState(() => _selectedType = val),
                  ),

                  _buildSectionSpacing(),

                  // --- SECTION 2: Format (Segmented Control - Full Rounded Stadium) ---
                  _buildSectionTitle(context, 'Format'),
                  const SizedBox(height: 8),
                  _buildSegmentedControl(
                    context: context,
                    options: _formats,
                    selectedOption: _selectedFormat,
                    onSelected: (val) => setState(() => _selectedFormat = val),
                  ),

                  _buildSectionSpacing(),

                  // --- SECTION 3: Genuri (Full Rounded Multi-Select Pills, Solid Flat Colors) ---
                  _buildSectionTitle(context, 'Genuri'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genresList.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return _buildMultiSelectPill(
                        context: context,
                        label: genre,
                        isSelected: isSelected,
                        activeColor: context.accentPrimary,
                        activeTextColor: context.onPrimary,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedGenres.remove(genre);
                            } else {
                              _selectedGenres.add(genre);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  _buildSectionSpacing(),

                  // --- SECTION 4: Micro-Tag-uri & Trope-uri (Full Rounded, Flat High Contrast) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(context, 'Micro-Tag-uri & Trope-uri'),
                      if (_selectedMicroTags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.brandHighlight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_selectedMicroTags.length} selectate',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleMicroTags.map((item) {
                      final isSelected = _selectedMicroTags.contains(item.tag);
                      return _buildMultiSelectPill(
                        context: context,
                        label: item.label,
                        icon: item.icon,
                        isSelected: isSelected,
                        activeColor: AppColors.brandHighlight,
                        activeTextColor: Colors.white,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMicroTags.remove(item.tag);
                            } else {
                              _selectedMicroTags.add(item.tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  // Progressive Disclosure Toggle Button (+ Vezi toate tag-urile)
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllMicroTags = !_showAllMicroTags;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showAllMicroTags
                                ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                                : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                            size: 15,
                            color: context.isDarkMode ? context.accentPrimary : AppColors.brandHighlight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showAllMicroTags
                                ? 'Arată mai puține tag-uri'
                                : '+ Vezi toate tag-urile (${_allMicroTags.length - 10} în plus)',
                            style: TextStyle(
                              color: context.isDarkMode ? context.accentPrimary : AppColors.brandHighlight,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 3. Sticky Bottom Footer: Reset Circle Button (Left) + Stadium "Aplică Filtrele" (Right)
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, (bottomInset > 0 ? bottomInset : bottomPadding) + 12),
            color: context.bgSurface,
            child: Row(
              children: [
                // Intuitive Circle Reset Button with Phosphor Icon
                GestureDetector(
                  onTap: _resetFilters,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.bgPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.bold),
                      size: 21,
                      color: context.isDarkMode ? AppColors.alertCoral : AppColors.lightAlertCoral,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Expanded "Aplică Filtrele" Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accentPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        'Aplică Filtrele',
                        style: TextStyle(
                          color: context.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
        fontSize: 14,
        fontFamily: 'Google Sans',
      ),
    );
  }

  Widget _buildSectionSpacing() {
    return const SizedBox(height: 22);
  }

  Widget _buildSegmentedControl({
    required BuildContext context,
    required List<String> options,
    required String selectedOption,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: options.map((opt) {
            final isSelected = opt == selectedOption;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(opt);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                decoration: BoxDecoration(
                  color: isSelected ? context.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  opt == 'ALL' ? 'Toate' : opt,
                  style: TextStyle(
                    color: isSelected ? context.onPrimary : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMultiSelectPill({
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : context.isDarkMode
                  ? context.bgPrimary
                  : context.bgPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeTextColor : context.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeTextColor : context.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
                fontFamily: 'Google Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

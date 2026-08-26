import 'package:flutter/material.dart';
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
  late double _minScore;
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
    // Progressive disclosure extended list (37 total)
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
    _MicroTagItem(tag: 'Vampire', label: 'Vampire', icon: PhosphorIcons.drop(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Demon', label: 'Demon', icon: PhosphorIcons.maskHappy(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Magic', label: 'Magic', icon: PhosphorIcons.magicWand(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Space', label: 'Space', icon: PhosphorIcons.planet(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Detective', label: 'Detective', icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Comedy', label: 'Comedy', icon: PhosphorIcons.smiley(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Dark Fantasy', label: 'Dark Fantasy', icon: PhosphorIcons.moon(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Dungeon', label: 'Dungeon', icon: PhosphorIcons.door(PhosphorIconsStyle.bold)),
    _MicroTagItem(tag: 'Necromancer', label: 'Necromancer', icon: PhosphorIcons.bone(PhosphorIconsStyle.bold)),
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
    _minScore = currentFilters.minScore ?? 0.0;
    _sortBy = currentFilters.sortBy;
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'ALL';
      _selectedFormat = 'ALL';
      _selectedGenres.clear();
      _selectedMicroTags.clear();
      _minScore = 0.0;
      _sortBy = 'RELEVANCE';
    });
  }

  void _applyFilters() {
    ref.read(searchFiltersProvider.notifier).state = ref.read(searchFiltersProvider).copyWith(
          type: _selectedType,
          format: _selectedFormat,
          genres: _selectedGenres,
          microTags: _selectedMicroTags,
          minScore: _minScore > 0 ? _minScore : null,
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
    final scoreColor = context.isDarkMode ? AppColors.scoreGold : AppColors.lightScoreGold;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90,
      ),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.45 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Fixed Header: Accessible Drag Handle + Title & Reset Action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
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

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: _resetFilters,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Resetează',
                          style: TextStyle(
                            color: context.isDarkMode ? AppColors.alertCoral : AppColors.lightAlertCoral,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Google Sans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 2. Scrollable Body (Clean Whitespace Hierarchy, Zero Borders, High Contrast)
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

                  // --- SECTION 3: Scor Minim Slider with Explicit Scale Labels ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(context, 'Scor Minim'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: scoreColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _minScore > 0 ? '${_minScore.toStringAsFixed(1)} / 10' : 'Oricare',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                                fontSize: 12,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scoreColor,
                      inactiveTrackColor: context.bgPrimary,
                      thumbColor: scoreColor,
                      overlayColor: scoreColor.withValues(alpha: 0.2),
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                    ),
                    child: Slider(
                      value: _minScore,
                      min: 0.0,
                      max: 9.5,
                      divisions: 19,
                      onChanged: (val) => setState(() => _minScore = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0.0 (Oricare)',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '5.0',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '9.5 (Capodopere)',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionSpacing(),

                  // --- SECTION 4: Genuri (Full Rounded Multi-Select Pills, Solid High Contrast) ---
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

                  // --- SECTION 5: Micro-Tag-uri & Trope-uri (Full Rounded, Coral Accent, High Contrast) ---
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

          // 3. Sticky Bottom Footer: Full Rounded Stadium "Aplică Filtrele"
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, (bottomInset > 0 ? bottomInset : bottomPadding) + 12),
            color: context.bgSurface,
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

  /// Full-Rounded (Stadium/Capsule) Connected Segmented Control (Zero Borders)
  Widget _buildSegmentedControl({
    required BuildContext context,
    required List<String> options,
    required String selectedOption,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = selectedOption == opt;

          return GestureDetector(
            onTap: () => onSelected(opt),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? context.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: isSelected ? context.onPrimary : context.textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'Google Sans',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Full-Rounded (Stadium/Pill) Multi-Select Pill with Solid High-Contrast Selection
  Widget _buildMultiSelectPill({
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isSelected,
    Color? activeColor,
    Color? activeTextColor,
    required VoidCallback onTap,
  }) {
    final effectiveBgColor = isSelected
        ? (activeColor ?? context.accentPrimary)
        : context.bgPrimary;
    final effectiveFgColor = isSelected
        ? (activeTextColor ?? context.onPrimary)
        : context.textPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13.5,
                color: effectiveFgColor,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: effectiveFgColor,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontFamily: 'Google Sans',
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4.5),
              Icon(
                PhosphorIcons.check(PhosphorIconsStyle.bold),
                size: 11.5,
                color: effectiveFgColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

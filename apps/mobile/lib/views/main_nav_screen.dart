import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/api_providers.dart';
import '../widgets/border_beam.dart';
import '../widgets/clean_poster_card.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'watchlist_screen.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  int _displayedScreenIndex = 0;

  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  late final AnimationController _borderBeamController;
  late final AnimationController _tabTransitionController;

  final List<GlobalKey> _screenBoundaryKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  ui.Image? _capturedSnapshot;
  DateTime? _lastBackPressedTime;

  @override
  void initState() {
    super.initState();
    _borderBeamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _borderBeamController.dispose();
    _tabTransitionController.dispose();
    _capturedSnapshot?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<Widget> get _screens => const [
        HomeScreen(),
        ExploreScreen(),
        WatchlistScreen(),
      ];

  List<_NavItemData> get _navItems => [
        _NavItemData(
          icon: PhosphorIcons.house(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
          label: AppStrings.navHome,
        ),
        _NavItemData(
          icon: PhosphorIcons.compass(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.compass(PhosphorIconsStyle.fill),
          label: AppStrings.navExplore,
        ),
        _NavItemData(
          icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
          label: AppStrings.navWatchlist,
        ),
      ];

  Future<void> _onTabTapped(int index) async {
    if (_selectedTabIndex == index) return;

    if (ref.read(mainNavTabProvider) != index) {
      ref.read(mainNavTabProvider.notifier).state = index;
    }

    final prevScreenIndex = _displayedScreenIndex;

    // 1. Schimbă instant index-ul bulei din bottom bar sincron pe cadrul de touch (fără delay async)
    setState(() {
      _selectedTabIndex = index;
    });

    // 2. Capturează snapshot-ul ecranului anterior pe GPU
    ui.Image? snapshot;
    try {
      final boundary = _screenBoundaryKeys[prevScreenIndex].currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null && boundary.hasSize) {
        snapshot = await boundary.toImage(pixelRatio: 1.0);
      }
    } catch (_) {
      snapshot = null;
    }

    if (!mounted) {
      snapshot?.dispose();
      return;
    }

    _capturedSnapshot?.dispose();
    setState(() {
      _capturedSnapshot = snapshot;
      _displayedScreenIndex = index;
    });

    _tabTransitionController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _capturedSnapshot?.dispose();
          _capturedSnapshot = null;
        });
      }
    });
  }

  Widget _buildScreenStack(BuildContext context, int activeIndex) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Ecrane izolate în RepaintBoundary pentru a preveni rerastrarea în timpul tranziției
        for (int i = 0; i < _screens.length; i++)
          RepaintBoundary(
            key: _screenBoundaryKeys[i],
            child: Offstage(
              offstage: i != activeIndex,
              child: TickerMode(
                enabled: i == activeIndex,
                child: i == activeIndex
                    ? FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _tabTransitionController,
                          curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.965, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _tabTransitionController,
                              curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
                            ),
                          ),
                          child: _screens[i],
                        ),
                      )
                    : _screens[i],
              ),
            ),
          ),

        // 2. Snapshot-ul ecranului anterior randat ca imagine statică cu Blur-Fade
        if (_capturedSnapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _tabTransitionController,
                builder: (context, _) {
                  final t = _tabTransitionController.value;
                  // Snapshot-ul face fade-out în prima jumătate (0.0 -> 0.45)
                  final fadeProgress = (t / 0.45).clamp(0.0, 1.0);
                  final opacity = 1.0 - Curves.easeInCubic.transform(fadeProgress);

                  // Blur-ul crește de la 0 la 12px DOAR pe snapshot-ul static
                  final blurSigma = Curves.easeOutQuad.transform(fadeProgress) * 12.0;

                  if (opacity <= 0.001) return const SizedBox.shrink();

                  Widget imageWidget = RawImage(
                    image: _capturedSnapshot,
                    fit: BoxFit.cover,
                  );

                  if (blurSigma > 0.3) {
                    imageWidget = ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                      child: imageWidget,
                    );
                  }

                  return Opacity(
                    opacity: opacity,
                    child: imageWidget,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) {
        ref.read(quickSearchQueryProvider.notifier).state = value;
      }
    });
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearchActive = !_isSearchActive;
    });

    if (_isSearchActive) {
      _borderBeamController.forward(from: 0.0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _borderBeamController.reset();
      _searchFocusNode.unfocus();
      _debounceTimer?.cancel();
      _searchController.clear();
      ref.read(quickSearchQueryProvider.notifier).state = '';
    }
  }

  static final ui.ImageFilter _glassFilter = ui.ImageFilter.compose(
    outer: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    inner: const ColorFilter.matrix(<double>[
      1.6296, -0.5720, -0.0576, 0, 0,
     -0.1704,  1.2280, -0.0576, 0, 0,
     -0.1704, -0.5720,  1.7424, 0, 0,
      0,       0,       0,      1, 0,
    ]),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainNavTabProvider, (prev, next) {
      if (next != _selectedTabIndex) {
        _onTabTapped(next);
      }
    });

    final activeNavIndex = _selectedTabIndex.clamp(0, _navItems.length - 1);
    final displayedScreenIndex = _displayedScreenIndex.clamp(0, _screens.length - 1);

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final barBottom = bottomInset > 0 ? bottomInset + 10.0 : bottomPadding + 12.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Dacă bara de Quick Search este activă, o închide la apăsarea back
        if (_isSearchActive) {
          _toggleSearch();
          return;
        }

        // 2. Dacă suntem pe alt tab (Explorare sau Watchlist), back ne duce pe tab-ul Acasă (0)
        if (_selectedTabIndex != 0) {
          _onTabTapped(0);
          return;
        }

        // 3. Pe tab-ul Acasă: dublu back pentru a ieși din aplicație
        final now = DateTime.now();
        if (_lastBackPressedTime == null ||
            now.difference(_lastBackPressedTime!) > const Duration(seconds: 2)) {
          _lastBackPressedTime = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Apasă din nou pentru a ieși din aplicație',
                style: TextStyle(
                  color: context.textPrimary,
                  fontFamily: 'Google Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.bgSurface.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.only(
                bottom: barBottom + 64,
                left: 24,
                right: 24,
              ),
            ),
          );
          return;
        }

        // Dublu back confirmat (< 2 secunde) -> Ieșire din aplicație
        await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          children: [
            // 1. Conținutul de bază al paginii (Snapshot Blur-Fade + RepaintBoundary)
            Positioned.fill(
              child: _buildScreenStack(context, displayedScreenIndex),
            ),

            // 2. Overlay-ul ecranului de Quick Search (Animat fade-in deasupra paginii)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isSearchActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  ignoring: !_isSearchActive,
                  child: _buildQuickSearchOverlay(context, barBottom),
                ),
              ),
            ),

            // 3. Floating Bottom Bar (Morph între tab-uri și Search Input) + Floating Action Button (Lupă / X)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              bottom: barBottom,
              child: Row(
                children: [
                  // Bara transformată prin morph cu efect de BorderBeam
                  Expanded(
                    child: _buildFloatingMorphBar(context, activeNavIndex),
                  ),

                  const SizedBox(width: 12),

                  // Butonul circular de control (Lupă <-> X)
                  _buildFloatingSearchButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMorphBar(BuildContext context, int activeIndex) {
    const double barHeight = 56.0;
    const double outerRadius = barHeight / 2; // 28.0

    return BorderBeam(
      animation: _borderBeamController,
      isActive: _isSearchActive,
      borderRadius: outerRadius,
      borderWidth: 1.2,
      glowBlurRadius: 4.0,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.45 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outerRadius),
          child: BackdropFilter(
            filter: _glassFilter,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: context.bgSurface.withValues(alpha: context.isDarkMode ? 0.75 : 0.88),
                borderRadius: BorderRadius.circular(outerRadius),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: _isSearchActive
                    ? _buildSearchInput(context)
                    : _buildNavTabs(context, activeIndex),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('search_input_active'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
              color: context.textMuted,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchChanged,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: context.textPrimary,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.quickSearchPlaceholder,
                  hintStyle: TextStyle(
                    color: context.textMuted,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
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
                    padding: const EdgeInsets.only(left: 6.0, right: 2.0, top: 4.0, bottom: 4.0),
                    child: Icon(
                      PhosphorIcons.x(PhosphorIconsStyle.bold),
                      color: context.textSecondary,
                      size: 21,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabs(BuildContext context, int activeIndex) {
    const double barHeight = 56.0;
    const double barPadding = 4.0;
    const double outerRadius = barHeight / 2; // 28.0
    const double innerRadius = outerRadius - barPadding; // 24.0

    return KeyedSubtree(
      key: const ValueKey('nav_tabs_active'),
      child: Padding(
        padding: const EdgeInsets.all(barPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tabWidth = constraints.maxWidth / _navItems.length;

            return Stack(
              children: [
                // 1. Bula Activă Glisantă (Translucidă glassmorphic cu glisare fluidă)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 380),
                  curve: const Cubic(0.25, 1.0, 0.35, 1.0),
                  left: activeIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(innerRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDarkMode ? 0.18 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Rândul cu iconițe și etichete
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isSelected = activeIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTabTapped(index),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? context.textPrimary
                                : context.textSecondary.withValues(alpha: 0.7),
                            letterSpacing: isSelected ? 0.2 : 0,
                            height: 1.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<Color?>(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                tween: ColorTween(
                                  begin: context.textSecondary.withValues(alpha: 0.7),
                                  end: isSelected
                                      ? context.textPrimary
                                      : context.textSecondary.withValues(alpha: 0.7),
                                ),
                                builder: (context, color, _) => Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  size: isSelected ? 24 : 23,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 3.5),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingSearchButton() {
    return _FloatingSearchCircle(
      size: 56,
      isSearchActive: _isSearchActive,
      onTap: _toggleSearch,
    );
  }

  Widget _buildQuickSearchOverlay(BuildContext context, double barBottom) {
    final query = ref.watch(quickSearchQueryProvider).trim();
    final resultsAsync = ref.watch(quickSearchResultsProvider);

    return Container(
      color: context.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: query.isEmpty
            ? Align(
                alignment: const Alignment(0, -0.45),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
                        size: 54,
                        color: context.textMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.quickSearchEmptyTitle,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.quickSearchEmptySubtitle,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : resultsAsync.when(
                loading: () => Align(
                  alignment: const Alignment(0, -0.45),
                  child: CircularProgressIndicator(
                    color: context.accentPrimary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (err, _) => Align(
                  alignment: const Alignment(0, -0.45),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      '${AppStrings.errorPrefix}: $err',
                      style: const TextStyle(color: AppColors.alertCoral, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return Align(
                      alignment: const Alignment(0, -0.45),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                              size: 46,
                              color: context.textMuted.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${AppStrings.quickSearchNoResults} "$query"',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.quickSearchTryAgain,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, barBottom + 70),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.63,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return CleanPosterCard.fromMediaItem(
                        item: results[index],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _FloatingSearchCircle extends StatefulWidget {
  final double size;
  final bool isSearchActive;
  final VoidCallback onTap;

  const _FloatingSearchCircle({
    required this.size,
    required this.isSearchActive,
    required this.onTap,
  });

  @override
  State<_FloatingSearchCircle> createState() => _FloatingSearchCircleState();
}

class _FloatingSearchCircleState extends State<_FloatingSearchCircle> {
  bool _isPressed = false;

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
        scale: _isPressed ? 1.14 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: ClipOval(
          child: BackdropFilter(
            filter: _MainNavScreenState._glassFilter,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim.drive(Tween<double>(begin: 0.75, end: 1.0)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  widget.isSearchActive
                      ? PhosphorIcons.x(PhosphorIconsStyle.bold)
                      : PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                  key: ValueKey(widget.isSearchActive),
                  color: widget.isSearchActive
                      ? context.textPrimary
                      : (_isPressed ? context.textSecondary : context.textPrimary),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

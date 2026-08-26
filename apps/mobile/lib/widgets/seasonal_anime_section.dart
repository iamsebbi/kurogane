import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import 'seasonal_anime_card.dart';

class SeasonalAnimeSection extends StatefulWidget {
  final List<MediaItem> items;

  const SeasonalAnimeSection({
    super.key,
    required this.items,
  });

  @override
  State<SeasonalAnimeSection> createState() => _SeasonalAnimeSectionState();
}

class _SeasonalAnimeSectionState extends State<SeasonalAnimeSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Calculează dinamic titlul și icon-ul sezonului curent în limba română (fără "Anime •")
  Map<String, dynamic> _getDynamicSeasonInfo(MediaItem? sampleItem) {
    String seasonName = 'Vară';
    IconData seasonIcon = PhosphorIcons.sun(PhosphorIconsStyle.bold);
    int year = DateTime.now().year;

    if (sampleItem?.season != null && sampleItem!.season!.isNotEmpty) {
      final s = sampleItem.season!.toUpperCase();
      if (sampleItem.year != null && sampleItem.year! > 2000) {
        year = sampleItem.year!;
      }
      if (s.contains('WINTER') || s.contains('IARN')) {
        seasonName = 'Iarnă';
        seasonIcon = PhosphorIcons.snowflake(PhosphorIconsStyle.bold);
      } else if (s.contains('SPRING') || s.contains('PRIM')) {
        seasonName = 'Primăvară';
        seasonIcon = PhosphorIcons.flower(PhosphorIconsStyle.bold);
      } else if (s.contains('SUMMER') || s.contains('VAR')) {
        seasonName = 'Vară';
        seasonIcon = PhosphorIcons.sun(PhosphorIconsStyle.bold);
      } else if (s.contains('FALL') || s.contains('AUTUMN') || s.contains('TOAM')) {
        seasonName = 'Toamnă';
        seasonIcon = PhosphorIcons.leaf(PhosphorIconsStyle.bold);
      }
    } else {
      final month = DateTime.now().month;
      if (month == 12 || month == 1 || month == 2) {
        seasonName = 'Iarnă';
        seasonIcon = PhosphorIcons.snowflake(PhosphorIconsStyle.bold);
      } else if (month >= 3 && month <= 5) {
        seasonName = 'Primăvară';
        seasonIcon = PhosphorIcons.flower(PhosphorIconsStyle.bold);
      } else if (month >= 6 && month <= 8) {
        seasonName = 'Vară';
        seasonIcon = PhosphorIcons.sun(PhosphorIconsStyle.bold);
      } else {
        seasonName = 'Toamnă';
        seasonIcon = PhosphorIcons.leaf(PhosphorIconsStyle.bold);
      }
    }

    return {
      'title': 'Sezonul de $seasonName $year',
      'icon': seasonIcon,
    };
  }

  /// Indicator dinamic cu puncte scalate (identic cu stilul din Hero)
  Widget _buildScalingDotsIndicator(BuildContext context, int totalCount, int currentIndex) {
    if (totalCount <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final distance = (index - currentIndex).abs();

        double dotSize;
        double opacity;
        if (distance == 0) {
          dotSize = 7.0;
          opacity = 1.0;
        } else if (distance == 1) {
          dotSize = 5.0;
          opacity = 0.65;
        } else if (distance == 2) {
          dotSize = 3.5;
          opacity = 0.35;
        } else {
          dotSize = 0.0;
          opacity = 0.0;
        }

        if (dotSize == 0.0) return const SizedBox.shrink();

        final activeColor = context.textPrimary;
        final inactiveColor = context.isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;

        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: distance == 0 ? activeColor : inactiveColor.withValues(alpha: opacity),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final seasonInfo = _getDynamicSeasonInfo(widget.items.first);
    final title = seasonInfo['title'] as String;
    final icon = seasonInfo['icon'] as IconData;

    const cardHeight = 195.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header-ul Secțiunii (Fără cuvântul "Anime •" și fără butoane ‹ ›)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: context.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Zalando Sans Expanded',
                    color: context.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. PageView cu card full-width pe pagină
        SizedBox(
          height: cardHeight + 10,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SeasonalAnimeCard(
                  item: item,
                  height: cardHeight,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 3. Pager Dots Indicator (Sub carduri, centrat, ca în Hero)
        Center(
          child: _buildScalingDotsIndicator(
            context,
            widget.items.length,
            _currentIndex,
          ),
        ),
      ],
    );
  }
}

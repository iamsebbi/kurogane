import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/media_item.dart';
import 'seasonal_anime_card.dart';

/// Secțiunea "Popular Anime Trailers" ce înlocuiește vechiul bloc sezonier.
///
/// Afișează un PageView cu carduri orizontale de trailere anime (16:9),
/// oferind acces direct la vizionarea trailerului pe YouTube/browser și puncte scalate de paginare.
class PopularTrailersSection extends StatefulWidget {
  final List<MediaItem> items;
  final String title;

  const PopularTrailersSection({
    super.key,
    required this.items,
    this.title = AppStrings.homePopularTrailers,
  });

  @override
  State<PopularTrailersSection> createState() => _PopularTrailersSectionState();
}

class _PopularTrailersSectionState extends State<PopularTrailersSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          dotSize = 4.0;
          opacity = 0.40;
        } else {
          dotSize = 3.0;
          opacity = 0.20;
        }

        final activeColor = context.accentPrimary;
        final inactiveColor = context.textSecondary;

        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
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

    const cardHeight = 185.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header Secțiune "Popular Anime Trailers"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.playCircle(PhosphorIconsStyle.bold),
                size: 20,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Zalando Sans Expanded',
                    color: context.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: context.bgSurfaceHover,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.borderSubtle.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'HD',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. PageView cu carduri 16:9 (next card peeking at 90% viewport fraction)
        SizedBox(
          height: cardHeight + 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimeTrailerCard(
                  item: item,
                  height: cardHeight,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 3. Pager Dots Indicator (Sub carduri, centrat)
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

/// Alias retrocompatibil
typedef SeasonalAnimeSection = PopularTrailersSection;

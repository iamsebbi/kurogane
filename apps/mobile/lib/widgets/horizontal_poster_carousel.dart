import 'package:flutter/material.dart';
import '../models/media_item.dart';
import 'clean_poster_card.dart';

/// Carusel orizontal standardizat de postere anime (CleanPosterCard)
///
/// Folosit în HomeScreen (Recomandări, În tendințe, În curând, Capodopere)
/// și în MediaDetailScreen (Recomandări Similare).
class HorizontalPosterCarousel extends StatelessWidget {
  final List<MediaItem> items;
  final double width;
  final double height;
  final double containerHeight;
  final double itemSpacing;
  final EdgeInsetsGeometry padding;
  final void Function(MediaItem item)? onItemTap;

  const HorizontalPosterCarousel({
    super.key,
    required this.items,
    this.width = 140,
    this.height = 200,
    this.containerHeight = 240,
    this.itemSpacing = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: containerHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : itemSpacing),
            child: CleanPosterCard.fromMediaItem(
              item: item,
              width: width,
              height: height,
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
            ),
          );
        },
      ),
    );
  }
}

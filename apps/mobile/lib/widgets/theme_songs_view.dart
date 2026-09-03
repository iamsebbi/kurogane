import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';

class ThemeSongsView extends StatelessWidget {
  final List<MediaThemeSong> themes;

  const ThemeSongsView({
    super.key,
    required this.themes,
  });

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.musicNotes(PhosphorIconsStyle.bold),
                size: 32,
                color: context.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                'Theme songs are not available for this title.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final openings = themes.where((t) => t.type.toUpperCase() == 'OP').toList();
    final endings = themes.where((t) => t.type.toUpperCase() == 'ED').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Opening Themes
        if (openings.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                PhosphorIcons.playCircle(PhosphorIconsStyle.bold),
                size: 18,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Opening Themes',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: openings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final song = openings[index];
              return _buildSongCard(context, song, index + 1);
            },
          ),
          const SizedBox(height: 28),
        ],

        // 2. Ending Themes
        if (endings.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                PhosphorIcons.stopCircle(PhosphorIconsStyle.bold),
                size: 18,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ending Themes',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: endings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final song = endings[index];
              return _buildSongCard(context, song, index + 1);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSongCard(BuildContext context, MediaThemeSong song, int number) {
    final badgeLabel = song.episodes != null && song.episodes!.isNotEmpty
        ? song.episodes!
        : '${song.type}$number';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Badge tip piesă
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.accentPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: context.accentPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Titlu și Artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (song.artists.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    song.artists.join(', '),
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),
          Icon(
            PhosphorIcons.musicNote(PhosphorIconsStyle.bold),
            size: 16,
            color: context.textMuted,
          ),
        ],
      ),
    );
  }
}

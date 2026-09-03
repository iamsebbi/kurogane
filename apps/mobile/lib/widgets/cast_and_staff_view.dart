import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';

class CastAndStaffView extends StatelessWidget {
  final List<MediaCharacter> characters;
  final List<MediaStaff> staff;

  const CastAndStaffView({
    super.key,
    required this.characters,
    required this.staff,
  });

  String _formatRole(String raw) {
    switch (raw.toUpperCase()) {
      case 'MAIN':
        return 'Main';
      case 'SUPPORTING':
        return 'Supporting';
      default:
        return raw;
    }
  }

  Widget _buildAvatar(
    BuildContext context, {
    required String? imageUrl,
    required bool isPerson,
    double width = 40,
    double height = 48,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: (imageUrl != null && imageUrl.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: context.bgSurfaceHover),
                errorWidget: (_, __, ___) => Container(
                  color: context.bgSurfaceHover,
                  child: Icon(
                    isPerson
                        ? PhosphorIcons.user(PhosphorIconsStyle.bold)
                        : PhosphorIcons.userCircle(PhosphorIconsStyle.bold),
                    color: context.textMuted,
                    size: 16,
                  ),
                ),
              )
            : Container(
                color: context.bgSurfaceHover,
                child: Icon(
                  isPerson
                      ? PhosphorIcons.user(PhosphorIconsStyle.bold)
                      : PhosphorIcons.userCircle(PhosphorIconsStyle.bold),
                  color: context.textMuted,
                  size: 16,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (characters.isEmpty && staff.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Cast and staff information is not available.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Distribuție Personaje & Actori de Voce (Listă Orizontală cu Scroll)
        if (characters.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                PhosphorIcons.users(PhosphorIconsStyle.bold),
                size: 18,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Characters & Voice Actors',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${characters.length} characters',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Listă orizontală: Personaj sus, Voice Actor jos
          SizedBox(
            height: 162,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: characters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final char = characters[index];
                final va = char.voiceActor;

                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: context.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rând 1: Personaj (SUS)
                      Row(
                        children: [
                          _buildAvatar(
                            context,
                            imageUrl: char.image,
                            isPerson: false,
                            width: 50,
                            height: 62,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  char.name,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatRole(char.role),
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Linie fină de separare între Personaj și VA
                      Container(
                        height: 1,
                        color: context.borderSubtle.withValues(alpha: 0.35),
                      ),

                      // Rând 2: Voice Actor (JOS)
                      if (va != null)
                        Row(
                          children: [
                            _buildAvatar(
                              context,
                              imageUrl: va.image,
                              isPerson: true,
                              width: 50,
                              height: 62,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    va.name,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    va.language ?? 'Japanese',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 62,
                              decoration: BoxDecoration(
                                color: context.bgSurfaceHover,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                PhosphorIcons.microphoneSlash(PhosphorIconsStyle.bold),
                                size: 18,
                                color: context.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'No voice actor',
                              style: TextStyle(
                                color: context.textMuted,
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],

        // 2. Echipa de Producție & Creatori (Container continuu vertical)
        if (staff.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                PhosphorIcons.filmReel(PhosphorIconsStyle.bold),
                size: 18,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Production Staff',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${staff.length} members',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staff.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: context.borderSubtle.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, index) {
                  final s = staff[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Avatar Staff (40 x 48)
                        _buildAvatar(
                          context,
                          imageUrl: s.image,
                          isPerson: true,
                          width: 40,
                          height: 48,
                        ),
                        const SizedBox(width: 12),

                        // Nume & Rol
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.name,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                s.role,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

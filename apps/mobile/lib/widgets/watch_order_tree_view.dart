import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/watch_order.dart';
import '../views/media_detail_screen.dart';
import 'pill_badge.dart';

class WatchOrderTreeView extends StatefulWidget {
  final WatchOrderGuide guide;
  final String? parentCoverImage;
  final Color? dominantAccent;

  const WatchOrderTreeView({
    super.key,
    required this.guide,
    this.parentCoverImage,
    this.dominantAccent,
  });

  @override
  State<WatchOrderTreeView> createState() => _WatchOrderTreeViewState();
}

class _WatchOrderTreeViewState extends State<WatchOrderTreeView> {
  String _selectedMode = 'RECOMMENDED';

  @override
  Widget build(BuildContext context) {
    final accent = widget.dominantAccent ?? context.accentPrimary;
    final availablePaths = widget.guide.paths;

    // Calculăm lista de noduri în funcție de mod
    List<WatchOrderNode> currentNodes;
    if (_selectedMode == 'RELEASE' && !availablePaths.containsKey('RELEASE')) {
      final base = List<WatchOrderNode>.from(
          availablePaths['RECOMMENDED'] ?? availablePaths.values.firstOrNull ?? []);
      base.sort((a, b) => (a.releaseYear ?? 0).compareTo(b.releaseYear ?? 0));
      currentNodes = base;
    } else {
      currentNodes = availablePaths[_selectedMode] ??
          availablePaths['RECOMMENDED'] ??
          availablePaths.values.firstOrNull ??
          [];
    }

    final bool hasMixedCanon = currentNodes.any((n) => !n.isCanon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Franchise Overview Card (Clean, borderless, contextual accent glow)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIcons.gitFork(PhosphorIconsStyle.bold),
                        color: accent,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.guide.franchiseName,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.guide.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.guide.description!,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
              if (widget.guide.communityTip != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        size: 16,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.guide.communityTip!,
                          style: TextStyle(
                            color: context.textPrimary.withValues(alpha: 0.92),
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Mode Switcher (Pills with dominant accent)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildModeButton(context, 'RECOMMENDED', 'Recomandat (Începători)', PhosphorIcons.sparkle(PhosphorIconsStyle.bold), accent),
              const SizedBox(width: 8),
              _buildModeButton(context, 'CHRONOLOGICAL', 'Cronologic (Poveste)', PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold), accent),
              const SizedBox(width: 8),
              _buildModeButton(context, 'RELEASE', 'Ordinea Lansării', PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold), accent),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. Signature Timeline with Canon vs Side-Story Visual Hierarchy
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentNodes.length,
          itemBuilder: (context, index) {
            final node = currentNodes[index];
            final isLast = index == currentNodes.length - 1;
            final isCanon = node.isCanon;
            final nodeCover = (node.coverImage != null && node.coverImage!.isNotEmpty)
                ? node.coverImage!
                : widget.parentCoverImage;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Step Index & Connector Line
                  SizedBox(
                    width: 42,
                    child: Column(
                      children: [
                        // Signature Timeline Node Badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCanon ? accent : context.bgSurfaceHover,
                            shape: BoxShape.circle,
                            boxShadow: isCanon
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${node.orderIndex}',
                            style: TextStyle(
                              color: isCanon ? Colors.black : context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        // Timeline stem (solid prominent for Canon, subtle for Side-story)
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: isCanon ? 3.0 : 1.5,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isCanon
                                    ? accent.withValues(alpha: 0.45)
                                    : context.borderSubtle.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right Content Node Card (Interactive & Depth)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          if (node.mediaId.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MediaDetailScreen(mediaId: node.mediaId),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.bgSurface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover thumbnail cu fallback inteligent
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 58,
                                  height: 82,
                                  child: (nodeCover != null && nodeCover.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: nodeCover,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: context.bgSurfaceHover),
                                          errorWidget: (_, __, ___) => _buildFallbackThumbnail(context, node, accent),
                                        )
                                      : _buildFallbackThumbnail(context, node, accent),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Text metadata & badges
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        PillBadge(
                                          label: node.type,
                                          fontSize: 9.5,
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        ),
                                        if (hasMixedCanon) ...[
                                          const SizedBox(width: 6),
                                          if (isCanon)
                                            PillBadge(
                                              label: 'CANON',
                                              fontSize: 9.5,
                                              backgroundColor: accent.withValues(alpha: 0.18),
                                              textColor: accent,
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            )
                                          else
                                            PillBadge(
                                              label: 'OPȚIONAL',
                                              fontSize: 9.5,
                                              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                              textColor: const Color(0xFFA78BFA),
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      node.title,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (node.episodesInfo != null || node.releaseYear != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if (node.releaseYear != null) '${node.releaseYear}',
                                          if (node.episodesInfo != null) node.episodesInfo!,
                                        ].join(' • '),
                                        style: TextStyle(color: context.textSecondary, fontSize: 11.5),
                                      ),
                                    ],
                                    if (node.note != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        node.note!,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail(BuildContext context, WatchOrderNode node, Color accent) {
    return Container(
      color: context.bgSurfaceHover,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.filmStrip(PhosphorIconsStyle.bold),
            size: 22,
            color: accent,
          ),
          const SizedBox(height: 4),
          Text(
            'Part ${node.orderIndex}',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, String modeKey, String label, IconData icon, Color accent) {
    final isSelected = _selectedMode == modeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = modeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent : context.bgSurface,
          borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.black : context.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : context.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

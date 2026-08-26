import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../models/watch_order.dart';
import '../views/media_detail_screen.dart';
import 'pill_badge.dart';

class WatchOrderTreeView extends StatefulWidget {
  final WatchOrderGuide guide;

  const WatchOrderTreeView({super.key, required this.guide});

  @override
  State<WatchOrderTreeView> createState() => _WatchOrderTreeViewState();
}

class _WatchOrderTreeViewState extends State<WatchOrderTreeView> {
  String _selectedMode = 'RECOMMENDED';

  @override
  Widget build(BuildContext context) {
    final availablePaths = widget.guide.paths;
    final currentNodes = availablePaths[_selectedMode] ?? availablePaths['RECOMMENDED'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Franchise Title & Description Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, color: AppColors.accentPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.guide.franchiseName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.guide.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.guide.description!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              if (widget.guide.communityTip != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    widget.guide.communityTip!,
                    style: const TextStyle(
                      color: AppColors.accentSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Mode Switcher (Recommended / Chronological / Release)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildModeButton('RECOMMENDED', 'Recomandat (Începători)', Icons.auto_awesome),
              const SizedBox(width: 8),
              if (availablePaths.containsKey('CHRONOLOGICAL')) ...[
                _buildModeButton('CHRONOLOGICAL', 'Cronologic (Poveste)', Icons.schedule),
                const SizedBox(width: 8),
              ],
              if (availablePaths.containsKey('RELEASE')) ...[
                _buildModeButton('RELEASE', 'Ordinea Lansării', Icons.calendar_today_outlined),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Vertical Timeline Nodes
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentNodes.length,
          itemBuilder: (context, index) {
            final node = currentNodes[index];
            final isLast = index == currentNodes.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Step Index & Connector Line
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        // Circle step badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: node.isCanon ? AppColors.accentPrimary : AppColors.bgSurfaceHover,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: node.isCanon ? AppColors.accentSecondary : AppColors.borderSubtle,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${node.orderIndex}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Line downwards
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.borderSubtle,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right Content Node Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
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
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: node.isCanon ? AppColors.borderSubtle : AppColors.borderSubtle.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover thumbnail if exists
                              if (node.coverImage != null && node.coverImage!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: node.coverImage!,
                                    width: 50,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: AppColors.bgSurfaceHover),
                                  ),
                                ),
                              const SizedBox(width: 12),

                              // Text metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        PillBadge(
                                          label: node.type,
                                          fontSize: 9,
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        ),
                                        const SizedBox(width: 6),
                                        if (node.isCanon)
                                          PillBadge(
                                            label: 'CANON',
                                            fontSize: 9,
                                            backgroundColor: AppColors.signalLive.withValues(alpha: 0.12),
                                            textColor: AppColors.signalLive,
                                            borderColor: AppColors.signalLive.withValues(alpha: 0.3),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          )
                                        else
                                          PillBadge(
                                            label: 'OPȚIONAL / SIDE',
                                            fontSize: 9,
                                            backgroundColor: AppColors.textMuted.withValues(alpha: 0.12),
                                            textColor: AppColors.textSecondary,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      node.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (node.episodesInfo != null || node.releaseYear != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if (node.releaseYear != null) '${node.releaseYear}',
                                          if (node.episodesInfo != null) node.episodesInfo!,
                                        ].join(' • '),
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                    if (node.note != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        node.note!,
                                        style: const TextStyle(
                                          color: AppColors.accentSecondary,
                                          fontSize: 11,
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

  Widget _buildModeButton(String modeKey, String label, IconData icon) {
    final isSelected = _selectedMode == modeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = modeKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

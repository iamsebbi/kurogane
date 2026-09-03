import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/watch_order.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../views/auth/login_screen.dart';
import '../views/media_detail_screen.dart';
import 'pill_badge.dart';
import 'watch_order_proposal_sheet.dart';

class WatchOrderTreeView extends ConsumerStatefulWidget {
  final WatchOrderGuide guide;
  final String? currentMediaId;
  final String? parentCoverImage;

  const WatchOrderTreeView({
    super.key,
    required this.guide,
    this.currentMediaId,
    this.parentCoverImage,
  });

  @override
  ConsumerState<WatchOrderTreeView> createState() => _WatchOrderTreeViewState();
}

class _WatchOrderTreeViewState extends ConsumerState<WatchOrderTreeView> {
  String _selectedMode = 'RECOMMENDED';
  WatchOrderPreset? _selectedPreset;

  @override
  void didUpdateWidget(covariant WatchOrderTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.guide != oldWidget.guide) {
      if (_selectedPreset != null) {
        _selectedPreset = widget.guide.communityPresets.where((p) => p.id == _selectedPreset!.id).firstOrNull;
        if (_selectedPreset == null) {
          _selectedMode = 'RECOMMENDED';
        }
      }
    }
  }

  bool _arePathsIdentical(List<WatchOrderNode>? a, List<WatchOrderNode>? b) {
    if (a == null || b == null) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].mediaId != b[i].mediaId) return false;
    }
    return true;
  }

  Future<void> _handleVote(WatchOrderPreset preset, int newVote) async {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      LoginScreen.show(context);
      return;
    }

    HapticFeedback.lightImpact();

    final prevVote = preset.userVote;
    final prevUpvotes = preset.upvotes;
    final prevDownvotes = preset.downvotes;

    setState(() {
      if (prevVote == newVote) {
        preset.userVote = null;
        if (newVote == 1) preset.upvotes = (preset.upvotes - 1).clamp(0, 999999);
        if (newVote == -1) preset.downvotes = (preset.downvotes - 1).clamp(0, 999999);
      } else {
        if (prevVote == 1) preset.upvotes = (preset.upvotes - 1).clamp(0, 999999);
        if (prevVote == -1) preset.downvotes = (preset.downvotes - 1).clamp(0, 999999);

        preset.userVote = newVote;
        if (newVote == 1) preset.upvotes += 1;
        if (newVote == -1) preset.downvotes += 1;
      }
    });

    try {
      final client = ref.read(apiClientProvider);
      await client.voteWatchOrderPreset(preset.id, newVote);
      if (widget.currentMediaId != null) {
        ref.invalidate(watchOrderProvider(widget.currentMediaId!));
      }
    } catch (e) {
      setState(() {
        preset.userVote = prevVote;
        preset.upvotes = prevUpvotes;
        preset.downvotes = prevDownvotes;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReport(WatchOrderPreset preset) async {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      LoginScreen.show(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Report this guide?', style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'If this guide contains inaccurate information, spam, or inappropriate content, submit a report to moderators.',
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel, style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: context.error),
            child: const Text('Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = ref.read(apiClientProvider);
      await client.reportWatchOrderPreset(preset.id, 'Inappropriate / Inaccurate');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your report has been submitted. Thank you!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.currentMediaId != null) {
        ref.invalidate(watchOrderProvider(widget.currentMediaId!));
      }
    }
  }

  void _openProposalSheet(List<WatchOrderNode> baseNodes) {
    if (widget.currentMediaId == null) return;
    WatchOrderProposalSheet.show(
      context,
      mediaId: widget.currentMediaId!,
      franchiseName: widget.guide.franchiseName,
      initialNodes: baseNodes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final availablePaths = widget.guide.paths;
    final communityPresets = widget.guide.communityPresets;

    // Deduplicare căi: verificăm dacă alternativele chiar diferă
    final recPath = availablePaths['RECOMMENDED'] ?? availablePaths.values.firstOrNull;
    final chronoPath = availablePaths['CHRONOLOGICAL'];
    final releasePath = availablePaths['RELEASE'];

    final bool hasDistinctChrono = chronoPath != null && chronoPath.isNotEmpty && !_arePathsIdentical(recPath, chronoPath);
    final bool hasDistinctRelease = releasePath != null && releasePath.isNotEmpty && !_arePathsIdentical(recPath, releasePath);
    final bool hasAlternativeOfficialModes = hasDistinctChrono || hasDistinctRelease;
    final bool hasCommunityPresets = communityPresets.isNotEmpty;
    final bool showSelectorRow = hasAlternativeOfficialModes || hasCommunityPresets;

    List<WatchOrderNode> currentNodes;
    if (_selectedPreset != null) {
      currentNodes = _selectedPreset!.items.map((it) {
        return WatchOrderNode(
          id: it.id ?? 'preset-${it.mediaId}',
          mediaId: it.mediaId,
          title: it.title ?? 'Episode / Entry',
          type: it.format ?? 'TV',
          releaseYear: it.year,
          coverImage: it.coverImage ?? widget.parentCoverImage,
          orderIndex: it.position,
          note: it.note,
          isCanon: it.isCanon,
        );
      }).toList();
    } else if (_selectedMode == 'RELEASE' && !availablePaths.containsKey('RELEASE')) {
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
        // 1. Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.25 : 0.7),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildAuthorityBadge(context, widget.guide.authority),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(color: context.textMuted, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                '${currentNodes.length} ${currentNodes.length == 1 ? "entry" : "entries"}',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.currentMediaId != null)
                GestureDetector(
                  onTap: () {
                    final base = widget.guide.paths['RECOMMENDED'] ?? widget.guide.paths.values.firstOrNull ?? [];
                    _openProposalSheet(base);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.3 : 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 12, color: context.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Propose',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Banner Sfat Esențial
        if (widget.guide.communityTip != null && _selectedPreset == null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.18 : 0.22),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: 15,
                  color: context.accentPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.guide.communityTip!,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 3. Path Selector
        if (showSelectorRow) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (hasAlternativeOfficialModes) ...[
                  _buildModeButton(context, 'RECOMMENDED', 'Recommended', PhosphorIcons.sparkle(PhosphorIconsStyle.bold), null),
                  if (hasDistinctChrono) ...[
                    const SizedBox(width: 8),
                    _buildModeButton(context, 'CHRONOLOGICAL', 'Chronological', PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold), null),
                  ],
                  if (hasDistinctRelease) ...[
                    const SizedBox(width: 8),
                    _buildModeButton(context, 'RELEASE', 'Release', PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold), null),
                  ],
                ] else ...[
                  _buildModeButton(context, 'RECOMMENDED', 'Canon Order', PhosphorIcons.sparkle(PhosphorIconsStyle.bold), null),
                ],
                if (communityPresets.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: context.borderSubtle.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  ...communityPresets.map((preset) {
                    final isVerified = preset.status == 'community_verified';
                    final label = '${preset.title} (@${preset.submitterUsername})';
                    final icon = isVerified ? PhosphorIcons.sealCheck(PhosphorIconsStyle.fill) : PhosphorIcons.users(PhosphorIconsStyle.bold);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildModeButton(context, preset.id, label, icon, preset),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],

        // 4. Card Meta Detalii Preset Comunitar Selectat
        if (_selectedPreset != null) ...[
          const SizedBox(height: 14),
          _buildCommunityPresetHeader(context, _selectedPreset!),
        ],

        const SizedBox(height: 16),

        // 5. Timeline Semnătură Curat (Fără GLOW, Fără TV redundant)
        ListView.builder(
          padding: EdgeInsets.zero,
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
                  // Left Step Index (Flat, Zero Glow) & Connector Line
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCanon ? context.accentPrimary : context.bgSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCanon
                                  ? context.accentPrimary
                                  : context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.4 : 0.8),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${node.orderIndex}',
                            style: TextStyle(
                              color: isCanon ? context.onPrimary : context.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: isCanon ? 2.5 : 1.5,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: isCanon
                                    ? context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.45 : 0.65)
                                    : context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.4 : 0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right Content Node Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
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
                            border: Border.all(
                              color: context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.25 : 0.7),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                          errorWidget: (_, __, ___) => _buildFallbackThumbnail(context, node),
                                        )
                                      : _buildFallbackThumbnail(context, node),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (node.type.toUpperCase() != 'TV' || hasMixedCanon) ...[
                                      Row(
                                        children: [
                                          if (node.type.toUpperCase() != 'TV')
                                            PillBadge(
                                              label: node.type,
                                              fontSize: 9.5,
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            ),
                                          if (hasMixedCanon) ...[
                                            if (node.type.toUpperCase() != 'TV') const SizedBox(width: 6),
                                            if (isCanon)
                                              PillBadge(
                                                label: 'CANON',
                                                fontSize: 9.5,
                                                backgroundColor: context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.18 : 0.15),
                                                textColor: context.isDarkMode ? context.accentPrimary : context.textPrimary,
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              )
                                            else
                                              PillBadge(
                                                label: 'OPTIONAL',
                                                fontSize: 9.5,
                                                backgroundColor: context.statusPlanToWatch.withValues(alpha: 0.15),
                                                textColor: context.statusPlanToWatch,
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                    ],
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
                                          color: context.textSecondary,
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

        const SizedBox(height: 10),

        // 6. Bottom Proposal CTA
        if (widget.currentMediaId != null)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                final base = widget.guide.paths['RECOMMENDED'] ?? widget.guide.paths.values.firstOrNull ?? [];
                _openProposalSheet(base);
              },
              icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.bold), size: 18, color: context.accentPrimary),
              label: Text(
                'Propose alternative order',
                style: TextStyle(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.6 : 0.9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAuthorityBadge(BuildContext context, String authority) {
    Color color = context.accentPrimary;
    String label = 'Editorial Official';
    IconData icon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill);

    if (authority == 'community_verified') {
      color = context.statusCompleted;
      label = 'Community Verified';
      icon = PhosphorIcons.sealCheck(PhosphorIconsStyle.fill);
    } else if (authority == 'algorithmic') {
      color = context.textSecondary;
      label = 'Algorithmic Order';
      icon = PhosphorIcons.cpu(PhosphorIconsStyle.bold);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildCommunityPresetHeader(BuildContext context, WatchOrderPreset preset) {
    final isVerified = preset.status == 'community_verified';
    final userVote = preset.userVote;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVerified ? context.statusCompleted.withValues(alpha: 0.35) : context.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillBadge(
                label: isVerified ? 'COMMUNITY VERIFIED' : 'COMMUNITY PROPOSAL',
                backgroundColor: isVerified ? context.statusCompleted.withValues(alpha: 0.15) : context.bgSurfaceHover,
                textColor: isVerified ? context.statusCompleted : context.textSecondary,
                fontSize: 9.5,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _handleReport(preset),
                icon: Icon(PhosphorIcons.flag(PhosphorIconsStyle.bold), size: 16, color: context.textMuted),
                tooltip: 'Report guide',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          if (preset.description != null && preset.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              preset.description!,
              style: TextStyle(color: context.textSecondary, fontSize: 12.5, height: 1.35),
            ),
          ],

          if (preset.isPossiblyOutdated) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.warning, size: 15, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Possibly outdated: +${preset.missingItemsCount} new titles in franchise.',
                      style: const TextStyle(color: Colors.orange, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Container(height: 1, color: context.borderSubtle.withValues(alpha: 0.25)),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'By @${preset.submitterUsername}',
                style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),

              // Upvote Button
              GestureDetector(
                onTap: () => _handleVote(preset, 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: userVote == 1 ? context.accentPrimary.withValues(alpha: 0.2) : context.bgSurfaceHover,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: userVote == 1 ? context.accentPrimary : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.arrowFatUp(userVote == 1 ? PhosphorIconsStyle.fill : PhosphorIconsStyle.bold),
                        size: 14,
                        color: userVote == 1 ? context.accentPrimary : context.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${preset.upvotes}',
                        style: TextStyle(
                          color: userVote == 1 ? context.accentPrimary : context.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Downvote Button
              GestureDetector(
                onTap: () => _handleVote(preset, -1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: userVote == -1 ? context.error.withValues(alpha: 0.2) : context.bgSurfaceHover,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: userVote == -1 ? context.error : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.arrowFatDown(userVote == -1 ? PhosphorIconsStyle.fill : PhosphorIconsStyle.bold),
                        size: 14,
                        color: userVote == -1 ? context.error : context.textSecondary,
                      ),
                      if (preset.downvotes > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${preset.downvotes}',
                          style: TextStyle(
                            color: userVote == -1 ? context.error : context.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail(BuildContext context, WatchOrderNode node) {
    return Container(
      color: context.bgSurfaceHover,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.filmStrip(PhosphorIconsStyle.bold),
            size: 22,
            color: context.accentPrimary,
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

  Widget _buildModeButton(
    BuildContext context,
    String modeKey,
    String label,
    IconData icon,
    WatchOrderPreset? preset,
  ) {
    final isSelected = _selectedMode == modeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = modeKey;
          _selectedPreset = preset;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.accentPrimary : context.bgSurface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? context.accentPrimary
                : context.borderSubtle.withValues(alpha: context.isDarkMode ? 0.3 : 0.8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? context.onPrimary : context.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.onPrimary : context.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

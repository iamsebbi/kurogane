import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../providers/api_providers.dart';
import 'franchise_horizontal_card.dart';

class MediaRelationsView extends ConsumerStatefulWidget {
  final List<MediaRelation> relations;
  final String? currentMediaId;

  const MediaRelationsView({
    super.key,
    required this.relations,
    this.currentMediaId,
  });

  @override
  ConsumerState<MediaRelationsView> createState() => _MediaRelationsViewState();
}

class _MediaRelationsViewState extends ConsumerState<MediaRelationsView> {
  List<MediaRelation>? _loadedRelations;
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.relations.isNotEmpty) {
      _loadedRelations = widget.relations;
    } else if (widget.currentMediaId != null) {
      _fetchRelations();
    }
  }

  @override
  void didUpdateWidget(covariant MediaRelationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.relations.isNotEmpty && widget.relations != oldWidget.relations) {
      setState(() {
        _loadedRelations = widget.relations;
      });
    } else if (widget.currentMediaId != oldWidget.currentMediaId && widget.currentMediaId != null) {
      _fetchRelations();
    }
  }

  Future<void> _fetchRelations() async {
    if (widget.currentMediaId == null) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final fetched = await client.getMediaRelations(widget.currentMediaId!);
      if (mounted) {
        setState(() {
          _loadedRelations = fetched;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: context.accentPrimary),
        ),
      );
    }

    final rawRelations = _loadedRelations ?? widget.relations;

    // Exclude media de tip Muzică (deoarece există deja tabul dedicat de Music)
    final relations = rawRelations.where((r) {
      final f = r.format?.toUpperCase();
      final t = r.type?.toUpperCase();
      final rt = r.relationType.toUpperCase();
      return f != 'MUSIC' && t != 'MUSIC' && rt != 'MUSIC';
    }).toList();

    if (relations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(20), // FULL ROUNDED
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.08 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.treeStructure(PhosphorIconsStyle.bold),
                size: 24,
                color: context.accentPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Standalone Production',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This title is standalone and has no direct sequels or spin-offs associated in the official database.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // Grupare semantică a relațiilor (standard MyAnimeList & AniList)
    final mainSequels = relations.where((r) => r.relationType == 'SEQUEL').toList();
    final mainPrequels = relations.where((r) => r.relationType == 'PREQUEL').toList();
    final sideStories = relations.where((r) => r.relationType == 'SIDE_STORY').toList();
    final spinOffs = relations.where((r) => r.relationType == 'SPIN_OFF').toList();
    final alternatives = relations.where((r) => r.relationType == 'ALTERNATIVE').toList();
    final summaries = relations.where((r) => r.relationType == 'SUMMARY').toList();
    final adaptations = relations.where((r) => r.relationType == 'SOURCE' || r.relationType == 'ADAPTATION').toList();
    final others = relations.where((r) =>
      r.relationType != 'SEQUEL' &&
      r.relationType != 'PREQUEL' &&
      r.relationType != 'SIDE_STORY' &&
      r.relationType != 'SPIN_OFF' &&
      r.relationType != 'ALTERNATIVE' &&
      r.relationType != 'SUMMARY' &&
      r.relationType != 'SOURCE' &&
      r.relationType != 'ADAPTATION'
    ).toList();

    final hasMainStory = mainSequels.isNotEmpty || mainPrequels.isNotEmpty;

    // Toate celelalte categorii secundare
    final otherCategories = <Widget>[
      // 3. Povești Secundare & OVA-uri
      if (sideStories.isNotEmpty) ...[
        _buildSectionHeader(context, 'Side Stories & Specials', PhosphorIcons.sparkle(PhosphorIconsStyle.bold)),
        const SizedBox(height: 8),
        ...sideStories.map((rel) => _buildRelationCard(context, rel)),
        const SizedBox(height: 14),
      ],

      // 4. Spin-off-uri & Paralele
      if (spinOffs.isNotEmpty) ...[
        _buildSectionHeader(context, 'Spin-offs & Alternatives', PhosphorIcons.gitFork(PhosphorIconsStyle.bold)),
        const SizedBox(height: 8),
        ...spinOffs.map((rel) => _buildRelationCard(context, rel)),
        const SizedBox(height: 14),
      ],

      // 5. Versiuni Alternative
      if (alternatives.isNotEmpty) ...[
        _buildSectionHeader(context, 'Alternative Versions', PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold)),
        const SizedBox(height: 8),
        ...alternatives.map((rel) => _buildRelationCard(context, rel)),
        const SizedBox(height: 14),
      ],

      // 6. Rezumate & Filme Recap
      if (summaries.isNotEmpty) ...[
        _buildSectionHeader(context, 'Summary Films (Recap)', PhosphorIcons.filmReel(PhosphorIconsStyle.bold)),
        const SizedBox(height: 8),
        ...summaries.map((rel) => _buildRelationCard(context, rel)),
        const SizedBox(height: 14),
      ],

      // 7. Material Sursă / Adaptări
      if (adaptations.isNotEmpty) ...[
        _buildSectionHeader(context, 'Source Material (Manga / Novel)', PhosphorIcons.bookOpen(PhosphorIconsStyle.bold)),
        const SizedBox(height: 8),
        ...adaptations.map((rel) => _buildRelationCard(context, rel, canNavigate: false)),
        const SizedBox(height: 14),
      ],

      // 8. Altele
      if (others.isNotEmpty) ...[
        _buildSectionHeader(context, 'Other Related Works', PhosphorIcons.dotsThreeCircle(PhosphorIconsStyle.bold)),
        const SizedBox(height: 8),
        ...others.map((rel) => _buildRelationCard(context, rel)),
      ],
    ];

    final hasOtherCategories = otherCategories.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Bar Suplu (Fără border, full rounded 9999)
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.treeStructure(PhosphorIconsStyle.bold),
                size: 14,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Franchise Relations',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.accentPrimary.withValues(alpha: context.isDarkMode ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
                ),
                child: Text(
                  '${relations.length} titles',
                  style: TextStyle(
                    color: context.accentPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Firul Narativ Principal (Continuare & Precursor) — Prioritate Maximă
        if (hasMainStory) ...[
          _buildSectionHeader(context, 'Main Story', PhosphorIcons.arrowBendRightDown(PhosphorIconsStyle.bold)),
          const SizedBox(height: 8),
          ...mainSequels.map((rel) => _buildRelationCard(context, rel, isMainStory: true, isSequel: true)),
          ...mainPrequels.map((rel) => _buildRelationCard(context, rel, isMainStory: true, isSequel: false)),
        ],

        // Dacă există Main Story și alte categorii -> AnimatedSize colapsat + buton "Show more"
        if (hasMainStory && hasOtherCategories) ...[
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: otherCategories,
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: context.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                      size: 14,
                      color: context.accentPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (!hasMainStory && hasOtherCategories) ...[
          // Dacă nu are Main Story, afișează direct categoriile disponibile
          ...otherCategories,
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRelationCard(
    BuildContext context,
    MediaRelation rel, {
    bool isMainStory = false,
    bool isSequel = false,
    bool canNavigate = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FranchiseHorizontalCard.fromRelation(
        context: context,
        relation: rel,
        isMainStory: isMainStory,
        isSequel: isSequel,
      ),
    );
  }
}

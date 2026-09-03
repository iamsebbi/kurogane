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

class WatchOrderProposalSheet extends ConsumerStatefulWidget {
  final String mediaId;
  final String franchiseName;
  final List<WatchOrderNode> initialNodes;

  const WatchOrderProposalSheet({
    super.key,
    required this.mediaId,
    required this.franchiseName,
    required this.initialNodes,
  });

  static Future<void> show(
    BuildContext context, {
    required String mediaId,
    required String franchiseName,
    required List<WatchOrderNode> initialNodes,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatchOrderProposalSheet(
        mediaId: mediaId,
        franchiseName: franchiseName,
        initialNodes: initialNodes,
      ),
    );
  }

  @override
  ConsumerState<WatchOrderProposalSheet> createState() => _WatchOrderProposalSheetState();
}

class _WatchOrderProposalSheetState extends ConsumerState<WatchOrderProposalSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late List<_EditableItem> _items;
  bool _isSelectiveCurated = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items = widget.initialNodes
        .map((n) => _EditableItem(
              mediaId: n.mediaId,
              title: n.title,
              type: n.type,
              releaseYear: n.releaseYear,
              coverImage: n.coverImage,
              note: n.note,
              isCanon: n.isCanon,
            ))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      LoginScreen.show(context);
      return;
    }

    final title = _titleController.text.trim();
    if (title.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title of at least 3 characters.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'title': title,
        if (_descController.text.trim().isNotEmpty) 'description': _descController.text.trim(),
        'isSelectiveCurated': _isSelectiveCurated,
        'items': _items.asMap().entries.map((entry) {
          final idx = entry.key;
          final it = entry.value;
          return {
            'mediaId': it.mediaId,
            'position': idx + 1,
            'isCanon': it.isCanon,
            if (it.note != null && it.note!.trim().isNotEmpty) 'note': it.note!.trim(),
          };
        }).toList(),
      };

      final client = ref.read(apiClientProvider);
      await client.createWatchOrderPreset(widget.mediaId, payload);

      ref.invalidate(watchOrderProvider(widget.mediaId));

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your proposal has been submitted for community voting! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _editNote(int index) async {
    final item = _items[index];
    final noteController = TextEditingController(text: item.note ?? '');

    final newNote = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Note for ${item.title}',
          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: noteController,
          autofocus: true,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g.: Watch after Season 1, optional...',
            hintStyle: TextStyle(color: context.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel, style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(noteController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.accentPrimary),
            child: Text(AppStrings.save, style: TextStyle(color: context.onPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (newNote != null) {
      setState(() {
        _items[index].note = newNote.isEmpty ? null : newNote;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = context.accentPrimary;
    final onAccent = context.onPrimary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Propose alternative order',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.franchiseName,
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), color: context.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: context.borderSubtle.withValues(alpha: 0.3)),

          // Body Form & Reorderable List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Preset Title Field
                Text(
                  'Guide Title *',
                  style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g.: Chronological order without fillers',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 13.5),
                    filled: true,
                    fillColor: context.bgSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Description Field
                Text(
                  'Rationale / Recommendation (optional)',
                  style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  style: TextStyle(color: context.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g.: Recommended for new fans to better understand origins...',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: context.bgSurface,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Curated Selection Toggle
                SwitchListTile.adaptive(
                  value: _isSelectiveCurated,
                  onChanged: (val) => setState(() => _isSelectiveCurated = val),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: accent,
                  title: Text(
                    'Curated selection (no fillers / recaps)',
                    style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Check if you intentionally skipped non-essential titles to avoid incomplete flags.',
                    style: TextStyle(color: context.textSecondary, fontSize: 11.5),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Reorder Instruction
                Row(
                  children: [
                    Icon(PhosphorIcons.arrowsDownUp(PhosphorIconsStyle.bold), size: 16, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Reorder titles via drag & drop (${_items.length} titles):',
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Virtualized Reorderable List
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.transparent,
                    shadowColor: Colors.black54,
                  ),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _items.removeAt(oldIndex);
                        _items.insert(newIndex, item);
                      });
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        key: ValueKey(item.mediaId),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Drag Handle
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: Icon(
                                  PhosphorIcons.dotsSixVertical(PhosphorIconsStyle.bold),
                                  color: context.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Număr pas
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Poster
                            if (item.coverImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.coverImage!,
                                  width: 38,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(color: context.bgSurfaceHover),
                                ),
                              ),
                            const SizedBox(width: 10),

                            // Titlu & Notă
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        [
                                          if (item.releaseYear != null) '${item.releaseYear}',
                                          if (item.type.toUpperCase() != 'TV') item.type,
                                        ].join(' • '),
                                        style: TextStyle(color: context.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  if (item.note != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '📝 ${item.note}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Buton Edit Notă
                            IconButton(
                              onPressed: () => _editNote(index),
                              icon: Icon(
                                item.note != null ? PhosphorIcons.notePencil(PhosphorIconsStyle.fill) : PhosphorIcons.notePencil(PhosphorIconsStyle.bold),
                                size: 18,
                                color: item.note != null ? accent : context.textMuted,
                              ),
                              tooltip: 'Add note',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Submit CTA Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              border: Border(top: BorderSide(color: context.borderSubtle.withValues(alpha: 0.3))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProposal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: onAccent, strokeWidth: 2.2),
                      )
                    : Text(
                        'Submit proposal for voting',
                        style: TextStyle(
                          color: onAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableItem {
  final String mediaId;
  final String title;
  final String type;
  final int? releaseYear;
  final String? coverImage;
  String? note;
  bool isCanon;

  _EditableItem({
    required this.mediaId,
    required this.title,
    required this.type,
    this.releaseYear,
    this.coverImage,
    this.note,
    this.isCanon = true,
  });
}

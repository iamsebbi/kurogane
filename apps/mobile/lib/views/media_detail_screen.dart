import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/pill_badge.dart';
import '../widgets/watch_order_tree_view.dart';
import '../widgets/media_card.dart';
import '../widgets/media_rating_sheet.dart';
import 'auth/login_screen.dart';

class MediaDetailScreen extends ConsumerStatefulWidget {
  final String mediaId;
  final MediaItem? initialItem;

  const MediaDetailScreen({super.key, required this.mediaId, this.initialItem});

  @override
  ConsumerState<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends ConsumerState<MediaDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaDetailProvider(widget.mediaId));
    final watchOrderAsync = ref.watch(watchOrderProvider(widget.mediaId));
    final similarAsync = ref.watch(similarMediaProvider(widget.mediaId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: mediaAsync.when(
        loading: () => widget.initialItem != null
            ? _buildDetailContent(widget.initialItem!, watchOrderAsync, similarAsync)
            : const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
        error: (err, stack) => Center(
          child: Text('Eroare la încărcare: $err', style: const TextStyle(color: AppColors.alertCoral)),
        ),
        data: (item) {
          if (item == null) {
            return const Center(
              child: Text('Titlul nu a fost găsit', style: TextStyle(color: AppColors.textPrimary)),
            );
          }
          return _buildDetailContent(item, watchOrderAsync, similarAsync);
        },
      ),
    );
  }

  Widget _buildDetailContent(
    MediaItem item,
    AsyncValue<dynamic> watchOrderAsync,
    AsyncValue<List<MediaItem>> similarAsync,
  ) {
    final bannerUrl = item.bannerImage ?? item.coverImage.large;
    final score = item.scores.weightedScore > 0 ? item.scores.weightedScore : item.scores.averageScore;
    final scoreDisplay = score > 10 ? (score / 10).toStringAsFixed(1) : score.toStringAsFixed(1);

    return CustomScrollView(
      slivers: [
        // App Bar with Backdrop Image
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.bgPrimary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_outline, color: Colors.white, size: 20),
              ),
              onPressed: () => _showAddToWatchlistModal(context, item),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.bgSurface),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        AppColors.bgPrimary.withValues(alpha: 0.85),
                        AppColors.bgPrimary,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main Header Info (Poster + Title + Badges)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item.coverImage.large,
                        width: 100,
                        height: 145,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Quick Meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title.userPreferred,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (item.title.romaji != null && item.title.romaji != item.title.userPreferred) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.title.romaji!,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Anti-Review Bombing Score Display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AppColors.scoreGold),
                                const SizedBox(width: 4),
                                Text(
                                  scoreDisplay,
                                  style: const TextStyle(
                                    color: AppColors.scoreGold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Ponderat',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Add / Edit Watchlist & Rate Buttons
                          Builder(
                            builder: (context) {
                              final watchlistAsync = ref.watch(watchlistProvider);
                              final existingRecord = watchlistAsync.maybeWhen(
                                data: (list) => list.where((w) => w.mediaId == item.id).firstOrNull,
                                orElse: () => null,
                              );

                              if (existingRecord != null) {
                                return Row(
                                  children: [
                                    // Buton Status & Episoade
                                    Expanded(
                                      flex: 6,
                                      child: SizedBox(
                                        height: 38,
                                        child: ElevatedButton.icon(
                                          onPressed: () => MediaRatingSheet.show(
                                            context,
                                            media: item,
                                            currentWatchlistRecord: existingRecord,
                                          ),
                                          icon: Icon(
                                            PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
                                            size: 15,
                                            color: Colors.black,
                                          ),
                                          label: Text(
                                            '${_getStatusLabel(existingRecord.status)} • Ep. ${existingRecord.progressEpisodes}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Google Sans',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _getStatusColor(existingRecord.status),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Buton Notă (⭐ 9.0 sau ⭐ Notează)
                                    Expanded(
                                      flex: 4,
                                      child: SizedBox(
                                        height: 38,
                                        child: ElevatedButton.icon(
                                          onPressed: () => MediaRatingSheet.show(
                                            context,
                                            media: item,
                                            currentWatchlistRecord: existingRecord,
                                          ),
                                          icon: Icon(
                                            PhosphorIcons.star(
                                              existingRecord.score != null && existingRecord.score! > 0
                                                  ? PhosphorIconsStyle.fill
                                                  : PhosphorIconsStyle.bold,
                                            ),
                                            size: 14,
                                            color: const Color(0xFFFBBF24),
                                          ),
                                          label: Text(
                                            existingRecord.score != null && existingRecord.score! > 0
                                                ? '${existingRecord.score!.toStringAsFixed(1)} / 10'
                                                : 'Notează',
                                            style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Google Sans',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context.bgSurface,
                                            side: BorderSide(color: context.borderSubtle),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return SizedBox(
                                width: double.infinity,
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () => MediaRatingSheet.show(
                                    context,
                                    media: item,
                                    currentWatchlistRecord: null,
                                  ),
                                  icon: Icon(
                                    PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                                    size: 16,
                                    color: context.onPrimary,
                                  ),
                                  label: Text(
                                    '+ Adaugă în Listă & Notează',
                                    style: TextStyle(
                                      color: context.onPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Google Sans',
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.accentPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Genres & Micro-tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PillBadge(label: item.format ?? item.type, backgroundColor: AppColors.accentPrimary.withValues(alpha: 0.15), textColor: AppColors.accentSecondary),
                    if (item.status != null) PillBadge(label: item.status!),
                    ...item.genres.map((g) => PillBadge(label: g)),
                    ...item.microTags.map((t) => PillBadge(label: t, backgroundColor: AppColors.badgeViolet.withValues(alpha: 0.15), textColor: AppColors.badgeViolet)),
                  ],
                ),

                const SizedBox(height: 16),

                // Synopsis
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const Text(
                    'Sinopsis',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description!.replaceAll(RegExp(r'<[^>]*>'), ''),
                    maxLines: _isSynopsisExpanded ? null : 3,
                    overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _isSynopsisExpanded ? 'Arată mai puțin ▲' : 'Citește mai mult ▼',
                        style: const TextStyle(color: AppColors.accentSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Trailer Launcher if available
                if (item.trailerUrl != null && item.trailerUrl!.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(item.trailerUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.smart_display, color: AppColors.alertCoral, size: 18),
                    label: const Text('Urmărește Trailer Oficial', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tab Bar Header
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accentPrimary,
                  labelColor: AppColors.accentPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Watch Order'),
                    Tab(text: 'Similare'),
                    Tab(text: 'Detalii'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tab Views
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: [
              // Tab 1: Watch Order Tree
              watchOrderAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
                error: (e, st) => const Center(child: Text('Ghidul de vizionare nu este disponibil.', style: TextStyle(color: AppColors.textSecondary))),
                data: (guide) {
                  if (guide == null) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(14)),
                      child: const Center(
                        child: Text(
                          'Această serie este autonomă (fără franciză complexă).',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return WatchOrderTreeView(guide: guide);
                },
              ),

              // Tab 2: Similar Anime
              similarAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
                error: (e, st) => const Center(child: Text('Recomandările nu sunt disponibile.', style: TextStyle(color: AppColors.textSecondary))),
                data: (simList) {
                  if (simList.isEmpty) {
                    return const Center(child: Text('Nicio recomandare similară momentan.', style: TextStyle(color: AppColors.textSecondary)));
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: simList.length,
                    itemBuilder: (context, index) => MediaCard(item: simList[index], width: double.infinity),
                  );
                },
              ),

              // Tab 3: Detailed Tech Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Format', item.format ?? item.type),
                    _buildInfoRow('Episoade', '${item.episodes ?? "Necunoscut"}'),
                    _buildInfoRow('Sezon / An', '${item.season ?? ""} ${item.year ?? ""}'),
                    _buildInfoRow('Status', item.status ?? 'Nespecificat'),
                    _buildInfoRow('Studio', item.studios.isNotEmpty ? item.studios.join(', ') : 'Nespecificat'),
                    _buildInfoRow('Demografie', item.demographic ?? 'General'),
                  ],
                ),
              ),
            ][_tabController.index],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddToWatchlistModal(BuildContext context, MediaItem item) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      LoginScreen.show(context);
      return;
    }

    final existingRecord = ref.read(watchlistProvider).maybeWhen(
          data: (list) => list.where((w) => w.mediaId == item.id).firstOrNull,
          orElse: () => null,
        );

    String selectedStatus = existingRecord?.status ?? 'WATCHING';
    int episodes = existingRecord?.progressEpisodes ?? 0;
    final totalEpisodes = item.episodes;

    const statuses = [
      {'key': 'WATCHING', 'label': 'Vizionare', 'color': AppColors.signalLive},
      {'key': 'COMPLETED', 'label': 'Finalizat', 'color': Color(0xFF60A5FA)},
      {'key': 'PLAN_TO_WATCH', 'label': 'De Văzut', 'color': AppColors.scoreGold},
      {'key': 'ON_HOLD', 'label': 'În Pauză', 'color': Color(0xFFFB923C)},
      {'key': 'DROPPED', 'label': 'Abandonat', 'color': AppColors.alertCoral},
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Adaugă în Watchlist',
                    style: TextStyle(
                      fontFamily: 'Zalando Sans Expanded',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status chips (Full rounded, zero border)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((st) {
                      final isSel = selectedStatus == st['key'];
                      final color = st['color'] as Color;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedStatus = st['key'] as String),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? color : context.bgSurfaceHover,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            st['label'] as String,
                            style: TextStyle(
                              color: isSel ? Colors.black : context.textSecondary,
                              fontFamily: 'Google Sans',
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Episode Stepper
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Episoade',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Google Sans',
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (episodes > 0) {
                                  setModalState(() {
                                    episodes--;
                                    if (selectedStatus == 'COMPLETED' &&
                                        totalEpisodes != null &&
                                        totalEpisodes > 0 &&
                                        episodes < totalEpisodes) {
                                      selectedStatus = 'WATCHING';
                                    }
                                  });
                                }
                              },
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 140),
                                    opacity: episodes > 0 ? 1.0 : 0.35,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: context.bgPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                          size: 15.5,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$episodes / ${totalEpisodes != null && totalEpisodes > 0 ? totalEpisodes : "?"}',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                if (totalEpisodes == null || totalEpisodes == 0 || episodes < totalEpisodes) {
                                  setModalState(() {
                                    episodes++;
                                    if (totalEpisodes != null && totalEpisodes > 0 && episodes >= totalEpisodes) {
                                      selectedStatus = 'COMPLETED';
                                    }
                                  });
                                }
                              },
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 140),
                                    opacity: (totalEpisodes == null || totalEpisodes == 0 || episodes < totalEpisodes)
                                        ? 1.0
                                        : 0.35,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: context.bgPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                          size: 15.5,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Actions: Save & optional Remove
                  Row(
                    children: [
                      if (existingRecord != null) ...[
                        GestureDetector(
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await ref.read(watchlistProvider.notifier).removeItem(item.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Eliminat din Watchlist')),
                            );
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.trash(PhosphorIconsStyle.bold),
                                size: 18,
                                color: context.error,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await ref.read(watchlistProvider.notifier).updateItem(
                                  mediaId: item.id,
                                  status: selectedStatus,
                                  progressEpisodes: episodes,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Salvat în Watchlist!')),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: context.accentPrimary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Salvează în Listă',
                              style: TextStyle(
                                color: context.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'WATCHING':
        return 'Vizionare';
      case 'COMPLETED':
        return 'Finalizat';
      case 'PLAN_TO_WATCH':
        return 'De Văzut';
      case 'ON_HOLD':
        return 'În Pauză';
      case 'DROPPED':
        return 'Abandonat';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WATCHING':
        return AppColors.signalLive;
      case 'COMPLETED':
        return const Color(0xFF60A5FA); // Sky Blue
      case 'PLAN_TO_WATCH':
        return AppColors.scoreGold;
      case 'ON_HOLD':
        return const Color(0xFFFB923C); // Warm Orange
      case 'DROPPED':
        return AppColors.alertCoral;
      default:
        return AppColors.textSecondary;
    }
  }
}

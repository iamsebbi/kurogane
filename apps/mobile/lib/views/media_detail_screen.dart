import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../models/media_item.dart';
import '../models/watchlist_item.dart';
import '../providers/anilist_provider.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/pill_badge.dart';
import '../widgets/watch_order_tree_view.dart';
import '../widgets/media_card.dart';
import 'auth/login_screen.dart';

class MediaDetailScreen extends ConsumerStatefulWidget {
  final String mediaId;
  final MediaItem? initialItem;

  const MediaDetailScreen({
    super.key,
    required this.mediaId,
    this.initialItem,
  });

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
      backgroundColor: context.bgPrimary,
      body: mediaAsync.when(
        loading: () => widget.initialItem != null
            ? _buildDetailContent(widget.initialItem!, watchOrderAsync, similarAsync)
            : Center(
                child: CircularProgressIndicator(color: context.accentPrimary),
              ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                  color: context.error,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Eroare la încărcare',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Center(
              child: Text(
                'Titlul nu a fost găsit',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    final studios = item.studios.isNotEmpty
        ? item.studios
        : (widget.initialItem?.studios ?? const <String>[]);
    final heroImageUrl = (item.coverImage.extraLarge != null && item.coverImage.extraLarge!.isNotEmpty)
        ? item.coverImage.extraLarge!
        : (item.coverImage.large.isNotEmpty ? item.coverImage.large : (item.bannerImage ?? ''));
    final score = item.scores.weightedScore > 0 ? item.scores.weightedScore : item.scores.averageScore;
    final scoreDisplay = score > 10 ? (score / 10).toStringAsFixed(1) : score.toStringAsFixed(1);

    // Titluri secundare (Romaji + Japoneză nativă Kanji/Kana)
    final secondaryTitles = <String>[];
    if (item.title.romaji != null &&
        item.title.romaji!.isNotEmpty &&
        item.title.romaji != item.title.userPreferred) {
      secondaryTitles.add(item.title.romaji!);
    }
    if (item.title.native != null &&
        item.title.native!.isNotEmpty &&
        item.title.native != item.title.userPreferred &&
        item.title.native != item.title.romaji) {
      secondaryTitles.add(item.title.native!);
    }

    // Metadate tehnice curate
    final technicalMetaList = <String>[];
    if (item.format != null && item.format!.isNotEmpty) {
      technicalMetaList.add(item.format!);
    } else if (item.type.isNotEmpty) {
      technicalMetaList.add(item.type);
    }
    if (item.episodes != null && item.episodes! > 0) {
      technicalMetaList.add('${item.episodes} Episoade');
    }
    if (item.status != null && item.status!.isNotEmpty) {
      technicalMetaList.add(_formatStatusText(item.status!));
    }
    if (item.year != null) {
      technicalMetaList.add('${item.season ?? ""} ${item.year}'.trim());
    }

    // Verificare stare Watchlist pentru butonul de adaugare rapida la 'De vazut'
    final watchlistAsync = ref.watch(watchlistProvider);
    final currentRecord = watchlistAsync.value?.cast<WatchlistItemRecord?>().firstWhere(
      (w) => w != null && (w.mediaId == item.id || w.mediaId == widget.mediaId),
      orElse: () => null,
    );
    final bool isPlanToWatch = currentRecord?.status == 'PLAN_TO_WATCH';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // 1. Hero AppBar cu Poster Cinematic Extins, Deep Scrim & Quick Floating Trailer CTA
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          stretch: true,
          backgroundColor: context.bgPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 76,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: _DetailFloatingCircleButton(
                size: 52,
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                  color: context.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: _DetailFloatingCircleButton(
                  size: 52,
                  onTap: () async {
                    final user = ref.read(currentUserProvider);
                    if (user == null) {
                      LoginScreen.show(context);
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    if (isPlanToWatch) {
                      await ref.read(watchlistProvider.notifier).removeItem(item.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Eliminat din 'De văzut'"),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      await ref.read(watchlistProvider.notifier).updateItem(
                            mediaId: item.id,
                            status: 'PLAN_TO_WATCH',
                            progressEpisodes: 0,
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Adăugat la 'De văzut'!"),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Icon(
                    isPlanToWatch
                        ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                        : PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                    color: context.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: heroImageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (context, url) => Container(color: context.bgSurface),
                  errorWidget: (_, __, ___) => Container(color: context.bgSurface),
                ),

                // Scrim Superior (pentru butoanele de navigare)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 90,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Scrim Inferior Profund (fuziune cinematică în fundalul paginii)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 0.8, 1.0],
                        colors: [
                          Colors.transparent,
                          context.bgPrimary.withValues(alpha: 0.35),
                          context.bgPrimary.withValues(alpha: 0.85),
                          context.bgPrimary,
                        ],
                      ),
                    ),
                  ),
                ),

                // Quick CTA Trailer Button (Overlay direct peste banner în Hero)
                if (item.trailerUrl != null && item.trailerUrl!.isNotEmpty)
                  Positioned(
                    right: 20,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(item.trailerUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsFill.playCircle,
                                  color: context.accentPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Trailer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Conținut Structurat cu Ritm de Spacing Modern
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Numele Studioului (în stânga, deasupra titlului, stilizat elegant)
                if (studios.isNotEmpty) ...[
                  Text(
                    studios.first.toUpperCase(),
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // 2. Titlu Principal poziționat central pe gradient/tranziție
                Center(
                  child: Text(
                    item.title.userPreferred,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Zalando Sans Expanded',
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),

                // Subtitlu Romaji & Japoneză Kanji/Kana (centrat)
                if (secondaryTitles.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      secondaryTitles.join(' • '),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 3. Rândul de Metadate + Scor pe același rând (fără textul 'Ponderat')
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsFill.star,
                            size: 14,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scoreDisplay,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (technicalMetaList.isNotEmpty) ...[
                        Text(
                          '•',
                          style: TextStyle(color: context.textMuted, fontSize: 12),
                        ),
                        Text(
                          technicalMetaList.join(' • '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Butoane de Acțiune (Full-width când nu e în listă, sau Status + Notare când e adăugat)
                _buildActionButtonsRow(context, item),

                const SizedBox(height: 20),

                // 5. Genuri & Tag-uri
                if (item.genres.isNotEmpty || item.microTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...item.genres.map(
                        (g) => PillBadge(
                          label: g,
                          backgroundColor: context.bgSurfaceHover,
                          textColor: context.textPrimary,
                        ),
                      ),
                      ...item.microTags.map(
                        (t) => PillBadge(
                          label: t,
                          backgroundColor: context.accentPrimary.withValues(alpha: 0.14),
                          textColor: context.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],

                // 6. Sinopsis
                if (item.description != null && item.description!.isNotEmpty) ...[
                  Text(
                    'SINOPSIS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description!.replaceAll(RegExp(r'<[^>]*>'), ''),
                    maxLines: _isSynopsisExpanded ? null : 3,
                    overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textPrimary.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      height: 1.52,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _isSynopsisExpanded ? 'Arată mai puțin ▲' : 'Citește mai mult ▼',
                        style: TextStyle(
                          color: context.accentPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // 7. Tab Bar & Semnătură Watch Order
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.bgSurface,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: context.accentPrimary,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: context.onPrimary,
                    unselectedLabelColor: context.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Watch Order'),
                      Tab(text: 'Similare'),
                      Tab(text: 'Detalii'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Tab Views Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: [
              // Tab 1: Elementul Semnătură - Watch Order Tree
              watchOrderAsync.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: context.accentPrimary),
                  ),
                ),
                error: (e, st) => Center(
                  child: Text(
                    'Ghidul de vizionare nu este disponibil.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                ),
                data: (guide) {
                  if (guide == null) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Această serie este autonomă (fără franciză complexă).',
                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return WatchOrderTreeView(
                    guide: guide,
                    parentCoverImage: item.coverImage.large,
                  );
                },
              ),

              // Tab 2: Similar Anime Cards
              similarAsync.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: context.accentPrimary),
                  ),
                ),
                error: (e, st) => Center(
                  child: Text(
                    'Recomandările nu sunt disponibile.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                ),
                data: (simList) {
                  if (simList.isEmpty) {
                    return Center(
                      child: Text(
                        'Nicio recomandare similară momentan.',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                    );
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
                    itemBuilder: (context, index) => MediaCard(
                      item: simList[index],
                      width: double.infinity,
                    ),
                  );
                },
              ),

              // Tab 3: Detailed Tech Info
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(context, 'Format', item.format ?? item.type),
                    _buildInfoRow(context, 'Episoade', '${item.episodes ?? "Necunoscut"}'),
                    _buildInfoRow(context, 'Sezon / An', '${item.season ?? ""} ${item.year ?? ""}'),
                    _buildInfoRow(context, 'Status', _formatStatusText(item.status ?? 'Nespecificat')),
                    _buildInfoRow(context, 'Studio', studios.isNotEmpty ? studios.join(', ') : 'Nespecificat'),
                    _buildInfoRow(context, 'Demografie', item.demographic ?? 'General'),
                  ],
                ),
              ),
            ][_tabController.index],
          ),
        ),

        // Bottom Safe Spacing
        const SliverToBoxAdapter(child: SizedBox(height: 70)),
      ],
    );
  }

  // --- BUTOANE DE ACȚIUNE (Full-width sau Status + Notare) ---
  Widget _buildActionButtonsRow(BuildContext context, MediaItem item) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final existingRecord = watchlistAsync.maybeWhen(
      data: (list) => list.where((w) => w.mediaId == item.id).firstOrNull,
      orElse: () => null,
    );

    // 1. Cazul când seria NU este încă în listă -> Buton Full-Width "+ Adaugă în Watchlist"
    if (existingRecord == null) {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          onPressed: () => _showAddToWatchlistModal(context, item),
          icon: Icon(
            PhosphorIconsBold.bookmarkSimple,
            size: 16,
            color: context.onPrimary,
          ),
          label: Text(
            '+ Adaugă în Watchlist',
            style: TextStyle(
              color: context.onPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.accentPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            elevation: 0,
          ),
        ),
      );
    }

    // 2. Cazul când seria ESTE în listă -> Buton Status (Expanded) + Buton Notare
    final hasPersonalScore = existingRecord.score != null && existingRecord.score! > 0;
    final int currentProgress = existingRecord.progressEpisodes;

    return Row(
      children: [
        // Buton Principal Status & Episoade (Expanded)
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: () => _showAddToWatchlistModal(context, item),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                  side: BorderSide(
                    color: _getStatusColor(existingRecord.status).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsFill.bookmarkSimple,
                    size: 15,
                    color: _getStatusColor(existingRecord.status),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_getStatusLabel(existingRecord.status)} • Ep. $currentProgress${item.episodes != null && item.episodes! > 0 ? " / ${item.episodes}" : ""}',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Buton Notare (Apare automat după ce seria e în listă)
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () => _showQuickRatingSheet(context, item, existingRecord),
            icon: Icon(
              hasPersonalScore ? PhosphorIconsFill.star : PhosphorIcons.star(PhosphorIconsStyle.bold),
              size: 15,
              color: hasPersonalScore ? const Color(0xFFFBBF24) : context.textSecondary,
            ),
            label: Text(
              hasPersonalScore ? existingRecord.score!.toStringAsFixed(1) : 'Notează',
              style: TextStyle(
                color: hasPersonalScore ? context.textPrimary : context.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.bgSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL DEDICAT DE NOTARE (RATING EXCLUSIV 1.0 – 10.0) ---
  void _showQuickRatingSheet(BuildContext context, MediaItem item, WatchlistItemRecord existingRecord) {
    double currentScore = existingRecord.score ?? 8.0;

    String getScoreLabel(double s) {
      if (s <= 0) return 'Fără notă';
      if (s >= 9.5) return 'Capodoperă Absolută';
      if (s >= 8.5) return 'Excelent';
      if (s >= 7.5) return 'Foarte Bun';
      if (s >= 6.5) return 'Bun';
      if (s >= 5.5) return 'Decent';
      if (s >= 4.0) return 'Mediocru';
      return 'Slab';
    }

    Color getScoreColor(double s) {
      if (s <= 0) return Colors.grey;
      if (s >= 8.5) return const Color(0xFFFBBF24); // Gold
      if (s >= 7.0) return const Color(0xFF10B981); // Emerald
      if (s >= 5.0) return const Color(0xFF3B82F6); // Blue
      return const Color(0xFFEF4444); // Red
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderSubtle,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notează Seria',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: getScoreColor(currentScore).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.star(PhosphorIconsStyle.fill),
                              size: 14,
                              color: getScoreColor(currentScore),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${currentScore.toStringAsFixed(1)} / 10',
                              style: TextStyle(
                                color: getScoreColor(currentScore),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    getScoreLabel(currentScore),
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Slider Rating Interactiv
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: getScoreColor(currentScore),
                      inactiveTrackColor: context.bgSurfaceHover,
                      thumbColor: getScoreColor(currentScore),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: currentScore,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setModalState(() => currentScore = val);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Preset Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [10.0, 9.0, 8.5, 8.0, 7.5, 7.0, 6.0, 5.0].map((preset) {
                        final isSel = (currentScore - preset).abs() < 0.1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => currentScore = preset);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? getScoreColor(preset) : context.bgSurfaceHover,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '⭐ ${preset.toStringAsFixed(preset % 1 == 0 ? 0 : 1)}',
                                style: TextStyle(
                                  color: isSel ? Colors.black : context.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buton Salvare Notă
                  InkWell(
                    borderRadius: BorderRadius.circular(9999),
                    onTap: () async {
                      Navigator.of(sheetCtx).pop();
                      HapticFeedback.mediumImpact();
                      await ref.read(watchlistProvider.notifier).updateItem(
                            mediaId: item.id,
                            status: existingRecord.status,
                            score: currentScore,
                            progressEpisodes: existingRecord.progressEpisodes,
                          );

                      // Sincronizare automată AniList dacă este conectat
                      final anilistState = ref.read(anilistProvider);
                      if (anilistState.isConnected) {
                        final anilistId = item.anilistId ?? int.tryParse(item.id.replaceAll('anilist-', ''));
                        if (anilistId != null) {
                          await ref.read(anilistProvider.notifier).syncMedia(
                                anilistMediaId: anilistId,
                                status: existingRecord.status,
                                score: currentScore,
                                progress: existingRecord.progressEpisodes,
                              );
                        }
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              anilistState.isConnected
                                  ? 'Nota ${currentScore.toStringAsFixed(1)} a fost salvată & sincronizată pe AniList!'
                                  : 'Nota ${currentScore.toStringAsFixed(1)} a fost salvată!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.accentPrimary,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Salvează Nota',
                        style: TextStyle(
                          color: context.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL ADĂUGARE / EDITARE STATUS & EPISOADE WATCHLIST ---
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
      {'key': 'WATCHING', 'label': 'Vizionare', 'color': Color(0xFF10B981)},
      {'key': 'COMPLETED', 'label': 'Finalizat', 'color': Color(0xFF60A5FA)},
      {'key': 'PLAN_TO_WATCH', 'label': 'De Văzut', 'color': Color(0xFFF59E0B)},
      {'key': 'ON_HOLD', 'label': 'În Pauză', 'color': Color(0xFFFB923C)},
      {'key': 'DROPPED', 'label': 'Abandonat', 'color': Color(0xFFEF4444)},
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                        color: context.borderSubtle,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    existingRecord != null ? 'Editează Progresul' : 'Adaugă în Watchlist',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
                        onTap: () => setModalState(() {
                          selectedStatus = st['key'] as String;
                          if (selectedStatus == 'COMPLETED') {
                            if (totalEpisodes != null && totalEpisodes > 0) {
                              episodes = totalEpisodes;
                            } else if (item.format?.toUpperCase() == 'MOVIE' || item.type.toUpperCase() == 'MOVIE') {
                              episodes = 1;
                            }
                          } else if (selectedStatus == 'PLAN_TO_WATCH' && totalEpisodes != null && episodes == totalEpisodes) {
                            episodes = 0;
                          }
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? color : context.bgSurfaceHover,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            st['label'] as String,
                            style: TextStyle(
                              color: isSel ? Colors.black : context.textSecondary,
                              fontSize: 12.5,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Episode Stepper (Zero border)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Episoade',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: context.bgPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                    size: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$episodes / ${totalEpisodes != null && totalEpisodes > 0 ? totalEpisodes : "?"}',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: context.bgPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                    size: 14,
                                    color: context.textPrimary,
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
                        InkWell(
                          borderRadius: BorderRadius.circular(9999),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await ref.read(watchlistProvider.notifier).removeItem(item.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Eliminat din Watchlist'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9999),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9999),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await ref.read(watchlistProvider.notifier).updateItem(
                                  mediaId: item.id,
                                  status: selectedStatus,
                                  progressEpisodes: episodes,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Salvat în Watchlist!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: context.accentPrimary,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Salvează în Listă',
                              style: TextStyle(
                                color: context.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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

  String _formatStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return 'Finalizat';
      case 'RELEASING':
        return 'În Difuzare';
      case 'NOT_YET_RELEASED':
        return 'Nelansat';
      case 'CANCELLED':
        return 'Anulat';
      default:
        return status;
    }
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
        return const Color(0xFF10B981);
      case 'COMPLETED':
        return const Color(0xFF60A5FA);
      case 'PLAN_TO_WATCH':
        return const Color(0xFFF59E0B);
      case 'ON_HOLD':
        return const Color(0xFFFB923C);
      case 'DROPPED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}

/// Floating Circle Button in Liquid Glass Style (52px)
class _DetailFloatingCircleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const _DetailFloatingCircleButton({
    required this.child,
    required this.onTap,
    this.size = 52,
  });

  @override
  State<_DetailFloatingCircleButton> createState() => _DetailFloatingCircleButtonState();
}

class _DetailFloatingCircleButtonState extends State<_DetailFloatingCircleButton> {
  bool _isPressed = false;
  static final _glassFilter = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: ClipOval(
          child: BackdropFilter(
            filter: _glassFilter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPressed
                    ? context.bgSurfaceHover
                    : context.bgSurface.withValues(alpha: context.isDarkMode ? 0.75 : 0.88),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode
                          ? (_isPressed ? 0.35 : 0.20)
                          : (_isPressed ? 0.10 : 0.05),
                    ),
                    blurRadius: _isPressed ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

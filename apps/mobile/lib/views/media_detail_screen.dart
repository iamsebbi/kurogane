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
import '../widgets/floating_circle_button.dart';
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
    final cleanDescription = item.description != null
        ? item.description!.replaceAll(RegExp(r'<[^>]*>'), '').trim()
        : '';
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.44).clamp(340.0, 450.0);

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

    // Metadate tehnice curate (fără formatul/canalul de difuzare TV)
    final technicalMetaList = <String>[];
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
          expandedHeight: heroHeight,
          pinned: true,
          stretch: true,
          backgroundColor: context.bgPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 76,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: FloatingCircleButton(
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
                child: FloatingCircleButton(
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
                          Icon(
                            PhosphorIconsFill.star,
                            size: 14,
                            color: context.scoreGold,
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
                if (cleanDescription.isNotEmpty) ...[
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
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: Text(
                      cleanDescription,
                      maxLines: _isSynopsisExpanded ? null : 3,
                      overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimary.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        height: 1.52,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isSynopsisExpanded = !_isSynopsisExpanded);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isSynopsisExpanded ? 'Arată mai puțin' : 'Citește mai mult',
                            style: TextStyle(
                              color: context.accentPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 5),
                          AnimatedRotation(
                            turns: _isSynopsisExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                              size: 13,
                              color: context.accentPrimary,
                            ),
                          ),
                        ],
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
                    _buildInfoRow(
                      context,
                      'Format',
                      (item.format != null && item.format!.isNotEmpty)
                          ? item.format!
                          : (item.type.isNotEmpty ? item.type : 'Nespecificat'),
                    ),
                    _buildInfoRow(
                      context,
                      'Episoade',
                      item.episodes != null && item.episodes! > 0 ? '${item.episodes}' : 'Necunoscut',
                    ),
                    _buildInfoRow(
                      context,
                      'Sezon / An',
                      '${item.season ?? ""} ${item.year ?? ""}'.trim().isNotEmpty
                          ? '${item.season ?? ""} ${item.year ?? ""}'.trim()
                          : 'Nespecificat',
                    ),
                    _buildInfoRow(context, 'Status', _formatStatusText(item.status ?? 'Nespecificat')),
                    _buildInfoRow(context, 'Studio', studios.isNotEmpty ? studios.join(', ') : 'Nespecificat'),
                    if (item.demographic != null && item.demographic!.trim().isNotEmpty)
                      _buildInfoRow(context, 'Demografie', item.demographic!.trim()),
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
                    color: _getStatusColor(context, existingRecord.status).withValues(alpha: 0.5),
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
                    color: _getStatusColor(context, existingRecord.status),
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
            onPressed: () => _showAddToWatchlistModal(context, item),
            icon: Icon(
              hasPersonalScore ? PhosphorIconsFill.star : PhosphorIcons.star(PhosphorIconsStyle.bold),
              size: 15,
              color: hasPersonalScore ? context.scoreGold : context.textSecondary,
            ),
            label: Text(
              hasPersonalScore ? '${existingRecord.score!.round()} / 10' : 'Notează',
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

  // --- MODAL UNIFICAT: STATUS, PROGRES EPISOADE & NOTĂ 1-10 ---
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
    String? startedAt = existingRecord?.startedAt;
    String? completedAt = existingRecord?.completedAt;

    // Scorul inițial al utilizatorului (rotunjit 1..10, sau 0 pentru Fără Notă)
    int userScore = (existingRecord?.score != null && existingRecord!.score! > 0)
        ? existingRecord.score!.round().clamp(1, 10)
        : 0;

    // Scorul implicit inteligent calculat din media seriei dacă utilizatorul apasă + de la 0
    final animeAvg = (item.scores.weightedScore > 0 ? item.scores.weightedScore : item.scores.averageScore);
    final defaultSmartScore = animeAvg > 0
        ? (animeAvg > 10 ? (animeAvg / 10).round() : animeAvg.round()).clamp(1, 10)
        : 8;

    String formatDateShort(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '--';
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return dateStr;
      const months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    Future<void> pickDate({
      required BuildContext ctx,
      required String? currentDateStr,
      required Function(String?) onSelected,
    }) async {
      final now = DateTime.now();
      final initial = (currentDateStr != null ? DateTime.tryParse(currentDateStr) : null) ?? now;
      final picked = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime(1970),
        lastDate: DateTime(now.year + 5),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: context.accentPrimary,
                onPrimary: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                surface: context.bgSurface,
                onSurface: context.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        onSelected(picked.toIso8601String().split('T').first);
      }
    }

    final statuses = [
      {'key': 'WATCHING', 'label': 'Vizionare', 'color': context.signalLive},
      {'key': 'COMPLETED', 'label': 'Finalizat', 'color': const Color(0xFF60A5FA)},
      {'key': 'PLAN_TO_WATCH', 'label': 'De Văzut', 'color': const Color(0xFFA78BFA)},
      {'key': 'ON_HOLD', 'label': 'În Pauză', 'color': const Color(0xFFFB923C)},
      {'key': 'DROPPED', 'label': 'Abandonat', 'color': context.error},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool autoCompletedEpisodes = false;
        bool episodesIncreasing = true;
        bool scoreIncreasing = true;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.paddingOf(modalCtx).bottom),
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
                    const SizedBox(height: 14),

                    Text(
                      existingRecord != null ? 'Editează Seria' : 'Adaugă în Watchlist',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status chips (Discrete semantic dot for unselected, solid fill for selected)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statuses.map((st) {
                        final isSel = selectedStatus == st['key'];
                        final color = st['color'] as Color;
                        final bool isLightColor = color.computeLuminance() > 0.4;
                        final Color isSelTextColor = isLightColor ? const Color(0xFF141414) : Colors.white;

                        return GestureDetector(
                          onTap: () => setModalState(() {
                            selectedStatus = st['key'] as String;
                            final todayStr = DateTime.now().toIso8601String().split('T').first;
                            if (selectedStatus == 'WATCHING') {
                              startedAt ??= todayStr;
                            } else if (selectedStatus == 'COMPLETED') {
                              startedAt ??= todayStr;
                              completedAt ??= todayStr;
                              int targetEp = episodes;
                              if (totalEpisodes != null && totalEpisodes > 0) {
                                targetEp = totalEpisodes;
                              } else if (item.format?.toUpperCase() == 'MOVIE' || item.type.toUpperCase() == 'MOVIE') {
                                targetEp = 1;
                              }
                              if (targetEp != episodes) {
                                episodesIncreasing = targetEp >= episodes;
                                episodes = targetEp;
                                autoCompletedEpisodes = true;
                                HapticFeedback.mediumImpact();
                                Future.delayed(const Duration(milliseconds: 750), () {
                                  if (modalCtx.mounted) {
                                    setModalState(() => autoCompletedEpisodes = false);
                                  }
                                });
                              }
                            } else if (selectedStatus == 'PLAN_TO_WATCH' && totalEpisodes != null && episodes == totalEpisodes) {
                              episodesIncreasing = false;
                              episodes = 0;
                            }
                          }),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? color : context.bgSurfaceHover,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: isSel ? color : context.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSel)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Icon(
                                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                                      size: 13,
                                      color: isSelTextColor,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      width: 6.5,
                                      height: 6.5,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                Text(
                                  st['label'] as String,
                                  style: TextStyle(
                                    color: isSel ? isSelTextColor : context.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // 1. Header & Stepper: Progres Episoade
                    Text(
                      'Progres Episoade',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: autoCompletedEpisodes
                            ? const Color(0xFF60A5FA).withValues(alpha: 0.16)
                            : context.bgSurfaceHover,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: autoCompletedEpisodes
                              ? const Color(0xFF60A5FA).withValues(alpha: 0.65)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Minus button (Left)
                          GestureDetector(
                            onTap: () {
                              if (episodes > 0) {
                                HapticFeedback.selectionClick();
                                setModalState(() {
                                  episodesIncreasing = false;
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: context.bgPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                  size: 16,
                                  color: episodes > 0 ? context.textPrimary : context.textMuted,
                                ),
                              ),
                            ),
                          ),

                          // Center Value: Only the updating episodes digit animates vertically
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (autoCompletedEpisodes) ...[
                                Icon(
                                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                  size: 14,
                                  color: const Color(0xFF60A5FA),
                                ),
                                const SizedBox(width: 4),
                              ],
                              SizedBox(
                                height: 36,
                                child: Center(
                                  child: ClipRect(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      transitionBuilder: (child, animation) {
                                        final key = child.key;
                                        final bool isIncoming = key is ValueKey<int> && key.value == episodes;
                                        final double beginY = episodesIncreasing
                                            ? (isIncoming ? 1.0 : -1.0)
                                            : (isIncoming ? -1.0 : 1.0);
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(0, beginY),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            )),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        '$episodes',
                                        key: ValueKey<int>(episodes),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: autoCompletedEpisodes ? const Color(0xFF60A5FA) : context.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                ' / ${totalEpisodes != null && totalEpisodes > 0 ? totalEpisodes : "?"}',
                                style: TextStyle(
                                  color: autoCompletedEpisodes ? const Color(0xFF60A5FA) : context.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),

                          // Plus button (Right)
                          GestureDetector(
                            onTap: () {
                              if (totalEpisodes == null || totalEpisodes == 0 || episodes < totalEpisodes) {
                                HapticFeedback.selectionClick();
                                setModalState(() {
                                  episodesIncreasing = true;
                                  episodes++;
                                  if (totalEpisodes != null && totalEpisodes > 0 && episodes >= totalEpisodes) {
                                    selectedStatus = 'COMPLETED';
                                  }
                                });
                              }
                            },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: (totalEpisodes == null || totalEpisodes == 0 || episodes < totalEpisodes)
                                    ? context.textPrimary
                                    : context.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Header & Stepper: Nota Ta (1 - 10)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userScore > 0 ? PhosphorIconsFill.star : PhosphorIcons.star(PhosphorIconsStyle.bold),
                        size: 14,
                        color: userScore > 0 ? context.scoreGold : context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nota Ta',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Minus button (Left)
                        GestureDetector(
                          onTap: () {
                            if (userScore > 0) {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                scoreIncreasing = false;
                                if (userScore > 1) {
                                  userScore--;
                                } else {
                                  userScore = 0; // Revine la Fără notă
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: userScore > 0 ? context.textPrimary : context.textMuted,
                              ),
                            ),
                          ),
                        ),

                        // Center Value: Only the updating rating score animates vertically
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 36,
                              child: Center(
                                child: ClipRect(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) {
                                      final key = child.key;
                                      final bool isIncoming = key is ValueKey<int> && key.value == userScore;
                                      final double beginY = scoreIncreasing
                                          ? (isIncoming ? 1.0 : -1.0)
                                          : (isIncoming ? -1.0 : 1.0);
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset(0, beginY),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      userScore > 0 ? '$userScore' : 'Fără notă',
                                      key: ValueKey<int>(userScore),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: userScore > 0 ? context.textPrimary : context.textMuted,
                                        fontSize: userScore > 0 ? 15 : 14.5,
                                        fontWeight: userScore > 0 ? FontWeight.w700 : FontWeight.w600,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (userScore > 0)
                              Text(
                                ' / 10',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                          ],
                        ),

                        // Plus button (Right)
                        GestureDetector(
                          onTap: () {
                            if (userScore < 10) {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                scoreIncreasing = true;
                                if (userScore == 0) {
                                  userScore = defaultSmartScore;
                                } else {
                                  userScore++;
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: userScore < 10 ? context.textPrimary : context.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Headers & Buttons: Data Început & Data Sfârșit
                  Row(
                    children: [
                      // Data Început Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
                                  size: 14,
                                  color: startedAt != null ? context.signalLive : context.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Data Început',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                await pickDate(
                                  ctx: modalCtx,
                                  currentDateStr: startedAt,
                                  onSelected: (date) => setModalState(() => startedAt = date),
                                );
                              },
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceHover,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDateShort(startedAt),
                                        style: TextStyle(
                                          color: startedAt != null ? context.textPrimary : context.textMuted,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (startedAt != null)
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => startedAt = null);
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: context.bgPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              PhosphorIcons.x(PhosphorIconsStyle.bold),
                                              size: 13,
                                              color: context.textMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                                        size: 14,
                                        color: context.textMuted,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Data Sfârșit Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.flagCheckered(PhosphorIconsStyle.bold),
                                  size: 14,
                                  color: completedAt != null ? context.scoreGold : context.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Data Sfârșit',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                await pickDate(
                                  ctx: modalCtx,
                                  currentDateStr: completedAt,
                                  onSelected: (date) => setModalState(() => completedAt = date),
                                );
                              },
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceHover,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDateShort(completedAt),
                                        style: TextStyle(
                                          color: completedAt != null ? context.textPrimary : context.textMuted,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (completedAt != null)
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => completedAt = null);
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: context.bgPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              PhosphorIcons.x(PhosphorIconsStyle.bold),
                                              size: 13,
                                              color: context.textMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                                        size: 14,
                                        color: context.textMuted,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Actions: Save & optional Remove
                  Row(
                    children: [
                      if (existingRecord != null) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(9999),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            HapticFeedback.mediumImpact();
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
                            HapticFeedback.mediumImpact();

                            final double finalScoreToSave = userScore > 0 ? userScore.toDouble() : 0.0;
                            await ref.read(watchlistProvider.notifier).updateItem(
                                  mediaId: item.id,
                                  status: selectedStatus,
                                  progressEpisodes: episodes,
                                  score: finalScoreToSave,
                                  startedAt: startedAt,
                                  completedAt: completedAt,
                                );

                            // Sincronizare automată AniList dacă este conectat
                            final anilistState = ref.read(anilistProvider);
                            if (anilistState.isConnected) {
                              final anilistId = item.anilistId ?? int.tryParse(item.id.replaceAll('anilist-', ''));
                              if (anilistId != null) {
                                await ref.read(anilistProvider.notifier).syncMedia(
                                      anilistMediaId: anilistId,
                                      status: selectedStatus,
                                      score: userScore > 0 ? userScore.toDouble() : null,
                                      progress: episodes,
                                      startedAt: startedAt,
                                      completedAt: completedAt,
                                    );
                              }
                            }

                            if (!context.mounted) return;
                            final String syncSuffix = anilistState.isConnected ? ' & sincronizat pe AniList' : '';
                            final String msg = userScore > 0
                                ? 'Salvat în Watchlist (Nota $userScore/10)$syncSuffix!'
                                : 'Salvat în Watchlist$syncSuffix!';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
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

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'WATCHING':
        return context.signalLive;
      case 'COMPLETED':
        return const Color(0xFF60A5FA);
      case 'PLAN_TO_WATCH':
        return context.scoreGold;
      case 'ON_HOLD':
        return const Color(0xFFFB923C);
      case 'DROPPED':
        return context.error;
      default:
        return context.textMuted;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/media_status_helper.dart';
import '../models/media_item.dart';
import '../models/watchlist_item.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/pill_badge.dart';
import '../widgets/media_relations_view.dart';
import '../widgets/floating_circle_button.dart';
import '../widgets/horizontal_poster_carousel.dart';
import '../widgets/section_header.dart';
import '../widgets/community_metrics_card.dart';
import '../widgets/cast_and_staff_view.dart';
import '../widgets/theme_songs_view.dart';
import '../widgets/watchlist_edit_modal.dart';
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
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaDetailProvider(widget.mediaId));
    final similarAsync = ref.watch(similarMediaProvider(widget.mediaId));

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: mediaAsync.when(
        loading: () => widget.initialItem != null
            ? _buildDetailContent(widget.initialItem!, similarAsync)
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
                  '${AppStrings.errorPrefix} loading title',
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
                'Title not found',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          return _buildDetailContent(item, similarAsync);
        },
      ),
    );
  }

  Widget _buildDetailContent(
    MediaItem item,
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
      technicalMetaList.add('${item.episodes} ${item.episodes == 1 ? "Episode" : "Episodes"}');
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

    return RefreshIndicator(
      color: context.accentPrimary,
      backgroundColor: context.bgSurface,
      onRefresh: () async {
        ref.invalidate(mediaDetailProvider(widget.mediaId));
        ref.invalidate(watchOrderProvider(widget.mediaId));
        ref.invalidate(similarMediaProvider(widget.mediaId));
        try {
          await ref.read(mediaDetailProvider(widget.mediaId).future);
        } catch (_) {}
      },
      child: CustomScrollView(
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
                          content: Text("Removed from 'Plan to Watch'"),
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
                          content: Text("Added to 'Plan to Watch'!"),
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

                // Quick CTA Trailer Button (Floating Glass Pill Button cu Play Triangle + Text)
                if (item.trailerUrl != null && item.trailerUrl!.isNotEmpty)
                  Positioned(
                    right: 20,
                    bottom: 22,
                    child: FloatingPillButton(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      onTap: () async {
                        final uri = Uri.parse(item.trailerUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsFill.play,
                            color: context.accentPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trailer',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
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
                    AppStrings.synopsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            _isSynopsisExpanded ? AppStrings.readLess : AppStrings.readMore,
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

                const SizedBox(height: 18),

                // 7. Tab Bar Scrollabil (Pill Navigation)
                Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.bgSurface,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    padding: EdgeInsets.zero,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    enableFeedback: false,
                    onTap: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {});
                    },
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
                      Tab(text: 'Relations'),
                      Tab(text: 'Characters'),
                      Tab(text: 'Music'),
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey<int>(_tabController.index),
                child: [
              // Tab 0: Relații Oficiale Franciză (Prequel, Sequel, Side Stories, etc.)
              MediaRelationsView(
                relations: item.relations,
                currentMediaId: item.id,
              ),

              // Tab 1: Distribuție & Staff (Voice Actors as Character + Production Staff)
              CastAndStaffView(
                characters: item.characters,
                staff: item.staff,
              ),

              // Tab 2: Teme Muzicale (Piese Opening & Ending)
              ThemeSongsView(
                themes: item.themes,
              ),
            ][_tabController.index],
          ),
        ),
      ),
    ),

        // 4. Secțiune Dedicată Recomandări Similare (Carusel Orizontal Fluid & Compact)
        SliverToBoxAdapter(
          child: similarAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (simList) {
              if (simList.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Similar Recommendations',
                    icon: PhosphorIcons.sparkle(PhosphorIconsStyle.bold),
                    trailing: Text(
                      AppStrings.titlesCount(simList.length),
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    fontSize: 15,
                    useZalandoFont: false,
                  ),
                  HorizontalPosterCarousel(
                    items: simList,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              );
            },
          ),
        ),

        // 4.5. Statistici & Comunitate (Mutat după secțiunea de recomandări)
        if (item.communityMetrics != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: CommunityMetricsCard(
                metrics: item.communityMetrics!,
                averageScore: score > 0 ? (score > 10 ? score / 10 : score) : null,
              ),
            ),
          ),

        // 5. Detalii (Secțiunea Finală a Paginii)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  'Format',
                  (item.format != null && item.format!.isNotEmpty)
                      ? item.format!
                      : (item.type.isNotEmpty ? item.type : 'Unspecified'),
                ),
                _buildInfoRow(
                  context,
                  'Episodes',
                  item.episodes != null && item.episodes! > 0 ? '${item.episodes}' : 'Unknown',
                ),
                _buildInfoRow(
                  context,
                  AppStrings.startDate,
                  item.startDate != null && item.startDate!.isNotEmpty
                      ? item.startDate!.formatDisplay()
                      : 'Unspecified',
                ),
                _buildInfoRow(
                  context,
                  AppStrings.endDate,
                  item.endDate != null && item.endDate!.isNotEmpty
                      ? item.endDate!.formatDisplay()
                      : (item.status == 'RELEASING' ? 'Airing' : 'Unspecified'),
                ),
                if (item.adaptationSource != null && item.adaptationSource!.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'Source',
                    _formatSourceText(item.adaptationSource!),
                  ),
                _buildInfoRow(
                  context,
                  'Season / Year',
                  '${item.season ?? ""} ${item.year ?? ""}'.trim().isNotEmpty
                      ? '${item.season ?? ""} ${item.year ?? ""}'.trim()
                      : 'Unspecified',
                ),
                _buildInfoRow(context, 'Status', _formatStatusText(item.status ?? 'Unspecified')),
                _buildInfoRow(
                  context,
                  'Studio',
                  studios.isNotEmpty ? studios.join(', ') : 'Unspecified',
                  isLast: item.demographic == null || item.demographic!.trim().isEmpty,
                ),
                if (item.demographic != null && item.demographic!.trim().isNotEmpty)
                  _buildInfoRow(context, 'Demographic', item.demographic!.trim(), isLast: true),
              ],
            ),
          ),
        ),

        // Bottom Safe Spacing
        const SliverToBoxAdapter(child: SizedBox(height: 70)),
      ],
    ),
    );
  }

  // --- BUTOANE DE ACȚIUNE (Full-width sau Status + Notare) ---
  Widget _buildActionButtonsRow(BuildContext context, MediaItem item) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final existingRecord = watchlistAsync.maybeWhen(
      data: (list) => list.where((w) => w.mediaId == item.id).firstOrNull,
      orElse: () => null,
    );

    // 1. Cazul când seria NU este încă în listă -> Buton Full-Width "Add to Watchlist" cu haptic & feedback vizual
    if (existingRecord == null) {
      return _InteractiveActionButton(
        onTap: () => _showAddToWatchlistModal(context, item),
        backgroundColor: context.accentPrimary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.plus(PhosphorIconsStyle.bold),
              size: 16,
              color: context.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.addToWatchlist,
              style: TextStyle(
                color: context.onPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ],
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
          child: _InteractiveActionButton(
            onTap: () => _showAddToWatchlistModal(context, item),
            backgroundColor: context.bgSurface,
            border: BorderSide(
              color: _getStatusColor(context, existingRecord.status).withValues(alpha: 0.5),
              width: 1.2,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(existingRecord.status),
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
        _InteractiveActionButton(
          onTap: () => _showAddToWatchlistModal(context, item),
          backgroundColor: context.bgSurface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPersonalScore ? PhosphorIconsFill.star : PhosphorIcons.star(PhosphorIconsStyle.bold),
                  size: 15,
                  color: hasPersonalScore ? context.scoreGold : context.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  hasPersonalScore ? '${existingRecord.score!.round()} / 10' : 'Score',
                  style: TextStyle(
                    color: hasPersonalScore ? context.textPrimary : context.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            color: context.borderSubtle.withValues(alpha: 0.35),
          ),
      ],
    );
  }

  // --- MODAL UNIFICAT: STATUS, PROGRES EPISOADE & NOTĂ 1-10 ---
  void _showAddToWatchlistModal(BuildContext context, MediaItem item) {
    showWatchlistEditModal(context, ref, item: item);
  }

  String _formatSourceText(String raw) {
    switch (raw.toUpperCase()) {
      case 'MANGA':
        return 'Manga';
      case 'LIGHT_NOVEL':
        return 'Light Novel';
      case 'VISUAL_NOVEL':
        return 'Visual Novel';
      case 'VIDEO_GAME':
        return 'Video Game';
      case 'ORIGINAL':
        return 'Original Work';
      case 'NOVEL':
        return 'Novel';
      case 'DOUJINSHI':
        return 'Doujinshi';
      case 'ANIME':
        return 'Anime';
      case 'WEB_NOVEL':
        return 'Web Novel';
      case 'OTHER':
        return 'Other Source';
      default:
        return raw;
    }
  }

  String _formatStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return 'Finished';
      case 'RELEASING':
        return 'Airing';
      case 'NOT_YET_RELEASED':
        return 'Upcoming';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getStatusLabel(String status) => MediaStatusHelper.getLabel(status);

  Color _getStatusColor(BuildContext context, String status) =>
      MediaStatusHelper.getColor(context, status);

  IconData _getStatusIcon(String status) => MediaStatusHelper.getIcon(status);
}

/// Buton de acțiune interactiv cu feedback haptic și micro-scale vizual tactil
class _InteractiveActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color backgroundColor;
  final BorderSide? border;

  const _InteractiveActionButton({
    required this.onTap,
    required this.child,
    required this.backgroundColor,
    this.border,
  });

  @override
  State<_InteractiveActionButton> createState() => _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isPressed = false;

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
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          height: 46.0,
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.backgroundColor.withValues(alpha: 0.85)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(9999),
            border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}


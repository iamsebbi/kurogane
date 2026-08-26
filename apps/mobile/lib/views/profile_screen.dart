import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import '../models/watchlist_item.dart';
import '../providers/anilist_provider.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/pill_badge.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'media_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String _defaultCoverImage =
      'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=85';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Dacă utilizatorul nu este conectat, afișăm ecranul dedicat de Autentificare
    if (user == null) {
      return _buildUnauthenticatedGate(context, ref);
    }

    final displayName = user.displayName != null && user.displayName!.isNotEmpty
        ? user.displayName!
        : (user.email?.split('@')[0] ?? 'Membru Kurogane');

    final username = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!.toLowerCase().replaceAll(' ', '_')
        : (user.email?.split('@')[0] ?? 'membru');

    // Date Live din Watchlist (Sincronizate automat cu orice acțiune din aplicație)
    final watchlistAsync = ref.watch(watchlistProvider);
    final List<WatchlistItemRecord> watchlist = watchlistAsync.value ?? [];

    // Stare AniList Sync
    final anilistState = ref.watch(anilistProvider);

    // Statistici calculate dinamic
    final int completedCount = watchlist.where((i) => i.status == 'COMPLETED').length;
    final int watchingCount = watchlist.where((i) => i.status == 'WATCHING').length;
    final int totalEpisodes = watchlist.fold<int>(0, (sum, i) => sum + i.progressEpisodes);

    final scoredItems = watchlist.where((i) => i.score != null && i.score! > 0).toList();
    final String avgScoreStr = scoredItems.isNotEmpty
        ? (scoredItems.fold<double>(0.0, (sum, i) => sum + i.score!) / scoredItems.length).toStringAsFixed(1)
        : '—';

    // Genuri favorite calculate dinamic din anime-urile din listă
    final Map<String, int> genreCounts = {};
    for (final item in watchlist) {
      if (item.mediaItem?.genres != null) {
        for (final g in item.mediaItem!.genres) {
          genreCounts[g] = (genreCounts[g] ?? 0) + 1;
        }
      }
    }
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<String> userTags = sortedGenres.isNotEmpty
        ? sortedGenres.take(4).map((e) => '#${e.key}').toList()
        : ['#Shonen', '#Fantasy', '#AnimeLover', '#Kurogane'];

    // Imagine de cover dinamică: dacă userul are anime-uri, folosim banner-ul primului anime
    final dynamicCover = watchlist.isNotEmpty && watchlist.first.mediaItem?.bannerImage != null
        ? watchlist.first.mediaItem!.bannerImage!
        : _defaultCoverImage;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: RefreshIndicator(
        color: context.accentPrimary,
        backgroundColor: context.bgSurface,
        onRefresh: () async {
          await ref.read(watchlistProvider.notifier).fetchWatchlist();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // 1. Hero Header cu Imagine mare & Gradient Fade
            _buildSliverHeader(context, ref, user, dynamicCover),

            // 2. Conținut Profil (Creator Card Layout)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Nume + Username + Badge Acțiune
                    _buildIdentitySection(context, displayName, username),

                    const SizedBox(height: 24),

                    // Rând de Statistici Inline Live (Sincronizat cu Watchlist)
                    _buildInlineStatsRow(
                      context,
                      completedCount: completedCount,
                      watchingCount: watchingCount,
                      totalEpisodes: totalEpisodes,
                      avgScore: avgScoreStr,
                    ),

                    const SizedBox(height: 28),

                    // Secțiune Bio / Citat & Tag-uri dinamice
                    _buildBioSection(context, userTags),

                    const SizedBox(height: 28),

                    // Buton Principal CTA Gradient (Edit Profile)
                    _buildPrimaryCtaButton(context, ref, user, displayName),

                    const SizedBox(height: 36),

                    // Secțiune "Conturi Conectate" (Sincronizare AniList 2-Way)
                    _buildConnectedAccountsSection(context, ref, anilistState),

                    const SizedBox(height: 36),

                    // Secțiune "Activitate Recentă" (Anime-uri reale din Watchlist-ul utilizatorului)
                    _buildRecentActivitySection(context, watchlist, watchlistAsync.isLoading),

                    const SizedBox(height: 28),

                    // Buton Deconectare
                    _buildLogoutButton(context, ref),

                    // Spațiere generoasă pentru Floating Navigation Bar
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ECRAN PENTRU UTILIZATORI NEAUTENTIFICAȚI (AUTH GATEKEEPER) ---
  Widget _buildUnauthenticatedGate(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.of(context).canPop())
                    _ProfileFloatingCircleButton(
                      size: 52,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                        color: context.textPrimary,
                        size: 23,
                      ),
                    )
                  else
                    const SizedBox(width: 52, height: 52),
                  _ProfileFloatingCircleButton(
                    size: 52,
                    onTap: () => _showSettingsSheet(context, ref, true),
                    child: Icon(
                      PhosphorIcons.gear(PhosphorIconsStyle.bold),
                      color: context.textPrimary,
                      size: 23,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Icon Simplu Phosphor
                    Icon(
                      PhosphorIcons.userCircle(PhosphorIconsStyle.regular),
                      size: 72,
                      color: context.textPrimary,
                    ),

                    const SizedBox(height: 24),

                    // Titlu
                    Text(
                      'Autentificare Necesară',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitlu explicativ
                    Text(
                      'Conectează-te pentru a-ți accesa profilul și lista de anime-uri sincronizată.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Lista caracteristici
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                      title: 'Watchlist Sincronizat Live',
                    ),
                    const SizedBox(height: 18),
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                      title: 'Statistici & Episoade Urmărite',
                    ),
                    const SizedBox(height: 18),
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.bold),
                      title: 'Notificări Episoade Noi',
                    ),

                    const SizedBox(height: 42),

                    // Buton Principal Conectare
                    _InteractiveScaleButton(
                      onTap: () => LoginScreen.show(context),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.accentPrimary,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Conectează-te la cont',
                          style: TextStyle(
                            color: context.onPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Buton Secundar Înregistrare
                    _InteractiveScaleButton(
                      onTap: () => RegisterScreen.show(context),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: context.borderSubtle),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Creează un cont nou',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.bgSurfaceHover,
          ),
          child: Center(
            child: Icon(
              icon,
              color: context.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // --- 1. SLIVER APP BAR HERO HEADER (PENTRU MEMBRII CONECTAȚI) ---
  Widget _buildSliverHeader(
    BuildContext context,
    WidgetRef ref,
    fb.User user,
    String coverImageUrl,
  ) {
    final double headerHeight = MediaQuery.of(context).size.height * 0.42;

    return SliverAppBar(
      expandedHeight: headerHeight.clamp(320.0, 420.0),
      pinned: true,
      stretch: true,
      backgroundColor: context.bgPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 76,
      leading: Navigator.of(context).canPop()
          ? Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Center(
                child: _ProfileFloatingCircleButton(
                  size: 52,
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    color: context.textPrimary,
                    size: 23,
                  ),
                ),
              ),
            )
          : null,
      actions: [
        // Buton Setări ⚙️ (52px floating button)
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Center(
            child: _ProfileFloatingCircleButton(
              size: 52,
              onTap: () => _showSettingsSheet(context, ref, false),
              child: Icon(
                PhosphorIcons.gear(PhosphorIconsStyle.bold),
                color: context.textPrimary,
                size: 23,
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
            // Imagine de fundal Portrait / Banner
            CachedNetworkImage(
              imageUrl: coverImageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (context, url) => Container(color: context.bgSurface),
              errorWidget: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.accentPrimary.withValues(alpha: 0.8),
                      const Color(0xFF1E293B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.user(PhosphorIconsStyle.bold),
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

            // Gradient de sus pentru contrast butoane AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 110,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Gradient de jos pentru tranzitie lina spre bgPrimary
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 0.80, 1.0],
                    colors: [
                      Colors.transparent,
                      context.bgPrimary.withValues(alpha: 0.45),
                      context.bgPrimary.withValues(alpha: 0.88),
                      context.bgPrimary,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. SECȚIUNE IDENTITATE (NUME + HANDLE + BADGE) ---
  Widget _buildIdentitySection(
    BuildContext context,
    String displayName,
    String username,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nume Utilizator + Dot de Status Online
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8.5,
                    height: 8.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xCC4ADE80),
                          blurRadius: 7,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Handle (@username) + Badge Verificat
              Row(
                children: [
                  Text(
                    '@$username',
                    style: TextStyle(
                      color: context.textSecondary.withValues(alpha: 0.85),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PillBadge(
                    label: 'MEMBRU VERIFICAT',
                    fontSize: 9,
                    backgroundColor: context.accentPrimary.withValues(alpha: 0.15),
                    textColor: context.accentPrimary,
                    borderColor: context.accentPrimary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Buton Circular de Identitate / Mențiuni (@)
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.at(PhosphorIconsStyle.bold),
              color: context.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. RÂND STATISTICI INLINE (SINCRONIZATE DIN WATCHLIST) ---
  Widget _buildInlineStatsRow(
    BuildContext context, {
    required int completedCount,
    required int watchingCount,
    required int totalEpisodes,
    required String avgScore,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInlineStatItem(context, '$completedCount', 'Completate'),
          _buildVerticalStatDivider(context),
          _buildInlineStatItem(context, '$watchingCount', 'În Curs'),
          _buildVerticalStatDivider(context),
          _buildInlineStatItem(context, '$totalEpisodes', 'Episoade'),
          _buildVerticalStatDivider(context),
          _buildInlineStatItem(context, avgScore, 'Scor Mediu'),
        ],
      ),
    );
  }

  Widget _buildInlineStatItem(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Zalando Sans Expanded',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary.withValues(alpha: 0.75),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: context.borderSubtle.withValues(alpha: 0.7),
    );
  }

  // --- 4. SECȚIUNE BIO, MOTTO & TAG-URI DINAMICE ---
  Widget _buildBioSection(BuildContext context, List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Citat / Motto Italic
        Text(
          '„Un nou capitol în fiecare sezon.”',
          style: TextStyle(
            fontSize: 16.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 10),

        // Descriere / Detalii Profil
        Text(
          'Anime & Manga Enthusiast • Membru Kurogane Universe\nSincronizat live pe mobil & AniList.',
          style: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.85),
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 16),

        // Tag-uri rotunjite (calculate dinamic din preferințe)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((t) => _buildInterestTag(context, t)).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.borderSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.textPrimary.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- 5. BUTON PRINCIPAL CTA GRADIENT (EDIT PROFILE) ---
  Widget _buildPrimaryCtaButton(
    BuildContext context,
    WidgetRef ref,
    fb.User user,
    String currentDisplayName,
  ) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5), // Indigo Radiant
            Color(0xFF9333EA), // Purple
            Color(0xFFEA580C), // Orange Flame
            Color(0xFFF59E0B), // Amber Gold
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => _showEditProfileSheet(context, ref, user, currentDisplayName),
          child: const Center(
            child: Text(
              'EDITEAZĂ PROFILUL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 6. SECȚIUNE CONTURI CONECTATE (ANILIST 2-WAY SYNC) ---
  Widget _buildConnectedAccountsSection(
    BuildContext context,
    WidgetRef ref,
    AnilistState anilistState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Conturi Conectate',
              style: TextStyle(
                fontFamily: 'Zalando Sans Expanded',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '2-Way Sync',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // AniList Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: anilistState.isConnected
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                  : context.borderSubtle,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Logo / Avatar AniList
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: anilistState.isConnected && anilistState.user?.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: anilistState.user!.avatarUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFF2B2D42),
                            child: const Center(
                              child: Text(
                                'AL',
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),

                  // Detalii Conexiune
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anilistState.isConnected
                              ? '@${anilistState.user!.name}'
                              : 'AniList Account',
                          style: TextStyle(
                            fontFamily: 'Zalando Sans Expanded',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          anilistState.isConnected
                              ? '✓ Sincronizare 2-Way Activă'
                              : 'Sincronizează notele și progresul mondial',
                          style: TextStyle(
                            color: anilistState.isConnected
                                ? const Color(0xFF10B981)
                                : context.textSecondary,
                            fontSize: 12,
                            fontWeight: anilistState.isConnected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Buton Conectare / Deconectare
                  if (!anilistState.isConnected)
                    ElevatedButton(
                      onPressed: () => _showAnilistConnectModal(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Conectează',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.linkBreak(PhosphorIconsStyle.bold),
                        color: AppColors.alertCoral,
                        size: 20,
                      ),
                      onPressed: () async {
                        await ref.read(anilistProvider.notifier).disconnect();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Te-ai deconectat de la AniList.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),

              // Acțiuni suplimentare când este conectat: 1-Click Import
              if (anilistState.isConnected) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: context.borderSubtle),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Importă anime-urile din AniList',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: anilistState.isSyncing
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              final count = await ref
                                  .read(anilistProvider.notifier)
                                  .importCollectionToKurogane();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Au fost importate $count anime-uri din AniList!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      icon: anilistState.isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                              size: 14,
                              color: const Color(0xFF3B82F6),
                            ),
                      label: Text(
                        anilistState.isSyncing ? 'Se importă...' : '1-Click Sync',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- 7. SECȚIUNE ACTIVITATE RECENTĂ (ANIME-URI REALE DIN WATCHLIST) ---
  Widget _buildRecentActivitySection(
    BuildContext context,
    List<WatchlistItemRecord> watchlist,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activitate Recentă',
              style: TextStyle(
                fontFamily: 'Zalando Sans Expanded',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (watchlist.isNotEmpty)
              Text(
                '${watchlist.length} titluri',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (isLoading && watchlist.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (watchlist.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                  size: 40,
                  color: context.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Niciun anime în listă încă',
                  style: TextStyle(
                    fontFamily: 'Zalando Sans Expanded',
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Adaugă anime-uri în Watchlist din ecranul Explorează sau Acasă pentru a-ți urmări progresul aici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: watchlist.take(6).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.40,
            ),
            itemBuilder: (context, index) {
              final item = watchlist[index];
              return _buildActivityCard(context, item);
            },
          ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, WatchlistItemRecord item) {
    final media = item.mediaItem;
    final title = media?.title.userPreferred ?? 'Anime #${item.mediaId}';
    final imageUrl = media?.coverImage.large ?? media?.coverImage.medium ?? '';
    final episodesText = 'Ep ${item.progressEpisodes}${media?.episodes != null ? " / ${media!.episodes}" : ""}';

    String statusLabel = 'În Curs';
    Color statusColor = context.accentPrimary;
    if (item.status == 'COMPLETED') {
      statusLabel = 'Completat';
      statusColor = const Color(0xFF10B981);
    } else if (item.status == 'PLAN_TO_WATCH') {
      statusLabel = 'Plănuit';
      statusColor = const Color(0xFF6366F1);
    } else if (item.status == 'ON_HOLD') {
      statusLabel = 'În Așteptare';
      statusColor = const Color(0xFFF59E0B);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MediaDetailScreen(
              mediaId: item.mediaId,
              initialItem: item.mediaItem,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail Imagine
            Expanded(
              flex: 4,
              child: SizedBox.expand(
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: context.bgPrimary,
                          child: Icon(
                            PhosphorIcons.image(PhosphorIconsStyle.bold),
                            color: context.textMuted,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        color: context.bgPrimary,
                        child: Icon(
                          PhosphorIcons.image(PhosphorIconsStyle.bold),
                          color: context.textMuted,
                          size: 20,
                        ),
                      ),
              ),
            ),

            // Informații Text Sincronizate
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Titlu
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        color: context.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Progres Episoade & Scor
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            episodesText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.score != null && item.score! > 0) ...[
                          Icon(
                            PhosphorIcons.star(PhosphorIconsStyle.fill),
                            size: 10,
                            color: const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.score!.toStringAsFixed(1),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. MODAL CONECTARE ANILIST ---
  void _showAnilistConnectModal(BuildContext context, WidgetRef ref) {
    final tokenController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'AL',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Conectare Cont AniList',
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Conectează-ți contul AniList pentru a sincroniza automat notele (1–10), statusul și progresul episoadelor în baza de date mondială.',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Buton Deschidere Link AniList
                OutlinedButton.icon(
                  onPressed: () async {
                    const url = 'https://anilist.co/api/v2/oauth/authorize?client_id=20894&response_type=token';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_browser, color: Color(0xFF3B82F6), size: 18),
                  label: const Text(
                    '1. Deschide AniList pentru a obține Token-ul',
                    style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '2. Lipește Token-ul de Acces',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tokenController,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Lipește token-ul AniList...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.clipboard(PhosphorIconsStyle.bold), size: 18),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            tokenController.text = data!.text!;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final token = tokenController.text.trim();
                      if (token.isNotEmpty) {
                        final success = await ref.read(anilistProvider.notifier).connect(token);
                        if (success) {
                          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contul AniList a fost conectat cu succes!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Eroare: Token-ul este invalid.')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Conectează Contul',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 9. MODAL EDITARE PROFIL ---
  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    fb.User user,
    String currentDisplayName,
  ) {
    final nameController = TextEditingController(text: currentDisplayName);
    final currentHandle = user.email?.split('@')[0] ?? 'membru';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Editează Profilul',
                  style: TextStyle(
                    fontFamily: 'Zalando Sans Expanded',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Handle Permanent (Read-Only)
                Text(
                  'Handle Unic (Permanent)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.bgPrimary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderSubtle.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                        size: 16,
                        color: context.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@$currentHandle',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Fix',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Nume Afișat (Display Name - Editabil)
                Text(
                  'Nume Afișat (Display Name)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: TextField(
                    controller: nameController,
                    style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Introdu numele tău...',
                      hintStyle: TextStyle(color: context.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buton Salvare
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      if (newName.isNotEmpty) {
                        try {
                          await user.updateDisplayName(newName);
                          ref.invalidate(currentUserProvider);
                          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Numele a fost actualizat cu succes!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Eroare: $e')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Salvează Modificările',
                      style: TextStyle(
                        color: context.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 10. BUTON DECONECTARE PE PAGINĂ (PENTRU LOGAȚI) ---
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmSignOut(context, ref),
      icon: Icon(
        PhosphorIcons.signOut(PhosphorIconsStyle.bold),
        size: 18,
        color: AppColors.alertCoral,
      ),
      label: const Text(
        'DECONECTEAZĂ-TE',
        style: TextStyle(
          color: AppColors.alertCoral,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
          letterSpacing: 0.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: AppColors.alertCoral.withValues(alpha: 0.35),
        ),
        backgroundColor: AppColors.alertCoral.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  // --- 11. MODAL SETĂRI & PREFERINȚE (TRIGGERAT DIN ⚙️) ---
  void _showSettingsSheet(BuildContext parentContext, WidgetRef ref, bool isGuest) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Consumer(
          builder: (consumerCtx, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDarkMode = themeMode == ThemeMode.dark;
            final currentUser = ref.watch(currentUserProvider);
            final isUserLoggedIn = currentUser != null;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              decoration: BoxDecoration(
                color: consumerCtx.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: consumerCtx.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: consumerCtx.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Titlu Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Setări & Preferințe',
                        style: TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: consumerCtx.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: consumerCtx.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Opțiuni Setări
                  _buildSettingsTile(
                    context: consumerCtx,
                    icon: PhosphorIcons.bell(PhosphorIconsStyle.bold),
                    title: 'Notificări Episoade Noi',
                    hasSwitch: true,
                    switchValue: true,
                  ),
                  Divider(height: 1, color: consumerCtx.borderSubtle),
                  _buildSettingsTile(
                    context: consumerCtx,
                    icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                    title: 'Anti-Review Bombing (Algoritm Activ)',
                    hasSwitch: true,
                    switchValue: true,
                  ),
                  Divider(height: 1, color: consumerCtx.borderSubtle),
                  _buildSettingsTile(
                    context: consumerCtx,
                    icon: isDarkMode
                        ? PhosphorIcons.moon(PhosphorIconsStyle.bold)
                        : PhosphorIcons.sun(PhosphorIconsStyle.bold),
                    title: isDarkMode
                        ? 'Temă Întunecată (OLED Dark)'
                        : 'Temă Luminoasă (Light Mode)',
                    hasSwitch: true,
                    switchValue: isDarkMode,
                    onSwitchChanged: (val) {
                      ref.read(themeModeProvider.notifier).toggleTheme(val);
                    },
                  ),
                  Divider(height: 1, color: consumerCtx.borderSubtle),
                  _buildSettingsTile(
                    context: consumerCtx,
                    icon: PhosphorIcons.info(PhosphorIconsStyle.bold),
                    title: 'Despre Kurogane Anime App',
                    subtitle: 'Versiunea 1.0.0 • Build Premium',
                    onTap: () {
                      showAboutDialog(
                        context: parentContext,
                        applicationName: 'Kurogane Anime',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 Kurogane. Toate drepturile rezervate.',
                      );
                    },
                  ),

                  if (isUserLoggedIn) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        _confirmSignOut(parentContext, ref);
                      },
                      icon: Icon(
                        PhosphorIcons.signOut(PhosphorIconsStyle.bold),
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text('Deconectează-te de la cont'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alertCoral,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.bgSurfaceHover,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: context.accentPrimary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          : null,
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged ?? (_) {},
              activeThumbColor: context.accentPrimary,
            )
          : (onTap != null
              ? Icon(
                  PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                  size: 16,
                  color: context.textSecondary,
                )
              : null),
      onTap: onTap,
    );
  }

  // --- DIALOG CONFIRMARE DECONECTARE ---
  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Deconectare',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Sigur vrei să te deconectezi din contul Kurogane?',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Anulează',
              style: TextStyle(
                color: context.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Te-ai deconectat cu succes.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertCoral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Deconectează-te',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Circle Button in Liquid Glass Style (52px)
class _ProfileFloatingCircleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const _ProfileFloatingCircleButton({
    required this.child,
    required this.onTap,
    this.size = 52,
  });

  @override
  State<_ProfileFloatingCircleButton> createState() => _ProfileFloatingCircleButtonState();
}

class _ProfileFloatingCircleButtonState extends State<_ProfileFloatingCircleButton> {
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
        scale: _isPressed ? 1.12 : 1.0,
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
                          ? (_isPressed ? 0.45 : 0.28)
                          : (_isPressed ? 0.12 : 0.06),
                    ),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: const Offset(0, 3),
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

/// Interactive button with touch scale feedback
class _InteractiveScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_InteractiveScaleButton> createState() => _InteractiveScaleButtonState();
}

class _InteractiveScaleButtonState extends State<_InteractiveScaleButton> {
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
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

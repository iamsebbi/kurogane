import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../models/watchlist_item.dart';
import '../providers/anilist_provider.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'media_detail_screen.dart';
import 'profile/edit_profile_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/floating_circle_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Dacă utilizatorul nu este conectat, afișăm ecranul dedicat de Autentificare
    if (user == null) {
      return _buildUnauthenticatedGate(context, ref);
    }

    // Date Locale & Cloud Profil (Username, Pronume, Bio)
    final profileData = ref.watch(userProfileProvider);

    // 1. Numele afișat (Display Name): Numele real din contul Google / Firebase
    final displayName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (profileData.username != null && profileData.username!.trim().isNotEmpty)
            ? profileData.username!.trim()
            : (user.email?.split('@')[0] ?? 'Membru Kurogane');

    // 2. Handle-ul unic (@handle): Identificatorul permanent din Kurogane API
    final username = (profileData.username != null && profileData.username!.trim().isNotEmpty)
        ? profileData.username!.trim().toLowerCase().replaceAll(' ', '_')
        : (user.email?.split('@')[0] ?? 'membru');

    // Date Live din Watchlist
    final watchlistAsync = ref.watch(watchlistProvider);
    final List<WatchlistItemRecord> watchlist = watchlistAsync.value ?? [];

    // Stare AniList Sync
    final anilistState = ref.watch(anilistProvider);

    // Statistici calculate dinamic din baza de date a utilizatorului
    final int completedCount = watchlist.where((i) => i.status == 'COMPLETED').length;
    final int watchingCount = watchlist.where((i) => i.status == 'WATCHING').length;
    final int totalEpisodes = watchlist.fold<int>(0, (sum, i) => sum + i.progressEpisodes);

    final scoredItems = watchlist.where((i) => i.score != null && i.score! > 0).toList();
    final String avgScoreStr = scoredItems.isNotEmpty
        ? (scoredItems.fold<double>(0.0, (sum, i) => sum + i.score!) / scoredItems.length).toStringAsFixed(1)
        : '—';

    // Genuri favorite calculate dinamic pe baza algoritmului Taste Score (Punctaj Ponderat)
    final Map<String, int> genreScores = {};
    int qualifyingSeriesCount = 0;

    for (final item in watchlist) {
      if (item.status == 'DROPPED') continue;

      final score = item.score ?? 0.0;
      int points = 0;

      if (item.status == 'COMPLETED' || item.status == 'WATCHING') {
        qualifyingSeriesCount++;
        if (score >= 8.0) {
          points = 10;
        } else if (score >= 6.0) {
          points = 5;
        } else if (score <= 0.0) {
          points = 3; // vizionat fără notă explicită
        } else {
          points = 0; // notă < 6.0, nu adăugăm afinitate pozitivă
        }
      } else if (item.status == 'PLAN_TO_WATCH') {
        points = 1;
      }

      if (points > 0 && item.mediaItem?.genres != null) {
        for (final g in item.mediaItem!.genres) {
          final trimmed = g.trim();
          if (trimmed.isNotEmpty) {
            genreScores[trimmed] = (genreScores[trimmed] ?? 0) + points;
          }
        }
      }
    }

    // Prag minim: necesită cel puțin 2 serii relevante (vizionate sau în curs)
    final List<String> userTags;
    if (qualifyingSeriesCount >= 2 && genreScores.isNotEmpty) {
      final sortedGenres = genreScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      userTags = sortedGenres.take(4).map((e) => '#${e.key}').toList();
    } else {
      userTags = const [];
    }

    // Imagine de cover dinamică: preia banner-ul primului anime din lista utilizatorului care are banner
    final String? dynamicCover = watchlist
        .map((i) => i.mediaItem?.bannerImage)
        .firstWhere(
          (b) => b != null && b.trim().isNotEmpty,
          orElse: () => null,
        );

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
            // 1. Header Compact Decorativ (~40% din valoarea anterioară)
            _buildCompactSliverHeader(context, ref, dynamicCover),

            // 2. Conținut Profil (Identitatea e imediat vizibilă fără scroll)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Identitate: Nume + Check Badge + Handle + Pronume (Full Rounded)
                    _buildIdentitySection(
                      context,
                      displayName: displayName,
                      username: username,
                      pronoun: profileData.pronoun,
                    ),

                    const SizedBox(height: 16),

                    // Buton Edit Profile (Păstrează feedback tactil & animat)
                    _buildEditProfileButton(
                      context,
                      ref,
                      user: user,
                      currentDisplayName: displayName,
                      currentHandle: username,
                      currentPronoun: profileData.pronoun,
                      currentBio: profileData.bio,
                    ),

                    const SizedBox(height: 22),

                    // Rând de Statistici Inline Live
                    _buildInlineStatsRow(
                      context,
                      completedCount: completedCount,
                      watchingCount: watchingCount,
                      totalEpisodes: totalEpisodes,
                      avgScore: avgScoreStr,
                    ),

                    const SizedBox(height: 24),

                    // Secțiune "Membru din..." + Bio + Tag-uri
                    _buildMemberAndBioSection(
                      context,
                      creationDate: user.metadata.creationTime,
                      bio: profileData.bio,
                      tags: userTags,
                      onAddBio: () => EditProfileScreen.show(
                        context,
                        user: user,
                        currentDisplayName: displayName,
                        currentHandle: username,
                        currentPronoun: profileData.pronoun,
                        currentBio: profileData.bio,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Secțiune "Conturi Conectate" (AniList 2-Way Sync)
                    _buildConnectedAccountsSection(context, ref, anilistState),

                    const SizedBox(height: 32),

                    // Secțiune "Activitate Recentă" (Single-Column Layout)
                    _buildRecentActivitySingleColumn(
                      context,
                      watchlist: watchlist,
                      isLoading: watchlistAsync.isLoading,
                    ),

                    const SizedBox(height: 32),

                    // Buton Deconectare Aliniat la System Design (Păstrează feedback tactil)
                    _buildSystemLogoutButton(context, ref),

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
                    FloatingCircleButton(
                      size: 52,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                        color: context.textPrimary,
                        size: 22,
                      ),
                    )
                  else
                    const SizedBox(width: 52, height: 52),
                  FloatingCircleButton(
                    size: 52,
                    onTap: () => SettingsScreen.show(context),
                    child: Icon(
                      PhosphorIcons.gear(PhosphorIconsStyle.bold),
                      color: context.textPrimary,
                      size: 22,
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

                    Icon(
                      PhosphorIcons.userCircle(PhosphorIconsStyle.regular),
                      size: 68,
                      color: context.textPrimary,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Autentificare Necesară',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Conectează-te pentru a-ți accesa profilul și lista de anime-uri sincronizată.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                      title: 'Watchlist Sincronizat Live',
                    ),
                    const SizedBox(height: 16),
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                      title: 'Statistici & Episoade Urmărite',
                    ),
                    const SizedBox(height: 16),
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.bold),
                      title: 'Notificări Episoade Noi',
                    ),

                    const SizedBox(height: 38),

                    // Buton Conectare (Full Rounded)
                    InkWell(
                      borderRadius: BorderRadius.circular(9999),
                      onTap: () => LoginScreen.show(context),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.accentPrimary,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Conectează-te la cont',
                          style: TextStyle(
                            color: context.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Buton Înregistrare (Full Rounded)
                    InkWell(
                      borderRadius: BorderRadius.circular(9999),
                      onTap: () => RegisterScreen.show(context),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: context.borderSubtle),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Creează un cont nou',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.bgSurfaceHover,
          ),
          child: Center(
            child: Icon(
              icon,
              color: context.textPrimary,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // --- 1. COMPACT SLIVER APP BAR HERO HEADER ---
  Widget _buildCompactSliverHeader(
    BuildContext context,
    WidgetRef ref,
    String? coverImageUrl,
  ) {
    return SliverAppBar(
      expandedHeight: 145.0,
      pinned: true,
      stretch: true,
      backgroundColor: context.bgPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 76,
      leading: Navigator.of(context).canPop()
          ? Padding(
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
            )
          : null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: FloatingCircleButton(
              size: 52,
              onTap: () => SettingsScreen.show(context),
              child: Icon(
                PhosphorIcons.gear(PhosphorIconsStyle.bold),
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
            if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty)
              CachedNetworkImage(
                imageUrl: coverImageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholder: (context, url) => _buildNativeLiquidGlassCover(context),
                errorWidget: (_, __, ___) => _buildNativeLiquidGlassCover(context),
              )
            else
              _buildNativeLiquidGlassCover(context),

            // Top subtle shadow for button contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom fade into background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      context.bgPrimary.withValues(alpha: 0.65),
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

  /// Cover nativ Liquid Glass utilizat când nu există banner anime sau imaginea nu se poate încărca
  Widget _buildNativeLiquidGlassCover(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.bgAccent.withValues(alpha: 0.65),
            context.bgSurface,
            context.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient glow top-right cu accent primar (aura Liquid Glass)
          Positioned(
            top: -45,
            right: -25,
            width: 240,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.accentPrimary.withValues(alpha: 0.16),
                    context.accentPrimary.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Brand warmth glow subtil top-left
          Positioned(
            top: -25,
            left: -35,
            width: 200,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.brandHighlight.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. SECȚIUNE IDENTITATE (NUME + CHECK BADGE + HANDLE + PRONUME FULL ROUNDED) ---
  Widget _buildIdentitySection(
    BuildContext context, {
    required String displayName,
    required String username,
    required String pronoun,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rând: Nume Display + Check Badge
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: TextStyle(
                  fontFamily: 'Zalando Sans Expanded',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
              size: 20,
              color: context.accentPrimary,
            ),
          ],
        ),
        const SizedBox(height: 5),

        // Rând: Handle Oficial (@username) + Pronoun Badge FULL ROUNDED
        Row(
          children: [
            Text(
              '@$username',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (pronoun.isNotEmpty && pronoun != 'Fără preferință') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7.0),
                child: Text(
                  '·',
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: context.bgSurfaceHover,
                  borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
                ),
                child: Text(
                  pronoun,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- 3. BUTON EDIT PROFILE (PĂSTREAZĂ FEEDBACK TACTIL) ---
  Widget _buildEditProfileButton(
    BuildContext context,
    WidgetRef ref, {
    required fb.User user,
    required String currentDisplayName,
    required String currentHandle,
    required String currentPronoun,
    required String currentBio,
  }) {
    return _TactileScaleButton(
      onTap: () => EditProfileScreen.show(
        context,
        user: user,
        currentDisplayName: currentDisplayName,
        currentHandle: currentHandle,
        currentPronoun: currentPronoun,
        currentBio: currentBio,
      ),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
              size: 14,
              color: context.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Editează Profilul',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. RÂND STATISTICI INLINE LIVE ---
  Widget _buildInlineStatsRow(
    BuildContext context, {
    required int completedCount,
    required int watchingCount,
    required int totalEpisodes,
    required String avgScore,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11,
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
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: context.borderSubtle.withValues(alpha: 0.6),
    );
  }

  // --- 5. SECȚIUNE MEMBRU DIN... + BIO + TAG-URI ---
  Widget _buildMemberAndBioSection(
    BuildContext context, {
    required DateTime? creationDate,
    required String bio,
    required List<String> tags,
    VoidCallback? onAddBio,
  }) {
    final memberSinceText = _formatMemberSince(creationDate);
    final cleanBio = bio.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rând "Membru din [dată] · [durată]" (Calculat direct din contul de autentificare)
        Row(
          children: [
            Icon(
              PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
              size: 15,
              color: context.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              memberSinceText,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        if (cleanBio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            cleanBio,
            style: TextStyle(
              color: context.textPrimary.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.42,
              fontWeight: FontWeight.w400,
            ),
          ),
        ] else if (onAddBio != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onAddBio();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.pencilSimpleLine(PhosphorIconsStyle.bold),
                    size: 14,
                    color: context.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Adaugă un bio…',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Tag-uri dinamice pe baza activității (afișate doar dacă există suficiente date)
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) => _buildInterestTag(context, t)).toList(),
          ),
        ],
      ],
    );
  }

  String _formatMemberSince(DateTime? creationDate) {
    final now = DateTime.now();
    final date = creationDate ?? now;
    const months = [
      '',
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie'
    ];

    final monthName = (date.month >= 1 && date.month <= 12) ? months[date.month] : 'ianuarie';
    final year = date.year;

    // Calcul precis durată
    int years = now.year - date.year;
    int monthsDiff = now.month - date.month;
    if (monthsDiff < 0) {
      years--;
      monthsDiff += 12;
    }
    if (now.day < date.day) {
      monthsDiff--;
      if (monthsDiff < 0) {
        years--;
        monthsDiff += 12;
      }
    }

    String durationStr;
    if (years <= 0 && monthsDiff <= 0) {
      durationStr = 'recent';
    } else if (years <= 0) {
      durationStr = monthsDiff == 1 ? '1 lună' : '$monthsDiff luni';
    } else {
      final yStr = years == 1 ? '1 an' : '$years ani';
      if (monthsDiff == 0) {
        durationStr = yStr;
      } else {
        final mStr = monthsDiff == 1 ? '1 lună' : '$monthsDiff luni';
        durationStr = '$yStr și $mStr';
      }
    }

    return 'Membru din $monthName $year · $durationStr';
  }

  Widget _buildInterestTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.bgSurfaceHover,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.textPrimary.withValues(alpha: 0.85),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- 6. SECȚIUNE CONTURI CONECTATE (ANILIST) ---
  Widget _buildConnectedAccountsSection(
    BuildContext context,
    WidgetRef ref,
    AnilistState anilistState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conturi Conectate',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        // AniList Card: Fără border-uri, fundal curat
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          anilistState.isConnected
                              ? 'Sincronizare activă'
                              : 'Sincronizează notele și progresul mondial',
                          style: TextStyle(
                            color: anilistState.isConnected
                                ? const Color(0xFF10B981)
                                : context.textSecondary,
                            fontSize: 12,
                            fontWeight: anilistState.isConnected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Buton Conectare Full Rounded
                  if (!anilistState.isConnected)
                    InkWell(
                      borderRadius: BorderRadius.circular(9999),
                      onTap: () => _showAnilistConnectModal(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Text(
                          'Conectează',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.linkBreak(PhosphorIconsStyle.bold),
                        color: context.error,
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

              if (anilistState.isConnected) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: context.bgSurfaceHover),
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
                    InkWell(
                      borderRadius: BorderRadius.circular(9999),
                      onTap: anilistState.isSyncing
                          ? null
                          : () async {
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (anilistState.isSyncing)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                              )
                            else
                              const Icon(
                                PhosphorIconsRegular.arrowsClockwise,
                                size: 13,
                                color: Color(0xFF3B82F6),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              anilistState.isSyncing ? 'Se importă...' : '1-Click Sync',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
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

  // --- 7. SECȚIUNE ACTIVITATE RECENTĂ (SINGLE-COLUMN LAYOUT) ---
  Widget _buildRecentActivitySingleColumn(
    BuildContext context, {
    required List<WatchlistItemRecord> watchlist,
    required bool isLoading,
  }) {
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
                fontSize: 18,
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
        const SizedBox(height: 14),

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
            ),
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                  size: 36,
                  color: context.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Niciun anime în listă încă',
                  style: TextStyle(
                    fontFamily: 'Zalando Sans Expanded',
                    color: context.textPrimary,
                    fontSize: 14.5,
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
          // Single-column layout (horizontal cards)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: watchlist.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = watchlist[index];
              return _buildActivitySingleRowCard(context, item);
            },
          ),
      ],
    );
  }

  Widget _buildActivitySingleRowCard(BuildContext context, WatchlistItemRecord item) {
    final media = item.mediaItem;
    final title = media?.title.userPreferred ?? 'Anime #${item.mediaId}';
    final imageUrl = media?.coverImage.large ?? media?.coverImage.medium ?? '';
    final int progress = item.progressEpisodes;
    final int? total = media?.episodes;

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

    final double progressPercent = (total != null && total > 0)
        ? (progress / total).clamp(0.0, 1.0)
        : (progress > 0 ? 0.5 : 0.0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MediaDetailScreen(
              mediaId: item.mediaId,
              initialItem: item.mediaItem,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Poster Imagine Rotunjită
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 58,
                height: 78,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: context.bgSurfaceHover,
                          child: Icon(
                            PhosphorIcons.image(PhosphorIconsStyle.bold),
                            color: context.textMuted,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        color: context.bgSurfaceHover,
                        child: Icon(
                          PhosphorIcons.image(PhosphorIconsStyle.bold),
                          color: context.textMuted,
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Informații Titlu, Progres & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Titlu Serie
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Zalando Sans Expanded',
                      color: context.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Episoade + Bară subțire de progres
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9999),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 4,
                            backgroundColor: context.bgSurfaceHover,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ep $progress${total != null ? "/$total" : ""}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Scor și Caret Navigare
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.score != null && item.score! > 0) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIconsFill.star,
                        size: 12,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.score!.toStringAsFixed(1),
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Icon(
                  PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                  size: 14,
                  color: context.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. BUTON DECONECTARE (PĂSTREAZĂ FEEDBACK TACTIL) ---
  Widget _buildSystemLogoutButton(BuildContext context, WidgetRef ref) {
    return _TactileScaleButton(
      onTap: () => _confirmSignOut(context, ref),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(9999),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.signOut(PhosphorIconsStyle.bold),
              size: 16,
              color: context.error,
            ),
            const SizedBox(width: 8),
            Text(
              'Deconectează-te',
              style: TextStyle(
                color: context.error,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 10. MODAL CONECTARE ANILIST (BORDERLESS & FULL ROUNDED) ---
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        fontSize: 17,
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
                InkWell(
                  borderRadius: BorderRadius.circular(9999),
                  onTap: () async {
                    const url = 'https://anilist.co/api/v2/oauth/authorize?client_id=20894&response_type=token';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_browser, color: Color(0xFF3B82F6), size: 18),
                        SizedBox(width: 8),
                        Text(
                          '1. Deschide AniList pentru Token',
                          style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '2. Lipește Token-ul de Acces',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.circular(9999),
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
                InkWell(
                  borderRadius: BorderRadius.circular(9999),
                  onTap: () async {
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
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Conectează Contul',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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



  // --- 12. DIALOG CONFIRMARE DECONECTARE SYSTEM DESIGN ---
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
            fontSize: 18,
          ),
        ),
        content: Text(
          'Sigur vrei să te deconectezi din contul Kurogane?',
          style: TextStyle(color: context.textSecondary, fontSize: 13.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Anulează',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TactileScaleButton(
                  onTap: () async {
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
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.error,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Deconectează',
                      style: TextStyle(
                        color: context.onError,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
  }
}



/// Tactile Scale Button (Păstrat strict pentru Editează Profil, Setări și Deconectare)
class _TactileScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_TactileScaleButton> createState() => _TactileScaleButtonState();
}

class _TactileScaleButtonState extends State<_TactileScaleButton> {
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

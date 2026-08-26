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
import '../providers/user_profile_provider.dart';
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

    // Username-ul oficial ales la înregistrare
    final username = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!.toLowerCase().replaceAll(' ', '_')
        : (user.email?.split('@')[0] ?? 'membru');

    // Numele afișat (Display Name)
    final displayName = user.displayName != null && user.displayName!.isNotEmpty
        ? user.displayName!
        : (user.email?.split('@')[0] ?? 'Membru Kurogane');

    // Date Locale Profil (Pronume, Bio)
    final profileData = ref.watch(userProfileProvider);

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

    // Imagine de cover dinamică: preia banner-ul primului anime din lista utilizatorului
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
                    _ProfileFloatingCircleButton(
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
                  _ProfileFloatingCircleButton(
                    size: 52,
                    onTap: () => _showSettingsSheet(context, ref, true),
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
    String coverImageUrl,
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
                child: _ProfileFloatingCircleButton(
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
            child: _ProfileFloatingCircleButton(
              size: 52,
              onTap: () => _showSettingsSheet(context, ref, false),
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
            CachedNetworkImage(
              imageUrl: coverImageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (context, url) => Container(color: context.bgSurface),
              errorWidget: (_, __, ___) => Container(
                color: context.bgSurface,
                child: Center(
                  child: Icon(
                    PhosphorIcons.user(PhosphorIconsStyle.bold),
                    size: 48,
                    color: context.textMuted,
                  ),
                ),
              ),
            ),

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
      onTap: () => _showEditProfileSheet(
        context,
        ref,
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
  }) {
    final memberSinceText = _formatMemberSince(creationDate);

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

        if (bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            bio,
            style: TextStyle(
              color: context.textPrimary.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.42,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Tag-uri dinamice pe baza activității
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((t) => _buildInterestTag(context, t)).toList(),
        ),
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

  // --- 9. MODAL EDITARE PROFIL (CU SELECTOR PRONUME & BIO) ---
  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref, {
    required fb.User user,
    required String currentDisplayName,
    required String currentHandle,
    required String currentPronoun,
    required String currentBio,
  }) {
    final nameController = TextEditingController(text: currentDisplayName);
    final bioController = TextEditingController(text: currentBio);

    String selectedPronoun = currentPronoun;
    final customPronounController = TextEditingController();

    const predefinedPronouns = [
      'el/lui',
      'ea/ei',
      'ei/lor',
      'they/them',
      'he/him',
      'she/her',
      'Fără preferință',
    ];

    bool isCustom = !predefinedPronouns.contains(currentPronoun) && currentPronoun.isNotEmpty;
    if (isCustom) {
      customPronounController.text = currentPronoun;
      selectedPronoun = 'Personalizat...';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                child: SingleChildScrollView(
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
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Handle Permanent (Username-ul ales la înregistrare)
                      Text(
                        'Handle Unic (Permanent)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.bgPrimary,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                              size: 15,
                              color: context.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '@$currentHandle',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13.5,
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

                      // 2. Nume Afișat
                      Text(
                        'Nume Afișat',
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
                        child: TextField(
                          controller: nameController,
                          style: TextStyle(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Introdu numele tău...',
                            hintStyle: TextStyle(color: context.textMuted, fontSize: 13.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Selector Pronume (Chips FULL ROUNDED)
                      Text(
                        'Pronume',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...predefinedPronouns.map((p) {
                            final isSelected = selectedPronoun == p;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedPronoun = p;
                                  isCustom = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? context.accentPrimary : context.bgPrimary,
                                  borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    color: isSelected ? context.onPrimary : context.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedPronoun = 'Personalizat...';
                                isCustom = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCustom ? context.accentPrimary : context.bgPrimary,
                                borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
                              ),
                              child: Text(
                                'Personalizat...',
                                style: TextStyle(
                                  color: isCustom ? context.onPrimary : context.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: isCustom ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (isCustom) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: context.bgPrimary,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: TextField(
                            controller: customPronounController,
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'ex: el/lui, per/pers...',
                              hintStyle: TextStyle(color: context.textMuted, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 4. Bio / Despre mine
                      Text(
                        'Despre Tine (Bio)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.bgPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: bioController,
                          maxLines: 2,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'O scurtă descriere a pasiunii tale pentru anime...',
                            hintStyle: TextStyle(color: context.textMuted, fontSize: 12.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Buton Salvare Full-Rounded
                      _TactileScaleButton(
                        onTap: () async {
                          final newName = nameController.text.trim();
                          final finalPronoun = isCustom
                              ? customPronounController.text.trim()
                              : selectedPronoun;
                          final newBio = bioController.text.trim();

                          if (newName.isNotEmpty) {
                            try {
                              await user.updateDisplayName(newName);
                              await ref.read(userProfileProvider.notifier).updateProfile(
                                    pronoun: finalPronoun,
                                    bio: newBio,
                                  );
                              ref.invalidate(currentUserProvider);
                              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profilul a fost actualizat cu succes!'),
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
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.accentPrimary,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Salvează Modificările',
                            style: TextStyle(
                              color: context.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  // --- 11. MODAL COMPLET SETĂRI & PREFERINȚE STRUCTURAT ---
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
            final settings = ref.watch(appSettingsProvider);

            return Container(
              height: MediaQuery.of(consumerCtx).size.height * 0.88,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: consumerCtx.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: consumerCtx.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Setări & Preferințe',
                        style: TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: consumerCtx.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: consumerCtx.textSecondary,
                          size: 19,
                        ),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // --- 1. AFIȘARE & CONȚINUT ---
                        _buildSettingsGroupHeader(consumerCtx, 'AFIȘARE & CONȚINUT'),
                        _buildGroupCard(
                          context: consumerCtx,
                          children: [
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
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.translate(PhosphorIconsStyle.bold),
                              title: 'Limbă Aplicație',
                              subtitle: 'Română (RO)',
                              badgeLabel: 'RO',
                              onTap: () {
                                _showDevelopmentNotice(parentContext, 'Suportul multi-limbă (Română / English) va fi disponibil în următorul update.');
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                              title: 'Filtru Conținut Adult / Ecchi (+18)',
                              subtitle: 'Ascunde automat seriile NSFW/Ecchi din recomandări',
                              hasSwitch: true,
                              switchValue: settings.adultContentFilter,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(adultContentFilter: val);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.maskHappy(PhosphorIconsStyle.bold),
                              title: 'Spoiler Blur',
                              subtitle: 'Ascunde imagini și sinopsis pentru episoade nevăzute',
                              hasSwitch: true,
                              switchValue: settings.spoilerBlur,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(spoilerBlur: val);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                              title: 'Anti-Review Bombing (Algoritm Activ)',
                              subtitle: 'Filtrează scorurile extreme generate de boți',
                              hasSwitch: true,
                              switchValue: settings.antiReviewBombing,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(antiReviewBombing: val);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- 2. NOTIFICĂRI ---
                        _buildSettingsGroupHeader(consumerCtx, 'NOTIFICĂRI'),
                        _buildGroupCard(
                          context: consumerCtx,
                          children: [
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.bold),
                              title: 'Episoade Noi din Watchlist',
                              subtitle: 'Notificări când apar episoade din seriile urmărite',
                              hasSwitch: true,
                              switchValue: settings.notifyNewEpisodes,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(notifyNewEpisodes: val);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.sparkle(PhosphorIconsStyle.bold),
                              title: 'Anunțuri Sezon Nou & Premiere',
                              subtitle: 'Alertă când un anime din listă primește sezon nou',
                              hasSwitch: true,
                              switchValue: settings.notifyNewSeasons,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(notifyNewSeasons: val);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.newspaper(PhosphorIconsStyle.bold),
                              title: 'Update-uri Aplicație & Changelog',
                              hasSwitch: true,
                              switchValue: settings.notifyAppUpdates,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(notifyAppUpdates: val);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- 3. SINCRONIZARE & DATE ---
                        _buildSettingsGroupHeader(consumerCtx, 'SINCRONIZARE & DATE'),
                        _buildGroupCard(
                          context: consumerCtx,
                          children: [
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                              title: 'Frecvență Sincronizare AniList',
                              subtitle: settings.syncFrequency == 'auto' ? 'Automat la pornirea aplicației' : 'Manual prin buton',
                              badgeLabel: settings.syncFrequency.toUpperCase(),
                              onTap: () {
                                final next = settings.syncFrequency == 'auto' ? 'manual' : 'auto';
                                ref.read(appSettingsProvider.notifier).updateSetting(syncFrequency: next);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.wifiHigh(PhosphorIconsStyle.bold),
                              title: 'Sincronizare doar pe Wi-Fi',
                              subtitle: 'Economisește datele mobile la sincronizarea imaginilor',
                              hasSwitch: true,
                              switchValue: settings.syncWifiOnly,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(syncWifiOnly: val);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.trash(PhosphorIconsStyle.bold),
                              title: 'Ștergere Cache Local & Re-sync',
                              subtitle: 'Curăță imaginile temporare și reîncarcă datele',
                              onTap: () {
                                _confirmClearCache(parentContext, ref);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- 4. CONT & SECURITATE (PENTRU MEMBRII CONECTAȚI) ---
                        if (isUserLoggedIn) ...[
                          _buildSettingsGroupHeader(consumerCtx, 'CONT & SECURITATE'),
                          _buildGroupCard(
                            context: consumerCtx,
                            children: [
                              _buildSettingsTile(
                                context: consumerCtx,
                                icon: PhosphorIcons.envelope(PhosphorIconsStyle.bold),
                                title: 'Email Asociat',
                                subtitle: currentUser.email ?? 'Neconfigurat',
                                badgeLabel: 'VERIFICAT',
                              ),
                              _buildSettingsDivider(consumerCtx),
                              _buildSettingsTile(
                                context: consumerCtx,
                                icon: PhosphorIcons.key(PhosphorIconsStyle.bold),
                                title: 'Schimbă Parola',
                                subtitle: 'Trimite link de securitate pe email',
                                onTap: () {
                                  _handlePasswordReset(parentContext, ref, currentUser.email);
                                },
                              ),
                              _buildSettingsDivider(consumerCtx),
                              _buildSettingsTile(
                                context: consumerCtx,
                                icon: PhosphorIcons.devices(PhosphorIconsStyle.bold),
                                title: 'Sesiuni Active',
                                subtitle: '1 dispozitiv conectat (Dispozitiv curent)',
                                badgeLabel: 'ÎN LUCRU ⏳',
                                onTap: () {
                                  _showDevelopmentNotice(parentContext, 'Gestionarea sesiunilor active remote este în curs de implementare.');
                                },
                              ),
                              _buildSettingsDivider(consumerCtx),
                              _buildSettingsTile(
                                context: consumerCtx,
                                icon: PhosphorIcons.userMinus(PhosphorIconsStyle.bold),
                                title: 'Ștergere Cont (GDPR)',
                                subtitle: 'Șterge ireversibil contul și toate datele tale',
                                titleColor: consumerCtx.error,
                                onTap: () {
                                  _confirmDeleteAccount(parentContext);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- 5. PRIVACITATE ---
                        _buildSettingsGroupHeader(consumerCtx, 'PRIVACITATE'),
                        _buildGroupCard(
                          context: consumerCtx,
                          children: [
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.globe(PhosphorIconsStyle.bold),
                              title: 'Profil Public',
                              subtitle: settings.isProfilePublic
                                  ? 'Watchlist-ul și scorurile sunt vizibile'
                                  : 'Doar tu poți vedea profilul',
                              hasSwitch: true,
                              switchValue: settings.isProfilePublic,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(isProfilePublic: val);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold),
                              title: 'Ascunde Activitatea Recentă',
                              subtitle: 'Nu afișa ultimele episoade vizionate',
                              hasSwitch: true,
                              switchValue: settings.hideRecentActivity,
                              onSwitchChanged: (val) {
                                ref.read(appSettingsProvider.notifier).updateSetting(hideRecentActivity: val);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- 6. SUPORT & FEEDBACK ---
                        _buildSettingsGroupHeader(consumerCtx, 'SUPORT & FEEDBACK'),
                        _buildGroupCard(
                          context: consumerCtx,
                          children: [
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.chatTeardropText(PhosphorIconsStyle.bold),
                              title: 'Trimite Feedback / Raportează o Problemă',
                              onTap: () {
                                _showFeedbackDialog(parentContext);
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
                            _buildSettingsTile(
                              context: consumerCtx,
                              icon: PhosphorIcons.star(PhosphorIconsStyle.bold),
                              title: 'Evaluează Aplicația (Rate the App)',
                              badgeLabel: 'STORE ⏳',
                              onTap: () {
                                _showDevelopmentNotice(parentContext, 'Link-ul către Google Play Store va fi activ la lansarea publică.');
                              },
                            ),
                            _buildSettingsDivider(consumerCtx),
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
                          ],
                        ),

                        if (isUserLoggedIn) ...[
                          const SizedBox(height: 28),
                          _TactileScaleButton(
                            onTap: () {
                              Navigator.of(sheetCtx).pop();
                              _confirmSignOut(parentContext, ref);
                            },
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                color: consumerCtx.bgSurfaceHover,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIcons.signOut(PhosphorIconsStyle.bold),
                                    size: 16,
                                    color: consumerCtx.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Deconectează-te',
                                    style: TextStyle(
                                      color: consumerCtx.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
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

  Widget _buildSettingsGroupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Zalando Sans Expanded',
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: context.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurfaceHover,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsDivider(BuildContext context) {
    return Container(
      height: 1,
      color: context.borderSubtle.withValues(alpha: 0.45),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    String? badgeLabel,
    Color? titleColor,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 14),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.bgPrimary.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: titleColor ?? context.accentPrimary, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: titleColor ?? context.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badgeLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 11.5),
              ),
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
                  size: 15,
                  color: context.textSecondary,
                )
              : null),
      onTap: onTap,
    );
  }

  // --- HELPERE MODALE SETĂRI ---
  void _showDevelopmentNotice(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(PhosphorIconsFill.hourglassSimple, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Ștergere Cache',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Vrei să golești imaginile și datele stocate temporar? Aplicația va reîncărca informațiile proaspete.',
          style: TextStyle(color: context.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Anulează', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              await ref.read(watchlistProvider.notifier).fetchWatchlist();
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache-ul a fost curățat și datele au fost resincronizate!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentPrimary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Curăță Cache', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _handlePasswordReset(BuildContext context, WidgetRef ref, String? email) {
    if (email == null || email.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Resetare Parolă',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Vom trimite un email de securitate către $email cu instrucțiunile pentru setarea unei parole noi.',
          style: TextStyle(color: context.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Anulează', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Email-ul de resetare a fost trimis la $email.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentPrimary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Trimite Email', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Ștergere Cont (GDPR)',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontWeight: FontWeight.w800,
            color: context.error,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Această acțiune este permanentă și ireversibilă. Toate listele, recenziile și istoricul tău vor fi șterse definitiv conform normelor GDPR.',
          style: TextStyle(color: context.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Anulează', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _showDevelopmentNotice(context, 'Pentru securitate maximă, confirmarea de ștergere definitivă prin re-autentificare va fi activă în build-ul următor.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.error,
              foregroundColor: context.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Înțeleg, continuă', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Trimite Feedback',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce putem îmbunătăți în Kurogane Anime App?',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: feedbackController,
                maxLines: 3,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Scrie părerea sau problema întâmpinată...',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Anulează', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Îți mulțumim! Mesajul tău a fost trimis echipei Kurogane.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentPrimary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Trimite', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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

/// Floating Circle Button in Liquid Glass Style (Păstrează feedback tactil pe butonul de setări)
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

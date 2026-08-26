import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/pill_badge.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

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

    final username = user.email?.split('@')[0] ?? 'membru';

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Hero Header cu Imagine mare & Gradient Fade
          _buildSliverHeader(context, ref, user),

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

                  // Rând de Statistici Inline (cu Divider Vertical)
                  _buildInlineStatsRow(context),

                  const SizedBox(height: 28),

                  // Secțiune Bio / Citat & Tag-uri
                  _buildBioSection(context),

                  const SizedBox(height: 28),

                  // Buton Principal CTA Gradient (Edit Profile)
                  _buildPrimaryCtaButton(context),

                  const SizedBox(height: 36),

                  // Secțiune "Activitate Recentă" (Echivalent Chats / Grid)
                  _buildRecentActivitySection(context),

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
    );
  }

  // --- ECRAN PENTRU UTILIZATORI NEAUTENTIFICAȚI (AUTH GATEKEEPER) ---
  Widget _buildUnauthenticatedGate(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (iOS System Design, Left & Right 52px Floating Buttons fără border)
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

                    // Icon Simplu Phosphor (fără glow, fără gradient squircle)
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

                    // Subtitlu explicativ scurtat
                    Text(
                      'Conectează-te pentru a-ți accesa profilul și lista de anime-uri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Lista simplificată (fără border, fără background, iconițe în cerc monocrom adaptat la temă)
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold),
                      title: 'Watchlist Personalizat',
                    ),
                    const SizedBox(height: 18),
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                      title: 'Comunitate & Recenzii',
                    ),
                    const SizedBox(height: 18),
                    _buildSimplifiedFeatureItem(
                      context: context,
                      icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.bold),
                      title: 'Notificări Episoade Noi',
                    ),

                    const SizedBox(height: 42),

                    // Buton Principal Conectare (Capital letters, normal spacing, solid accent, tap feedback)
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

                    // Buton Secundar Înregistrare (Capital letters, normal spacing, tap feedback)
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
    dynamic user,
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
        // Buton Setări ⚙️ (52px floating button iOS design)
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
            Image.network(
              _defaultCoverImage,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
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

            // Gradient de jos pentru topirea lină în fundalul paginii
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 180,
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

              // Handle (@username)
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

  // --- 3. RÂND STATISTICI INLINE (VERTICAL DIVIDERS) ---
  Widget _buildInlineStatsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInlineStatItem(context, '0', 'Completate'),
          _buildVerticalStatDivider(context),
          _buildInlineStatItem(context, '0', 'În Curs'),
          _buildVerticalStatDivider(context),
          _buildInlineStatItem(context, '0', 'Episoade'),
          _buildVerticalStatDivider(context),
          _buildInlineStatItem(context, '—', 'Scor Mediu'),
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

  // --- 4. SECȚIUNE BIO, MOTTO & TAG-URI ---
  Widget _buildBioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Citat / Motto Italic între ghilimele
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
          'Anime & Manga Enthusiast • Membru Comunitate\nTokyo ➔ București',
          style: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.85),
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 16),

        // Tag-uri rotunjite (Pills)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInterestTag(context, '#Shonen'),
            _buildInterestTag(context, '#DarkFantasy'),
            _buildInterestTag(context, '#Cyberpunk'),
            _buildInterestTag(context, '#Isekai'),
          ],
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
  Widget _buildPrimaryCtaButton(BuildContext context) {
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Editarea profilului va fi disponibilă în curând.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
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

  // --- 6. SECȚIUNE ACTIVITATE RECENTĂ / FAVORITE (CHATS STYLE) ---
  Widget _buildRecentActivitySection(BuildContext context) {
    const List<_RecentActivityItem> items = [
      _RecentActivityItem(
        title: 'Solo Leveling',
        imageUrl:
            'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=600&q=80',
        membersCount: '150k',
        score: '9.4',
      ),
      _RecentActivityItem(
        title: 'Jujutsu Kaisen',
        imageUrl:
            'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=600&q=80',
        membersCount: '280k',
        score: '9.1',
      ),
      _RecentActivityItem(
        title: 'Chainsaw Man',
        imageUrl:
            'https://images.unsplash.com/photo-1563089145-599997674d42?auto=format&fit=crop&w=600&q=80',
        membersCount: '95k',
        score: '8.9',
      ),
      _RecentActivityItem(
        title: 'Demon Slayer',
        imageUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
        membersCount: '410k',
        score: '9.3',
      ),
    ];

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
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 16,
              color: context.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildActivityCard(context, item);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, _RecentActivityItem item) {
    return Container(
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
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.bgPrimary,
                  child: Icon(
                    PhosphorIcons.image(PhosphorIconsStyle.bold),
                    color: context.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Informații Text
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.users(PhosphorIconsStyle.bold),
                        size: 11,
                        color: context.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.membersCount,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Zalando Sans Expanded',
                      color: context.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: 11,
                        color: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.score,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 7. BUTON DECONECTARE PE PAGINĂ (PENTRU LOGAȚI) ---
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

  // --- 8. MODAL SETĂRI & PREFERINȚE (TRIGGERAT DIN ⚙️) ---
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
                    title: 'Despre Kurogane v1.0',
                    hasSwitch: false,
                  ),

                  const SizedBox(height: 20),

                  // Buton Autentificare sau Deconectare în funcție de starea user-ului
                  if (isUserLoggedIn)
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(sheetCtx).pop();
                        await ref.read(authControllerProvider.notifier).signOut();
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Te-ai deconectat cu succes.'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        PhosphorIcons.signOut(PhosphorIconsStyle.bold),
                        size: 18,
                        color: AppColors.alertCoral,
                      ),
                      label: const Text(
                        'Deconectează-te',
                        style: TextStyle(
                          color: AppColors.alertCoral,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.alertCoral.withValues(alpha: 0.4),
                        ),
                        backgroundColor: AppColors.alertCoral.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        LoginScreen.show(parentContext);
                      },
                      icon: Icon(
                        PhosphorIcons.signIn(PhosphorIconsStyle.bold),
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Autentifică-te în Cont',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: consumerCtx.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

  static Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool hasSwitch,
    bool switchValue = true,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.accentPrimary, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              activeTrackColor: context.accentPrimary,
              thumbColor: const WidgetStatePropertyAll(Colors.white),
              onChanged: onSwitchChanged,
            )
          : Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: context.textMuted,
              size: 16,
            ),
    );
  }

  static Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Deconectare',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            color: dialogCtx.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Ești sigur că vrei să te deconectezi de pe acest cont?',
          style: TextStyle(color: dialogCtx.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Anulează', style: TextStyle(color: dialogCtx.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Deconectare',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te-ai deconectat cu succes.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// --- FLOATING CIRCLE BUTTON IDENTIC CU HOME SCREEN (52px, ZERO BORDER, GLASS EFFECT, TAP FEEDBACK) ---
class _ProfileFloatingCircleButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;

  const _ProfileFloatingCircleButton({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  State<_ProfileFloatingCircleButton> createState() => _ProfileFloatingCircleButtonState();
}

class _ProfileFloatingCircleButtonState extends State<_ProfileFloatingCircleButton> {
  bool _isPressed = false;

  static final ImageFilter _glassFilter = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    inner: const ColorFilter.matrix(<double>[
      1.6296, -0.5720, -0.0576, 0, 0,
     -0.1704,  1.2280, -0.0576, 0, 0,
     -0.1704, -0.5720,  1.7424, 0, 0,
      0,       0,       0,      1, 0,
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 1.15 : 1.0,
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
                        alpha: context.isDarkMode ? (_isPressed ? 0.5 : 0.35) : (_isPressed ? 0.12 : 0.08)),
                    blurRadius: _isPressed ? 14 : 10,
                    offset: const Offset(0, 4),
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
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _RecentActivityItem {
  final String title;
  final String imageUrl;
  final String membersCount;
  final String score;

  const _RecentActivityItem({
    required this.title,
    required this.imageUrl,
    required this.membersCount,
    required this.score,
  });
}

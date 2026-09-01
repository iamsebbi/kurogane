import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/blur_fade_route.dart';
import '../../widgets/floating_circle_button.dart';

/// Ecran Complet pentru Setări & Preferințe (cu suport Back Button & Gesturi de Sistem)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      BlurFadePageRoute(
        child: const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isUserLoggedIn = currentUser != null;
    final settings = ref.watch(appSettingsProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar cu Back Button & Titlu
              _buildTopBar(context),

              // Corp setări scrollable
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // --- 1. AFIȘARE & CONȚINUT ---
                    _buildSettingsGroupHeader(context, 'AFIȘARE & CONȚINUT'),
                    _buildGroupCard(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: isDarkMode
                              ? PhosphorIcons.moon(PhosphorIconsStyle.bold)
                              : PhosphorIcons.sun(PhosphorIconsStyle.bold),
                          title: isDarkMode
                              ? 'Temă Întunecată (OLED Dark)'
                              : 'Temă Luminoasă (Light Mode)',
                          hasSwitch: true,
                          switchValue: isDarkMode,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(themeModeProvider.notifier).toggleTheme(val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.translate(PhosphorIconsStyle.bold),
                          title: 'Limbă Aplicație',
                          subtitle: 'Română (RO)',
                          badgeLabel: 'RO',
                          onTap: () {
                            _showDevelopmentNotice(context, 'Suportul multi-limbă (Română / English) va fi disponibil în următorul update.');
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                          title: 'Filtru Conținut Adult / Ecchi (+18)',
                          subtitle: 'Ascunde automat seriile NSFW/Ecchi din recomandări',
                          hasSwitch: true,
                          switchValue: settings.adultContentFilter,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(adultContentFilter: val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.maskHappy(PhosphorIconsStyle.bold),
                          title: 'Spoiler Blur',
                          subtitle: 'Ascunde imagini și sinopsis pentru episoade nevăzute',
                          hasSwitch: true,
                          switchValue: settings.spoilerBlur,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(spoilerBlur: val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                          title: 'Anti-Review Bombing (Algoritm Activ)',
                          subtitle: 'Filtrează scorurile extreme generate de boți',
                          hasSwitch: true,
                          switchValue: settings.antiReviewBombing,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(antiReviewBombing: val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 2. NOTIFICĂRI ---
                    _buildSettingsGroupHeader(context, 'NOTIFICĂRI'),
                    _buildGroupCard(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.bold),
                          title: 'Episoade Noi din Watchlist',
                          subtitle: 'Notificări când apar episoade din seriile urmărite',
                          hasSwitch: true,
                          switchValue: settings.notifyNewEpisodes,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(notifyNewEpisodes: val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.sparkle(PhosphorIconsStyle.bold),
                          title: 'Anunțuri Sezon Nou & Premiere',
                          subtitle: 'Alertă când un anime din listă primește sezon nou',
                          hasSwitch: true,
                          switchValue: settings.notifyNewSeasons,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(notifyNewSeasons: val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.newspaper(PhosphorIconsStyle.bold),
                          title: 'Update-uri Aplicație & Changelog',
                          hasSwitch: true,
                          switchValue: settings.notifyAppUpdates,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(notifyAppUpdates: val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 3. SINCRONIZARE & DATE ---
                    _buildSettingsGroupHeader(context, 'SINCRONIZARE & DATE'),
                    _buildGroupCard(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                          title: 'Frecvență Sincronizare AniList',
                          subtitle: settings.syncFrequency == 'auto'
                              ? 'Automat la pornirea aplicației'
                              : 'Manual prin buton',
                          badgeLabel: settings.syncFrequency.toUpperCase(),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final next = settings.syncFrequency == 'auto' ? 'manual' : 'auto';
                            ref.read(appSettingsProvider.notifier).updateSetting(syncFrequency: next);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.wifiHigh(PhosphorIconsStyle.bold),
                          title: 'Sincronizare doar pe Wi-Fi',
                          subtitle: 'Economisește datele mobile la descărcarea imaginilor',
                          hasSwitch: true,
                          switchValue: settings.syncWifiOnly,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(syncWifiOnly: val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.trash(PhosphorIconsStyle.bold),
                          title: 'Ștergere Cache Local & Re-sync',
                          subtitle: 'Curăță imaginile temporare și reîncarcă datele proaspete',
                          onTap: () => _confirmClearCache(context, ref),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 4. CONT & SECURITATE (MEMBRI CONECTAȚI) ---
                    if (isUserLoggedIn) ...[
                      _buildSettingsGroupHeader(context, 'CONT & SECURITATE'),
                      _buildGroupCard(
                        context: context,
                        children: [
                          _buildSettingsTile(
                            context: context,
                            icon: PhosphorIcons.envelope(PhosphorIconsStyle.bold),
                            title: 'Email Asociat',
                            subtitle: currentUser.email ?? 'Neconfigurat',
                            badgeLabel: 'VERIFICAT',
                          ),
                          _buildSettingsDivider(context),
                          _buildSettingsTile(
                            context: context,
                            icon: PhosphorIcons.key(PhosphorIconsStyle.bold),
                            title: 'Schimbă Parola',
                            subtitle: 'Trimite link de securitate pe email',
                            onTap: () => _handlePasswordReset(context, ref, currentUser.email),
                          ),
                          _buildSettingsDivider(context),
                          _buildSettingsTile(
                            context: context,
                            icon: PhosphorIcons.devices(PhosphorIconsStyle.bold),
                            title: 'Sesiuni Active',
                            subtitle: '1 dispozitiv conectat (Dispozitiv curent)',
                            badgeLabel: 'ÎN LUCRU ⏳',
                            onTap: () {
                              _showDevelopmentNotice(context, 'Gestionarea sesiunilor active remote este în curs de implementare.');
                            },
                          ),
                          _buildSettingsDivider(context),
                          _buildSettingsTile(
                            context: context,
                            icon: PhosphorIcons.userMinus(PhosphorIconsStyle.bold),
                            title: 'Ștergere Cont (GDPR)',
                            subtitle: 'Șterge ireversibil contul și toate datele tale',
                            titleColor: context.error,
                            onTap: () => _confirmDeleteAccount(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- 5. PRIVACITATE ---
                    _buildSettingsGroupHeader(context, 'PRIVACITATE'),
                    _buildGroupCard(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.globe(PhosphorIconsStyle.bold),
                          title: 'Profil Public',
                          subtitle: settings.isProfilePublic
                              ? 'Watchlist-ul și scorurile sunt vizibile'
                              : 'Doar tu poți vedea profilul',
                          hasSwitch: true,
                          switchValue: settings.isProfilePublic,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(isProfilePublic: val);
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold),
                          title: 'Ascunde Activitatea Recentă',
                          subtitle: 'Nu afișa ultimele episoade vizionate',
                          hasSwitch: true,
                          switchValue: settings.hideRecentActivity,
                          onSwitchChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref.read(appSettingsProvider.notifier).updateSetting(hideRecentActivity: val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 6. SUPORT & FEEDBACK ---
                    _buildSettingsGroupHeader(context, 'SUPORT & FEEDBACK'),
                    _buildGroupCard(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.chatTeardropText(PhosphorIconsStyle.bold),
                          title: 'Trimite Feedback / Raportează o Problemă',
                          onTap: () => _showFeedbackDialog(context),
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.star(PhosphorIconsStyle.bold),
                          title: 'Evaluează Aplicația (Rate the App)',
                          badgeLabel: 'STORE ⏳',
                          onTap: () {
                            _showDevelopmentNotice(context, 'Link-ul către Google Play Store va fi activ la lansarea publică.');
                          },
                        ),
                        _buildSettingsDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: PhosphorIcons.info(PhosphorIconsStyle.bold),
                          title: 'Despre Kurogane Anime App',
                          subtitle: 'Versiunea 1.0.0 • Build Premium',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Kurogane Anime',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2026 Kurogane. Toate drepturile rezervate.',
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(
          bottom: BorderSide(
            color: context.borderSubtle.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button rotund 52px Liquid Glass
          FloatingCircleButton(
            size: 52,
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
              color: context.textPrimary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Titlu Ecran
          Expanded(
            child: Text(
              'Setări & Preferințe',
              style: TextStyle(
                fontFamily: 'Zalando Sans Expanded',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderSubtle.withValues(alpha: 0.4)),
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
      color: context.borderSubtle.withValues(alpha: 0.35),
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
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.bgPrimary.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: titleColor ?? context.accentPrimary, size: 19),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: titleColor ?? context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (badgeLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
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
                style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.3),
              ),
            )
          : null,
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
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
                  hintText: 'Scrie părerea sau problema întâmpinată…',
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
                    backgroundColor: AppColors.signalLive,
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
}

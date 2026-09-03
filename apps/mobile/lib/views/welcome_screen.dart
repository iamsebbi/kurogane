import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import 'auth/login_screen.dart';
import 'main_nav_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _completeWelcome(BuildContext context, {required bool goToLogin}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (context.mounted) {
      if (goToLogin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen(showCloseButton: true)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.bgPrimary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bgPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Brand Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'KUROGANE v1.0',
                        style: TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          color: AppColors.accentSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                // Center Brand Icon & Hero Text
                Column(
                  children: [
                    // Glowing Brand Shield
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accentPrimary, Color(0xFF1E3A8A)],
                        ),
                        border: Border.all(color: AppColors.accentSecondary.withValues(alpha: 0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPrimary.withValues(alpha: 0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Discover the Universe of\nKurogane',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Zalando Sans Expanded',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    const Text(
                      'Your dedicated platform for anime, manga, and real-time episode tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Google Sans',
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Key Highlights (iOS Rounded Cards)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniFeature(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold), 'Watchlist'),
                          Container(width: 1, height: 28, color: AppColors.borderSubtle),
                          _buildMiniFeature(PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold), 'Anti-Bombing'),
                          Container(width: 1, height: 28, color: AppColors.borderSubtle),
                          _buildMiniFeature(PhosphorIcons.devices(PhosphorIconsStyle.bold), 'Sync'),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Action Buttons
                Column(
                  children: [
                    // Primary "Get Started" Button (Steel Azure Pill)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _completeWelcome(context, goToLogin: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontFamily: 'Zalando Sans Expanded',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary "Continue as Guest" Button
                    TextButton(
                      onPressed: () => _completeWelcome(context, goToLogin: false),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'Google Sans',
          ),
        ),
      ],
    );
  }
}

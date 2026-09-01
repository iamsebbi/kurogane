import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../widgets/blur_fade_route.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_logo_header.dart';
import 'widgets/auth_text_field.dart';
import 'google_username_screen.dart';
import 'widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool showCloseButton;

  const LoginScreen({
    super.key,
    this.showCloseButton = true,
  });

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      BlurFadePageRoute(
        fullscreenDialog: true,
        child: const LoginScreen(showCloseButton: true),
      ),
    );
  }

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _localError = null);

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Te rugăm să completezi toate câmpurile.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signIn(
      identifier: identifier,
      password: password,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentificare reușită! Bine ai revenit.'),
          backgroundColor: AppColors.signalLive,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _localError = null);

    final credential = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (credential != null && mounted) {
      final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
      final prefs = await SharedPreferences.getInstance();
      final hasCustomUsername = prefs.getBool('kurogane_custom_username_set_${credential.user?.uid}') ?? false;
      final currentUsername = credential.user?.displayName ?? '';
      final needsUsername = !hasCustomUsername || isNewUser || currentUsername.contains(' ');

      // Onboarding la prima conectare / cand username-ul contine spatii: alegere username personalizat
      if (needsUsername) {
        if (!mounted) return;
        final suggested = AuthService.deriveSuggestedUsername(credential.user);
        await Navigator.of(context).pushReplacement<void, void>(
          BlurFadePageRoute(
            fullscreenDialog: true,
            child: GoogleUsernameScreen(
              suggestedUsername: suggested,
              currentUserId: credential.user?.uid,
              userEmail: credential.user?.email,
            ),
          ),
        );
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentificare cu Google reușită! Bine ai revenit.'),
            backgroundColor: AppColors.signalLive,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final errorMessage = _localError ?? authState.error?.toString();

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (52px Floating Close Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.of(context).canPop() && !widget.showCloseButton)
                    _AuthFloatingCircleButton(
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
                  if (widget.showCloseButton)
                    _AuthFloatingCircleButton(
                      size: 52,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        PhosphorIcons.x(PhosphorIconsStyle.bold),
                        color: context.textPrimary,
                        size: 22,
                      ),
                    )
                  else
                    const SizedBox(width: 52, height: 52),
                ],
              ),
            ),

            // Form Body Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Kurogane Minimalist Header
                    const AuthLogoHeader(
                      title: 'Conectare',
                      subtitle: 'Ne bucurăm să te revedem pe Kurogane.',
                    ),
                    const SizedBox(height: 28),

                    // Error Box
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold), color: context.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: context.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Main Form Card (Minimalist surface)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthTextField(
                            controller: _identifierController,
                            label: 'Adresă Email sau Username',
                            hint: 'nume_utilizator sau email@exemplu.com',
                            icon: PhosphorIcons.user(PhosphorIconsStyle.bold),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Parolă',
                            hint: '••••••••',
                            icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                                    : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                                color: context.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Forgot password link (aligned right)
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  BlurFadePageRoute(
                                    child: const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Ai uitat parola?',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Google Sans',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Primary Action Button (Solid Accent Color + OnPrimary + Tap Feedback)
                          _AuthScaleButton(
                            onTap: isLoading ? () {} : _handleLogin,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: context.accentPrimary,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: context.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Conectează-te',
                                      style: TextStyle(
                                        color: context.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        fontFamily: 'Google Sans',
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Social Auth Buttons (Google & Apple)
                    SocialAuthButtons(
                      isLoading: isLoading,
                      onGooglePressed: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 28),

                    // Switch to Register Screen
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nu ai cont? ',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13.5,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                BlurFadePageRoute(
                                  fullscreenDialog: true,
                                  child: RegisterScreen(
                                    initialEmail: _identifierController.text.contains('@')
                                        ? _identifierController.text.trim()
                                        : null,
                                    showCloseButton: widget.showCloseButton,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Înregistrează-te',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FLOATING 52px GLASS CIRCLE BUTTON PENTRU AUTH (IDENTIC CU HOME & PROFILE) ---
class _AuthFloatingCircleButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;

  const _AuthFloatingCircleButton({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AuthFloatingCircleButton> createState() => _AuthFloatingCircleButtonState();
}

class _AuthFloatingCircleButtonState extends State<_AuthFloatingCircleButton> {
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

class _AuthScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AuthScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AuthScaleButton> createState() => _AuthScaleButtonState();
}

class _AuthScaleButtonState extends State<_AuthScaleButton> {
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

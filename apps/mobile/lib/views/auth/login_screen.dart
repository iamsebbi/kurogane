import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../widgets/blur_fade_route.dart';
import '../../widgets/floating_circle_button.dart';
import '../../widgets/tactile_scale_button.dart';
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
      setState(() => _localError = AppStrings.fillAllFields);
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
          content: Text(AppStrings.signInSuccess),
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
            content: Text(AppStrings.googleSignInSuccess),
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
                  if (widget.showCloseButton)
                    FloatingCircleButton(
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
                      title: AppStrings.signIn,
                      subtitle: AppStrings.welcomeBackSubtitle,
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
                            label: AppStrings.emailOrUsername,
                            hint: AppStrings.emailOrUsernameHint,
                            icon: PhosphorIcons.user(PhosphorIconsStyle.bold),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passwordController,
                            label: AppStrings.password,
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
                                AppStrings.forgotPassword,
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
                          TactileScaleButton(
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
                                      AppStrings.signIn,
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
                            '${AppStrings.dontHaveAccount} ',
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
                              AppStrings.signUp,
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

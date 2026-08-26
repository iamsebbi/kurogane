import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../widgets/blur_fade_route.dart';
import 'login_screen.dart';
import 'widgets/auth_logo_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_auth_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final bool showCloseButton;

  const RegisterScreen({
    super.key,
    this.initialEmail,
    this.showCloseButton = true,
  });

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      BlurFadePageRoute(
        fullscreenDialog: true,
        child: const RegisterScreen(showCloseButton: true),
      ),
    );
  }

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  bool _isEmailValid = false;
  bool _isUsernameValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
      _isEmailValid = AuthService.isValidEmail(widget.initialEmail!);
    }

    _emailController.addListener(_validateFields);
    _usernameController.addListener(_validateFields);
    _passwordController.addListener(_validateFields);
    _confirmPasswordController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      _isEmailValid = AuthService.isValidEmail(_emailController.text.trim());
      _isUsernameValid = AuthService.isValidUsername(_usernameController.text.trim());
      _isPasswordValid = _passwordController.text.length >= 8;
      _isConfirmPasswordValid = _confirmPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text == _passwordController.text;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _localError = null);

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _localError = 'Te rugăm să completezi toate câmpurile.');
      return;
    }
    if (!AuthService.isValidEmail(email)) {
      setState(() => _localError = 'Adresa de email nu este validă.');
      return;
    }
    if (!AuthService.isValidUsername(username)) {
      setState(() => _localError = 'Username-ul trebuie să aibă între 2 și 24 caractere (litere, cifre, _, -).');
      return;
    }
    if (password.length < 8) {
      setState(() => _localError = 'Parola trebuie să aibă cel puțin 8 caractere.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _localError = 'Parolele introduse nu coincid.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signUp(
      username: username,
      email: email,
      password: password,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cont creat cu succes! Bine ai venit pe Kurogane.'),
          backgroundColor: AppColors.signalLive,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _localError = null);

    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentificare cu Google reușită! Bine ai venit pe Kurogane.'),
          backgroundColor: AppColors.signalLive,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
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
            // Top Navigation Bar (52px Floating Close / Back Button)
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
                      title: 'Creare Cont Nou',
                      subtitle: 'Alătură-te comunității Kurogane.',
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
                          // 1. Email Field
                          AuthTextField(
                            controller: _emailController,
                            label: 'Adresă de Email',
                            hint: 'email@exemplu.com',
                            icon: PhosphorIcons.envelope(PhosphorIconsStyle.bold),
                            keyboardType: TextInputType.emailAddress,
                            suffixIcon: _emailController.text.isNotEmpty
                                ? Icon(
                                    _isEmailValid
                                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                                    color: _isEmailValid ? AppColors.signalLive : context.error,
                                    size: 18,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. Username Field
                          AuthTextField(
                            controller: _usernameController,
                            label: 'Nume de Utilizator (2-24 caractere)',
                            hint: 'ex: sebbi_otaku',
                            icon: PhosphorIcons.user(PhosphorIconsStyle.bold),
                            suffixIcon: _usernameController.text.isNotEmpty
                                ? Icon(
                                    _isUsernameValid
                                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                                    color: _isUsernameValid ? AppColors.signalLive : context.error,
                                    size: 18,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // 3. Password Field
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Parolă (minim 8 caractere)',
                            hint: '••••••••',
                            icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                            obscureText: _obscurePassword,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_passwordController.text.isNotEmpty)
                                  Icon(
                                    _isPasswordValid
                                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                                    color: _isPasswordValid ? AppColors.signalLive : context.error,
                                    size: 18,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                                        : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                                    color: context.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. Confirm Password Field
                          AuthTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmă Parola',
                            hint: '••••••••',
                            icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_confirmPasswordController.text.isNotEmpty)
                                  Icon(
                                    _isConfirmPasswordValid
                                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                                    color: _isConfirmPasswordValid ? AppColors.signalLive : context.error,
                                    size: 18,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                                        : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                                    color: context.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Primary Action Button (Solid Accent Color + OnPrimary + Tap Feedback)
                          _AuthScaleButton(
                            onTap: isLoading ? () {} : _handleRegister,
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
                                      'Creează contul',
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

                    // Switch to Login Screen
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ai deja cont? ',
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
                                  child: LoginScreen(showCloseButton: widget.showCloseButton),
                                ),
                              );
                            },
                            child: Text(
                              'Conectează-te',
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

// --- FLOATING 52px GLASS CIRCLE BUTTON PENTRU AUTH ---
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

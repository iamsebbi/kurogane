import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

enum AuthMode {
  signIn,
  signUp,
  forgotPassword,
}

class AuthModalSheet extends ConsumerStatefulWidget {
  final AuthMode initialMode;
  final bool isFullScreen;

  const AuthModalSheet({
    super.key,
    this.initialMode = AuthMode.signIn,
    this.isFullScreen = false,
  });

  static Future<void> show(
    BuildContext context, {
    AuthMode mode = AuthMode.signIn,
    bool isFullScreen = false,
  }) {
    if (isFullScreen) {
      return Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => AuthModalSheet(
            initialMode: mode,
            isFullScreen: true,
          ),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthModalSheet(
        initialMode: mode,
        isFullScreen: false,
      ),
    );
  }

  @override
  ConsumerState<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends ConsumerState<AuthModalSheet> {
  late AuthMode _mode;

  final _identifierController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;

    // Listeners for live real-time validation
    _identifierController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _usernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);

    _identifierController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Live validation helpers
  bool get _isEmailValid => AuthService.isValidEmail(_emailController.text);
  bool get _isUsernameValid => AuthService.isValidUsername(_usernameController.text);
  bool get _isPasswordValid => _passwordController.text.length >= 8;
  bool get _isConfirmPasswordValid =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;

  void _switchMode(AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _localError = null;
      _successMessage = null;
    });
    ref.read(authControllerProvider.notifier).clearError();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _localError = null;
      _successMessage = null;
    });

    final authController = ref.read(authControllerProvider.notifier);

    if (_mode == AuthMode.signIn) {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;

      if (identifier.isEmpty) {
        setState(() => _localError = 'Introdu numele de utilizator sau adresa de email.');
        return;
      }
      if (password.isEmpty) {
        setState(() => _localError = 'Introdu parola contului tău.');
        return;
      }

      final success = await authController.signIn(
        identifier: identifier,
        password: password,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentificare reușită! Bine ai revenit pe Kurogane.'),
            backgroundColor: AppColors.signalLive,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else if (_mode == AuthMode.signUp) {
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (!AuthService.isValidEmail(email)) {
        setState(() => _localError = 'Introdu o adresă de email validă.');
        return;
      }
      if (!AuthService.isValidUsername(username)) {
        setState(() => _localError = 'Numele de utilizator trebuie să conțină 2-24 caractere (litere, cifre, _, -, .).');
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

      final success = await authController.signUp(
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
    } else if (_mode == AuthMode.forgotPassword) {
      final email = _emailController.text.trim();
      if (!AuthService.isValidEmail(email)) {
        setState(() => _localError = 'Introdu o adresă de email validă.');
        return;
      }

      final success = await authController.sendPasswordReset(email);
      if (success && mounted) {
        setState(() {
          _successMessage = 'Dacă adresa există în sistem, am trimis un link de resetare pe email.';
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _localError = null;
      _successMessage = null;
    });

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
    if (widget.isFullScreen) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.bgPrimary,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.bgPrimary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.bgPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: AppColors.bgPrimary,
              statusBarIconBrightness: Brightness.light,
            ),
            leading: const SizedBox.shrink(),
            leadingWidth: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'KUROGANE',
                    style: TextStyle(
                      fontFamily: 'Zalando Sans Expanded',
                      color: AppColors.accentSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: _buildFormContent(isModalSheet: false),
          ),
        ),
      ),
    );
  }

    // Modal Bottom Sheet Layout
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.2),
          left: BorderSide(color: AppColors.borderSubtle, width: 1.2),
          right: BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFormContent(isModalSheet: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent({required bool isModalSheet}) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final errorMessage = _localError ?? authState.error?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _mode == AuthMode.signIn
                  ? 'Conectare'
                  : _mode == AuthMode.signUp
                      ? 'Creare Cont Nou'
                      : 'Resetare Parolă',
              style: const TextStyle(
                fontFamily: 'Zalando Sans Expanded',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isModalSheet)
              IconButton(
                icon: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _mode == AuthMode.signIn
              ? 'Autentifică-te pentru a-ți sincroniza lista și recenziile.'
              : _mode == AuthMode.signUp
                  ? 'Alătură-te comunității Kurogane.'
                  : 'Introdu adresa ta de email pentru a primi instrucțiunile.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),

        // Tab Switcher (Conectare / Înregistrare)
        if (_mode != AuthMode.forgotPassword) ...[
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isModalSheet ? AppColors.bgPrimary : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(AuthMode.signIn),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _mode == AuthMode.signIn ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Conectare',
                        style: TextStyle(
                          fontWeight: _mode == AuthMode.signIn ? FontWeight.bold : FontWeight.w500,
                          color: _mode == AuthMode.signIn ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(AuthMode.signUp),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _mode == AuthMode.signUp ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Înregistrare',
                        style: TextStyle(
                          fontWeight: _mode == AuthMode.signUp ? FontWeight.bold : FontWeight.w500,
                          color: _mode == AuthMode.signUp ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Google OAuth Button (Above the form)
          OutlinedButton(
            onPressed: isLoading ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: isModalSheet ? AppColors.bgPrimary : AppColors.bgSurface,
              side: const BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Continuă cu Google',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider "sau continuă cu email"
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _mode == AuthMode.signIn ? 'sau conectează-te cu email' : 'sau înregistrează-te cu email',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Error Box
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.alertCoral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.alertCoral.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold), color: AppColors.alertCoral, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: AppColors.alertCoral, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Success Box
        if (_successMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.signalLive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.signalLive.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.bold), color: AppColors.signalLive, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: AppColors.signalLive, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Form Fields
        if (_mode == AuthMode.signIn) ...[
          _buildTextField(
            controller: _identifierController,
            label: 'Username sau Email',
            hint: 'nume sau email@exemplu.com',
            icon: PhosphorIcons.user(PhosphorIconsStyle.bold),
            keyboardType: TextInputType.emailAddress,
            isModalSheet: isModalSheet,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            label: 'Parolă',
            hint: '••••••••',
            icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
            obscureText: _obscurePassword,
            isModalSheet: isModalSheet,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                    : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _switchMode(AuthMode.forgotPassword),
              child: const Text(
                'Ai uitat parola?',
                style: TextStyle(color: AppColors.accentSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ] else if (_mode == AuthMode.signUp) ...[
          // EXACT ORDER: Email -> Username -> Parolă -> Confirmă Parolă
          _buildTextField(
            controller: _emailController,
            label: 'Adresă de Email',
            hint: 'email@exemplu.com',
            icon: PhosphorIcons.envelope(PhosphorIconsStyle.bold),
            keyboardType: TextInputType.emailAddress,
            isModalSheet: isModalSheet,
            suffixIcon: _emailController.text.isNotEmpty
                ? Icon(
                    _isEmailValid
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                    color: _isEmailValid ? AppColors.signalLive : AppColors.alertCoral,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _usernameController,
            label: 'Nume de Utilizator (2-24 caractere)',
            hint: 'ex: sebbi_otaku',
            icon: PhosphorIcons.user(PhosphorIconsStyle.bold),
            isModalSheet: isModalSheet,
            suffixIcon: _usernameController.text.isNotEmpty
                ? Icon(
                    _isUsernameValid
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                    color: _isUsernameValid ? AppColors.signalLive : AppColors.alertCoral,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            label: 'Parolă (minim 8 caractere)',
            hint: '••••••••',
            icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
            obscureText: _obscurePassword,
            isModalSheet: isModalSheet,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_passwordController.text.isNotEmpty)
                  Icon(
                    _isPasswordValid
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                    color: _isPasswordValid ? AppColors.signalLive : AppColors.alertCoral,
                    size: 18,
                  ),
                IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                        : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmă Parola',
            hint: '••••••••',
            icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
            obscureText: _obscureConfirmPassword,
            isModalSheet: isModalSheet,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_confirmPasswordController.text.isNotEmpty)
                  Icon(
                    _isConfirmPasswordValid
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                        : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                    color: _isConfirmPasswordValid ? AppColors.signalLive : AppColors.alertCoral,
                    size: 18,
                  ),
                IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                        : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ] else if (_mode == AuthMode.forgotPassword) ...[
          _buildTextField(
            controller: _emailController,
            label: 'Adresă de Email Înregistrată',
            hint: 'email@exemplu.com',
            icon: PhosphorIcons.envelope(PhosphorIconsStyle.bold),
            keyboardType: TextInputType.emailAddress,
            isModalSheet: isModalSheet,
          ),
          const SizedBox(height: 18),
        ],

        // Submit Button
        ElevatedButton(
          onPressed: isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accentPrimary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _mode == AuthMode.signIn
                      ? 'Conectează-te'
                      : _mode == AuthMode.signUp
                          ? 'Creează Contul'
                          : 'Trimite Link Resetare',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        ),
        const SizedBox(height: 16),

        // Switch between Sign In and Sign Up links
        if (_mode == AuthMode.signIn) ...[
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Nu ai cont? ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {
                    if (_identifierController.text.contains('@') && _emailController.text.isEmpty) {
                      _emailController.text = _identifierController.text.trim();
                    }
                    _switchMode(AuthMode.signUp);
                  },
                  child: const Text(
                    'Înregistrează-te',
                    style: TextStyle(
                      color: AppColors.accentSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_mode == AuthMode.signUp) ...[
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ai deja cont? ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {
                    if (_emailController.text.isNotEmpty && _identifierController.text.isEmpty) {
                      _identifierController.text = _emailController.text.trim();
                    }
                    _switchMode(AuthMode.signIn);
                  },
                  child: const Text(
                    'Conectează-te',
                    style: TextStyle(
                      color: AppColors.accentSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_mode == AuthMode.forgotPassword) ...[
          Center(
            child: TextButton.icon(
              onPressed: () => _switchMode(AuthMode.signIn),
              icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), size: 16, color: AppColors.textSecondary),
              label: const Text(
                'Înapoi la Conectare',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isModalSheet,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isModalSheet ? AppColors.bgPrimary : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

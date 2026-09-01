import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/auth_service.dart';
import '../../widgets/blur_fade_route.dart';

enum _SubmitPhase { idle, loading, success }

/// Ecran Complet pentru alegerea și verificarea numelui de utilizator la conectarea cu Google
class GoogleUsernameScreen extends ConsumerStatefulWidget {
  final String suggestedUsername;
  final String? currentUserId;
  final String? userEmail;

  const GoogleUsernameScreen({
    super.key,
    required this.suggestedUsername,
    this.currentUserId,
    this.userEmail,
  });

  static Future<void> show(
    BuildContext context, {
    required String suggestedUsername,
    String? currentUserId,
    String? userEmail,
  }) {
    return Navigator.of(context).push<void>(
      BlurFadePageRoute(
        fullscreenDialog: true,
        child: GoogleUsernameScreen(
          suggestedUsername: suggestedUsername,
          currentUserId: currentUserId,
          userEmail: userEmail,
        ),
      ),
    );
  }

  @override
  ConsumerState<GoogleUsernameScreen> createState() => _GoogleUsernameScreenState();
}

class _GoogleUsernameScreenState extends ConsumerState<GoogleUsernameScreen> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  bool _isChecking = false;
  bool? _isAvailable;
  String? _statusMessage;
  _SubmitPhase _submitPhase = _SubmitPhase.idle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedUsername);
    _controller.addListener(_onTextChanged);
    // Verifică disponibilitatea inițială a numelui sugerat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability(_controller.text.trim());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_submitPhase != _SubmitPhase.idle) return;
    final text = _controller.text.trim();
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _statusMessage = 'Numele de utilizator nu poate fi gol.';
      });
      return;
    }

    if (!AuthService.isValidUsername(text)) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _statusMessage = 'Folosește 2-24 caractere (litere, cifre, _, -, .)';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _checkAvailability(text);
    });
  }

  Future<void> _checkAvailability(String username) async {
    if (!mounted) return;
    final result = await ref.read(authServiceProvider).checkUsernameAvailable(
          username,
          excludeUserId: widget.currentUserId,
          email: widget.userEmail,
        );

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _isAvailable = result.available;
      _statusMessage = result.available
          ? 'Nume de utilizator disponibil'
          : (result.error ?? 'Acest nume de utilizator este deja folosit.');
    });
  }

  Future<void> _submit([String? overrideUsername]) async {
    final text = (overrideUsername ?? _controller.text).trim();
    if (_submitPhase != _SubmitPhase.idle) return;

    if (!AuthService.isValidUsername(text)) {
      setState(() {
        _statusMessage = 'Numele trebuie să aibă între 2 și 24 caractere valide.';
        _isAvailable = false;
      });
      return;
    }

    // Faza 1: Se ascunde textul și apare animația de loading
    setState(() => _submitPhase = _SubmitPhase.loading);
    HapticFeedback.mediumImpact();

    try {
      final minLoadingDelay = Future.delayed(const Duration(milliseconds: 600));

      // Actualizare profil în backend și storage local
      await ref.read(userProfileProvider.notifier).updateProfile(
            username: text,
          );

      if (widget.currentUserId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('kurogane_custom_username_set_${widget.currentUserId}', true);
      }

      ref.invalidate(currentUserProvider);
      ref.invalidate(userProfileProvider);

      await minLoadingDelay;

      if (!mounted) return;

      // Faza 2: Apare textul 'Gata!' cu bifa animată
      setState(() => _submitPhase = _SubmitPhase.success);
      HapticFeedback.lightImpact();

      // Pauză pentru a savura starea de succes (800ms)
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Faza 3: Tranziție directă în ecranul de profil
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bun venit pe Kurogane! Profilul tău a fost creat.'),
          backgroundColor: AppColors.signalLive,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitPhase = _SubmitPhase.idle;
          _statusMessage = 'A apărut o eroare la salvarea profilului. Reîncearcă.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = (_isAvailable == true || _controller.text.trim() == widget.suggestedUsername) && !_isChecking;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Main Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // Titlu Principal
                    Text(
                      'Alege-ți Numele de Utilizator',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontFamily: 'Zalando Sans Expanded',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitlu
                    Text(
                      'Sub acest @handle vei fi recunoscut în comunitatea Kurogane, în comentarii și în clasamente.',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontFamily: 'Google Sans',
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Input Field Pill Full-Rounded (9999)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
                        border: Border.all(
                          color: _isAvailable == false
                              ? context.error
                              : (_isAvailable == true
                                  ? const Color(0xFF10B981)
                                  : context.accentPrimary.withValues(alpha: 0.2)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Prefix Icon @ de la Phosphor
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 12),
                            child: Icon(
                              PhosphorIcons.at(PhosphorIconsStyle.bold),
                              color: _isAvailable == true
                                  ? const Color(0xFF10B981)
                                  : context.accentPrimary,
                              size: 20,
                            ),
                          ),

                          // Text Input
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              enabled: _submitPhase == _SubmitPhase.idle,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              autocorrect: false,
                              enableSuggestions: false,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontFamily: 'Google Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'nume_utilizator',
                                hintStyle: TextStyle(
                                  color: context.textMuted,
                                  fontFamily: 'Google Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                          // Suffix Indicator: Loading, Checkmark, sau Clear
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: _buildSuffixIndicator(context),
                          ),
                        ],
                      ),
                    ),

                    // Status Message (Disponibil / Eroare)
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              _isAvailable == true
                                  ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                                  : PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                              size: 15,
                              color: _isAvailable == true
                                  ? const Color(0xFF10B981)
                                  : context.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: _isAvailable == true
                                      ? const Color(0xFF10B981)
                                      : context.error,
                                  fontFamily: 'Google Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Primary Action Button (Pill 9999) cu animatie interactiva: Idle -> Loading -> Gata!
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 52,
                      decoration: BoxDecoration(
                        color: _submitPhase == _SubmitPhase.success
                            ? const Color(0xFF10B981)
                            : (isValid
                                ? context.accentPrimary
                                : context.accentPrimary.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
                      ),
                      child: ElevatedButton(
                        onPressed: (isValid && _submitPhase == _SubmitPhase.idle)
                            ? () => _submit()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          foregroundColor: context.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          elevation: 0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: _buildButtonContent(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Secondary Action: Păstrează sugestia
                    Center(
                      child: TextButton(
                        onPressed: _submitPhase != _SubmitPhase.idle
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _submit(widget.suggestedUsername);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: context.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: Text(
                          'Păstrează @${widget.suggestedUsername}',
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildButtonContent(BuildContext context) {
    switch (_submitPhase) {
      case _SubmitPhase.loading:
        return SizedBox(
          key: const ValueKey('loading'),
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: context.onPrimary,
          ),
        );

      case _SubmitPhase.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack, // Bouncy spring effect
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Gata!',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );

      case _SubmitPhase.idle:
        return Row(
          key: const ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirmă și Continuă',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: context.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
              size: 16,
              color: context.onPrimary,
            ),
          ],
        );
    }
  }

  Widget _buildSuffixIndicator(BuildContext context) {
    if (_isChecking) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.accentPrimary,
        ),
      );
    }

    if (_isAvailable == true) {
      return Icon(
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFF10B981),
        size: 20,
      );
    }

    if (_controller.text.isNotEmpty && _submitPhase == _SubmitPhase.idle) {
      return IconButton(
        icon: Icon(
          PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
          color: context.textMuted,
          size: 18,
        ),
        onPressed: () => _controller.clear(),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      );
    }

    return const SizedBox.shrink();
  }
}

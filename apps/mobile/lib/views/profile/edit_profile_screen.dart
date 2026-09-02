import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/blur_fade_route.dart';
import '../../widgets/floating_circle_button.dart';

/// Ecran Complet pentru Editarea Profilului Utilizatorului (cu suport Back Button & Gesturi de Sistem)
class EditProfileScreen extends ConsumerStatefulWidget {
  final fb.User user;
  final String currentDisplayName;
  final String currentHandle;
  final String currentPronoun;
  final String currentBio;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.currentDisplayName,
    required this.currentHandle,
    required this.currentPronoun,
    required this.currentBio,
  });

  static Future<void> show(
    BuildContext context, {
    required fb.User user,
    required String currentDisplayName,
    required String currentHandle,
    required String currentPronoun,
    required String currentBio,
  }) {
    return Navigator.of(context).push<void>(
      BlurFadePageRoute(
        child: EditProfileScreen(
          user: user,
          currentDisplayName: currentDisplayName,
          currentHandle: currentHandle,
          currentPronoun: currentPronoun,
          currentBio: currentBio,
        ),
      ),
    );
  }

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _handleController;
  late final TextEditingController _bioController;
  late final TextEditingController _customPronounController;

  Timer? _debounceTimer;
  bool _isCheckingHandle = false;
  bool? _isHandleAvailable;
  String? _handleError;

  late String _selectedPronoun;
  late bool _isCustomPronoun;
  bool _isSaving = false;

  static const _predefinedPronouns = [
    'el/lui',
    'ea/ei',
    'ei/lor',
    'they/them',
    'he/him',
    'she/her',
    'Fără preferință',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentDisplayName);
    _handleController = TextEditingController(text: widget.currentHandle);
    _bioController = TextEditingController(text: widget.currentBio);
    _customPronounController = TextEditingController();

    _selectedPronoun = widget.currentPronoun;
    _isCustomPronoun = !_predefinedPronouns.contains(widget.currentPronoun) && widget.currentPronoun.isNotEmpty;
    if (_isCustomPronoun) {
      _customPronounController.text = widget.currentPronoun;
      _selectedPronoun = 'Personalizat...';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _customPronounController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onHandleChanged(String val, bool canChange) {
    if (!canChange) return;
    _debounceTimer?.cancel();
    final clean = val.trim().toLowerCase();

    if (clean == widget.currentHandle.toLowerCase()) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = true;
        _handleError = null;
      });
      return;
    }

    if (clean.isEmpty) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = false;
        _handleError = 'Introdu un @handle.';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_.-]{2,24}$').hasMatch(clean)) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = false;
        _handleError = '2-24 caractere (litere, cifre, _, -, .)';
      });
      return;
    }

    setState(() {
      _isCheckingHandle = true;
      _handleError = null;
      _isHandleAvailable = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await ref.read(authServiceProvider).checkUsernameAvailable(
          clean,
          excludeUserId: widget.user.uid,
        );
        if (!mounted) return;
        setState(() {
          _isCheckingHandle = false;
          _isHandleAvailable = res.available;
          _handleError = res.available ? null : (res.error ?? 'Acest @handle este deja ocupat.');
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingHandle = false;
          _isHandleAvailable = true;
          _handleError = null;
        });
      }
    });
  }

  Future<void> _handleSave(bool canChangeHandle) async {
    if (_isSaving) return;
    final newName = _nameController.text.trim();
    final rawHandle = _handleController.text.trim();
    final finalPronoun = _isCustomPronoun
        ? _customPronounController.text.trim()
        : _selectedPronoun;
    final newBio = _bioController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numele afișat nu poate fi gol.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isChangingHandle = canChangeHandle &&
        rawHandle.isNotEmpty &&
        rawHandle.toLowerCase() != widget.currentHandle.toLowerCase();

    if (isChangingHandle) {
      if (_isCheckingHandle) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se verifică disponibilitatea @handle-ului...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_isHandleAvailable == false || _handleError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_handleError ?? 'Numele de utilizator nu este valid sau este deja ocupat.'),
            backgroundColor: context.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final targetHandle = isChangingHandle ? rawHandle : widget.currentHandle;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await widget.user.updateDisplayName(newName);
      await ref.read(userProfileProvider.notifier).updateProfile(
            username: targetHandle,
            pronoun: finalPronoun,
            bio: newBio,
          );
      ref.invalidate(currentUserProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilul a fost actualizat cu succes!'),
          backgroundColor: AppColors.signalLive,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String msg = 'Eroare la salvare: $e';
        if (e is DioException && e.response?.data is Map) {
          final errStr = e.response!.data['error'];
          if (errStr != null) msg = errStr.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: context.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final canChangeHandle = userProfile.canChangeUsername;
    final daysRemaining = userProfile.daysUntilUsernameChangeAllowed;

    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSaving) {
          // Prevent pop while actively saving
          return;
        }
      },
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar cu Back Button & Titlu
              _buildTopBar(context),

              // Corp formular scrollable
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Handle Unic / Nume de Utilizator (@handle)
                      Row(
                        children: [
                          Text(
                            'Nume de Utilizator (@handle)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (!canChangeHandle)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: context.accentPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: context.accentPrimary.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIcons.clock(PhosphorIconsStyle.bold),
                                    size: 11,
                                    color: context.accentPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'În $daysRemaining ${daysRemaining == 1 ? 'zi' : 'zile'}',
                                    style: TextStyle(
                                      color: context.accentPrimary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppColors.signalLive.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: AppColors.signalLive.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                                    size: 11,
                                    color: AppColors.signalLive,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Editabil acum',
                                    style: TextStyle(
                                      color: AppColors.signalLive,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (!canChangeHandle) ...[
                        // Handle blocat (14 zile cooldown)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: context.bgSurface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: context.borderSubtle.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                                size: 17,
                                color: context.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '@${widget.currentHandle}',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
                                size: 15,
                                color: context.textMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.info(PhosphorIconsStyle.bold),
                                size: 13,
                                color: context.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ai modificat recent handle-ul. Îl vei putea schimba din nou peste $daysRemaining ${daysRemaining == 1 ? 'zi' : 'zile'}.',
                                  style: TextStyle(
                                    color: context.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Handle editabil (cu verificare live debounced)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.bgSurface,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: _handleError != null
                                  ? context.error
                                  : (_isHandleAvailable == true &&
                                          _handleController.text.trim().toLowerCase() !=
                                              widget.currentHandle.toLowerCase()
                                      ? AppColors.signalLive
                                      : context.borderSubtle),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.at(PhosphorIconsStyle.bold),
                                size: 18,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _handleController,
                                  onChanged: (val) => _onHandleChanged(val, canChangeHandle),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.-]')),
                                    LengthLimitingTextInputFormatter(24),
                                  ],
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'introdu_noul_handle',
                                    hintStyle: TextStyle(
                                      color: context.textMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                ),
                              ),
                              if (_isCheckingHandle)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.accentPrimary,
                                  ),
                                )
                              else if (_isHandleAvailable == true &&
                                  _handleController.text.trim().toLowerCase() !=
                                      widget.currentHandle.toLowerCase())
                                Icon(
                                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                                  size: 18,
                                  color: AppColors.signalLive,
                                )
                              else if (_handleError != null)
                                Icon(
                                  PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                                  size: 18,
                                  color: context.error,
                                )
                              else
                                Icon(
                                  PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
                                  size: 16,
                                  color: context.textMuted,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Icon(
                                _handleError != null
                                    ? PhosphorIcons.warning(PhosphorIconsStyle.bold)
                                    : PhosphorIcons.info(PhosphorIconsStyle.bold),
                                size: 13,
                                color: _handleError != null ? context.error : context.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _handleError ??
                                      'Atenție: Îți poți schimba @handle-ul o singură dată la 14 zile.',
                                  style: TextStyle(
                                    color: _handleError != null ? context.error : context.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: _handleError != null ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 2. Nume Afișat
                      Text(
                        'Nume Afișat',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: context.borderSubtle.withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSaving,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 16, // >=16 to prevent iOS zoom
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Introdu numele tău…',
                            hintStyle: TextStyle(
                              color: context.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Selector Pronume (Chips FULL ROUNDED)
                      Text(
                        'Pronume',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._predefinedPronouns.map((p) {
                            final isSelected = !_isCustomPronoun && _selectedPronoun == p;
                            return GestureDetector(
                              onTap: _isSaving
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _selectedPronoun = p;
                                        _isCustomPronoun = false;
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? context.accentPrimary : context.bgSurface,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: isSelected
                                        ? context.accentPrimary
                                        : context.borderSubtle.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    color: isSelected ? context.onPrimary : context.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _isSaving
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedPronoun = 'Personalizat...';
                                      _isCustomPronoun = true;
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isCustomPronoun ? context.accentPrimary : context.bgSurface,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                  color: _isCustomPronoun
                                      ? context.accentPrimary
                                      : context.borderSubtle.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'Personalizat…',
                                style: TextStyle(
                                  color: _isCustomPronoun ? context.onPrimary : context.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: _isCustomPronoun ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isCustomPronoun) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: context.bgSurface,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: context.borderSubtle.withValues(alpha: 0.5)),
                          ),
                          child: TextField(
                            controller: _customPronounController,
                            enabled: !_isSaving,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'ex: el/lui, per/pers…',
                              hintStyle: TextStyle(
                                color: context.textMuted,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 4. Bio / Despre mine
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Despre Tine (Bio)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _bioController,
                            builder: (context, value, _) {
                              final count = value.text.length;
                              final isNearLimit = count > 450;
                              return Text(
                                '$count / 500',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: count >= 500
                                      ? context.error
                                      : (isNearLimit ? context.brandHighlight : context.textMuted),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.borderSubtle.withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          controller: _bioController,
                          enabled: !_isSaving,
                          maxLines: 4,
                          maxLength: 500,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 16,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'O scurtă descriere a pasiunii tale pentru anime…',
                            hintStyle: TextStyle(
                              color: context.textMuted,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Primary Action Button (Salvează Modificările)
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _handleSave(canChangeHandle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accentPrimary,
                            disabledBackgroundColor: context.accentPrimary.withValues(alpha: 0.35),
                            foregroundColor: context.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: context.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Salvează Modificările',
                                  style: TextStyle(
                                    fontFamily: 'Google Sans',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    color: context.onPrimary,
                                  ),
                                ),
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
              'Editează Profilul',
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
}

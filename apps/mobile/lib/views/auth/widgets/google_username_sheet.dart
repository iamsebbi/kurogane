import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/auth_service.dart';

/// Modal Bottom Sheet pentru alegerea numelui de utilizator la prima conectare cu Google
class GoogleUsernameSheet extends StatefulWidget {
  final String suggestedUsername;

  const GoogleUsernameSheet({
    super.key,
    required this.suggestedUsername,
  });

  static Future<String?> show(
    BuildContext context, {
    required String suggestedUsername,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => GoogleUsernameSheet(
        suggestedUsername: suggestedUsername,
      ),
    );
  }

  @override
  State<GoogleUsernameSheet> createState() => _GoogleUsernameSheetState();
}

class _GoogleUsernameSheetState extends State<GoogleUsernameSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedUsername);
    _controller.addListener(_validate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Numele de utilizator nu poate fi gol.');
    } else if (text.length < 2 || text.length > 24) {
      setState(() => _errorText = 'Trebuie să aibă între 2 și 24 caractere.');
    } else if (!AuthService.isValidUsername(text)) {
      setState(() => _errorText = 'Folosește doar litere, cifre, _, - sau .');
    } else {
      setState(() => _errorText = null);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (!AuthService.isValidUsername(text)) {
      _validate();
      return;
    }
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isValid = _errorText == null && _controller.text.trim().isNotEmpty;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: context.accentPrimary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sparkle / Welcome Icon Badge
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: context.accentPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.accentPrimary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    color: context.accentPrimary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Bun venit pe Kurogane!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textPrimary,
                  fontFamily: 'Zalando Sans Expanded',
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Alege-ți un username unic sub care vei fi cunoscut în comunitatea de anime & manga.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontFamily: 'Google Sans',
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Username Input Field
              Container(
                decoration: BoxDecoration(
                  color: context.bgPrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorText != null
                        ? context.error
                        : (isValid ? context.accentPrimary : context.accentPrimary.withValues(alpha: 0.2)),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '@',
                        style: TextStyle(
                          color: context.accentPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                              color: context.textMuted,
                              size: 18,
                            ),
                            onPressed: () => _controller.clear(),
                          )
                        : null,
                    hintText: 'nume_utilizator',
                    hintStyle: TextStyle(
                      color: context.textMuted,
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              // Error Text
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                        size: 14,
                        color: context.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            color: context.error,
                            fontFamily: 'Google Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Primary Action: Confirm Button
              ElevatedButton(
                onPressed: isValid && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentPrimary,
                  disabledBackgroundColor: context.accentPrimary.withValues(alpha: 0.3),
                  foregroundColor: context.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.onPrimary,
                        ),
                      )
                    : const Text(
                        'Confirmă și Continuă',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // Secondary Action: Keep suggested username
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(widget.suggestedUsername);
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'Păstrează @${widget.suggestedUsername}',
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

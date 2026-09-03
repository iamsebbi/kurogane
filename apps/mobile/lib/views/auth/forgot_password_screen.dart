import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../widgets/floating_circle_button.dart';
import '../../widgets/tactile_scale_button.dart';
import 'widgets/auth_logo_header.dart';
import 'widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _localError;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() {
      _localError = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    if (!AuthService.isValidEmail(email)) {
      setState(() => _localError = AppStrings.invalidEmail);
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (success && mounted) {
      setState(() {
        _successMessage = 'If this email exists in our system, we have sent a password reset link.';
      });
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
            // Top Navigation Bar (52px Floating Back Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  FloatingCircleButton(
                    size: 52,
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                      color: context.textPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Body Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    AuthLogoHeader(
                      icon: PhosphorIcons.lockKey(PhosphorIconsStyle.regular),
                      title: 'Reset Password',
                      subtitle: 'Enter your email address to receive a password reset link.',
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

                    // Success Box
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.signalLive.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.signalLive.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.bold), color: AppColors.signalLive, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  color: AppColors.signalLive,
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

                    // Main Form Card
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
                            controller: _emailController,
                            label: 'Registered Email Address',
                            hint: 'email@example.com',
                            icon: PhosphorIcons.envelope(PhosphorIconsStyle.bold),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 22),

                          // Primary Action Button (Solid Accent Color + OnPrimary + Tap Feedback)
                          TactileScaleButton(
                            onTap: isLoading ? () {} : _handleReset,
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
                                      'Send Reset Link',
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
                    const SizedBox(height: 28),

                    // Back to Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                              size: 16,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Back to ${AppStrings.signIn}',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                          ],
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
    );
  }
}

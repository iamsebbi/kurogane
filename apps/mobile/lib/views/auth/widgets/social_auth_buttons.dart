import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
// ignore: implementation_imports
import 'package:sign_in_with_apple/src/widgets/apple_logo_painter.dart';
import '../../../core/constants/app_colors.dart';

class SocialAuthButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGooglePressed;
  final VoidCallback? onApplePressed;

  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    required this.onGooglePressed,
    this.onApplePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Separator
        Row(
          children: [
            Expanded(child: Divider(color: context.borderSubtle, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'sau continuă cu',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  fontFamily: 'Google Sans',
                ),
              ),
            ),
            Expanded(child: Divider(color: context.borderSubtle, thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),

        // Google Sign-In Button (Official Vector Google G Logo)
        _SocialScaleButton(
          onTap: isLoading ? () {} : onGooglePressed,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoogleLogoIcon(size: 20),
                SizedBox(width: 12),
                Text(
                  'Continuă cu Google',
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Apple Sign-In Button (Official AppleLogoPainter din sign_in_with_apple + Google Sans Font)
        _SocialScaleButton(
          onTap: isLoading
              ? () {}
              : () {
                  if (onApplePressed != null) {
                    onApplePressed!();
                  } else {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              PhosphorIcons.info(PhosphorIconsStyle.fill),
                              color: context.accentPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Autentificarea cu Apple va fi disponibilă în curând.',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontFamily: 'Google Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: context.bgSurface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: context.borderSubtle, width: 1.2),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.black : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: context.borderSubtle),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  painter: AppleLogoPainter(
                    color: Colors.white,
                  ),
                  size: Size(17, 20),
                ),
                SizedBox(width: 10),
                Text(
                  'Continuă cu Apple',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_SocialScaleButton> createState() => _SocialScaleButtonState();
}

class _SocialScaleButtonState extends State<_SocialScaleButton> {
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

/// Official Vector Google 4-Color "G" Icon
class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
    );
  }
}

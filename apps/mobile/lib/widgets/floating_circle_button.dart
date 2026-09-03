import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// Buton plutitor rotund 52x52 cu efect Liquid Glass și micro-animație elastică (design system Kurogane)
class FloatingCircleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const FloatingCircleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 52.0,
  });

  @override
  State<FloatingCircleButton> createState() => _FloatingCircleButtonState();
}

class _FloatingCircleButtonState extends State<FloatingCircleButton> {
  bool _isPressed = false;
  static final _glassFilter = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

  @override
  Widget build(BuildContext context) {
    final Color buttonBg = _isPressed
        ? (context.isDarkMode ? const Color(0xFF383838) : Colors.white)
        : (context.isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFFAF7F0));

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 1.08 : 1.0,
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
                color: buttonBg.withValues(
                  alpha: _isPressed
                      ? (context.isDarkMode ? 0.88 : 0.96)
                      : (context.isDarkMode ? 0.72 : 0.78),
                ),
                border: Border.all(
                  color: !context.isDarkMode
                      ? Colors.white.withValues(alpha: _isPressed ? 0.95 : 0.70)
                      : Colors.transparent,
                  width: 0.6,
                ),
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

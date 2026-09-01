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
                color: _isPressed
                    ? context.bgSurfaceHover
                    : context.bgSurface.withValues(alpha: context.isDarkMode ? 0.75 : 0.88),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode
                          ? (_isPressed ? 0.35 : 0.20)
                          : (_isPressed ? 0.10 : 0.05),
                    ),
                    blurRadius: _isPressed ? 10 : 6,
                    offset: const Offset(0, 2),
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

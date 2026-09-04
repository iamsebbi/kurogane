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

  static final ImageFilter _glassFilter = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode
                      ? (_isPressed ? 0.45 : 0.30)
                      : (_isPressed ? 0.12 : 0.08),
                ),
                blurRadius: _isPressed ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                      : context.bgSurface.withValues(
                          alpha: context.isDarkMode ? 0.75 : 0.88,
                        ),
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: _isPressed ? 0.20 : 0.12)
                        : Colors.black.withValues(alpha: _isPressed ? 0.10 : 0.05),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Buton plutitor alungit tip capsulă (Pill) cu același efect Liquid Glass și micro-animație elastică
class FloatingPillButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double height;

  const FloatingPillButton({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.height = 46.0,
  });

  @override
  State<FloatingPillButton> createState() => _FloatingPillButtonState();
}

class _FloatingPillButtonState extends State<FloatingPillButton> {
  bool _isPressed = false;

  static final ImageFilter _glassFilter = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
        scale: _isPressed ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode
                      ? (_isPressed ? 0.40 : 0.25)
                      : (_isPressed ? 0.10 : 0.06),
                ),
                blurRadius: _isPressed ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: BackdropFilter(
              filter: _glassFilter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  color: _isPressed
                      ? context.bgSurfaceHover
                      : context.bgSurface.withValues(
                          alpha: context.isDarkMode ? 0.75 : 0.88,
                        ),
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: _isPressed ? 0.20 : 0.12)
                        : Colors.black.withValues(alpha: _isPressed ? 0.10 : 0.05),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Aurora Pastel Palette — Tonuri delicate, catifelați și milky (Apple Intelligence / Pastel Glow)
const List<Color> kPastelAuroraBeamColors = [
  Color(0x00000000), // 0.00 - Invizibil
  Color(0x00BAE6FD), // 0.04 - Început transparent
  Color(0x40BAE6FD), // 0.08 - Ice Cyan difuz
  Color(0xFF7DD3FC), // 0.13 - Pastel Sky / Ice Cyan
  Color(0xFF6EE7B7), // 0.19 - Pastel Mint Sorbet
  Color(0xFFFDE68A), // 0.25 - Pastel Buttercup / Soft Vanilla
  Color(0xFFFDBA74), // 0.31 - Pastel Soft Peach
  Color(0xFFF9A8D4), // 0.37 - Pastel Blossom Pink / Cotton Candy
  Color(0xFFD8B4FE), // 0.43 - Pastel Lavender / Lilac
  Color(0xFF93C5FD), // 0.49 - Pastel Soft Periwinkle
  Color(0x4093C5FD), // 0.55 - Periwinkle difuz
  Color(0x0093C5FD), // 0.60 - Fade-out transparent
  Color(0x00000000), // 1.00 - Invizibil
];

const List<double> kPastelAuroraBeamStops = [
  0.0,
  0.04,
  0.08,
  0.13,
  0.19,
  0.25,
  0.31,
  0.37,
  0.43,
  0.49,
  0.55,
  0.60,
  1.0,
];

class BorderBeam extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final bool isActive;
  final double borderRadius;
  final double borderWidth;
  final double glowBlurRadius;
  final List<Color> colors;
  final List<double> stops;

  const BorderBeam({
    super.key,
    required this.child,
    required this.animation,
    this.isActive = true,
    this.borderRadius = 28.0,
    this.borderWidth = 1.2,
    this.glowBlurRadius = 5.0,
    this.colors = kPastelAuroraBeamColors,
    this.stops = kPastelAuroraBeamStops,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        // Fade in rapid la început, menține luminozitatea pe parcurs, fade out lin la final
        double opacity;
        if (!isActive || progress <= 0.0 || progress >= 1.0) {
          opacity = 0.0;
        } else if (progress < 0.12) {
          opacity = progress / 0.12;
        } else if (progress > 0.82) {
          opacity = ((1.0 - progress) / 0.18).clamp(0.0, 1.0);
        } else {
          opacity = 1.0;
        }

        return CustomPaint(
          foregroundPainter: opacity > 0.001
              ? _BorderBeamPainter(
                  progress: progress,
                  opacity: opacity,
                  borderRadius: borderRadius,
                  borderWidth: borderWidth,
                  glowBlurRadius: glowBlurRadius,
                  colors: colors,
                  stops: stops,
                )
              : null,
          child: child,
        );
      },
    );
  }
}

class _BorderBeamPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final double borderRadius;
  final double borderWidth;
  final double glowBlurRadius;
  final List<Color> colors;
  final List<double> stops;

  _BorderBeamPainter({
    required this.progress,
    required this.opacity,
    required this.borderRadius,
    required this.borderWidth,
    required this.glowBlurRadius,
    required this.colors,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || opacity <= 0) return;

    final rect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final strokeRRect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(math.max(0, borderRadius - borderWidth / 2)),
    );

    canvas.save();
    // 1. Constrânge desenul STRICT în interiorul conturului componentei (fără scurgeri exterioare)
    canvas.clipRRect(outerRRect);

    // Rotație continuă 360° pe contur
    final angle = progress * 2 * math.pi;

    // Modulare opacitate culori pastel
    final modulatedColors = colors
        .map((c) => c.withValues(alpha: c.a * opacity))
        .toList();

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: modulatedColors,
      stops: stops,
      transform: GradientRotation(angle),
    );

    final shader = sweepGradient.createShader(rect);

    // 2. Soft Ambient Bloom interior pastelat, catifelat
    if (glowBlurRadius > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2.6
        ..shader = shader
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlurRadius);

      canvas.drawRRect(strokeRRect, glowPaint);
    }

    // 3. Contur Luminous Core subțire și fin
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = shader;

    canvas.drawRRect(strokeRRect, corePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BorderBeamPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.glowBlurRadius != glowBlurRadius;
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Badge reutilizabil de rating în stil Glassmorphism
/// Folosește blur pe fundal (BackdropFilter), contur translucid de sticlă și cifre tabulare.
class GlassScoreBadge extends StatelessWidget {
  final String score;
  final double height;
  final double iconSize;
  final double fontSize;
  final Color iconColor;
  final Color textColor;
  final double blurSigma;

  const GlassScoreBadge({
    super.key,
    required this.score,
    this.height = 23,
    this.iconSize = 10.5,
    this.fontSize = 10.5,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.blurSigma = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 7.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28), // Frosted Dark Glass
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18), // Glass Rim Highlight
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                size: iconSize,
                color: iconColor,
              ),
              const SizedBox(width: 3.5),
              Text(
                score,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

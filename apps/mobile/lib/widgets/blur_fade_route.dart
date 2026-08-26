import 'dart:ui';
import 'package:flutter/material.dart';

/// Rutează tranziția între ecrane folosind efectul iOS Fluid Blur-Fade
/// cu interpolare de estompare, scalare de adâncime și RepaintBoundary izolat.
class BlurFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  BlurFadePageRoute({
    required this.child,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 360),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([animation, secondaryAnimation]),
                builder: (context, currentChild) {
                  final animVal = curvedAnimation.value;
                  final secVal = secondaryCurved.value;

                  // Blur la intrare (12px -> 0px) și la ieșire secundară (0px -> 6px)
                  final entranceBlur = (1.0 - animVal) * 12.0;
                  final exitBlur = secVal * 6.0;
                  final totalBlur = entranceBlur + exitBlur;

                  // Scalare de profunzime (0.95 -> 1.0 la intrare, 1.0 -> 0.96 pe ecranul din spate)
                  final scale = (0.95 + (0.05 * animVal)) * (1.0 - (0.04 * secVal));

                  // Opacitate (0.0 -> 1.0 la intrare, 1.0 -> 0.85 pe ecranul din spate)
                  final opacity = (animVal).clamp(0.0, 1.0) * (1.0 - (0.15 * secVal));

                  Widget result = Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: currentChild,
                    ),
                  );

                  // Aplicăm filtrul de blur doar pe durata tranziției
                  if (totalBlur > 0.15) {
                    result = ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: totalBlur,
                        sigmaY: totalBlur,
                      ),
                      child: result,
                    );
                  }

                  return result;
                },
                child: child,
              ),
            );
          },
        );
}

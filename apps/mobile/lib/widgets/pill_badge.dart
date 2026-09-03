import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// Variantă stilistică pentru pastile
enum PillVariant {
  surface, // Nuanță neutră de fundal (standard pentru genuri și metadate)
  accent,  // Tonalitate subtilă de accent (pentru tag-uri evidențiate sau highlight)
  status,  // Pastilă de stare cu punct luminos (ex: În difuzare, Finalizat)
}

/// Pastilă reutilizabilă Full-Rounded (9999px) pentru Genuri, Metadate și Tag-uri
class PillBadge extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? statusDotColor;
  final PillVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.statusDotColor,
    this.variant = PillVariant.surface,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    this.onTap,
  });

  @override
  State<PillBadge> createState() => _PillBadgeState();
}

class _PillBadgeState extends State<PillBadge> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Calculare culori automate în funcție de temă și variantă
    final Color bg = widget.backgroundColor ?? _getDefaultBackground(context);
    final Color txt = widget.textColor ?? _getDefaultTextColor(context);

    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: 0.6)
            : (!context.isDarkMode
                ? Border.all(color: Colors.white.withValues(alpha: 0.50), width: 0.6)
                : null),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Punct luminos de status (opțional)
          if (widget.statusDotColor != null) ...[
            Container(
              width: 6.5,
              height: 6.5,
              decoration: BoxDecoration(
                color: widget.statusDotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.statusDotColor!.withValues(alpha: 0.55),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5.5),
          ] else if (widget.icon != null) ...[
            // 2. Iconiță opțională
            Icon(widget.icon, size: widget.fontSize + 1.5, color: txt),
            const SizedBox(width: 4.5),
          ],

          // 3. Text etichetă
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: txt,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
              height: 1.15,
            ),
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    // Comportament interactiv la tap cu micro-scale
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: content,
      ),
    );
  }

  Color _getDefaultBackground(BuildContext context) {
    if (widget.variant == PillVariant.accent) {
      return context.accentPrimary.withValues(
        alpha: context.isDarkMode ? 0.16 : 0.14,
      );
    }
    if (widget.variant == PillVariant.status) {
      return context.isDarkMode
          ? const Color(0xFF222428)
          : const Color(0xFFE8E4D8);
    }
    // Variant.surface:
    return context.isDarkMode
        ? const Color(0xFF24262A)
        : const Color(0xFFEBE6DA);
  }

  Color _getDefaultTextColor(BuildContext context) {
    if (widget.variant == PillVariant.accent) {
      return context.accentPrimary;
    }
    return context.textPrimary;
  }
}

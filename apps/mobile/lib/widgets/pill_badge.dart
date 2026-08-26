import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsets padding;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.bgSurfaceHover;
    final txt = textColor ?? context.textPrimary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null, // ZERO BORDER BY DEFAULT
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: txt),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: txt,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

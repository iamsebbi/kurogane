import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'pill_badge.dart';

/// Header unificat de secțiune pentru ecrane și carduri Kurogane.
///
/// Afișează iconiță tematică, titlu stilizat cu fontul sistemului,
/// badge numeric opțional și widget de acțiune în partea dreaptă (ex: "Show more" sau PillBadge).
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final int? count;
  final String? badge;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final bool useZalandoFont;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.count,
    this.badge,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
    this.fontSize = 16,
    this.iconSize = 18,
    this.useZalandoFont = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: iconSize,
                    color: context.accentPrimary,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      fontFamily: useZalandoFont ? 'Zalando Sans Expanded' : 'Google Sans',
                      color: context.textPrimary,
                      letterSpacing: useZalandoFont ? -0.2 : -0.1,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 7),
                  PillBadge(
                    label: '$count',
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (badge != null)
            PillBadge(label: badge!),
        ],
      ),
    );
  }
}

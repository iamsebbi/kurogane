import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/constants/app_colors.dart';

class AuthLogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const AuthLogoHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Minimalist Phosphor Icon (fără glow, fără gradient box)
        Icon(
          icon ?? PhosphorIcons.userCircle(PhosphorIconsStyle.regular),
          size: 72,
          color: context.textPrimary,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

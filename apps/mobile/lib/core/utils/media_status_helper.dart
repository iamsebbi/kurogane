import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Helper unificat pentru gestionarea stărilor seriilor / watchlist-ului în Kurogane
/// (WATCHING, COMPLETED, PLAN_TO_WATCH, ON_HOLD, DROPPED).
class MediaStatusHelper {
  const MediaStatusHelper._();

  /// Returnează eticheta localizată pentru statusul specificat
  static String getLabel(String? status) {
    if (status == null || status.isEmpty) return '';
    switch (status.toUpperCase()) {
      case 'WATCHING':
        return AppStrings.statusWatching;
      case 'COMPLETED':
        return AppStrings.statusCompleted;
      case 'PLAN_TO_WATCH':
        return AppStrings.statusPlanToWatch;
      case 'ON_HOLD':
        return AppStrings.statusOnHold;
      case 'DROPPED':
        return AppStrings.statusDropped;
      default:
        return status;
    }
  }

  /// Returnează culoarea semantică conform temei contextuale (Light / Dark)
  static Color getColor(BuildContext context, String? status) {
    if (status == null) return context.textMuted;
    switch (status.toUpperCase()) {
      case 'WATCHING':
        return context.statusWatching;
      case 'COMPLETED':
        return context.statusCompleted;
      case 'PLAN_TO_WATCH':
        return context.statusPlanToWatch;
      case 'ON_HOLD':
        return context.statusOnHold;
      case 'DROPPED':
        return context.statusDropped;
      default:
        return context.textMuted;
    }
  }

  /// Returnează iconița umplută (Filled) specifică statusului
  static IconData getIcon(String? status) {
    if (status == null) return PhosphorIconsFill.bookmarkSimple;
    switch (status.toUpperCase()) {
      case 'WATCHING':
        return PhosphorIconsFill.play;
      case 'COMPLETED':
        return PhosphorIconsFill.checkCircle;
      case 'PLAN_TO_WATCH':
        return PhosphorIconsFill.bookmarkSimple;
      case 'ON_HOLD':
        return PhosphorIconsFill.pause;
      case 'DROPPED':
        return PhosphorIconsFill.xCircle;
      default:
        return PhosphorIconsFill.bookmarkSimple;
    }
  }

  /// Returnează iconița conturată (Regular / Bold) pentru controale de selecție
  static IconData getOutlineIcon(String? status) {
    if (status == null) return PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold);
    switch (status.toUpperCase()) {
      case 'WATCHING':
        return PhosphorIcons.play(PhosphorIconsStyle.bold);
      case 'COMPLETED':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.bold);
      case 'PLAN_TO_WATCH':
        return PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold);
      case 'ON_HOLD':
        return PhosphorIcons.pause(PhosphorIconsStyle.bold);
      case 'DROPPED':
        return PhosphorIcons.xCircle(PhosphorIconsStyle.bold);
      default:
        return PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold);
    }
  }
}

/// Extensie utilitară pe String pentru acces rapid și fluent
extension MediaStatusExtension on String {
  String get statusLabel => MediaStatusHelper.getLabel(this);
  Color statusColor(BuildContext context) => MediaStatusHelper.getColor(context, this);
  IconData get statusIcon => MediaStatusHelper.getIcon(this);
  IconData get statusOutlineIcon => MediaStatusHelper.getOutlineIcon(this);
}

import 'package:flutter/material.dart';

class AppColors {
  // --- DARK THEME PALETTE (Kurogane Aesthetic) ---
  static const Color bgPrimary = Color(0xFF141414); // surface
  static const Color bgSurface = Color(0xFF1C1C1C); // surfaceContainer
  static const Color bgSurfaceHover = Color(0xFF222222); // surfaceContainerHigh
  static const Color bgAccent = Color(0xFF363636); // surfaceContainerHighest
  static const Color accentPrimary = Color(0xFFD1CFC0); // primary
  static const Color accentSecondary = Color(0xFFD1CFC0);
  static const Color onPrimary = Color(0xFF363636); // onPrimary
  static const Color borderSubtle = Color(0xFF2C2C2C); // outlineVariant
  static const Color textPrimary = Color(0xFFE8E3DA); // onSurface
  static const Color textSecondary = Color(0xFF8E8A83); // onSurfaceVariant
  static const Color textMuted = Color(0xFF5C5A56); // outline
  static const Color alertCoral = Color(0xFFEF4444); // error
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color brandHighlight = Color(0xFFF26A4B); // tertiary

  // Drawer / Navigation Rail (Dark Mode)
  static const Color drawerBackground = Color(0xFF101010);
  static const Color drawerTextAndIcons = Color(0xFFE8E3DA);
  static const Color drawerActiveItemBg = Color(0xFFD1CFC0);
  static const Color drawerActiveItemFg = Color(0xFF363636);
  static const Color drawerDivider = Color(0xFF2C2C2C);

  // Semantic Accents
  static const Color signalLive = Color(0xFF4ADE80);
  static const Color scoreGold = Color(0xFFFBBF24);
  static const Color badgeViolet = Color(0xFFF26A4B);
  static const Color highlightEmber = Color(0xFFF26A4B);

  // --- LIGHT THEME PALETTE ---
  static const Color lightBgPrimary = Color(0xFFE9E4D8); // surface
  static const Color lightBgSurface = Color(0xFFF4EFE4); // surfaceContainer
  static const Color lightBgSurfaceHover = Color(0xFFD8D2C4); // surfaceContainerHigh
  static const Color lightBgAccent = Color(0xFFE6E4D7); // surfaceContainerHighest
  static const Color lightAccentPrimary = Color(0xFF2E2E2E); // primary
  static const Color lightAccentSecondary = Color(0xFF2E2E2E);
  static const Color lightOnPrimary = Color(0xFFE6E4D7); // onPrimary
  static const Color lightBorderSubtle = Color(0xFFD2CBBB); // outlineVariant
  static const Color lightTextPrimary = Color(0xFF1E1E1E); // onSurface
  static const Color lightTextSecondary = Color(0xFF5E5A52); // onSurfaceVariant
  static const Color lightTextMuted = Color(0xFFA89F8F); // outline
  static const Color lightAlertCoral = Color(0xFFDC2626); // error
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightBrandHighlight = Color(0xFFF26A4B); // tertiary

  // Drawer / Navigation Rail (Light Mode)
  static const Color lightDrawerBackground = Color(0xFFE3DDCF);
  static const Color lightDrawerTextAndIcons = Color(0xFF1E1E1E);
  static const Color lightDrawerActiveItemBg = Color(0xFF2E2E2E);
  static const Color lightDrawerActiveItemFg = Color(0xFFE6E4D7);
  static const Color lightDrawerDivider = Color(0xFFD2CBBB);

  static const Color lightSignalLive = Color(0xFF16A34A);
  static const Color lightScoreGold = Color(0xFFD97706);
  static const Color lightBadgeViolet = Color(0xFFF26A4B);
  static const Color lightHighlightEmber = Color(0xFFF26A4B);
}

extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get bgPrimary => isDarkMode ? AppColors.bgPrimary : AppColors.lightBgPrimary;
  Color get bgSurface => isDarkMode ? AppColors.bgSurface : AppColors.lightBgSurface;
  Color get bgSurfaceHover => isDarkMode ? AppColors.bgSurfaceHover : AppColors.lightBgSurfaceHover;
  Color get bgAccent => isDarkMode ? AppColors.bgAccent : AppColors.lightBgAccent;
  Color get accentPrimary => isDarkMode ? AppColors.accentPrimary : AppColors.lightAccentPrimary;
  Color get onPrimary => isDarkMode ? AppColors.onPrimary : AppColors.lightOnPrimary;
  Color get borderSubtle => isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
  Color get textPrimary => isDarkMode ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get textMuted => isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;
  Color get error => isDarkMode ? AppColors.error : AppColors.lightError;
  Color get onError => isDarkMode ? AppColors.onError : AppColors.lightOnError;
  Color get brandHighlight => isDarkMode ? AppColors.brandHighlight : AppColors.lightBrandHighlight;

  // Drawer
  Color get drawerBackground => isDarkMode ? AppColors.drawerBackground : AppColors.lightDrawerBackground;
  Color get drawerTextAndIcons => isDarkMode ? AppColors.drawerTextAndIcons : AppColors.lightDrawerTextAndIcons;
  Color get drawerActiveItemBg => isDarkMode ? AppColors.drawerActiveItemBg : AppColors.lightDrawerActiveItemBg;
  Color get drawerActiveItemFg => isDarkMode ? AppColors.drawerActiveItemFg : AppColors.lightDrawerActiveItemFg;
  Color get drawerDivider => isDarkMode ? AppColors.drawerDivider : AppColors.lightDrawerDivider;
}

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const String fontSans = 'Google Sans';
  static const String fontHeading = 'Zalando Sans Expanded';

  /// Dark Theme (Sincronizat 1:1 cu schema Kurogane Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontSans,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      primaryColor: AppColors.accentPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.bgSurface,
        surfaceContainer: AppColors.bgSurface,
        surfaceContainerHigh: AppColors.bgSurfaceHover,
        surfaceContainerHighest: AppColors.bgAccent,
        outlineVariant: AppColors.borderSubtle,
        outline: AppColors.textMuted,
        tertiary: AppColors.brandHighlight,
        error: AppColors.error,
        onError: AppColors.onError,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.drawerBackground,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xEB141414),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontHeading,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgAccent,
        selectedColor: AppColors.accentPrimary,
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontFamily: fontSans, fontSize: 12, color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fontHeading, fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontFamily: fontHeading, fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontFamily: fontHeading, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontFamily: fontHeading, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontFamily: fontHeading, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: fontSans, color: AppColors.textPrimary, fontSize: 15),
        bodyMedium: TextStyle(fontFamily: fontSans, color: AppColors.textSecondary, fontSize: 13),
        bodySmall: TextStyle(fontFamily: fontSans, color: AppColors.textMuted, fontSize: 11),
        labelLarge: TextStyle(fontFamily: fontSans, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  /// Light Theme (Sincronizat 1:1 cu schema Kurogane Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontSans,
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      primaryColor: AppColors.lightAccentPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightAccentPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightAccentSecondary,
        surface: AppColors.lightBgSurface,
        surfaceContainer: AppColors.lightBgSurface,
        surfaceContainerHigh: AppColors.lightBgSurfaceHover,
        surfaceContainerHighest: AppColors.lightBgAccent,
        outlineVariant: AppColors.lightBorderSubtle,
        outline: AppColors.lightTextMuted,
        tertiary: AppColors.lightBrandHighlight,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightDrawerBackground,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBgSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontHeading,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightBgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBgSurface,
        selectedItemColor: AppColors.lightAccentPrimary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBgAccent,
        selectedColor: AppColors.lightAccentPrimary,
        side: const BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontFamily: fontSans, fontSize: 12, color: AppColors.lightTextPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fontHeading, fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        displayMedium: TextStyle(fontFamily: fontHeading, fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        displaySmall: TextStyle(fontFamily: fontHeading, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        headlineMedium: TextStyle(fontFamily: fontHeading, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        headlineSmall: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        titleLarge: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        titleMedium: TextStyle(fontFamily: fontHeading, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        titleSmall: TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        bodyLarge: TextStyle(fontFamily: fontSans, color: AppColors.lightTextPrimary, fontSize: 15),
        bodyMedium: TextStyle(fontFamily: fontSans, color: AppColors.lightTextSecondary, fontSize: 13),
        bodySmall: TextStyle(fontFamily: fontSans, color: AppColors.lightTextMuted, fontSize: 11),
        labelLarge: TextStyle(fontFamily: fontSans, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

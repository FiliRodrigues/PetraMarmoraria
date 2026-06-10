import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 10; // padrão de controles (botões, inputs)
  static const double radiusLg = 12; // cards
  static const double radiusXl = 16;
  static const double radiusFull = 999; // pills

  /// Sombra sutil de elevação base (cards, inputs).
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: AppColors.shadowSoft, blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Sombra de elevação ao hover / camadas flutuantes.
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(color: AppColors.shadowMedium, blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: AppColors.shadowSoft, blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Anel de foco translúcido (estilo reui) — usar em controles custom.
  static List<BoxShadow> focusRing([Color color = AppColors.accent]) => [
    BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 0, spreadRadius: 3),
  ];

  static TextStyle syne({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle jakarta({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle numeric({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Alias mantido para compatibilidade com código existente.
  static ThemeData get lightTheme => theme;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: syne(fontSize: 28, fontWeight: FontWeight.w700),
        displayMedium: syne(fontSize: 22, fontWeight: FontWeight.w700),
        displaySmall: syne(fontSize: 18, fontWeight: FontWeight.w700),
        headlineLarge: syne(fontSize: 17, fontWeight: FontWeight.w700),
        headlineMedium: syne(fontSize: 15, fontWeight: FontWeight.w700),
        headlineSmall: syne(fontSize: 13, fontWeight: FontWeight.w700),
        titleLarge: syne(fontSize: 16, fontWeight: FontWeight.w700),
        titleMedium: syne(fontSize: 14, fontWeight: FontWeight.w700),
        titleSmall: syne(fontSize: 13, fontWeight: FontWeight.w700),
        bodyLarge: jakarta(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: jakarta(fontSize: 13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall: jakarta(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted),
        labelLarge: jakarta(fontSize: 13.5, fontWeight: FontWeight.w600),
        labelMedium: jakarta(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: jakarta(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sidebarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: syne(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.sidebarDark,
        elevation: 0,
        width: 240,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.shadowMedium,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: AppColors.shadowMedium,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: jakarta(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: jakarta(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: jakarta(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: jakarta(fontSize: 13, color: AppColors.textMuted),
        labelStyle: jakarta(fontSize: 13, color: AppColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
        labelStyle: jakarta(fontSize: 12, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get warmTheme => theme.copyWith(
        scaffoldBackgroundColor: AppColors.backgroundWarm,
        cardTheme: theme.cardTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: const BorderSide(color: AppColors.borderWarm),
          ),
        ),
      );
}

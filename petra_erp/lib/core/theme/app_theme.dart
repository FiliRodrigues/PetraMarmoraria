import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => theme;

  // ── Raios de borda ────────────────────────────────────────────────────────
  static const double radiusXs   = 4;
  static const double radiusSm   = 8;
  static const double radiusMd   = 12;
  static const double radiusLg   = 16;
  static const double radiusXl   = 24;
  static const double radiusFull = 999;

  // ── Fonte de exibição (títulos, labels de seção) ─────────────────────────
  static TextStyle syne({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: 'Syne',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
      );

  // ── Fonte de corpo ────────────────────────────────────────────────────────
  static TextStyle jakarta({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
      );

  // ── Fonte numérica (KPIs, preços, #OS) ───────────────────────────────────
  static TextStyle numeric({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ── Tema principal ────────────────────────────────────────────────────────
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

      // ── Tipografia ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge:  syne(fontSize: 30, fontWeight: FontWeight.w800),
        displayMedium: syne(fontSize: 24, fontWeight: FontWeight.w700),
        displaySmall:  syne(fontSize: 20, fontWeight: FontWeight.w700),
        headlineLarge: syne(fontSize: 18, fontWeight: FontWeight.w700),
        headlineMedium:syne(fontSize: 15, fontWeight: FontWeight.w700),
        headlineSmall: syne(fontSize: 13, fontWeight: FontWeight.w700),
        titleLarge:    syne(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium:   syne(fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall:    syne(fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge:     jakarta(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium:    jakarta(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall:     jakarta(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted),
        labelLarge:    jakarta(fontSize: 13, fontWeight: FontWeight.w600),
        labelMedium:   jakarta(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall:    jakarta(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sidebarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: syne(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
      ),

      // ── Drawer ────────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.sidebarDark,
        elevation: 0,
        width: 260,
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),

      // ── Botão principal ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: jakarta(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Botão outline ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: jakarta(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: jakarta(fontSize: 14, color: AppColors.textMuted),
        labelStyle: jakarta(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: AppColors.border),
        ),
        labelStyle: jakarta(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ── Variante warm (Pedra Clara) ───────────────────────────────────────────
  static ThemeData get warmTheme => theme.copyWith(
    scaffoldBackgroundColor: AppColors.backgroundWarm,
    cardTheme: theme.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: AppColors.borderWarm),
      ),
    ),
  );
}

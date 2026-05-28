import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const background       = Color(0xFFF8FAFC);
  static const backgroundWarm   = Color(0xFFFAF8F5);
  static const surface          = Color(0xFFFFFFFF);
  static const surfaceElevated  = Color(0xFFF1F5F9);

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static const sidebarDark            = Color(0xFF0A1628);
  static const sidebarLight           = Color(0xFFFFFFFF);
  static const sidebarItemHoverBg     = Color(0x0FFFFFFF);
  static const sidebarItemActiveBg    = Color(0x2EC49A3C);
  static const sidebarItemActiveBorder = Color(0x4DC49A3C);

  // ── Primary (navy) ────────────────────────────────────────────────────────
  static const primary          = Color(0xFF0D2B45);
  static const primaryDark      = Color(0xFF071828);

  // ── Accent (ouro — identidade da marmoraria) ──────────────────────────────
  static const accent           = Color(0xFFC49A3C);
  static const accentWarm       = Color(0xFFB8882E);
  static const accentLight      = Color(0xFFF5E9C8);

  // ── Status por etapa ──────────────────────────────────────────────────────
  static const orcamento        = Color(0xFFC49A3C);
  static const orcamentoBg      = Color(0x1FC49A3C);
  static const aprovado         = Color(0xFF0D2B45);
  static const aprovadoBg       = Color(0x140D2B45);
  static const espMaterial      = Color(0xFFC2510F);
  static const espMaterialBg    = Color(0x16C2510F);
  static const corte            = Color(0xFF6058D0);
  static const corteBg          = Color(0x156058D0);
  static const montagem         = Color(0xFF0D8B7E);
  static const montagemBg       = Color(0x150D8B7E);
  static const entrega          = Color(0xFF1A7A5E);
  static const entregaBg        = Color(0x151A7A5E);

  // ── Staleness (dias parado) ───────────────────────────────────────────────
  static const staleOk          = Color(0xFF1A7A5E);
  static const staleWarn        = Color(0xFFC49A3C);
  static const staleCrit        = Color(0xFFC0392B);

  // ── Feedback ─────────────────────────────────────────────────────────────
  static const success          = Color(0xFF1A7A5E);
  static const warning          = Color(0xFFC49A3C);
  static const error            = Color(0xFFC0392B);
  static const info             = Color(0xFF0EA5E9);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const textPrimary      = Color(0xFF0F172A);
  static const textSecondary    = Color(0xFF334155);
  static const textMuted        = Color(0xFF64748B);
  static const textWarmPrimary  = Color(0xFF1C1917);
  static const textWarmSecondary= Color(0xFF57534E);
  static const textWarmMuted    = Color(0xFFA8A29E);

  // ── Bordas ────────────────────────────────────────────────────────────────
  static const border           = Color(0xFFE2E8F0);
  static const borderWarm       = Color(0xFFE8E2D9);
  static const borderFocus      = Color(0xFF0D2B45);

  // ── Sombras ───────────────────────────────────────────────────────────────
  static const shadowCard       = Color(0x0A000000);
  static const shadowElevated   = Color(0x16000000);

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0C0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 3,  offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 6,  offset: Offset(0, 2)),
  ];

  // ── Aliases legados ──────────────────────────────────────────────────────
  static const white            = Color(0xFFFFFFFF);
  static const navyBlue         = primary;
  static const grey             = textSecondary;
  static const lightGrey        = border;
  static const secondary        = surfaceElevated;

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color stalenessColor(int days) {
    if (days <= 2) return staleOk;
    if (days <= 5) return staleWarn;
    return staleCrit;
  }

  static ({Color color, Color bg}) statusColors(String status) {
    return switch (status) {
      'orcamento'          => (color: orcamento,   bg: orcamentoBg),
      'aprovado'           => (color: aprovado,    bg: aprovadoBg),
      'esperando_material' => (color: espMaterial, bg: espMaterialBg),
      'corte'              => (color: corte,       bg: corteBg),
      'montagem'           => (color: montagem,    bg: montagemBg),
      'entrega'            => (color: entrega,     bg: entregaBg),
      _                    => (color: textMuted,   bg: surfaceElevated),
    };
  }
}

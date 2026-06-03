import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const background       = Color(0xFFEEF3F8); // painel principal
  static const backgroundWarm   = Color(0xFFFAF8F5); // variante Pedra Clara
  static const surface          = Color(0xFFFFFFFF);
  static const surfaceElevated  = Color(0xFFF4F8FC);

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static const sidebarDark      = Color(0xFF091E2E); // Profundidade
  static const sidebarLight     = Color(0xFFFFFFFF); // Pedra Clara

  // ── Primary (navy) ────────────────────────────────────────────────────────
  static const primary          = Color(0xFF0A3D62);
  static const primaryDark      = Color(0xFF071E30);

  // ── Accent (âmbar / ouro — identidade da marmoraria) ─────────────────────
  static const accent           = Color(0xFFC0802A); // Profundidade
  static const accentWarm       = Color(0xFF9A6B2A); // Pedra Clara
  static const accentLight      = Color(0xFFF5DFB0);

  // ── Status por etapa ──────────────────────────────────────────────────────
  static const orcamento        = Color(0xFFC0802A);
  static const orcamentoBg      = Color(0x1EC0802A);
  static const aprovado         = Color(0xFF0A3D62);
  static const aprovadoBg       = Color(0x140A3D62);
  static const espMaterial      = Color(0xFFC2510F);
  static const espMaterialBg    = Color(0x16C2510F);
  static const corte            = Color(0xFF6058D0);
  static const corteBg          = Color(0x156058D0);
  static const montagem         = Color(0xFF0D8B7E);
  static const montagemBg       = Color(0x150D8B7E);
  static const entrega          = Color(0xFF1A7A5E);
  static const entregaBg        = Color(0x151A7A5E);

  // ── Staleness (dias parado) ───────────────────────────────────────────────
  static const staleOk          = Color(0xFF1A7A5E); // 0–2 dias
  static const staleWarn        = Color(0xFFC0802A); // 3–5 dias
  static const staleCrit        = Color(0xFFC0392B); // 6+ dias

  // ── Feedback ─────────────────────────────────────────────────────────────
  static const success          = Color(0xFF1A7A5E);
  static const warning          = Color(0xFFC0802A);
  static const error            = Color(0xFFC0392B);
  static const info             = Color(0xFF0EA5E9);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const textPrimary      = Color(0xFF0D1B26);
  static const textSecondary    = Color(0xFF374151);
  static const textMuted        = Color(0xFF6B7280);
  // variante warm
  static const textWarmPrimary  = Color(0xFF1C1917);
  static const textWarmSecondary= Color(0xFF57534E);
  static const textWarmMuted    = Color(0xFFA8A29E);

  // ── Bordas ────────────────────────────────────────────────────────────────
  static const border           = Color(0xFFD8E3EC);
  static const borderWarm        = Color(0xFFE8E2D9);
  static const borderFocus       = Color(0xFF0A3D62);

  // ── Neutros (escala para superfícies/zebra/chips) ────────────────────────
  static const neutral50         = Color(0xFFF8FAFC);
  static const neutral100        = Color(0xFFF1F5F9);
  static const neutral200        = Color(0xFFE7EDF3);
  static const neutral300        = Color(0xFFD8E3EC);

  // ── Sombras ───────────────────────────────────────────────────────────────
  static const shadowCard        = Color(0x0A000000);
  static const shadowElevated     = Color(0x16000000);
  // Sombras em camadas (tom navy frio, estilo reui)
  static const shadowSoft        = Color(0x0F101828);
  static const shadowMedium      = Color(0x1A101828);

  // ── Aliases legados (mantidos p/ telas ainda não migradas) ───────────────
  static const white            = Color(0xFFFFFFFF);
  static const black            = Color(0xFF0D1B26);
  static const navyBlue         = primary;
  // `secondary` historicamente era o dourado de acento — mantemos esse
  // significado para não quebrar botões/badges das telas legadas.
  static const secondary        = accent;
  static const grey             = textMuted;
  static const lightGrey        = border;
  static const darkGrey         = textSecondary;

  // ── Helpers ───────────────────────────────────────────────────────────────
  /// Cor de staleness baseada nos dias sem mover de etapa.
  static Color stalenessColor(int days) {
    if (days <= 2) return staleOk;
    if (days <= 5) return staleWarn;
    return staleCrit;
  }

  /// Cor e bg para cada status de OS.
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

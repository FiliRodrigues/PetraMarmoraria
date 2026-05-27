import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Petra Marmoraria Branding Colors
  static const Color primary = Color(0xFF1A1A1A);       // Preto (textos, headers, navbar)
  static const Color secondary = Color(0xFFC4A747);     // Dourado (botões, badges, acentos)
  static const Color background = Color(0xFFF5F0E8);    // Creme (fundo geral)
  static const Color surface = Color(0xFFF5F0E8);       // Creme (superfícies principais)

  // Functional Status Colors
  static const Color error = Color(0xFFC62828);         // Vermelho (atraso > 5 dias)
  static const Color warning = Color(0xFFE6A817);       // Amarelo (atenção 3-5 dias)
  static const Color success = Color(0xFF2E7D32);       // Verde (concluído ou em dia <= 2 dias)

  // Neutral Tones
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);
}

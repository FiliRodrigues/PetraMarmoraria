import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppRoles {
  AppRoles._();

  static const admin = 'admin';
  static const vendedor = 'vendedor';
  static const cortador = 'cortador';
  static const montador = 'montador';
  static const entregador = 'entregador';

  static const List<String> all = [
    admin,
    vendedor,
    cortador,
    montador,
    entregador,
  ];

  static const List<String> productionRoles = [
    cortador,
    montador,
    entregador,
  ];

  static const Map<String, String> labels = {
    admin: 'Admin',
    vendedor: 'Vendedor',
    cortador: 'Cortador',
    montador: 'Montador',
    entregador: 'Entregador',
  };

  static String roleLabel(String role) => labels[role.toLowerCase()] ?? role;

  static Color roleColor(String role) {
    return switch (role.toLowerCase()) {
      admin => AppColors.primary,
      vendedor => AppColors.accent,
      cortador => AppColors.corte,
      montador => AppColors.montagem,
      entregador => AppColors.entrega,
      _ => AppColors.textMuted,
    };
  }

  static String? roleStage(String role) {
    return switch (role.toLowerCase()) {
      cortador => 'corte',
      montador => 'montagem',
      entregador => 'entrega',
      _ => null,
    };
  }

  static String? stageRole(String stage) {
    return switch (stage) {
      'corte' => cortador,
      'montagem' => montador,
      'entrega' => entregador,
      _ => null,
    };
  }

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum AppSnackbarType { info, success, warning, error }

/// Helper centralizado para feedback (toast) no estilo reui.
/// Uso: `AppSnackbar.show(context, 'Salvo', type: AppSnackbarType.success);`
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
  }) {
    final (:color, :icon) = _style(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface,
          elevation: 6,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: color.withValues(alpha: 0.35)),
          ),
          content: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void info(BuildContext c, String m) => show(c, m, type: AppSnackbarType.info);
  static void success(BuildContext c, String m) => show(c, m, type: AppSnackbarType.success);
  static void warning(BuildContext c, String m) => show(c, m, type: AppSnackbarType.warning);
  static void error(BuildContext c, String m) => show(c, m, type: AppSnackbarType.error);

  static ({Color color, IconData icon}) _style(AppSnackbarType type) => switch (type) {
        AppSnackbarType.info => (color: AppColors.info, icon: LucideIcons.info),
        AppSnackbarType.success => (color: AppColors.success, icon: LucideIcons.checkCircle),
        AppSnackbarType.warning => (color: AppColors.warning, icon: LucideIcons.alertTriangle),
        AppSnackbarType.error => (color: AppColors.error, icon: LucideIcons.alertCircle),
      };
}

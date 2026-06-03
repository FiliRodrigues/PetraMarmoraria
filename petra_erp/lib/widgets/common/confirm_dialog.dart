import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';

/// A reusable confirmation dialog with customized titles and actions.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.confirmColor,
  });

  /// Helper method to show this dialog and await response.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }

  bool get _isDestructive =>
      confirmColor == AppColors.error ||
      RegExp(r'excluir|sair|remover|apagar|deletar', caseSensitive: false)
          .hasMatch(confirmLabel);

  @override
  Widget build(BuildContext context) {
    final destructive = _isDestructive;
    final iconColor = destructive ? AppColors.error : AppColors.primary;
    final iconBg = destructive
        ? const Color(0xFFFBE9E7)
        : AppColors.primary.withValues(alpha: 0.08);

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      destructive ? LucideIcons.alertTriangle : LucideIcons.info,
                      size: 21, color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: AppTheme.syne(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  Text(content,
                    style: AppTheme.jakarta(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 9),
                  AppButton(
                    label: confirmLabel,
                    variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

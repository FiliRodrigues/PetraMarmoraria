import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class DelayBadge extends StatelessWidget {
  final int daysStale;

  const DelayBadge({super.key, required this.daysStale});

  Color _color() {
    if (daysStale <= 2) return AppColors.success;
    if (daysStale <= 5) return AppColors.warning;
    return AppColors.error;
  }

  String _text() {
    if (daysStale == 0) return 'Atualizado hoje';
    if (daysStale == 1) return '1 dia sem alteração';
    return '$daysStale dias sem alteração';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 13, color: color),
          const SizedBox(width: 4),
          Text(_text(),
            style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

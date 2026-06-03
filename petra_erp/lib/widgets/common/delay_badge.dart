import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A badge that displays how many days a Service Order is stale in its current status.
class DelayBadge extends StatelessWidget {
  final int daysStale;

  const DelayBadge({super.key, required this.daysStale});

  Color _getBadgeColor() {
    if (daysStale <= 2) return AppColors.success;
    if (daysStale <= 5) return AppColors.warning;
    return AppColors.error;
  }

  String _getBadgeText() {
    if (daysStale == 0) return 'Atualizado hoje';
    if (daysStale == 1) return '1 dia sem alteração';
    return '$daysStale dias sem alteração';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor();
    final text = _getBadgeText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 14.0, color: color),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: AppTheme.jakarta(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

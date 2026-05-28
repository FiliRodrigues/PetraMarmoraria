import 'package:flutter/material.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final label    = OSStatus.labels[status] ?? status;
    final (:color, :bg) = AppColors.statusColors(status);
    final fontSize = small ? 10.0 : 11.0;
    final hPad     = small ? 7.0  : 10.0;
    final vPad     = small ? 2.0  : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: AppTheme.jakarta(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

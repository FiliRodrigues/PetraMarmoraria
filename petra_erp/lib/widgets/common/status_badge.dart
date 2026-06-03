import 'package:flutter/material.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Badge de status para OS — dot colorido + label.
/// Exemplo: `StatusBadge(status: order.status)`
class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final label = OSStatus.labels[status] ?? status;
    final (:color, :bg) = AppColors.statusColors(status);
    final fontSize  = small ? 9.5 : 11.0;
    final dotSize   = small ? 4.5 : 5.5;
    final hPad      = small ? 8.0 : 11.0;
    final vPad      = small ? 2.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize, height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.jakarta(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

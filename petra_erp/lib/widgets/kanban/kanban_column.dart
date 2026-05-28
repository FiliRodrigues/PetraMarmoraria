import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import 'os_card.dart';
import 'status_transition_dialog.dart';

class KanbanColumn extends ConsumerWidget {
  final String status;
  final List<ServiceOrder> orders;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.orders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = OSStatus.labels[status] ?? status;
    final statusColor = AppColors.statusColors(status).color;

    return DragTarget<ServiceOrder>(
      onWillAccept: (order) {
        if (order == null) return false;
        return OSStatus.canMoveTo(order.status, status);
      },
      onAccept: (order) {
        showDialog(
          context: context,
          builder: (context) => StatusTransitionDialog(
            order: order,
            targetStatus: status,
            onTransitionCompleted: () {
              ref.invalidate(osProvider);
            },
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final isDesktop = MediaQuery.of(context).size.width > 900;

        return Container(
          width: isDesktop ? 300.0 : null,
          margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.primary.withOpacity(0.04)
                : AppColors.surfaceElevated.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isHovered ? AppColors.primary.withOpacity(0.3) : AppColors.border,
              width: isHovered ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              statusLabel.toUpperCase(),
                              style: AppTheme.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ).copyWith(letterSpacing: 0.6),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: AppTheme.numeric(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return OSCard(order: orders[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

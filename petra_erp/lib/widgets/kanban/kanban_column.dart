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
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.primary.withOpacity(0.04)
                : AppColors.surfaceElevated.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
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
                              color: AppColors.statusColors(status).color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              statusLabel.toUpperCase(),
                              style: AppTheme.jakarta(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ).copyWith(letterSpacing: 0.8),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${orders.length}',
                      style: AppTheme.numeric(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Cards List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
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

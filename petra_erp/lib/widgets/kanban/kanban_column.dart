import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import 'os_card.dart';
import 'status_transition_dialog.dart';

/// Column widget representing a production stage on the Kanban board.
/// Implements DragTarget and verifies valid stage changes.
class KanbanColumn extends ConsumerWidget {
  final String status;
  final List<ServiceOrder> orders;

  /// Quando true, a coluna ocupa a largura disponível (sem largura fixa),
  /// permitindo distribuir N colunas igualmente em uma única tela.
  final bool flexible;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.orders,
    this.flexible = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = OSStatus.labels[status] ?? status;
    final statusColor = AppColors.statusColors(status).color;

    return DragTarget<ServiceOrder>(
      onWillAcceptWithDetails: (details) {
        // Verify sequence transition
        return OSStatus.canMoveTo(details.data.status, status);
      },
      onAcceptWithDetails: (details) {
        showDialog(
          context: context,
          builder: (context) => StatusTransitionDialog(
            order: details.data,
            targetStatus: status,
            onTransitionCompleted: () {
              ref.invalidate(osProvider);
            },
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        // Highlight background when a draggable item is hovered over
        final isHovered = candidateData.isNotEmpty;

        return Container(
          width: flexible ? null : (context.isDesktop ? 300.0 : null),
          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.secondary.withValues(alpha: 0.08)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isHovered ? AppColors.secondary : AppColors.border,
              width: isHovered ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header (claro, com ponto da etapa + contador em pill)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusLg),
                    topRight: Radius.circular(AppTheme.radiusLg),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.neutral200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              statusLabel,
                              style: AppTheme.syne(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: AppTheme.numeric(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
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

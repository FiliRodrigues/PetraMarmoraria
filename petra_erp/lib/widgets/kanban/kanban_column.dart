import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
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
        final isDesktop = MediaQuery.of(context).size.width > 900;

        return Container(
          width: flexible ? null : (isDesktop ? 300.0 : null),
          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isHovered 
                ? AppColors.secondary.withValues(alpha: 0.08) 
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isHovered ? AppColors.secondary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import 'status_transition_dialog.dart';

/// Card widget to display a Service Order in the Kanban Board.
/// Features a colored left border for staleness and is Draggable.
class OSCard extends ConsumerWidget {
  final ServiceOrder order;
  final bool isFeedback;

  const OSCard({
    super.key,
    required this.order,
    this.isFeedback = false,
  });

  Color _getStalenessColor(int days) {
    if (days <= 2) return AppColors.success;
    if (days <= 5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = order.daysStale;
    final stalenessColor = _getStalenessColor(days);

    // Watch assignments if the current stage requires it
    String? assignedEmployee;
    if (OSStatus.requiresAssignment(order.status)) {
      final assignmentsAsync = ref.watch(osAssignmentsProvider(order.id));
      assignedEmployee = assignmentsAsync.maybeWhen(
        data: (list) {
          final match = list.firstWhere(
            (a) => a.stage == order.status,
            orElse: () => list.isNotEmpty ? list.first : OrderAssignment(
              id: '',
              orderId: order.id,
              stage: order.status,
              employeeId: '',
              assignedAt: DateTime.now(),
            ),
          );
          return match.employeeName;
        },
        orElse: () => null,
      );
    }

    final cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: isFeedback ? 6.0 : 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          // Colored left border represent time stale
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(
                color: stalenessColor,
                width: 6.0,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row (OS Display Number and Menu Actions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.formattedNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      color: AppColors.primary,
                    ),
                  ),
                  if (!isFeedback)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18.0),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          context.push('/orders/${order.id}/edit');
                        } else if (value == 'detail') {
                          context.push('/orders/${order.id}');
                        } else if (value == 'move') {
                          final currentStatus = order.status;
                          final nextStatus = OSStatus.next(currentStatus);
                          final prevStatus = OSStatus.previous(currentStatus);
                          
                          if (nextStatus == null && prevStatus == null) return;
                          
                          // Open Transition Dialog
                          showDialog(
                            context: context,
                            builder: (context) => StatusTransitionDialog(
                              order: order,
                              onTransitionCompleted: () {
                                ref.invalidate(osProvider);
                              },
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 8),
                              Text('Ver Detalhes'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Editar OS'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'move',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 16),
                              SizedBox(width: 8),
                              Text('Mover Etapa'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Customer Name
              Text(
                order.customerName ?? 'Sem Cliente',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),

              // Material Description
              if (order.material != null && order.material!.isNotEmpty) ...[
                Text(
                  order.material!,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: AppColors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6.0),
              ],

              // Total Value & Assignments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatCurrency(order.totalValue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                      color: AppColors.primary,
                    ),
                  ),
                  // Staleness days count label
                  Text(
                    days == 0 ? 'Hoje' : '$days d',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: stalenessColor,
                    ),
                  ),
                ],
              ),

              // Assigned Employee Badge
              if (assignedEmployee != null) ...[
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_pin,
                        size: 12.0,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        assignedEmployee,
                        style: const TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isFeedback) {
      return cardContent;
    }

    // Return Draggable wrapped card
    return Draggable<ServiceOrder>(
      data: order,
      feedback: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 250.0,
          child: OSCard(order: order, isFeedback: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: cardContent,
      ),
      child: InkWell(
        onDoubleTap: () => context.push('/orders/${order.id}'),
        child: cardContent,
      ),
    );
  }
}

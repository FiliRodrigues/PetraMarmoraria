import 'package:flutter/material.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatelessWidget {
  final List<ServiceOrder> orders;
  final List<String>? statuses;

  const KanbanBoard({
    super.key,
    required this.orders,
    this.statuses,
  });

  Map<String, List<ServiceOrder>> _groupOrdersByStatus(List<String> list) {
    final Map<String, List<ServiceOrder>> grouped = {
      for (var status in list) status: [],
    };

    for (var order in orders) {
      if (grouped.containsKey(order.status)) {
        grouped[order.status]!.add(order);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final list = statuses ?? OSStatus.ordered;
    final groupedOrders = _groupOrdersByStatus(list);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (isDesktop) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list.map((status) {
            return KanbanColumn(
              status: status,
              orders: groupedOrders[status] ?? [],
            );
          }).toList(),
        ),
      );
    }

    return DefaultTabController(
      length: list.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.accent,
            unselectedLabelColor: AppColors.grey,
            tabs: list.map((status) {
              final label = OSStatus.labels[status] ?? status;
              final count = groupedOrders[status]?.length ?? 0;
              return Tab(
                child: Row(
                  children: [
                    Text(label),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '$count',
                        style: AppTheme.jakarta(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: count > 0 ? AppColors.accent : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: list.map((status) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: KanbanColumn(
                    status: status,
                    orders: groupedOrders[status] ?? [],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

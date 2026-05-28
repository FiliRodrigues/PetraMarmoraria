import 'package:flutter/material.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import 'kanban_column.dart';

/// The main Kanban Board widget. Adapts responsively:
/// - Desktop: horizontal scrolling row of columns.
/// - Mobile: TabBar with scrollable stage tabs and horizontal paging.
class KanbanBoard extends StatelessWidget {
  final List<ServiceOrder> orders;

  /// Etapas exibidas neste board. Default: todas, na ordem do fluxo.
  final List<String> statuses;

  const KanbanBoard({
    super.key,
    required this.orders,
    this.statuses = OSStatus.ordered,
  });

  Map<String, List<ServiceOrder>> _groupOrdersByStatus() {
    final Map<String, List<ServiceOrder>> grouped = {
      for (var status in statuses) status: [],
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
    final groupedOrders = _groupOrdersByStatus();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (isDesktop) {
      // Horizontal row for desktop screens
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: statuses.map((status) {
            return KanbanColumn(
              status: status,
              orders: groupedOrders[status] ?? [],
            );
          }).toList(),
        ),
      );
    }

    // Scrollable TabBar layout for mobile/tablet screens
    return DefaultTabController(
      length: statuses.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.secondary,
            unselectedLabelColor: AppColors.grey,
            tabs: statuses.map((status) {
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
                        color: count > 0 ? AppColors.secondary : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: count > 0 ? AppColors.primary : AppColors.grey,
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
              children: statuses.map((status) {
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

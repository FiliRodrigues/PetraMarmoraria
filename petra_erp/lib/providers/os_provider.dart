import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class ServiceOrderNotifier extends StateNotifier<AsyncValue<List<ServiceOrder>>> {
  final ServiceOrderService _service;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;

  ServiceOrderNotifier(this._service) : super(const AsyncValue.loading()) {
    loadOrders();
    _listenToStream();
  }

  Future<void> loadOrders() async {
    try {
      final orders = await _service.getServiceOrders();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToStream() {
    _streamSubscription = _service.streamServiceOrders().listen((_) async {
      // When database changes, reload orders to fetch client joins correctly
      await loadOrders();
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });
  }

  Future<void> moveOrder({
    required String orderId,
    required String newStatus,
    required String changedById,
    String? notes,
    String? employeeId,
  }) async {
    try {
      await _service.moveStatus(
        orderId: orderId,
        newStatus: newStatus,
        changedById: changedById,
        notes: notes,
        employeeId: employeeId,
      );
      // Reload immediately for responsive UI. The stream subscription also
      // reloads on DB changes (and is the only path that brings the customer
      // join), so realtime stays the source of truth if it is enabled.
      await loadOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOrder(ServiceOrder order) async {
    try {
      await _service.createServiceOrder(order);
      await loadOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrder(ServiceOrder order) async {
    try {
      await _service.updateServiceOrder(order);
      await loadOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> checkQueueViolations(String orderId) async {
    return await _service.checkQueueViolations(orderId);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

// Global Service Orders Provider
final osProvider = StateNotifierProvider<ServiceOrderNotifier, AsyncValue<List<ServiceOrder>>>((ref) {
  final service = ref.watch(serviceOrderServiceProvider);
  return ServiceOrderNotifier(service);
});

// Helper Providers for Filtering
final delayedOrdersProvider = Provider<List<ServiceOrder>>((ref) {
  final state = ref.watch(osProvider);
  return state.maybeWhen(
    data: (orders) => orders.where((o) => o.isDelayed).toList(),
    orElse: () => [],
  );
});

final ordersByStatusProvider = Provider.family<List<ServiceOrder>, String>((ref, status) {
  final state = ref.watch(osProvider);
  return state.maybeWhen(
    data: (orders) => orders.where((o) => o.status == status).toList(),
    orElse: () => [],
  );
});

// Provides the list of assignments for a specific service order
final osAssignmentsProvider = FutureProvider.family<List<OrderAssignment>, String>((ref, orderId) async {
  final service = ref.watch(serviceOrderServiceProvider);
  return await service.getAssignments(orderId);
});

// Provides the status change history for a specific service order
final osHistoryProvider = FutureProvider.family<List<StatusHistory>, String>((ref, orderId) async {
  final service = ref.watch(serviceOrderServiceProvider);
  return await service.getStatusHistory(orderId);
});

// Provides ALL employee assignments (relatório de produção por funcionário).
final allAssignmentsProvider = FutureProvider<List<OrderAssignment>>((ref) async {
  final service = ref.watch(serviceOrderServiceProvider);
  return await service.getAllAssignments();
});

/// Etapa finalizada por um funcionário, aguardando o ADM liberar a OS para a
/// próxima etapa. Derivado de order_assignments concluídos cuja OS ainda está
/// parada na etapa do assignment.
class PendingAdminAction {
  final ServiceOrder order;
  final String stage; // etapa concluída
  final String employeeName;
  final DateTime completedAt;

  const PendingAdminAction({
    required this.order,
    required this.stage,
    required this.employeeName,
    required this.completedAt,
  });
}

final pendingAdminActionsProvider = FutureProvider<List<PendingAdminAction>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  final rows = await client
      .from('order_assignments')
      .select('stage, completed_at, employee:profiles(name), '
          'order:service_orders!order_assignments_order_id_fkey('
          '*, customers(name), creator:profiles!service_orders_created_by_fkey(name))')
      .not('completed_at', 'is', null)
      .order('completed_at', ascending: false);

  final result = <PendingAdminAction>[];
  for (final r in (rows as List)) {
    final orderMap = r['order'] as Map<String, dynamic>?;
    if (orderMap == null) continue;
    final stage = r['stage'] as String;
    // Só interessa se a OS ainda está parada na etapa concluída (ninguém moveu).
    if (orderMap['status'] != stage) continue;

    final customerName = orderMap['customers'] != null
        ? orderMap['customers']['name'] as String?
        : null;
    result.add(PendingAdminAction(
      order: ServiceOrder.fromMap(orderMap, customerName: customerName),
      stage: stage,
      employeeName: (r['employee']?['name'] as String?) ?? 'Funcionário',
      completedAt: DateTime.parse(r['completed_at'] as String),
    ));
  }
  return result;
});

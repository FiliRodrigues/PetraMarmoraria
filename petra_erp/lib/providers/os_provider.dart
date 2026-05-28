import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class ServiceOrderNotifier extends StateNotifier<AsyncValue<List<ServiceOrder>>> {
  final ServiceOrderService _service;
  StreamSubscription<List<ServiceOrder>>? _streamSubscription;

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
    _streamSubscription = _service.streamServiceOrders().listen((event) async {
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

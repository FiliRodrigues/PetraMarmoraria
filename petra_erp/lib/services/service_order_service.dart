import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order.dart';
import '../models/status_history.dart';
import '../models/order_assignment.dart';
import '../core/constants/os_status.dart';

class ServiceOrderService {
  final SupabaseClient _client;

  ServiceOrderService(this._client);

  // Fetch all OS, including the client join
  Future<List<ServiceOrder>> getServiceOrders() async {
    try {
      final response = await _client
          .from('service_orders')
          .select('*, customers(name)')
          .order('queue_position', ascending: true);
      return (response as List).map((e) {
        final customerName = e['customers'] != null ? e['customers']['name'] as String? : null;
        return ServiceOrder.fromMap(e, customerName: customerName);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ServiceOrder>> streamServiceOrders() {
    return _client
        .from('service_orders')
        .stream(primaryKey: ['id'])
        .order('queue_position', ascending: true)
        .map((events) => events.map((e) => ServiceOrder.fromMap(e)).toList());
  }

  Future<ServiceOrder> getServiceOrderById(String id) async {
    try {
      final response = await _client
          .from('service_orders')
          .select('*, customers(name)')
          .eq('id', id)
          .single();
      final customerName = response['customers'] != null ? response['customers']['name'] as String? : null;
      return ServiceOrder.fromMap(response, customerName: customerName);
    } catch (e) {
      rethrow;
    }
  }

  Future<ServiceOrder> createServiceOrder(ServiceOrder order) async {
    try {
      final data = order.toMap()..remove('id')..remove('display_number')..remove('created_at')..remove('updated_at');
      final response = await _client.from('service_orders').insert(data).select().single();
      return ServiceOrder.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ServiceOrder> updateServiceOrder(ServiceOrder order) async {
    try {
      final data = order.toMap()..remove('created_at')..remove('updated_at')..remove('display_number');
      final response = await _client
          .from('service_orders')
          .update(data)
          .eq('id', order.id)
          .select()
          .single();
      return ServiceOrder.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteServiceOrder(String id) async {
    try {
      await _client.from('service_orders').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ServiceOrder>> getDelayedOrders({int maxStaleDays = 5}) async {
    try {
      final all = await getServiceOrders();
      final cutoff = DateTime.now().subtract(Duration(days: maxStaleDays));
      return all.where((o) =>
          o.status != OSStatus.entrega && o.statusChangedAt.isBefore(cutoff)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> moveStatus({
    required String orderId,
    required String newStatus,
    required String changedById,
    String? notes,
    String? employeeId,
  }) async {
    try {
      final order = await getServiceOrderById(orderId);
      final currentStatus = order.status;

      if (!OSStatus.canMoveTo(currentStatus, newStatus)) {
        throw Exception(
          'Transição inválida: Não é permitido pular etapas. Do status "${OSStatus.labels[currentStatus]}" só é possível mover para status adjacentes.',
        );
      }

      final requiredRole = OSStatus.requiredRole(newStatus);
      if (OSStatus.requiresAssignment(newStatus)) {
        if (employeeId == null || employeeId.trim().isEmpty) {
          throw Exception(
            'Funcionário é obrigatório para a etapa "${OSStatus.labels[newStatus]}".',
          );
        }
        if (requiredRole != null) {
          final empResponse = await _client.from('profiles').select('roles').eq('id', employeeId).single();
          final empRoles = (empResponse['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [];
          if (!empRoles.contains(requiredRole)) {
            throw Exception(
              'Funcionário inválido para "${OSStatus.labels[newStatus]}". É necessário um funcionário com cargo "$requiredRole".',
            );
          }
        }
      }

      await _client.from('service_orders').update({
        'status': newStatus,
        'status_changed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _client.from('status_history').insert({
        'order_id': orderId,
        'from_status': currentStatus,
        'to_status': newStatus,
        'changed_by': changedById,
        'notes': notes,
      });

      if (employeeId != null && OSStatus.requiresAssignment(newStatus)) {
        await _client.from('order_assignments').insert({
          'order_id': orderId,
          'stage': newStatus,
          'employee_id': employeeId,
          'notes': notes,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Call Supabase database function check_queue_violation
  Future<List<Map<String, dynamic>>> checkQueueViolations(String orderId) async {
    try {
      final response = await _client.rpc(
        'check_queue_violation',
        params: {'p_order_id': orderId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If function doesn't exist or error occurs, return empty list
      return [];
    }
  }

  // Fetch status history for a specific OS
  Future<List<StatusHistory>> getStatusHistory(String orderId) async {
    try {
      final response = await _client
          .from('status_history')
          .select('*, profiles(name)')
          .eq('order_id', orderId)
          .order('changed_at', ascending: false);
      return (response as List).map((e) {
        final profileName = e['profiles'] != null ? e['profiles']['name'] as String? : null;
        return StatusHistory.fromMap(e, changedByName: profileName);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch employee assignments for a specific OS
  Future<List<OrderAssignment>> getAssignments(String orderId) async {
    try {
      final response = await _client
          .from('order_assignments')
          .select('*, profiles(name)')
          .eq('order_id', orderId)
          .order('assigned_at', ascending: false);
      return (response as List).map((e) {
        final employeeName = e['profiles'] != null ? e['profiles']['name'] as String? : null;
        return OrderAssignment.fromMap(e, employeeName: employeeName);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

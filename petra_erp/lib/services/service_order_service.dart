import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order.dart';
import '../models/status_history.dart';
import '../models/order_assignment.dart';
import '../core/constants/os_status.dart';

class ServiceOrderService {
  final SupabaseClient _client;

  ServiceOrderService(this._client);

  Future<List<ServiceOrder>> getServiceOrders({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client
          .from('service_orders')
          .select('*, customers(name)');
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }
      final response = await query
          .order('queue_position', ascending: true)
          .limit(500);
      return (response as List).map((e) {
        final customerName = e['customers'] != null ? e['customers']['name'] as String? : null;
        return ServiceOrder.fromMap(e, customerName: customerName);
      }).toList();
    } catch (e) {
      throw Exception('Falha ao buscar OS: ${e.toString()}');
    }
  }

  Future<List<ServiceOrder>> getServiceOrdersPaged({
    required int offset,
    int pageSize = 30,
    String? search,
    String? status,
    int? month,
    int? year,
  }) async {
    try {
      var query = _client.from('service_orders').select('*, customers(name)');
      if (search != null && search.isNotEmpty) {
        query = query.or('display_number.ilike.%$search%,customers.name.ilike.%$search%');
      }
      if (status != null) query = query.eq('status', status);
      if (month != null && year != null) {
        final from = DateTime(year, month, 1);
        final to = DateTime(year, month + 1, 1);
        query = query.gte('created_at', from.toIso8601String()).lt('created_at', to.toIso8601String());
      }
      final response = await query
          .order('queue_position', ascending: true)
          .range(offset, offset + pageSize - 1);
      return (response as List).map((e) {
        final customerName = e['customers'] != null ? e['customers']['name'] as String? : null;
        return ServiceOrder.fromMap(e, customerName: customerName);
      }).toList();
    } catch (e) {
      throw Exception('Falha ao buscar OS: ${e.toString()}');
    }
  }

  Stream<List<ServiceOrder>> streamServiceOrders() {
    return _client
        .from('service_orders')
        .stream(primaryKey: ['id'])
        .order('queue_position', ascending: true)
        .asyncMap((_) => getServiceOrders());
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
      throw Exception('Falha ao buscar OS: ${e.toString()}');
    }
  }

  Future<ServiceOrder> createServiceOrder(ServiceOrder order) async {
    try {
      final data = order.toMap()..remove('id')..remove('display_number')..remove('created_at')..remove('updated_at');
      final response = await _client.from('service_orders').insert(data).select().single();
      return ServiceOrder.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar OS: ${e.toString()}');
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
      throw Exception('Falha ao atualizar OS: ${e.toString()}');
    }
  }

  Future<void> deleteServiceOrder(String id) async {
    try {
      await _client.from('service_orders').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao excluir OS: ${e.toString()}');
    }
  }

  Future<List<ServiceOrder>> getDelayedOrders({int maxStaleDays = 5}) async {
    try {
      final all = await getServiceOrders();
      final cutoff = DateTime.now().subtract(Duration(days: maxStaleDays));
      return all.where((o) =>
          o.status != OSStatus.entrega && o.statusChangedAt.isBefore(cutoff)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar OS atrasadas: ${e.toString()}');
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
          'Transição inválida: Do status "${OSStatus.labels[currentStatus]}" só é possível mover para status adjacentes.',
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
          final empRoles = (empResponse['roles'] as List?)?.cast<String>() ?? [];
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
      throw Exception('Falha ao mover status da OS: ${e.toString()}');
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
      debugPrint('Erro ao verificar violação de fila: $e');
      return [];
    }
  }

  Future<List<OrderAssignment>> getAssignmentsForOrders(List<String> orderIds) async {
    try {
      if (orderIds.isEmpty) return [];
      final response = await _client
          .from('order_assignments')
          .select('*, profiles(name)')
          .inFilter('order_id', orderIds)
          .order('assigned_at', ascending: false);
      return (response as List).map((e) {
        final employeeName = e['profiles'] != null ? e['profiles']['name'] as String? : null;
        return OrderAssignment.fromMap(e, employeeName: employeeName);
      }).toList();
    } catch (e) {
      throw Exception('Falha ao buscar designações: ${e.toString()}');
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
      throw Exception('Falha ao buscar histórico de status: ${e.toString()}');
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
      throw Exception('Falha ao buscar designações: ${e.toString()}');
    }
  }
}

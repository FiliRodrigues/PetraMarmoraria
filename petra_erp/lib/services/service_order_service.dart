import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order.dart';
import '../models/status_history.dart';
import '../models/order_assignment.dart';
import '../core/constants/os_status.dart';

class ServiceOrderService {
  final SupabaseClient _client;

  ServiceOrderService(this._client);

  // Join do criador (vendedor). FK explícita p/ desambiguar profiles.
  static const _selectWithJoins =
      '*, customers(name), creator:profiles!service_orders_created_by_fkey(name)';

  // Fetch all OS, including the client join
  Future<List<ServiceOrder>> getServiceOrders({int? offset, int? limit}) async {
    try {
      dynamic query = _client
          .from('service_orders')
          .select(_selectWithJoins)
          .order('queue_position', ascending: true);
      if (offset != null && limit != null) query = query.range(offset, offset + limit - 1);
      final response = await query;
      return (response as List).map((e) {
        final customerName = e['customers'] != null ? e['customers']['name'] as String? : null;
        return ServiceOrder.fromMap(e, customerName: customerName);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Escuta mudanças na tabela service_orders. O provider usa isso só como
  /// gatilho para recarregar os dados com join via [getServiceOrders].
  Stream<List<Map<String, dynamic>>> streamServiceOrders() {
    return _client
        .from('service_orders')
        .stream(primaryKey: ['id'])
        .order('queue_position', ascending: true);
  }

  Future<ServiceOrder> getServiceOrderById(String id) async {
    try {
      final response = await _client
          .from('service_orders')
          .select(_selectWithJoins)
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
      // Grava o vendedor responsável = usuário logado (se ainda não definido).
      data['created_by'] ??= _client.auth.currentUser?.id;
      final response = await _client.from('service_orders').insert(data).select().single();
      return ServiceOrder.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ServiceOrder> updateServiceOrder(ServiceOrder order) async {
    try {
      // Não sobrescreve created_by no update (preserva o vendedor original).
      // status_changed_at só muda via moveStatus; editar a OS não pode resetar
      // o relógio de "tempo parado" (daysStale/isDelayed).
      final data = order.toMap()
        ..remove('created_at')
        ..remove('updated_at')
        ..remove('display_number')
        ..remove('created_by')
        ..remove('status_changed_at');
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
          o.status != OSStatus.entrega &&
          o.status != OSStatus.entregue &&
          o.statusChangedAt.isBefore(cutoff)).toList();
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

      await _client.rpc('move_service_order_status', params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
        'p_changed_by': changedById,
        'p_notes': notes,
        'p_employee_id': employeeId,
      });
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

  // Fetch ALL assignments (para relatório de produção por funcionário).
  // Filtro opcional por período sobre assigned_at.
  Future<List<OrderAssignment>> getAllAssignments({DateTime? from, DateTime? to}) async {
    try {
      final response = await _client
          .rpc('get_all_order_assignments', params: {
            if (from != null) 'p_from': from.toIso8601String(),
            if (to != null) 'p_to': to.toIso8601String(),
          });
      return (response as List).map((e) {
        return OrderAssignment.fromMap(e, employeeName: e['employee_name'] as String?);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch employee assignments for a specific OS
  Future<List<OrderAssignment>> getAssignments(String orderId) async {
    try {
      final response = await _client
          .rpc('get_order_assignments', params: {'p_order_id': orderId});
      return (response as List).map((e) {
        return OrderAssignment.fromMap(e, employeeName: e['employee_name'] as String?);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  final SupabaseClient _client;

  ExpenseService(this._client);

  /// Contas a pagar estão na tabela accounts_payable (não 'expenses').
  static const _select = '*';

  Future<List<Expense>> getAll({int? offset, int? limit, DateTime? startDate, DateTime? endDate}) async {
    try {
      dynamic query = _client
          .from('accounts_payable')
          .select(_select);
      if (startDate != null) query = query.gte('due_date', startDate.toIso8601String().substring(0, 10));
      if (endDate != null) query = query.lte('due_date', endDate.toIso8601String().substring(0, 10));
      query = query.order('due_date', ascending: true);
      if (offset != null && limit != null) query = query.range(offset, offset + limit - 1);
      final response = await query;
      return (response as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // accounts_payable não tem coluna 'type' — tudo é despesa
        map['type'] = 'despesa';
        return Expense.fromMap(map);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Expense>> getPayables() async {
    try {
      final response = await _client
          .from('accounts_payable')
          .select(_select)
          .neq('status', 'pago')
          .order('due_date', ascending: true);
      return (response as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        map['type'] = 'despesa';
        return Expense.fromMap(map);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Expense> create(Expense expense) async {
    try {
      final data = expense.toMap()
        ..remove('id')
        ..remove('created_at')
        ..remove('type') // accounts_payable não tem coluna type
        ..remove('categoryName')
        ..remove('supplierId'); // snake_case é supplier_id
      data['created_by'] ??= _client.auth.currentUser?.id;
      // supplier_id já está no mapa com a chave correta
      if (expense.supplierId != null) {
        data['supplier_id'] = expense.supplierId;
      }
      final response = await _client
          .from('accounts_payable')
          .insert(data)
          .select(_select)
          .single();
      return Expense.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Expense> update(Expense expense) async {
    try {
      final data = expense.toMap()
        ..remove('created_at')
        ..remove('created_by')
        ..remove('type')
        ..remove('categoryName')
        ..remove('supplierId');
      if (expense.supplierId != null) {
        data['supplier_id'] = expense.supplierId;
      }
      final response = await _client
          .from('accounts_payable')
          .update(data)
          .eq('id', expense.id)
          .select(_select)
          .single();
      return Expense.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markPaid(String id) async {
    try {
      await _client.from('accounts_payable').update({
        'status': 'pago',
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('accounts_payable').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/payment_constants.dart';
import '../models/payment.dart';

class PaymentService {
  final SupabaseClient _client;

  PaymentService(this._client);

  static const _select =
      '*, service_orders(display_number, total_value, customer_id, customers(name))';

  /// Pagamentos de uma OS específica (mais antigos primeiro p/ ordem das parcelas).
  Future<List<Payment>> getByOrder(String orderId) async {
    try {
      final response = await _client
          .from('payments')
          .select(_select)
          .eq('order_id', orderId)
          .order('due_date', ascending: true)
          .order('created_at', ascending: true);
      return (response as List).map((e) => Payment.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Todos os pagamentos.
  Future<List<Payment>> getAll() async {
    try {
      final response = await _client
          .from('payments')
          .select(_select)
          .order('due_date', ascending: true);
      return (response as List).map((e) => Payment.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Apenas recebíveis (pendentes).
  Future<List<Payment>> getReceivables() async {
    try {
      final response = await _client
          .from('payments')
          .select(_select)
          .eq('status', PaymentConstants.pendente)
          .order('due_date', ascending: true);
      return (response as List).map((e) => Payment.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Payment> create(Payment payment) async {
    try {
      final data = payment.toMap()..remove('id')..remove('created_at');
      data['created_by'] ??= _client.auth.currentUser?.id;
      final response = await _client.from('payments').insert(data).select(_select).single();
      return Payment.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Cria N parcelas mensais a partir de [firstDueDate].
  Future<void> createInstallments({
    required String orderId,
    required double totalAmount,
    required int count,
    required DateTime firstDueDate,
    required String method,
  }) async {
    if (count <= 0) return;
    final userId = _client.auth.currentUser?.id;
    // Distribui o total, ajustando a última parcela p/ fechar o valor exato.
    final base = (totalAmount / count);
    final rounded = double.parse(base.toStringAsFixed(2));
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      final isLast = i == count - 1;
      final amount = isLast
          ? double.parse((totalAmount - rounded * (count - 1)).toStringAsFixed(2))
          : rounded;
      final due = DateTime(firstDueDate.year, firstDueDate.month + i, firstDueDate.day);
      rows.add({
        'order_id': orderId,
        'amount': amount,
        'method': method,
        'status': PaymentConstants.pendente,
        'due_date': due.toIso8601String().substring(0, 10),
        'notes': 'Parcela ${i + 1}/$count',
        'created_by': userId,
      });
    }
    await _client.from('payments').insert(rows);
  }

  Future<Payment> update(Payment payment) async {
    try {
      final data = payment.toMap()..remove('created_at')..remove('created_by');
      final response = await _client
          .from('payments')
          .update(data)
          .eq('id', payment.id)
          .select(_select)
          .single();
      return Payment.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markPaid(String id, {String? method}) async {
    try {
      final data = {
        'status': PaymentConstants.pago,
        'paid_at': DateTime.now().toIso8601String(),
        if (method != null) 'method': method,
      };
      await _client.from('payments').update(data).eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('payments').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}

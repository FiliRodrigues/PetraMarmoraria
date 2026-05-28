import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_payable.dart';
import '../models/account_receivable.dart';

class FinanceService {
  final SupabaseClient _client;

  FinanceService(this._client);

  Future<List<AccountPayable>> getPayables({String? status}) async {
    try {
      dynamic query = _client.from('accounts_payable').select();
      if (status == 'pending') {
        query = query.isFilter('paid_at', null);
      } else if (status == 'paid') {
        query = query.not('paid_at', 'is', null);
      }
      query = query.order('due_date', ascending: true);
      final response = await query;
      return (response as List).map((e) => AccountPayable.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar contas a pagar: ${e.toString()}');
    }
  }

  Future<List<AccountReceivable>> getReceivables({String? status}) async {
    try {
      dynamic query = _client.from('accounts_receivable').select();
      if (status == 'pending') {
        query = query.isFilter('received_at', null);
      } else if (status == 'received') {
        query = query.not('received_at', 'is', null);
      }
      query = query.order('due_date', ascending: true);
      final response = await query;
      return (response as List).map((e) => AccountReceivable.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar contas a receber: ${e.toString()}');
    }
  }

  Future<AccountPayable> createPayable(AccountPayable payable) async {
    try {
      final data = payable.toMap()..remove('id')..remove('created_at')..remove('updated_at');
      final response = await _client.from('accounts_payable').insert(data).select().single();
      return AccountPayable.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar conta a pagar: ${e.toString()}');
    }
  }

  Future<AccountPayable> updatePayable(AccountPayable payable) async {
    try {
      final data = payable.toMap()..remove('created_at');
      final response = await _client
          .from('accounts_payable')
          .update(data)
          .eq('id', payable.id)
          .select()
          .single();
      return AccountPayable.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao atualizar conta a pagar: ${e.toString()}');
    }
  }

  Future<void> deletePayable(String id) async {
    try {
      await _client.from('accounts_payable').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao excluir conta a pagar: ${e.toString()}');
    }
  }

  Future<AccountReceivable> createReceivable(AccountReceivable receivable) async {
    try {
      final data = receivable.toMap()..remove('id')..remove('created_at')..remove('updated_at');
      final response = await _client.from('accounts_receivable').insert(data).select().single();
      return AccountReceivable.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar conta a receber: ${e.toString()}');
    }
  }

  Future<AccountReceivable> updateReceivable(AccountReceivable receivable) async {
    try {
      final data = receivable.toMap()..remove('created_at');
      final response = await _client
          .from('accounts_receivable')
          .update(data)
          .eq('id', receivable.id)
          .select()
          .single();
      return AccountReceivable.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao atualizar conta a receber: ${e.toString()}');
    }
  }

  Future<void> deleteReceivable(String id) async {
    try {
      await _client.from('accounts_receivable').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao excluir conta a receber: ${e.toString()}');
    }
  }

  Future<AccountPayable> markAsPaid(String id, double paidAmount) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('accounts_payable')
          .update({'paid_at': now, 'paid_amount': paidAmount})
          .eq('id', id)
          .select()
          .single();
      return AccountPayable.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao marcar como pago: ${e.toString()}');
    }
  }

  Future<AccountReceivable> markAsReceived(String id, double receivedAmount) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('accounts_receivable')
          .update({'received_at': now, 'received_amount': receivedAmount})
          .eq('id', id)
          .select()
          .single();
      return AccountReceivable.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao marcar como recebido: ${e.toString()}');
    }
  }

  Future<Map<String, double>> getFinanceSummary(int month, int year) async {
    try {
      final fromDate = DateTime(year, month, 1).toIso8601String();
      final toDate = month == 12
          ? DateTime(year + 1, 1, 1).toIso8601String()
          : DateTime(year, month + 1, 1).toIso8601String();

      final payables = await _client
          .from('accounts_payable')
          .select()
          .gte('due_date', fromDate)
          .lt('due_date', toDate);

      final receivables = await _client
          .from('accounts_receivable')
          .select()
          .gte('due_date', fromDate)
          .lt('due_date', toDate);

      double totalToPay = 0;
      double totalPaid = 0;
      double totalToReceive = 0;
      double totalReceived = 0;

      for (final p in payables as List) {
        final amount = (p['amount'] as num).toDouble();
        if (p['paid_at'] != null) {
          totalPaid += (p['paid_amount'] as num?)?.toDouble() ?? amount;
        } else {
          totalToPay += amount;
        }
      }

      for (final r in receivables as List) {
        final amount = (r['amount'] as num).toDouble();
        if (r['received_at'] != null) {
          totalReceived += (r['received_amount'] as num?)?.toDouble() ?? amount;
        } else {
          totalToReceive += amount;
        }
      }

      return {
        'totalToPay': totalToPay,
        'totalPaid': totalPaid,
        'totalToReceive': totalToReceive,
        'totalReceived': totalReceived,
        'balance': totalReceived - totalPaid,
      };
    } catch (e) {
      throw Exception('Falha ao buscar resumo financeiro: ${e.toString()}');
    }
  }
}

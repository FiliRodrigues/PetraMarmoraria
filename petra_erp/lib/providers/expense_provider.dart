import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseService _service;

  ExpenseNotifier(this._service) : super(const AsyncValue.loading()) {
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      final list = await _service.getAll();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> create(Expense expense) async {
    await _service.create(expense);
    await loadAll();
  }

  Future<void> update(Expense expense) async {
    await _service.update(expense);
    await loadAll();
  }

  Future<void> markPaid(String id) async {
    await _service.markPaid(id);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await loadAll();
  }
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  final service = ref.watch(expenseServiceProvider);
  return ExpenseNotifier(service);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_category.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class FinancialCategoryNotifier
    extends StateNotifier<AsyncValue<List<FinancialCategory>>> {
  final FinancialCategoryService _service;

  FinancialCategoryNotifier(this._service) : super(const AsyncValue.loading()) {
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      state = const AsyncValue.loading();
      final list = await _service.getAll();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> create(FinancialCategory category) async {
    await _service.create(category);
    await loadAll();
  }

  Future<void> update(FinancialCategory category) async {
    await _service.update(category);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await loadAll();
  }
}

final financialCategoryProvider = StateNotifierProvider<
    FinancialCategoryNotifier, AsyncValue<List<FinancialCategory>>>((ref) {
  final service = ref.watch(financialCategoryServiceProvider);
  return FinancialCategoryNotifier(service);
});

/// Filtro em memória: categorias por tipo ('expense', 'income').
final categoriesByTypeProvider =
    Provider.family<List<FinancialCategory>, String>((ref, type) {
  final categoriesAsync = ref.watch(financialCategoryProvider);
  return categoriesAsync.when(
    data: (categories) =>
        categories.where((c) => c.type == type).toList(),
    loading: () => [],
    error: (e, st) => [],
  );
});

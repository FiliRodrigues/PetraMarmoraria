import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class SupplierNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  final SupplierService _service;

  SupplierNotifier(this._service) : super(const AsyncValue.loading()) {
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

  Future<void> create(Supplier supplier) async {
    await _service.create(supplier);
    await loadAll();
  }

  Future<void> update(Supplier supplier) async {
    await _service.update(supplier);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await loadAll();
  }
}

final supplierProvider =
    StateNotifierProvider<SupplierNotifier, AsyncValue<List<Supplier>>>((ref) {
  final service = ref.watch(supplierServiceProvider);
  return SupplierNotifier(service);
});

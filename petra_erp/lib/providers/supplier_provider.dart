import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class SupplierNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  final SupplierService _service;
  StreamSubscription<List<Supplier>>? _streamSubscription;

  SupplierNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSuppliers();
    _listenToStream();
  }

  Future<void> loadSuppliers() async {
    try {
      final list = await _service.getSuppliers();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToStream() {
    _streamSubscription = _service.streamSuppliers().listen((suppliers) async {
      await loadSuppliers();
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _service.createSupplier(supplier);
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _service.updateSupplier(supplier);
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _service.deleteSupplier(id);
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final supplierProvider = StateNotifierProvider<SupplierNotifier, AsyncValue<List<Supplier>>>((ref) {
  final service = ref.watch(supplierServiceProvider);
  return SupplierNotifier(service);
});

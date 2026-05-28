import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/paged_notifier.dart';
import '../models/product.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductService _service;
  StreamSubscription<List<Product>>? _streamSubscription;

  ProductNotifier(this._service) : super(const AsyncValue.loading()) {
    loadProducts();
    _listenToStream();
  }

  Future<void> loadProducts() async {
    try {
      final list = await _service.getProducts();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToStream() {
    _streamSubscription = _service.streamProducts().listen((products) async {
      await loadProducts();
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });
  }

  Future<void> addProduct(Product product) async {
    try {
      await _service.createProduct(product);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _service.updateProduct(product);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      await loadProducts();
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

final productProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final service = ref.watch(productServiceProvider);
  return ProductNotifier(service);
});

class ProductPagedNotifier extends PagedNotifier<Product> {
  final ProductService _service;
  ProductPagedNotifier(this._service) {
    refresh();
  }

  @override
  Future<List<Product>> fetchPage({required int offset, required int pageSize, String? search}) =>
      _service.getProductsPaged(offset: offset, pageSize: pageSize, search: search);
}

final productPagedProvider = StateNotifierProvider<ProductPagedNotifier, PagedState<Product>>((ref) {
  return ProductPagedNotifier(ref.watch(productServiceProvider));
});

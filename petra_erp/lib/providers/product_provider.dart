import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductService _service;

  ProductNotifier(this._service) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final list = await _service.getProducts();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
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
}

final productProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final service = ref.watch(productServiceProvider);
  return ProductNotifier(service);
});

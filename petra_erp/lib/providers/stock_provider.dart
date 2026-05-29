import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'supabase_provider.dart';
import 'product_provider.dart';

class StockNotifier extends StateNotifier<AsyncValue<void>> {
  final StockService _service;
  final Ref _ref;

  StockNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  /// Registra uma movimentação e recarrega o catálogo de produtos (estoque).
  Future<void> registerMovement({
    required String productId,
    required String type,
    required double quantity,
    String? reason,
    String? orderId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.registerMovement(
        productId: productId,
        type: type,
        quantity: quantity,
        reason: reason,
        orderId: orderId,
      );
      // Atualiza o estoque exibido nas telas.
      await _ref.read(productProvider.notifier).loadProducts();
      // Invalida o histórico do produto movimentado.
      _ref.invalidate(stockMovementsProvider(productId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final stockProvider = StateNotifierProvider<StockNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(stockServiceProvider);
  return StockNotifier(service, ref);
});

/// Histórico de movimentações de um material.
final stockMovementsProvider =
    FutureProvider.family<List<StockMovement>, String>((ref, productId) async {
  final service = ref.watch(stockServiceProvider);
  return service.getMovements(productId);
});

/// Materiais com estoque no/abaixo do mínimo (alertas).
final lowStockProductsProvider = Provider<List<Product>>((ref) {
  final state = ref.watch(productProvider);
  return state.maybeWhen(
    data: (products) => products.where((p) => p.isLowStock).toList(),
    orElse: () => const [],
  );
});

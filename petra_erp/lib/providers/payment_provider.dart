import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  final PaymentService _service;
  final Ref _ref;

  PaymentNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
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

  void _refreshFor(String orderId) {
    loadAll();
    _ref.invalidate(orderPaymentsProvider(orderId));
  }

  Future<void> create(Payment payment) async {
    await _service.create(payment);
    _refreshFor(payment.orderId);
  }

  Future<void> createInstallments({
    required String orderId,
    required double totalAmount,
    required int count,
    required DateTime firstDueDate,
    required String method,
  }) async {
    await _service.createInstallments(
      orderId: orderId,
      totalAmount: totalAmount,
      count: count,
      firstDueDate: firstDueDate,
      method: method,
    );
    _refreshFor(orderId);
  }

  Future<void> markPaid(Payment payment, {String? method}) async {
    await _service.markPaid(payment.id, method: method);
    _refreshFor(payment.orderId);
  }

  Future<void> delete(Payment payment) async {
    await _service.delete(payment.id);
    _refreshFor(payment.orderId);
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<List<Payment>>>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return PaymentNotifier(service, ref);
});

/// Pagamentos de uma OS específica (usado no detalhe).
final orderPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, orderId) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getByOrder(orderId);
});

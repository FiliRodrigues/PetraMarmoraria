import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class CashFlowState {
  final List<Payment> receivables;
  final List<Expense> payables;
  final DateTime month;

  const CashFlowState({
    required this.receivables,
    required this.payables,
    required this.month,
  });

  double get totalReceivables =>
      _round2(receivables.where((p) => !p.isPaid).fold<double>(0, (s, p) => s + p.amount));

  double get received =>
      _round2(receivables.where((p) => p.isPaid).fold<double>(0, (s, p) => s + p.amount));

  double get totalPayables =>
      _round2(payables.where((e) => e.type == 'despesa' && !e.isPaid).fold<double>(0, (s, e) => s + e.amount));

  double get paidExpenses =>
      _round2(payables.where((e) => e.type == 'despesa' && e.isPaid).fold<double>(0, (s, e) => s + e.amount));

  double get totalIncome =>
      _round2(payables.where((e) => e.type == 'receita').fold<double>(0, (s, e) => s + e.amount));

  double get balance => _round2((received + totalIncome) - paidExpenses);

  double get projectedBalance => _round2(totalReceivables + totalIncome - totalPayables);

  static double _round2(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  CashFlowState copyWith({
    List<Payment>? receivables,
    List<Expense>? payables,
    DateTime? month,
  }) {
    return CashFlowState(
      receivables: receivables ?? this.receivables,
      payables: payables ?? this.payables,
      month: month ?? this.month,
    );
  }
}

class CashFlowNotifier extends StateNotifier<AsyncValue<CashFlowState>> {
  final PaymentService _paymentService;
  final ExpenseService _expenseService;

  CashFlowNotifier(this._paymentService, this._expenseService)
      : super(const AsyncValue.loading()) {
    load(DateTime.now());
  }

  Future<void> load(DateTime month) async {
    try {
      state = const AsyncValue.loading();
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);

      // Fetch with server-side date window to avoid loading entire history.
      // Items due up to 3 months before/after the target month are included;
      // fine-grained paidAt filtering remains client-side on the reduced set.
      final serverStart = DateTime(month.year, month.month - 3, 1);
      final serverEnd = DateTime(month.year, month.month + 4, 0);
      final allPayments = await _paymentService.getAll(startDate: serverStart, endDate: serverEnd);
      final allExpenses = await _expenseService.getAll(startDate: serverStart, endDate: serverEnd);

      final monthPayments = allPayments.where((p) {
        if (p.paidAt != null) {
          return p.paidAt!.isAfter(start.subtract(const Duration(days: 1))) &&
              p.paidAt!.isBefore(end.add(const Duration(days: 1)));
        }
        if (p.dueDate != null) {
          return p.dueDate!.isAfter(start.subtract(const Duration(days: 1))) &&
              p.dueDate!.isBefore(end.add(const Duration(days: 1)));
        }
        return true;
      }).toList();

      final monthExpenses = allExpenses.where((e) {
        if (e.paidAt != null) {
          return e.paidAt!.isAfter(start.subtract(const Duration(days: 1))) &&
              e.paidAt!.isBefore(end.add(const Duration(days: 1)));
        }
        if (e.dueDate != null) {
          return e.dueDate!.isAfter(start.subtract(const Duration(days: 1))) &&
              e.dueDate!.isBefore(end.add(const Duration(days: 1)));
        }
        return true;
      }).toList();

      state = AsyncValue.data(CashFlowState(
        receivables: monthPayments,
        payables: monthExpenses,
        month: month,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final cashFlowProvider =
    StateNotifierProvider<CashFlowNotifier, AsyncValue<CashFlowState>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  final expenseService = ref.watch(expenseServiceProvider);
  return CashFlowNotifier(paymentService, expenseService);
});

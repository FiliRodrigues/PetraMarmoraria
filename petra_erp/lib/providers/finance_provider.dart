import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_payable.dart';
import '../models/account_receivable.dart';
import 'supabase_provider.dart';

final payablesProvider = FutureProvider.family<List<AccountPayable>, String?>((ref, status) async {
  final service = ref.watch(financeServiceProvider);
  return service.getPayables(status: status);
});

final receivablesProvider = FutureProvider.family<List<AccountReceivable>, String?>((ref, status) async {
  final service = ref.watch(financeServiceProvider);
  return service.getReceivables(status: status);
});

final financeSummaryProvider = FutureProvider.family<Map<String, double>, ({int month, int year})>((ref, params) async {
  final service = ref.watch(financeServiceProvider);
  return service.getFinanceSummary(params.month, params.year);
});

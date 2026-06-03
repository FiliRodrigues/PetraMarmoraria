import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class CompanyNotifier extends StateNotifier<AsyncValue<CompanyInfo>> {
  final CompanyService _service;

  CompanyNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final info = await _service.getCompanyInfo();
      state = AsyncValue.data(info);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> save(CompanyInfo info) async {
    try {
      final updated = await _service.updateCompanyInfo(info);
      state = AsyncValue.data(updated);
    } catch (e) {
      rethrow;
    }
  }
}

final companyProvider =
    StateNotifierProvider<CompanyNotifier, AsyncValue<CompanyInfo>>((ref) {
  final service = ref.watch(companyServiceProvider);
  return CompanyNotifier(service);
});

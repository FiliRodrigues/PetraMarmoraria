import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsService(client);
});

final companyInfoProvider = FutureProvider<CompanyInfo?>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return service.getCompanyInfo();
});

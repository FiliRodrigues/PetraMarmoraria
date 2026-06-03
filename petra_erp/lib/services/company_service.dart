import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_info.dart';

class CompanyService {
  final SupabaseClient _client;

  CompanyService(this._client);

  Future<CompanyInfo> getCompanyInfo() async {
    try {
      final response = await _client.from('company_info').select().eq('id', 1).single();
      return CompanyInfo.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<CompanyInfo> updateCompanyInfo(CompanyInfo info) async {
    try {
      final response = await _client
          .from('company_info')
          .update(info.toMap())
          .eq('id', 1)
          .select()
          .single();
      return CompanyInfo.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }
}

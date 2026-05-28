import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_info.dart';

class SettingsService {
  final SupabaseClient _client;

  SettingsService(this._client);

  Future<CompanyInfo?> getCompanyInfo() async {
    try {
      final response = await _client.from('company_info').select().maybeSingle();
      if (response == null) return null;
      return CompanyInfo.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao buscar informações da empresa: ${e.toString()}');
    }
  }

  Future<CompanyInfo> updateCompanyInfo(CompanyInfo info) async {
    try {
      final data = info.toMap()..remove('updated_at');
      final response = await _client
          .from('company_info')
          .update(data)
          .eq('id', info.id)
          .select()
          .single();
      return CompanyInfo.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao atualizar informações da empresa: ${e.toString()}');
    }
  }
}

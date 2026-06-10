import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_category.dart';

class FinancialCategoryService {
  final SupabaseClient _client;

  FinancialCategoryService(this._client);

  static const _select = '*';

  /// Retorna todas as categorias financeiras.
  Future<List<FinancialCategory>> getAll() async {
    try {
      final response = await _client
          .from('financial_categories')
          .select(_select)
          .order('name', ascending: true);
      return (response as List)
          .map((e) => FinancialCategory.fromMap(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Retorna categorias filtradas por tipo (ex: 'receita', 'despesa').
  Future<List<FinancialCategory>> getByType(String type) async {
    try {
      final response = await _client
          .from('financial_categories')
          .select(_select)
          .eq('type', type)
          .order('name', ascending: true);
      return (response as List)
          .map((e) => FinancialCategory.fromMap(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<FinancialCategory> create(FinancialCategory category) async {
    try {
      final data = category.toMap()..remove('id')..remove('created_at');
      final response = await _client
          .from('financial_categories')
          .insert(data)
          .select(_select)
          .single();
      return FinancialCategory.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<FinancialCategory> update(FinancialCategory category) async {
    try {
      final data = category.toMap()..remove('created_at');
      final response = await _client
          .from('financial_categories')
          .update(data)
          .eq('id', category.id)
          .select(_select)
          .single();
      return FinancialCategory.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('financial_categories').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}

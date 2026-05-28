import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService(this._client);

  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _client
          .from('suppliers')
          .select()
          .limit(500)
          .order('name', ascending: true);
      return (response as List).map((e) => Supplier.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar fornecedores: ${e.toString()}');
    }
  }

  Future<Supplier> getSupplierById(String id) async {
    try {
      final response = await _client.from('suppliers').select().eq('id', id).single();
      return Supplier.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao buscar fornecedor: ${e.toString()}');
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final data = supplier.toMap()..remove('id')..remove('created_at')..remove('updated_at');
      final response = await _client.from('suppliers').insert(data).select().single();
      return Supplier.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar fornecedor: ${e.toString()}');
    }
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      final data = supplier.toMap()..remove('created_at')..remove('updated_at');
      final response = await _client
          .from('suppliers')
          .update(data)
          .eq('id', supplier.id)
          .select()
          .single();
      return Supplier.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao atualizar fornecedor: ${e.toString()}');
    }
  }

  Stream<List<Supplier>> streamSuppliers() {
    return _client
        .from('suppliers')
        .stream(primaryKey: ['id'])
        .map((events) => events.map((e) => Supplier.fromMap(e)).toList());
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _client.from('suppliers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao excluir fornecedor: ${e.toString()}');
    }
  }
}

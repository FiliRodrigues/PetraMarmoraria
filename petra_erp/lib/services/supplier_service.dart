import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService(this._client);

  static const _table = 'suppliers';
  static const _select = '*';

  Future<List<Supplier>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select(_select)
          .order('name', ascending: true);
      return (response as List)
          .map((e) => Supplier.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Supplier> create(Supplier supplier) async {
    try {
      final data = supplier.toMap()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      final response = await _client
          .from(_table)
          .insert(data)
          .select(_select)
          .single();
      return Supplier.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Supplier> update(Supplier supplier) async {
    try {
      final data = supplier.toMap()
        ..remove('created_at')
        ..remove('updated_at');
      data['updated_at'] = DateTime.now().toIso8601String();
      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', supplier.id)
          .select(_select)
          .single();
      return Supplier.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}

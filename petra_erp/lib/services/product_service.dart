import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client;

  ProductService(this._client);

  Future<List<Product>> getProducts({int? offset, int? limit}) async {
    try {
      dynamic query = _client
          .from('products')
          .select()
          .order('name', ascending: true);
      if (offset != null && limit != null) query = query.range(offset, offset + limit - 1);
      final response = await query;
      return (response as List).map((e) => Product.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _client.from('products').select().eq('id', id).single();
      return Product.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final data = product.toMap()..remove('id')..remove('created_at');
      final response = await _client.from('products').insert(data).select().single();
      return Product.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      final data = product.toMap()..remove('created_at');
      final response = await _client
          .from('products')
          .update(data)
          .eq('id', product.id)
          .select()
          .single();
      return Product.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}

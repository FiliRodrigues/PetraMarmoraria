import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client;

  ProductService(this._client);

  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('name', ascending: true);
      return (response as List).map((e) => Product.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar produtos: ${e.toString()}');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _client.from('products').select().eq('id', id).single();
      return Product.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao buscar produto: ${e.toString()}');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final data = product.toMap()..remove('id')..remove('created_at');
      final response = await _client.from('products').insert(data).select().single();
      return Product.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar produto: ${e.toString()}');
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
      throw Exception('Falha ao atualizar produto: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao excluir produto: ${e.toString()}');
    }
  }
}

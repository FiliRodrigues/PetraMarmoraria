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
          .limit(500)
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

  Stream<List<Product>> streamProducts() {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .map((events) => events.map((e) => Product.fromMap(e)).toList());
  }

  Future<List<Product>> getProductsPaged({
    required int offset,
    int pageSize = 30,
    String? search,
  }) async {
    try {
      var query = _client.from('products').select();
      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,type.ilike.%$search%');
      }
      final response = await query
          .order('name', ascending: true)
          .range(offset, offset + pageSize - 1);
      return (response as List).map((e) => Product.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar produtos: ${e.toString()}');
    }
  }

  Future<List<Product>> listActive() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('active', true)
          .limit(500)
          .order('name', ascending: true);
      return (response as List).map((e) => Product.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar produtos ativos: ${e.toString()}');
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

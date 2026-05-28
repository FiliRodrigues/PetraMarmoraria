import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseClient _client;

  CustomerService(this._client);

  Future<List<Customer>> getCustomers() async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .limit(500)
          .order('name', ascending: true);
      return (response as List).map((e) => Customer.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar clientes: ${e.toString()}');
    }
  }

  Future<List<Customer>> getCustomersPaged({
    required int offset,
    int pageSize = 30,
    String? search,
  }) async {
    try {
      var query = _client.from('customers').select();
      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,phone.ilike.%$search%,cpf_cnpj.ilike.%$search%');
      }
      final response = await query
          .order('name', ascending: true)
          .range(offset, offset + pageSize - 1);
      return (response as List).map((e) => Customer.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar clientes: ${e.toString()}');
    }
  }

  Future<Customer> getCustomerById(String id) async {
    try {
      final response = await _client.from('customers').select().eq('id', id).single();
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao buscar cliente: ${e.toString()}');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final data = customer.toMap()..remove('id')..remove('created_at');
      final response = await _client.from('customers').insert(data).select().single();
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar cliente: ${e.toString()}');
    }
  }

  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final data = customer.toMap()..remove('created_at');
      final response = await _client
          .from('customers')
          .update(data)
          .eq('id', customer.id)
          .select()
          .single();
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao atualizar cliente: ${e.toString()}');
    }
  }

  Stream<List<Customer>> streamCustomers() {
    return _client
        .from('customers')
        .stream(primaryKey: ['id'])
        .map((events) => events.map((e) => Customer.fromMap(e)).toList());
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao excluir cliente: ${e.toString()}');
    }
  }
}

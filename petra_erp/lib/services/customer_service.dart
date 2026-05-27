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
          .order('name', ascending: true);
      return (response as List).map((e) => Customer.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Customer> getCustomerById(String id) async {
    try {
      final response = await _client.from('customers').select().eq('id', id).single();
      return Customer.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final data = customer.toMap()..remove('id')..remove('created_at');
      final response = await _client.from('customers').insert(data).select().single();
      return Customer.fromMap(response);
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerService _service;

  CustomerNotifier(this._service) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final list = await _service.getCustomers();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _service.createCustomer(customer);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _service.updateCustomer(customer);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  final service = ref.watch(customerServiceProvider);
  return CustomerNotifier(service);
});

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/paged_notifier.dart';
import '../models/customer.dart';
import '../services/services.dart';
import 'os_provider.dart';
import 'supabase_provider.dart';

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerService _service;
  final Ref _ref;
  StreamSubscription<List<Customer>>? _streamSubscription;

  CustomerNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadCustomers();
    _listenToStream();
  }

  Future<void> loadCustomers() async {
    try {
      final list = await _service.getCustomers();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToStream() {
    _streamSubscription = _service.streamCustomers().listen((customers) async {
      await loadCustomers();
      _ref.invalidate(osProvider);
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });
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

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  final service = ref.watch(customerServiceProvider);
  return CustomerNotifier(service, ref);
});

class CustomerPagedNotifier extends PagedNotifier<Customer> {
  final CustomerService _service;
  CustomerPagedNotifier(this._service) {
    refresh();
  }

  @override
  Future<List<Customer>> fetchPage({required int offset, required int pageSize, String? search}) =>
      _service.getCustomersPaged(offset: offset, pageSize: pageSize, search: search);
}

final customerPagedProvider = StateNotifierProvider<CustomerPagedNotifier, PagedState<Customer>>((ref) {
  return CustomerPagedNotifier(ref.watch(customerServiceProvider));
});

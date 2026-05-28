import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/services.dart';

// Provides the SupabaseClient instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provides the SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

// Provides the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

// Provides the CustomerService
final customerServiceProvider = Provider<CustomerService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CustomerService(client);
});

// Provides the ProductService
final productServiceProvider = Provider<ProductService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProductService(client);
});

// Provides the ServiceOrderService
final serviceOrderServiceProvider = Provider<ServiceOrderService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ServiceOrderService(client);
});

// Provides the ProfileService
final profileServiceProvider = Provider<ProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileService(client);
});

// Provides the SupplierService
final supplierServiceProvider = Provider<SupplierService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierService(client);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FinanceService(client);
});

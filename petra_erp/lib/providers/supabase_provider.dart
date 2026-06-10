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

// Provides the StockService
final stockServiceProvider = Provider<StockService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StockService(client);
});

// Provides the PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaymentService(client);
});

// Provides the CompanyService
final companyServiceProvider = Provider<CompanyService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CompanyService(client);
});

// Provides the StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

// Provides the WorkerAuthService
final workerAuthServiceProvider = Provider<WorkerAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WorkerAuthService(client);
});

// Provides the FinancialCategoryService
final financialCategoryServiceProvider = Provider<FinancialCategoryService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FinancialCategoryService(client);
});

// Provides the ExpenseService
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ExpenseService(client);
});

// Provides the SupplierService
final supplierServiceProvider = Provider<SupplierService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierService(client);
});

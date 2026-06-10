import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petra_erp/app.dart';
import 'package:petra_erp/providers/auth_provider.dart';
import 'package:petra_erp/providers/os_provider.dart';
import 'package:petra_erp/providers/supabase_provider.dart';
import 'package:petra_erp/services/auth_service.dart';
import 'package:petra_erp/services/customer_service.dart';
import 'package:petra_erp/services/product_service.dart';
import 'package:petra_erp/services/profile_service.dart';
import 'package:petra_erp/services/service_order_service.dart';
import 'package:petra_erp/services/company_service.dart';
import 'package:petra_erp/models/models.dart';

class FakeAuthService implements AuthService {
  final User? _user;
  FakeAuthService(this._user);

  @override
  User? get currentUser => _user;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResponse> signInWithSession({required String refreshToken}) async =>
      throw UnimplementedError();

  @override
  Future<void> resetPasswordForEmail(String email) async {}
}

class FakeCustomerService implements CustomerService {
  @override
  Future<List<Customer>> getCustomers({int? offset, int? limit}) async => [];
  @override
  Future<Customer> createCustomer(Customer customer) async => customer;
  @override
  Future<Customer> updateCustomer(Customer customer) async => customer;
  @override
  Future<Customer> getCustomerById(String id) async => Customer(
    id: id, name: 'Test', phone: '(11) 99999-0000', state: 'SP', createdAt: DateTime.now(),
  );
  @override
  Future<void> deleteCustomer(String id) async {}
}

class FakeProductService implements ProductService {
  @override
  Future<List<Product>> getProducts({int? offset, int? limit}) async => [];
  @override
  Future<Product> createProduct(Product product) async => product;
  @override
  Future<Product> updateProduct(Product product) async => product;
  @override
  Future<Product> getProductById(String id) async => Product(
    id: id, name: 'Test', type: 'marmore', unitPrice: 0, unit: 'm2', createdAt: DateTime.now(),
  );
  @override
  Future<void> deleteProduct(String id) async {}
}

class FakeProfileService implements ProfileService {
  @override
  Future<List<Profile>> getProfiles() async => [];
  @override
  Future<Profile> getProfileById(String id) async => Profile(
    id: id,
    email: 'test@petramarmoraria.com',
    name: 'Admin Test',
    roles: const ['admin'],
    createdAt: DateTime.now(),
  );
  @override
  Future<List<Profile>> getProfilesByRole(String role) async => [];
  @override
  Future<void> setProfileActiveStatus(String id, bool active) async {}
  @override
  Future<Profile> updateProfile(Profile profile) async => profile;
  @override
  Future<void> createEmployee({
    required String email,
    required String password,
    required String name,
    required List<String> roles,
    String? phone,
    String loginMode = 'email',
  }) async {}

  @override
  Future<void> unblockWorker(String id) async {}

  @override
  Future<void> resetWorkerPin(String id) async {}

  @override
  Future<void> resetEmployeePassword({
    required String userId,
    required String password,
  }) async {}
}

class FakeCompanyService implements CompanyService {
  @override
  Future<CompanyInfo> getCompanyInfo() async => const CompanyInfo(name: 'Petra Test');
  @override
  Future<CompanyInfo> updateCompanyInfo(CompanyInfo info) async => info;
}

class FakeServiceOrderService implements ServiceOrderService {
  @override
  Future<List<ServiceOrder>> getServiceOrders({int? offset, int? limit}) async => [];
  @override
  Stream<List<Map<String, dynamic>>> streamServiceOrders() => const Stream.empty();
  @override
  Future<ServiceOrder> createServiceOrder(ServiceOrder order) async => order;
  @override
  Future<ServiceOrder> updateServiceOrder(ServiceOrder order) async => order;
  @override
  Future<ServiceOrder> getServiceOrderById(String id) async => ServiceOrder(
    id: id,
    displayNumber: 1,
    customerId: '',
    description: 'Test',
    status: 'orcamento',
    queuePosition: 1,
    totalValue: 0,
    statusChangedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  @override
  Future<void> deleteServiceOrder(String id) async {}
  @override
  Future<List<ServiceOrder>> getDelayedOrders({int maxStaleDays = 5}) async => [];
  @override
  Future<void> moveStatus({
    required String orderId,
    required String newStatus,
    required String changedById,
    String? notes,
    String? employeeId,
  }) async {}
  @override
  Future<List<Map<String, dynamic>>> checkQueueViolations(String orderId) async => [];
  @override
  Future<List<StatusHistory>> getStatusHistory(String orderId) async => [];
  @override
  Future<List<OrderAssignment>> getAssignments(String orderId) async => [];
  @override
  Future<List<OrderAssignment>> getAllAssignments({DateTime? from, DateTime? to}) async => [];
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User? user) : super(FakeAuthService(user));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // SharedPreferences não tem implementação nativa no ambiente de teste;
    // o storage de sessão do gotrue depende dele. Mock com valores vazios.
    SharedPreferences.setMockInitialValues({});
    // Inicializa um Supabase dummy (sem conexão real) para que o
    // supabaseClientProvider possa resolver Supabase.instance.client durante o
    // smoke test. Os serviços usados pela UI são fakeados via overrides; este
    // init só satisfaz providers que tocam o cliente no boot.
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('Dashboard Kanban screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockUser = User(
      id: 'mock-user-id',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(mockUser)),
          customerServiceProvider.overrideWithValue(FakeCustomerService()),
          productServiceProvider.overrideWithValue(FakeProductService()),
          profileServiceProvider.overrideWithValue(FakeProfileService()),
          serviceOrderServiceProvider.overrideWithValue(FakeServiceOrderService()),
          companyServiceProvider.overrideWithValue(FakeCompanyService()),
          // pendingAdminActionsProvider acessa o SupabaseClient direto (sem
          // serviço fakeável) e bate na rede no boot da HomeScreen para admins.
          pendingAdminActionsProvider.overrideWith((ref) async => const []),
        ],
        child: const PetraApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Painel Kanban'), findsWidgets);
  });
}

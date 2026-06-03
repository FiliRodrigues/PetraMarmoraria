import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/screens.dart';
import 'widgets/widgets.dart';
import 'providers/auth_provider.dart';

final _publicRoutes = {
  '/entrar',
  '/login',
  '/forgot-password',
  '/funcionario',
  '/funcionario/pin',
  '/carregando',
};

bool _isPublic(String location) =>
    _publicRoutes.contains(location) || location.startsWith('/funcionario');

bool _isWorkerRoute(String location) =>
    location == '/meu-painel' || location == '/meu-painel/trocar-pin';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/entrar',
    redirect: (context, state) {
      final user = authState.value;
      final profile = profileAsync.value;
      final profileLoading = profileAsync is AsyncLoading;
      final location = state.matchedLocation;

      final onPublic = _isPublic(location);

      if (user == null) {
        return onPublic ? null : '/entrar';
      }

      if (profile == null && profileLoading) {
        if (location == '/carregando') return null;
        return '/carregando';
      }

      if (profile != null && profile.isWorker) {
        if (!_isWorkerRoute(location)) return '/meu-painel';
        return null;
      }

      if (profile != null && !profile.isWorker) {
        if (onPublic || location == '/carregando' || _isWorkerRoute(location)) {
          return '/';
        }

        if ((location.startsWith('/employees') ||
             location == '/configuracoes' ||
             location == '/financeiro') &&
            !profile.isAdmin) {
          return '/';
        }

        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/entrar',
        builder: (context, state) => const RoleGateScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final perfil = state.uri.queryParameters['perfil'] ?? 'admin';
          return LoginScreen(perfil: perfil);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/funcionario',
        builder: (context, state) => const WorkerSelectScreen(),
      ),
      GoRoute(
        path: '/funcionario/pin',
        builder: (context, state) => const WorkerPinScreen(),
      ),
      GoRoute(
        path: '/carregando',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/meu-painel',
        builder: (context, state) => const WorkerHomeScreen(),
      ),
      GoRoute(
        path: '/meu-painel/trocar-pin',
        builder: (context, state) => const ChangePinScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/kanban',
            builder: (context, state) => const KanbanScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/customers/new',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: '/customers/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerDetailScreen(id: id);
            },
          ),
          GoRoute(
            path: '/customers/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerFormScreen(id: id);
            },
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OSListScreen(),
          ),
          GoRoute(
            path: '/orders/new',
            builder: (context, state) => const OSFormScreen(),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OSDetailScreen(id: id);
            },
          ),
          GoRoute(
            path: '/orders/:id/print',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OSPrintScreen(id: id);
            },
          ),
          GoRoute(
            path: '/orders/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OSFormScreen(id: id);
            },
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeeListScreen(),
          ),
          GoRoute(
            path: '/employees/new',
            builder: (context, state) => const EmployeeFormScreen(),
          ),
          GoRoute(
            path: '/employees/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EmployeeFormScreen(id: id);
            },
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/products/new',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: '/products/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductFormScreen(id: id);
            },
          ),
          GoRoute(
            path: '/estoque',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/financeiro',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/configuracoes',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class PetraApp extends ConsumerWidget {
  const PetraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Petra ERP',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
    );
  }
}

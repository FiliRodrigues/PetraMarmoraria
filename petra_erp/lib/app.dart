import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/screens.dart';
import 'widgets/widgets.dart';
import 'providers/auth_provider.dart';

// GoRouter provider that listens to auth state changes to trigger redirects
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Treat loading as "no session yet" so router always lands somewhere.
      final user = authState.value;

      final isLoggingIn = state.matchedLocation == '/login' ||
                           state.matchedLocation == '/forgot-password';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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

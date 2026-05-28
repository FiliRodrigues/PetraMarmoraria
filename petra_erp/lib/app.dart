import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'models/profile.dart';
import 'screens/screens.dart';
import 'widgets/widgets.dart';
import 'providers/auth_provider.dart';

// Stable GoRouter that doesn't get recreated on every auth state change.
// Uses refreshListenable to re-evaluate redirects without rebuilding the router.
final _authStateListenable = ValueNotifier<AsyncValue<User?>>(const AsyncValue.loading());
final _profileListenable = ValueNotifier<Profile?>(null);

final routerProvider = Provider<GoRouter>((ref) {
  ref.listen(authProvider, (_, next) {
    _authStateListenable.value = next;
  });
  ref.listen(currentProfileProvider, (_, next) {
    _profileListenable.value = next.valueOrNull;
  });
  // Seed initial values
  _authStateListenable.value = ref.read(authProvider);
  _profileListenable.value = ref.read(currentProfileProvider).valueOrNull;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _authStateListenable,
    redirect: (context, state) {
      final authState = _authStateListenable.value;

      if (authState.isLoading) return null;

      final user = authState.value;

      final isLoggingIn = state.matchedLocation == '/login' ||
                           state.matchedLocation == '/forgot-password';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      // Employee route guard - admin only
      if (state.matchedLocation.startsWith('/employees')) {
        final profile = _profileListenable.value;
        if (profile == null || !profile.hasRole('admin')) {
          return '/';
        }
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
            builder: (context, state) => const OrderListScreen(),
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
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const ProfileEditScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SupplierListScreen(),
          ),
          GoRoute(
            path: '/suppliers/new',
            builder: (context, state) => const SupplierFormScreen(),
          ),
          GoRoute(
            path: '/suppliers/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierDetailScreen(id: id);
            },
          ),
          GoRoute(
            path: '/suppliers/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierFormScreen(id: id);
            },
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
    );
  }
}

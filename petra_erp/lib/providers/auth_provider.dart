import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'supabase_provider.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Set initial user if session exists
    final user = _authService.currentUser;
    state = AsyncValue.data(user);

    // Listen to Supabase Auth State changes in real time
    _authStateSubscription = _authService.authStateChanges.listen((event) {
      state = AsyncValue.data(event.session?.user);
    }, onError: (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

// Global Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Provides the Profile model for the currently logged-in user
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userAsync = ref.watch(authProvider);
  final user = userAsync.value;
  if (user == null) return null;
  final profileService = ref.watch(profileServiceProvider);
  return await profileService.getProfileById(user.id);
});


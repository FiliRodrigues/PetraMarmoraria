import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/services.dart';
import 'supabase_provider.dart';

class EmployeeNotifier extends StateNotifier<AsyncValue<List<Profile>>> {
  final ProfileService _service;

  EmployeeNotifier(this._service) : super(const AsyncValue.loading()) {
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      final list = await _service.getProfiles();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleActiveStatus(String id, bool active) async {
    try {
      await _service.setProfileActiveStatus(id, active);
      await loadEmployees();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEmployee(Profile profile) async {
    try {
      await _service.updateProfile(profile);
      await loadEmployees();
    } catch (e) {
      rethrow;
    }
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, AsyncValue<List<Profile>>>((ref) {
  final service = ref.watch(profileServiceProvider);
  return EmployeeNotifier(service);
});

// Fetch active employees filtered by role for assignments (e.g. cortador, montador, entregador)
final activeEmployeesByRoleProvider = FutureProvider.family<List<Profile>, String>((ref, role) async {
  final service = ref.watch(profileServiceProvider);
  return await service.getProfilesByRole(role);
});

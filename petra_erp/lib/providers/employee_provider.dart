import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/paged_notifier.dart';
import '../models/profile.dart';
import '../services/services.dart';
import 'os_provider.dart';
import 'supabase_provider.dart';

class EmployeeNotifier extends StateNotifier<AsyncValue<List<Profile>>> {
  final ProfileService _service;
  final Ref _ref;
  StreamSubscription<List<Profile>>? _streamSubscription;

  EmployeeNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadEmployees();
    _listenToStream();
  }

  Future<void> loadEmployees() async {
    try {
      final list = await _service.getProfiles();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToStream() {
    _streamSubscription = _service.streamProfiles().listen((profiles) async {
      await loadEmployees();
      _ref.invalidate(osProvider);
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });
  }

  Future<void> toggleActiveStatus(String id, bool active) async {
    try {
      await _service.setProfileActiveStatus(id, active);
      await loadEmployees();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createEmployee({
    required String name,
    required List<String> roles,
    String? phone,
  }) async {
    try {
      await _service.createProfile(name: name, roles: roles, phone: phone);
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

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, AsyncValue<List<Profile>>>((ref) {
  final service = ref.watch(profileServiceProvider);
  return EmployeeNotifier(service, ref);
});

final activeEmployeesByRoleProvider = FutureProvider.family<List<Profile>, String>((ref, role) async {
  final service = ref.watch(profileServiceProvider);
  return await service.getProfilesByRole(role);
});

class EmployeePagedNotifier extends PagedNotifier<Profile> {
  final ProfileService _service;
  EmployeePagedNotifier(this._service) {
    refresh();
  }

  @override
  Future<List<Profile>> fetchPage({required int offset, required int pageSize, String? search}) =>
      _service.getProfilesPaged(offset: offset, pageSize: pageSize, search: search);
}

final employeePagedProvider = StateNotifierProvider<EmployeePagedNotifier, PagedState<Profile>>((ref) {
  return EmployeePagedNotifier(ref.watch(profileServiceProvider));
});

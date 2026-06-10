import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  Future<List<Profile>> getProfiles() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('name', ascending: true);
      return (response as List).map((e) => Profile.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Profile>> getProfilesByRole(String role) async {
    try {
      // `roles` is a text[] column, so match profiles whose array contains the role.
      final response = await _client
          .from('profiles')
          .select()
          .contains('roles', [role])
          .eq('active', true)
          .order('name', ascending: true);
      return (response as List).map((e) => Profile.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Profile> getProfileById(String id) async {
    try {
      final response = await _client.from('profiles').select().eq('id', id).single();
      return Profile.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    try {
      // login_mode/blocked/pin_set têm RPCs dedicados (unblockWorker,
      // resetWorkerPin) — a edição comum não deve tocá-los.
      final data = profile.toMap()
        ..remove('created_at')
        ..remove('email')
        ..remove('login_mode')
        ..remove('blocked')
        ..remove('pin_set');
      final response = await _client
          .from('profiles')
          .update(data)
          .eq('id', profile.id)
          .select()
          .single();
      return Profile.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setProfileActiveStatus(String id, bool active) async {
    try {
      await _client.from('profiles').update({'active': active}).eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createEmployee({
    required String email,
    required String password,
    required String name,
    required List<String> roles,
    String? phone,
    String loginMode = 'email',
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
      'roles': roles,
      'phone': phone,
    };
    if (loginMode != 'email') {
      body['login_mode'] = loginMode;
    }
    final res = await _client.functions.invoke('create-employee', body: body);
    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map ? data['error'] as String? : null;
      throw Exception(msg ?? 'Falha ao criar funcionário');
    }
  }

  Future<void> resetEmployeePassword({
    required String userId,
    required String password,
  }) async {
    final res = await _client.functions.invoke(
      'admin-reset-password',
      body: {'user_id': userId, 'password': password},
    );
    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map ? (data['error'] as String?) : null;
      throw Exception(msg ?? 'Falha ao redefinir senha (status ${res.status})');
    }
  }

  Future<void> unblockWorker(String id) async {
    await _client.from('profiles').update({
      'failed_attempts': 0,
      'blocked': false,
    }).eq('id', id);
  }

  Future<void> resetWorkerPin(String id) async {
    await _client.from('profiles').update({
      'pin_set': false,
      'pin_hash': null,
    }).eq('id', id);
  }
}

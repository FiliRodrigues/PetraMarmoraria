import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
      throw Exception('Falha ao buscar funcionários: ${e.toString()}');
    }
  }

  Future<List<Profile>> getProfilesByRole(String role) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .contains('roles', [role])
          .eq('active', true)
          .order('name', ascending: true);
      return (response as List).map((e) => Profile.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar funcionários por cargo: ${e.toString()}');
    }
  }

  Future<Profile> getProfileById(String id) async {
    try {
      final response = await _client.from('profiles').select().eq('id', id).single();
      return Profile.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao buscar perfil: ${e.toString()}');
    }
  }

  Future<Profile> createProfile({
    required String name,
    required List<String> roles,
    String? phone,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final data = {
        'id': id,
        'name': name,
        'roles': roles,
        'phone': phone,
        'active': true,
        'created_at': now,
      };
      final response = await _client.from('profiles').insert(data).select().single();
      return Profile.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao criar funcionário: ${e.toString()}');
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    try {
      final data = profile.toMap()..remove('created_at')..remove('email');
      final response = await _client
          .from('profiles')
          .update(data)
          .eq('id', profile.id)
          .select()
          .single();
      return Profile.fromMap(response);
    } catch (e) {
      throw Exception('Falha ao atualizar funcionário: ${e.toString()}');
    }
  }

  Future<void> setProfileActiveStatus(String id, bool active) async {
    try {
      await _client.from('profiles').update({'active': active}).eq('id', id);
    } catch (e) {
      throw Exception('Falha ao alterar status do funcionário: ${e.toString()}');
    }
  }
}

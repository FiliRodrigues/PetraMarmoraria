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
      throw Exception('Falha ao buscar funcionários: ${e.toString()}');
    }
  }

  Future<List<Profile>> getProfilesByRole(String role) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', role)
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

  Future<Map<String, dynamic>> createProfile({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _client.functions.invoke('create-employee', body: {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      return response.data as Map<String, dynamic>;
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

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
          .limit(500)
          .order('name', ascending: true);
      return (response as List).map((e) => Profile.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar funcionários: ${e.toString()}');
    }
  }

  Future<List<Profile>> getProfilesByRole(String role) async {
    try {
      final response = await _client.rpc('get_profiles_by_role', params: {
        'p_role': role,
      });
      return (response as List).map((e) => Profile.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar funcionários por cargo: ${e.toString()}');
    }
  }

  Future<List<Profile>> getProfilesPaged({
    required int offset,
    int pageSize = 30,
    String? search,
  }) async {
    try {
      var query = _client.from('profiles').select();
      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,email.ilike.%$search%');
      }
      final response = await query
          .order('name', ascending: true)
          .range(offset, offset + pageSize - 1);
      return (response as List).map((e) => Profile.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar funcionários: ${e.toString()}');
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
      final id = await _client.rpc('admin_create_employee', params: {
        'p_name': name,
        'p_roles': roles,
        'p_phone': phone,
      });
      return await getProfileById(id as String);
    } catch (e) {
      throw Exception('Falha ao criar funcionário: ${e.toString()}');
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    try {
      await _client.rpc('admin_update_employee', params: {
        'p_id': profile.id,
        'p_name': profile.name,
        'p_roles': profile.roles,
        'p_phone': profile.phone,
        'p_active': profile.active,
      });
      return profile;
    } catch (e) {
      throw Exception('Falha ao atualizar funcionário: ${e.toString()}');
    }
  }

  Stream<List<Profile>> streamProfiles() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((events) => events.map((e) => Profile.fromMap(e)).toList());
  }

  Future<void> setProfileActiveStatus(String id, bool active) async {
    try {
      await _client.rpc('admin_set_profile_active_status', params: {
        'p_id': id,
        'p_active': active,
      });
    } catch (e) {
      throw Exception('Falha ao alterar status do funcionário: ${e.toString()}');
    }
  }
}

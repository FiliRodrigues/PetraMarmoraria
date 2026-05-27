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
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', role)
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
      final data = profile.toMap()..remove('created_at')..remove('email');
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
}

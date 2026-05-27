import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  // General check helper
  bool get isAuthenticated => client.auth.currentSession != null;
}

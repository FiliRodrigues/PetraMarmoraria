import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class PinWorker {
  final String id;
  final String name;
  final List<String> roles;
  final bool blocked;
  final bool pinSet;

  const PinWorker({
    required this.id,
    required this.name,
    required this.roles,
    this.blocked = false,
    this.pinSet = false,
  });

  factory PinWorker.fromMap(Map<String, dynamic> map) {
    final raw = map['roles'];
    final roles = raw is List
        ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return PinWorker(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      roles: roles,
      blocked: map['blocked'] as bool? ?? false,
      pinSet: map['pin_set'] as bool? ?? false,
    );
  }
}

class WorkerAuthService {
  final SupabaseClient _client;

  WorkerAuthService(this._client);

  Future<List<PinWorker>> listWorkers() async {
    final res = await _client.functions.invoke('worker-pin-login', body: {
      'action': 'list',
    });

    if (res.status != 200) {
      throw Exception('Falha ao carregar funcionários.');
    }

    final data = res.data;
    final workers = data is Map ? data['workers'] as List? : null;
    if (workers == null) return [];

    return workers.map((e) => PinWorker.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> setPin(String workerId, String pin) async {
    final res = await _client.functions.invoke('worker-pin-login', body: {
      'action': 'set',
      'worker_id': workerId,
      'pin': pin,
    });

    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map ? data['error'] as String? : null;
      throw Exception(msg ?? 'Falha ao definir PIN.');
    }

    final data = res.data;
    final session = data is Map ? data['session'] as Map<String, dynamic>? : null;
    if (session != null) {
      await _client.auth.setSession(session['refresh_token'] as String);
    }

    return {'ok': true};
  }

  Future<({String? code, int? remaining})> verifyPin(String workerId, String pin) async {
    final res = await _client.functions.invoke('worker-pin-login', body: {
      'action': 'verify',
      'worker_id': workerId,
      'pin': pin,
    });

    if (res.status == 403) {
      return (code: 'blocked', remaining: null);
    }

    if (res.status == 409) {
      return (code: 'not_set', remaining: null);
    }

    if (res.status == 401) {
      final data = res.data;
      final remaining = data is Map ? data['remaining'] as int? : null;
      return (code: 'wrong_pin', remaining: remaining);
    }

    if (res.status != 200) {
      final errorData = res.data;
      final msg = errorData is Map ? errorData['error'] as String? : null;
      throw Exception(msg ?? 'Falha ao verificar o PIN.');
    }

    final resultData = res.data;
    final session = resultData is Map ? resultData['session'] as Map<String, dynamic>? : null;
    if (session != null) {
      await _client.auth.setSession(session['refresh_token'] as String);
    }

    return (code: null, remaining: null);
  }

  Future<void> changePin(String currentPin, String newPin) async {
    final res = await _client.functions.invoke('worker-pin-login', body: {
      'action': 'change',
      'current_pin': currentPin,
      'new_pin': newPin,
    });

    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map ? data['error'] as String? : null;
      throw Exception(msg ?? 'Falha ao trocar PIN.');
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef BiometricCredentials = ({String email, String password});

/// Atalho de login por biometria, ativado por aparelho (Android/iOS).
///
/// As credenciais ficam no cofre do SO (Keystore/Keychain) e só são lidas
/// após autenticação biométrica. A autenticação real continua via Supabase.
class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
  })  : _auth = localAuth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _kEmail = 'biometric_email';
  static const _kPassword = 'biometric_password';

  bool get _platformSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Plataforma suportada e há biometria cadastrada no aparelho.
  Future<bool> isAvailable() async {
    if (!_platformSupported) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck && !supported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Existe credencial salva para este aparelho.
  Future<bool> isEnabled() async {
    if (!_platformSupported) return false;
    final email = await _storage.read(key: _kEmail);
    final password = await _storage.read(key: _kPassword);
    return email != null && password != null;
  }

  Future<void> enable(String email, String password) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
  }

  Future<void> disable() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
  }

  /// Pede a biometria; se confirmada, devolve as credenciais salvas.
  Future<BiometricCredentials?> authenticateAndGetCredentials() async {
    if (!await isEnabled()) return null;
    final ok = await _auth.authenticate(
      localizedReason: 'Confirme sua identidade para entrar',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    if (!ok) return null;
    final email = await _storage.read(key: _kEmail);
    final password = await _storage.read(key: _kPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }
}

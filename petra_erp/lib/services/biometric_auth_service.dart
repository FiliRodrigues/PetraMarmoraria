import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef BiometricSession = ({String accessToken, String refreshToken});

/// Atalho de login por biometria, ativado por aparelho (Android/iOS).
///
/// Os tokens de sessão ficam no cofre do SO (Keystore/Keychain) e só são lidos
/// após autenticação biométrica. A sessão é restaurada via Supabase setSession,
/// que faz refresh automático se o access token estiver expirado.
/// Diferente de guardar a senha, o refresh_token pode ser revogado remotamente.
class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
  })  : _auth = localAuth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'biometric_access_token';
  static const _kRefreshToken = 'biometric_refresh_token';

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

  /// Existe sessão salva para este aparelho.
  Future<bool> isEnabled() async {
    if (!_platformSupported) return false;
    final refreshToken = await _storage.read(key: _kRefreshToken);
    return refreshToken != null;
  }

  Future<void> saveSession(String accessToken, String refreshToken) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<void> disable() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  /// Pede a biometria; se confirmada, devolve os tokens da sessão salva.
  Future<BiometricSession?> authenticateAndGetSession() async {
    if (!await isEnabled()) return null;
    final ok = await _auth.authenticate(
      localizedReason: 'Confirme sua identidade para entrar',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    if (!ok) return null;
    final accessToken = await _storage.read(key: _kAccessToken);
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null) return null;
    return (accessToken: accessToken ?? '', refreshToken: refreshToken);
  }
}

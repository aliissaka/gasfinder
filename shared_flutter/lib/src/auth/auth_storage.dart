import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/models/auth_response.dart';

/// Persists the most recent successful AuthResponse to Android Keystore (or
/// equivalent secure storage on other platforms). Clear-text PINs are never
/// stored — only the bearer token plus the basic user metadata.
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _key = 'gasfinder.auth.v1';

  final FlutterSecureStorage _storage;

  Future<void> save(AuthResponse auth) async {
    final payload = jsonEncode({
      'accessToken': auth.accessToken,
      'expiresAt': auth.expiresAt.toIso8601String(),
      'userId': auth.userId,
      'role': auth.role,
      'retailerId': auth.retailerId,
      'retailerStatus': auth.retailerStatus,
    });
    await _storage.write(key: _key, value: payload);
  }

  Future<AuthResponse?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final auth = AuthResponse.fromJson(map);
      if (auth.expiresAt.isBefore(DateTime.now().toUtc())) return null;
      return auth;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}

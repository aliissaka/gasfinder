import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/models/auth_response.dart';
import 'auth_storage.dart';

/// Observable wrapper around the currently logged-in user. Pushes its
/// bearer token into the supplied [ApiClient] so downstream API calls are
/// automatically authenticated.
class AuthSession extends ChangeNotifier {
  AuthSession({required ApiClient apiClient, required AuthStorage storage})
      : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final AuthStorage _storage;

  AuthResponse? _current;
  AuthResponse? get current => _current;
  bool get isAuthenticated => _current != null;

  /// Hydrate session from secure storage on app start.
  Future<void> restore() async {
    final saved = await _storage.load();
    if (saved != null) {
      _apply(saved, persist: false);
    }
  }

  Future<void> setAuth(AuthResponse auth) async {
    _apply(auth, persist: true);
  }

  Future<void> signOut() async {
    _current = null;
    _apiClient.bearerToken = null;
    await _storage.clear();
    notifyListeners();
  }

  void _apply(AuthResponse auth, {required bool persist}) {
    _current = auth;
    _apiClient.bearerToken = auth.accessToken;
    notifyListeners();
    if (persist) {
      // Fire-and-forget; UI doesn't need to wait for disk.
      _storage.save(auth);
    }
  }
}

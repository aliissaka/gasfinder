import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'models/auth_response.dart';
import 'models/login_request.dart';
import 'models/register_retailer_request.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<AuthResponse> registerRetailer(RegisterRetailerRequest req) async {
    try {
      final r = await _client.dio.post<Map<String, dynamic>>(
        '/api/auth/register-retailer',
        data: req.toJson(),
      );
      return AuthResponse.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<AuthResponse> login(LoginRequest req) async {
    try {
      final r = await _client.dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: req.toJson(),
      );
      return AuthResponse.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

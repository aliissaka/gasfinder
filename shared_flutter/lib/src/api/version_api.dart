import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'models/app_version_response.dart';

class VersionApi {
  VersionApi(this._client);
  final ApiClient _client;

  /// Fetches the version policy for the given app ('user' or 'retailer').
  /// Returns null on 404 (unknown app) so callers can no-op gracefully.
  Future<AppVersionResponse?> getPolicy(String app) async {
    try {
      final r = await _client.dio.get<Map<String, dynamic>>('/api/version/$app');
      return AppVersionResponse.fromJson(r.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e);
    }
  }
}

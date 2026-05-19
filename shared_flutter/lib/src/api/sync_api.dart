import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'models/brand_sync_response.dart';
import 'models/retailer_sync_response.dart';

/// Wraps the backend delta-sync endpoints. The server is the source of truth
/// for the cursor; clients store it opaquely and pass it back next time.
class SyncApi {
  SyncApi(this._client);
  final ApiClient _client;

  Future<BrandSyncResponse> brands({String? cursor}) async {
    try {
      final r = await _client.dio.get<Map<String, dynamic>>(
        '/api/sync/brands',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      return BrandSyncResponse.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<RetailerSyncResponse> retailers({
    required double lat,
    required double lon,
    int? radiusMeters,
    String? cursor,
  }) async {
    try {
      final r = await _client.dio.get<Map<String, dynamic>>(
        '/api/sync/retailers',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          if (radiusMeters != null) 'radiusMeters': radiusMeters,
          if (cursor != null) 'cursor': cursor,
        },
      );
      return RetailerSyncResponse.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

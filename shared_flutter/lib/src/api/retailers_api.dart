import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'models/retailer_detail.dart';
import 'models/retailer_list_item.dart';

class RetailersApi {
  RetailersApi(this._client);
  final ApiClient _client;

  Future<List<RetailerListItem>> list({
    required double lat,
    required double lon,
    int? radiusMeters,
    List<String>? brandIds,
    int? take,
  }) async {
    try {
      final r = await _client.dio.get<List<dynamic>>(
        '/api/retailers',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          if (radiusMeters != null) 'radiusMeters': radiusMeters,
          if (brandIds != null && brandIds.isNotEmpty) 'brandIds': brandIds.join(','),
          if (take != null) 'take': take,
        },
      );
      return (r.data ?? const [])
          .map((e) => RetailerListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<RetailerDetail> get(String id) async {
    try {
      final r = await _client.dio.get<Map<String, dynamic>>('/api/retailers/$id');
      return RetailerDetail.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

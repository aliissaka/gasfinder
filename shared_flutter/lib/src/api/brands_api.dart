import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'models/brand_dto.dart';

class BrandsApi {
  BrandsApi(this._client);
  final ApiClient _client;

  Future<List<BrandDto>> list() async {
    try {
      final r = await _client.dio.get<List<dynamic>>('/api/brands');
      return (r.data ?? const [])
          .map((e) => BrandDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

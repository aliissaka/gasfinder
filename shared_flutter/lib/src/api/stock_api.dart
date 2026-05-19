import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'models/stock_item_dto.dart';
import 'models/stock_update_batch_request.dart';
import 'models/stock_update_batch_response.dart';

class StockApi {
  StockApi(this._client);
  final ApiClient _client;

  Future<List<StockItemDto>> getMine() async {
    try {
      final r = await _client.dio.get<List<dynamic>>('/api/stock/me');
      return (r.data ?? const [])
          .map((e) => StockItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<StockUpdateBatchResponse> submit(StockUpdateBatchRequest body) async {
    try {
      final r = await _client.dio.post<Map<String, dynamic>>(
        '/api/stock/updates',
        data: body.toJson(),
      );
      return StockUpdateBatchResponse.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

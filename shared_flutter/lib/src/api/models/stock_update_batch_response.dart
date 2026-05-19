import 'stock_update_result.dart';

class StockUpdateBatchResponse {
  StockUpdateBatchResponse(this.results);
  final List<StockUpdateResult> results;

  factory StockUpdateBatchResponse.fromJson(Map<String, dynamic> json) => StockUpdateBatchResponse(
        (json['results'] as List)
            .map((e) => StockUpdateResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

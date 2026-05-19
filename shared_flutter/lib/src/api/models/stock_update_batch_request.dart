import 'stock_update_request.dart';

class StockUpdateBatchRequest {
  StockUpdateBatchRequest(this.updates);
  final List<StockUpdateRequest> updates;

  Map<String, dynamic> toJson() => {'updates': updates.map((u) => u.toJson()).toList()};
}

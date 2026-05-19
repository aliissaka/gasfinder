class StockUpdateRequest {
  StockUpdateRequest({
    required this.clientOutboxId,
    required this.brandId,
    required this.status,
    this.quantity,
    required this.reportedAt,
  });

  final String clientOutboxId;
  final String brandId;
  final String status;
  final int? quantity;
  final DateTime reportedAt;

  Map<String, dynamic> toJson() => {
        'clientOutboxId': clientOutboxId,
        'brandId': brandId,
        'status': status,
        'quantity': quantity,
        'reportedAt': reportedAt.toUtc().toIso8601String(),
      };

  factory StockUpdateRequest.fromJson(Map<String, dynamic> json) => StockUpdateRequest(
        clientOutboxId: json['clientOutboxId'] as String,
        brandId: json['brandId'] as String,
        status: json['status'] as String,
        quantity: (json['quantity'] as num?)?.toInt(),
        reportedAt: DateTime.parse(json['reportedAt'] as String),
      );
}

class StockItemDto {
  StockItemDto({
    required this.brandId,
    required this.brandName,
    required this.logoUrl,
    required this.status,
    this.quantity,
    required this.lastUpdatedAt,
  });

  final String brandId;
  final String brandName;
  final String logoUrl;
  final String status;
  final int? quantity;
  final DateTime lastUpdatedAt;

  factory StockItemDto.fromJson(Map<String, dynamic> json) => StockItemDto(
        brandId: json['brandId'] as String,
        brandName: json['brandName'] as String,
        logoUrl: json['logoUrl'] as String,
        status: json['status'] as String,
        quantity: (json['quantity'] as num?)?.toInt(),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

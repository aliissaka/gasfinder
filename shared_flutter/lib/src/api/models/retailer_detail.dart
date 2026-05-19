import 'stock_item_dto.dart';

class RetailerDetail {
  RetailerDetail({
    required this.id,
    required this.shopName,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.address,
    this.photoUrl,
    required this.openingHours,
    required this.updatedAt,
    required this.stock,
  });

  final String id;
  final String shopName;
  final double latitude;
  final double longitude;
  final String phone;
  final String? address;
  final String? photoUrl;
  final String openingHours;
  final DateTime updatedAt;
  final List<StockItemDto> stock;

  factory RetailerDetail.fromJson(Map<String, dynamic> json) => RetailerDetail(
        id: json['id'] as String,
        shopName: json['shopName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String,
        address: json['address'] as String?,
        photoUrl: json['photoUrl'] as String?,
        openingHours: json['openingHours'] as String? ?? '{}',
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        stock: ((json['stock'] as List?) ?? const [])
            .map((e) => StockItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RetailerListItem {
  RetailerListItem({
    required this.id,
    required this.shopName,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.photoUrl,
    required this.updatedAt,
    required this.availableBrandIds,
  });

  final String id;
  final String shopName;
  final double latitude;
  final double longitude;
  final String phone;
  final String? photoUrl;
  final DateTime updatedAt;
  final List<String> availableBrandIds;

  factory RetailerListItem.fromJson(Map<String, dynamic> json) => RetailerListItem(
        id: json['id'] as String,
        shopName: json['shopName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String,
        photoUrl: json['photoUrl'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        availableBrandIds: ((json['availableBrandIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

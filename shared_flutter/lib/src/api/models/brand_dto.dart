class BrandDto {
  BrandDto({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.displayOrder,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String logoUrl;
  final int displayOrder;
  final DateTime updatedAt;

  factory BrandDto.fromJson(Map<String, dynamic> json) => BrandDto(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logoUrl'] as String,
        displayOrder: (json['displayOrder'] as num).toInt(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

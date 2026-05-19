import 'brand_dto.dart';

class BrandSyncResponse {
  BrandSyncResponse({required this.cursor, required this.changes, required this.deletes});

  final String cursor;
  final List<BrandDto> changes;
  final List<String> deletes;

  factory BrandSyncResponse.fromJson(Map<String, dynamic> json) => BrandSyncResponse(
        cursor: json['cursor'] as String,
        changes: ((json['changes'] as List?) ?? const [])
            .map((e) => BrandDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        deletes: ((json['deletes'] as List?) ?? const []).map((e) => e as String).toList(),
      );
}

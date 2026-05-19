import 'retailer_list_item.dart';

class RetailerSyncResponse {
  RetailerSyncResponse({required this.cursor, required this.changes, required this.deletes});

  final String cursor;
  final List<RetailerListItem> changes;
  final List<String> deletes;

  factory RetailerSyncResponse.fromJson(Map<String, dynamic> json) => RetailerSyncResponse(
        cursor: json['cursor'] as String,
        changes: ((json['changes'] as List?) ?? const [])
            .map((e) => RetailerListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        deletes: ((json['deletes'] as List?) ?? const []).map((e) => e as String).toList(),
      );
}

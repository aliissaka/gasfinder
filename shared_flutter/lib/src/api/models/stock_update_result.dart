class StockUpdateResult {
  StockUpdateResult({required this.clientOutboxId, required this.outcome, this.message});

  final String clientOutboxId;
  final String outcome;
  final String? message;

  factory StockUpdateResult.fromJson(Map<String, dynamic> json) => StockUpdateResult(
        clientOutboxId: json['clientOutboxId'] as String,
        outcome: json['outcome'] as String,
        message: json['message'] as String?,
      );

  bool get isAccepted => outcome == 'accepted';
  bool get isDuplicate => outcome == 'duplicate';
  bool get isRejected => outcome == 'rejected';

  /// An outbox row can be cleared from the queue on accepted OR duplicate (the
  /// server already has the update — duplicate just confirms it).
  bool get clearable => isAccepted || isDuplicate;
}

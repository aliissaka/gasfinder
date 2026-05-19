class AuthResponse {
  AuthResponse({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
    required this.role,
    this.retailerId,
    this.retailerStatus,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String userId;
  final String role;
  final String? retailerId;
  final String? retailerStatus;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        userId: json['userId'] as String,
        role: json['role'] as String,
        retailerId: json['retailerId'] as String?,
        retailerStatus: json['retailerStatus'] as String?,
      );
}

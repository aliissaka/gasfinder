class AppVersionResponse {
  AppVersionResponse({
    required this.app,
    required this.minimumVersion,
    required this.recommendedVersion,
    required this.critical,
    this.playStoreUrl,
    this.message,
  });

  final String app;
  final int minimumVersion;
  final int recommendedVersion;
  final bool critical;
  final String? playStoreUrl;
  final String? message;

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) => AppVersionResponse(
        app: json['app'] as String,
        minimumVersion: (json['minimumVersion'] as num).toInt(),
        recommendedVersion: (json['recommendedVersion'] as num).toInt(),
        critical: json['critical'] as bool? ?? false,
        playStoreUrl: json['playStoreUrl'] as String?,
        message: json['message'] as String?,
      );

  /// True when the current client version is below the minimum and must be upgraded.
  bool isBelowMinimum(int currentVersion) => currentVersion < minimumVersion;

  /// True when the current client version is below the recommended (soft prompt).
  bool isBelowRecommended(int currentVersion) => currentVersion < recommendedVersion;
}

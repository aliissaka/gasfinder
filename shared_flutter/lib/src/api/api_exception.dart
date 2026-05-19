import 'package:dio/dio.dart';

/// Thin wrapper around DioException with the server-supplied `code` (when present)
/// surfaced as a field. Clients can branch on `code` for things like
/// `invalid_credentials`, `phone_already_registered`, etc.
class ApiException implements Exception {
  ApiException({required this.statusCode, required this.code, required this.message, this.cause});

  final int? statusCode;
  final String? code;
  final String message;
  final Object? cause;

  factory ApiException.from(DioException e) {
    final resp = e.response;
    String? code;
    String message = e.message ?? 'Network error';
    if (resp?.data is Map) {
      final m = resp!.data as Map;
      code = (m['code'] ?? m['error'])?.toString();
      if (m['message'] is String) message = m['message'] as String;
    }
    return ApiException(statusCode: resp?.statusCode, code: code, message: message, cause: e);
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

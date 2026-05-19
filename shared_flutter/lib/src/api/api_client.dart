import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'models/app_version_response.dart';

/// Wraps Dio with the conventions every Gas Finder client needs:
/// gzip, JSON, a configurable bearer token, app-version headers, 426 handling,
/// and 3 retries on transient errors.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.appName,
    required this.appVersionCode,
    this.bearerToken,
    this.onUpgradeRequired,
    Duration timeout = const Duration(seconds: 20),
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          headers: {'Accept': 'application/json', 'Accept-Encoding': 'gzip, br'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-App-Name'] = appName;
        options.headers['X-App-Version'] = appVersionCode.toString();
        final token = bearerToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 426 && onUpgradeRequired != null) {
          try {
            final data = e.response!.data;
            if (data is Map<String, dynamic>) {
              onUpgradeRequired!(AppVersionResponse.fromJson(data));
            }
          } catch (_) {
            // Swallow parse errors — caller will see the original exception below.
          }
        }
        return handler.next(e);
      },
    ));
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      retries: 3,
      retryDelays: const [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4)],
      retryEvaluator: (error, attempt) {
        // Do not retry 426 — let the client trigger an upgrade flow.
        if (error.response?.statusCode == 426) return false;
        return DefaultRetryEvaluator(defaultRetryableStatuses).evaluate(error, attempt);
      },
    ));
  }

  final Dio _dio;

  /// Logical app name sent as X-App-Name. Use 'user' or 'retailer'.
  final String appName;

  /// Integer version code (Android versionCode) sent as X-App-Version.
  final int appVersionCode;

  String? bearerToken;
  final void Function(AppVersionResponse policy)? onUpgradeRequired;

  Dio get dio => _dio;
}

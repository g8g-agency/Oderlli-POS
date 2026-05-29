import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_config.dart';
import 'device_fingerprint_service.dart';
import 'secure_storage_service.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService _secureStorage;
  final DeviceFingerprintService _fingerprintService;

  // Stream controller to notify when a session has expired (refresh failed)
  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  // Single-flight refresh locks
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  DioClient(
    this._secureStorage,
    this._fingerprintService,
  ) : dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _initInterceptors();
  }

  void _initInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inject Fingerprint header
          final fingerprint = await _fingerprintService.getOrCreateFingerprint();
          options.headers['X-Device-Fingerprint'] = fingerprint;

          // Inject Access Token header (if available)
          final credentials = await _secureStorage.getCredentials();
          final accessToken = credentials['accessToken'];
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          if (kDebugMode) {
            debugPrint('--> [DIO REQUEST] ${options.method} ${options.uri}');
            debugPrint('Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('<-- [DIO RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (kDebugMode) {
            debugPrint('[DIO ERROR] ${error.response?.statusCode} ${error.requestOptions.uri}');
            debugPrint('Message: ${error.message}');
            debugPrint('Response: ${error.response?.data}');
          }

          // If the request was unauthorized, attempt token refresh
          if (error.response?.statusCode == 401) {
            // Avoid infinite loops if refreshing fails
            if (error.requestOptions.path.contains('/auth/refresh') ||
                error.requestOptions.path.contains('/auth/login')) {
              return handler.next(error);
            }

            final credentials = await _secureStorage.getCredentials();
            final refreshToken = credentials['refreshToken'];
            final deviceSessionId = credentials['deviceSessionId'];

            if (refreshToken == null || deviceSessionId == null) {
              _triggerSessionExpired();
              return handler.next(error);
            }

            try {
              String? newAccessToken;

              if (_isRefreshing) {
                // Another request is already refreshing. Wait for it to complete.
                newAccessToken = await _refreshCompleter?.future;
              } else {
                _isRefreshing = true;
                _refreshCompleter = Completer<String?>();

                // Trigger token refresh call
                newAccessToken = await _performRefresh(refreshToken, deviceSessionId);

                _refreshCompleter?.complete(newAccessToken);
                _isRefreshing = false;
                _refreshCompleter = null;
              }

              if (newAccessToken != null) {
                // Retry the original request with the new access token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final response = await dio.fetch(options);
                return handler.resolve(response);
              }
            } catch (refreshError) {
              _isRefreshing = false;
              _refreshCompleter = null;
              _triggerSessionExpired();
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _performRefresh(String refreshToken, String deviceSessionId) async {
    try {
      final fingerprint = await _fingerprintService.getOrCreateFingerprint();
      
      // Use clean options to avoid interceptor recursion
      final refreshResponse = await Dio(BaseOptions(baseUrl: AppConfig.baseUrl)).post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
          'device_fingerprint': fingerprint,
        },
        options: Options(
          headers: {
            'X-Device-Fingerprint': fingerprint,
            'X-Device-Session-Id': deviceSessionId,
          },
        ),
      );

      if (refreshResponse.statusCode == 200) {
        final data = refreshResponse.data;
        if (data != null && data['success'] == true) {
          final resData = data['data'];
          final newAccessToken = resData['access_token'] as String;
          final newRefreshToken = resData['refresh_token'] as String;
          final newDeviceSessionId = resData['device_session_id'] as String;

          await _secureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            deviceSessionId: newDeviceSessionId,
          );

          return newAccessToken;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DioClient] Refresh token request failed: $e');
      }
      rethrow;
    }
    return null;
  }

  void _triggerSessionExpired() {
    _secureStorage.clearSession();
    _sessionExpiredController.add(null);
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}

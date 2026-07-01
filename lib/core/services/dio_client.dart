import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../constants/app_config.dart';
import 'device_fingerprint_service.dart';
import 'secure_storage_service.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService _secureStorage;
  final DeviceFingerprintService _fingerprintService;
  final Ref? _ref;

  // Stream controller to notify when a session has expired (refresh failed)
  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  // Single-flight refresh locks
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  DioClient(
    this._secureStorage,
    this._fingerprintService, [
    this._ref,
  ]) : dio = Dio(BaseOptions(
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
          // Prevent duplicate /api/v1 when combined with baseUrl ending in /api/v1
          if (options.path.startsWith('/api/v1') &&
              (options.baseUrl.endsWith('/api/v1') || options.baseUrl.endsWith('/api/v1/'))) {
            options.path = options.path.substring(7);
          }

          // Inject Fingerprint header
          final fingerprint = await _fingerprintService.getOrCreateFingerprint();
          options.headers['X-Device-Fingerprint'] = fingerprint;

          // Inject tenant id if present in auth state and not already set
          if (_ref != null) {
            final authState = _ref.read(authProvider);
            if (authState.tenantId != null && !options.headers.containsKey('x-tenant-id')) {
              options.headers['x-tenant-id'] = authState.tenantId;
            }
          }

          // Inject Access/Runtime Token header (if not already set manually)
          if (!options.headers.containsKey('Authorization')) {
            final staffToken = await _secureStorage.getRuntimeToken();
            if (staffToken != null && staffToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $staffToken';
              debugPrint('[AUTH] STAFF RUNTIME HEADER ADDED: Bearer $staffToken');
            } else {
              final credentials = await _secureStorage.getCredentials();
              final accessToken = credentials['accessToken'];
              if (accessToken != null && accessToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $accessToken';
                debugPrint('[AUTH] OWNER AUTHORIZATION HEADER ADDED: Bearer $accessToken');
              } else {
                debugPrint('[AUTH] AUTHORIZATION HEADER NOT ADDED (token is null/empty)');
              }
            }
          } else {
            debugPrint('[AUTH] AUTHORIZATION HEADER PRESERVED: ${options.headers['Authorization']}');
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
            final path = error.requestOptions.path;

            // These endpoints return 401 for wrong credentials — that is
            // expected, not a session expiry. Pass through untouched.
            final isAuthEndpoint =
                path.contains('/auth/staff') ||
                path.contains('/auth/login') ||
                path.contains('/auth/pin');

            if (isAuthEndpoint) {
              return handler.next(error); // let it bubble as DioException
            }

            // Avoid infinite loops if refreshing fails
            if (path.contains('/auth/refresh') ||
                path.contains('/auth/login')) {
              return handler.next(error);
            }

            final credentials = await _secureStorage.getCredentials();
            final refreshToken = credentials['refreshToken'];
            final deviceSessionId = credentials['deviceSessionId'];

            if (refreshToken == null || refreshToken.trim().isEmpty) {
              _triggerSessionExpired();
              return handler.next(error);
            }

            if (deviceSessionId == null) {
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
          
          final newAccessToken = resData?['access_token'] as String?;
          final newRefreshToken = resData?['refresh_token'] as String?;
          final newDeviceSessionId = resData?['device_session_id'] as String?;

          if (newAccessToken == null || newRefreshToken == null || newDeviceSessionId == null) {
            throw Exception('Token response contains null values');
          }

          await _secureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            deviceSessionId: newDeviceSessionId,
          );

          return newAccessToken;
        }
      }
      throw Exception('Token refresh response status code was not 200 or success flag was false');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DioClient] Refresh token request failed: $e');
      }
      _triggerSessionExpired();
      return null;
    }
  }

  void _triggerSessionExpired() {
    _secureStorage.clearSession();
    _sessionExpiredController.add(null);
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}

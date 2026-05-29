import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String devUrl = 'http://192.168.1.50:3001/api/v1';
  static const String prodUrl = 'https://api.orderlli.com/api/v1';
  static const String healthEndpoint = '/health';

  static String get baseUrl => kDebugMode ? devUrl : prodUrl;

  static const String deviceFingerprintKey = 'device_fingerprint';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String deviceSessionIdKey = 'device_session_id';
  static const String authUserKey = 'auth_user_json';
  
  static const bool allowMockFallbackInDebug = true;
}

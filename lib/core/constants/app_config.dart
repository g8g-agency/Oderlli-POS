import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  /// Compile-time override: pass --dart-define=API_BASE_URL=http://192.168.1.50:3001/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String devUrl = kIsWeb
      ? 'http://localhost:3001/api/v1'
      : 'http://localhost:3001/api/v1';
  static const String prodUrl = 'https://api.orderlyy.com/api/v1';
  static const String healthEndpoint = '/health';

  static String get baseUrl {
    // 1. Compile-time override takes highest priority
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;

    // 2. Production mode
    if (!kDebugMode) return prodUrl;

    // 3. Desktop + web use localhost
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:3001/api/v1';
    }

    // 4. Mobile debug — use env override or localhost
    return devUrl;
  }

  static const String deviceFingerprintKey = 'device_fingerprint';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String deviceSessionIdKey = 'device_session_id';
  static const String authUserKey = 'auth_user_json';
  static const String runtimeTokenKey = 'runtime_token';

  static bool allowMockFallbackInDebug = false;

  static const String printerIp = String.fromEnvironment('PRINTER_IP', defaultValue: '');

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mdwryhxnruprtuqonbwy.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd3J5aHhucnVwcnR1cW9uYnd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzU1MTEsImV4cCI6MjA5MDU1MTUxMX0.5hGdHHSzRnfENndmbL1pdiT2LsqhJCHkz1Fq2-8ADAY',
  );
}

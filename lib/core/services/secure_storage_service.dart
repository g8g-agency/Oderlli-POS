import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      try {
        await _storage.write(key: key, value: value);
      } catch (e) {
        if (kDebugMode) debugPrint('[SecureStorageService] Error writing to secure storage: $e');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fallback_$key', value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      String? value;
      try {
        value = await _storage.read(key: key);
      } catch (e) {
        if (kDebugMode) debugPrint('[SecureStorageService] Error reading from secure storage: $e');
      }
      if (value == null || value.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        value = prefs.getString('fallback_$key');
      }
      return value;
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      try {
        await _storage.delete(key: key);
      } catch (e) {
        if (kDebugMode) debugPrint('[SecureStorageService] Error deleting from secure storage: $e');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fallback_$key');
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String deviceSessionId,
  }) async {
    await _write(AppConfig.accessTokenKey, accessToken);
    await _write(AppConfig.refreshTokenKey, refreshToken);
    await _write(AppConfig.deviceSessionIdKey, deviceSessionId);
    debugPrint('[AUTH] TOKEN SAVED: $accessToken');
  }

  Future<void> saveUserJson(String userJson) async {
    await _write(AppConfig.authUserKey, userJson);
  }

  Future<Map<String, String?>> getCredentials() async {
    final accessToken = await _read(AppConfig.accessTokenKey);
    final refreshToken = await _read(AppConfig.refreshTokenKey);
    final deviceSessionId = await _read(AppConfig.deviceSessionIdKey);
    final userJson = await _read(AppConfig.authUserKey);

    debugPrint('[AUTH] TOKEN READ: $accessToken');

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'deviceSessionId': deviceSessionId,
      'userJson': userJson,
    };
  }

  Future<void> saveRuntimeToken(String runtimeToken) async {
    await _write(AppConfig.runtimeTokenKey, runtimeToken);
    await _write('staff_jwt_token', runtimeToken);
  }

  Future<String?> getRuntimeToken() async {
    final token = await _read(AppConfig.runtimeTokenKey);
    if (token != null && token.isNotEmpty) return token;
    return _read('staff_jwt_token');
  }

  Future<void> clearRuntimeToken() async {
    await _delete(AppConfig.runtimeTokenKey);
    await _delete('staff_jwt_token');
  }

  Future<void> clearSession() async {
    await _delete(AppConfig.accessTokenKey);
    await _delete(AppConfig.refreshTokenKey);
    await _delete(AppConfig.deviceSessionIdKey);
    await _delete(AppConfig.authUserKey);
    await clearRuntimeToken();
  }
}

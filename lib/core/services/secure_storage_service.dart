import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String deviceSessionId,
  }) async {
    await _storage.write(key: AppConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
    await _storage.write(key: AppConfig.deviceSessionIdKey, value: deviceSessionId);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: AppConfig.authUserKey, value: userJson);
  }

  Future<Map<String, String?>> getCredentials() async {
    return {
      'accessToken': await _storage.read(key: AppConfig.accessTokenKey),
      'refreshToken': await _storage.read(key: AppConfig.refreshTokenKey),
      'deviceSessionId': await _storage.read(key: AppConfig.deviceSessionIdKey),
      'userJson': await _storage.read(key: AppConfig.authUserKey),
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConfig.accessTokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
    await _storage.delete(key: AppConfig.deviceSessionIdKey);
    await _storage.delete(key: AppConfig.authUserKey);
  }
}

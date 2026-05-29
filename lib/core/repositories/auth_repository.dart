import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../services/auth_service.dart';
import '../services/device_fingerprint_service.dart';
import '../services/secure_storage_service.dart';

class AuthRepository {
  final AuthService _authService;
  final SecureStorageService _secureStorage;
  final DeviceFingerprintService _fingerprintService;

  AuthRepository(
    this._authService,
    this._secureStorage,
    this._fingerprintService,
  );

  Future<PosUser> login(String email, String password) async {
    final fingerprint = await _fingerprintService.getOrCreateFingerprint();

    final session = await _authService.login(
      email: email,
      password: password,
      deviceFingerprint: fingerprint,
    );

    // Save tokens and user info securely
    await _secureStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      deviceSessionId: session.deviceSessionId,
    );

    final userJson = jsonEncode(session.user.toJson());
    await _secureStorage.saveUserJson(userJson);

    return PosUser.fromBackendUser(session.user);
  }

  Future<void> logout() async {
    final credentials = await _secureStorage.getCredentials();
    final deviceSessionId = credentials['deviceSessionId'];

    if (deviceSessionId != null && deviceSessionId.isNotEmpty) {
      try {
        await _authService.logout(deviceSessionId: deviceSessionId);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AuthRepository] Logout request failed: $e. Proceeding with local token clearance.');
        }
      }
    }

    // Always clear local session, even if API call fails
    await _secureStorage.clearSession();
  }

  Future<PosUser?> restoreSession() async {
    final credentials = await _secureStorage.getCredentials();
    final userJson = credentials['userJson'];
    final accessToken = credentials['accessToken'];

    if (userJson == null || accessToken == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      final backendUser = BackendUser.fromJson(decoded);
      return PosUser.fromBackendUser(backendUser);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] Failed to restore session: $e');
      }
      return null;
    }
  }
}

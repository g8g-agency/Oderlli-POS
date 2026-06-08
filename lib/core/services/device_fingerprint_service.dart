import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_config.dart';

class DeviceFingerprintService {
  // On web, flutter_secure_storage can silently fail — use SharedPreferences instead.
  final _storage = kIsWeb ? null : const FlutterSecureStorage();
  static const _prefKey = 'device_fingerprint_pref';

  Future<String> getOrCreateFingerprint() async {
    String? fingerprint;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      fingerprint = prefs.getString(_prefKey);
      if (fingerprint == null || fingerprint.isEmpty) {
        fingerprint = const Uuid().v4();
        await prefs.setString(_prefKey, fingerprint);
      }
    } else {
      try {
        fingerprint = await _storage!.read(key: AppConfig.deviceFingerprintKey);
      } catch (_) {}

      if (fingerprint == null || fingerprint.isEmpty) {
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        fingerprint = prefs.getString(_prefKey);
      }

      if (fingerprint == null || fingerprint.isEmpty) {
        fingerprint = const Uuid().v4();
        try {
          await _storage!.write(key: AppConfig.deviceFingerprintKey, value: fingerprint);
        } catch (_) {}
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, fingerprint);
      }
    }

    return fingerprint;
  }
}


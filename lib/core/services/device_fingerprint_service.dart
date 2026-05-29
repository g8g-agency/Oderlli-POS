import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_config.dart';

class DeviceFingerprintService {
  final _storage = const FlutterSecureStorage();

  Future<String> getOrCreateFingerprint() async {
    String? fingerprint = await _storage.read(key: AppConfig.deviceFingerprintKey);
    if (fingerprint == null) {
      fingerprint = const Uuid().v4();
      await _storage.write(key: AppConfig.deviceFingerprintKey, value: fingerprint);
    }
    return fingerprint;
  }
}

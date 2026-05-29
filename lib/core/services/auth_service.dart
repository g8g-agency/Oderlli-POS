import 'package:dio/dio.dart';
import '../../models/models.dart';
import 'dio_client.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceFingerprint,
    bool rememberMe = false,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_fingerprint': deviceFingerprint,
        'remember_me': rememberMe,
      },
    );

    if (response.statusCode == 200) {
      final body = response.data;
      if (body != null && body['success'] == true) {
        return AuthSession.fromJson(body['data'] as Map<String, dynamic>);
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Authentication failed',
    );
  }

  Future<void> logout({
    required String deviceSessionId,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/logout',
      data: {
        'device_session_id': deviceSessionId,
        'revoke_all_sessions': false,
      },
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Logout failed',
      );
    }
  }
}

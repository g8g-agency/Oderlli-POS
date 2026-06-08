import 'package:flutter/foundation.dart';
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
        final session = AuthSession.fromJson(body['data'] as Map<String, dynamic>);
        debugPrint('[AUTH] LOGIN TOKEN RECEIVED: ${session.accessToken}');
        return session;
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Authentication failed',
    );
  }

  Future<List<BranchInfo>> fetchBranches() async {
    final response = await _dioClient.dio.get('/tenants/current');
    if (response.statusCode == 200) {
      final body = response.data;
      if (body != null && body['success'] == true) {
        final branchesJson = (body['data']['branches'] as List<dynamic>?) ?? [];
        return branchesJson.map((b) => BranchInfo.fromJson(b as Map<String, dynamic>)).toList();
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to fetch branches',
    );
  }

  Future<List<PosUser>> fetchStaff({
    required String tenantId,
    required String branchId,
  }) async {
    final response = await _dioClient.dio.get(
      '/tenants/$tenantId/staff',
      queryParameters: {'branchId': branchId},
    );
    if (response.statusCode == 200) {
      final body = response.data;
      if (body != null && body['success'] == true) {
        final staffJson = (body['data']['staff'] as List<dynamic>?) ?? [];
        return staffJson.map((s) {
          final roleStr = (s['role'] as String? ?? '').toLowerCase();
          final UserRole mappedRole;
          if (roleStr == 'manager' || roleStr == 'owner' || roleStr == 'superadmin') {
            mappedRole = UserRole.manager;
          } else if (roleStr == 'cashier') {
            mappedRole = UserRole.cashier;
          } else {
            // waiter, kitchen, server → floor service
            mappedRole = UserRole.server;
          }
          // Backend column is 'name'; PIN login response aliases as 'full_name'
          final displayName = (s['name'] ?? s['full_name'] ?? 'Unknown').toString();
          return PosUser(
            id: s['id'] as String,
            name: displayName,
            role: mappedRole,
            pin: '',
            terminalId: 'Main Terminal',
            email: s['email'] as String?,
          );
        }).toList();
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to fetch staff members',
    );
  }

  Future<PosUser> loginStaff({
    required String tenantId,
    required String branchId,
    required String employeeId,
    required String pin,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/staff/pin-login',
      data: {
        'tenantId': tenantId,
        'branchId': branchId,
        'employeeId': employeeId,
        'pin': pin,
      },
    );
    if (response.statusCode == 200) {
      final body = response.data;
      if (body != null && body['success'] == true) {
        final staff = body['data']['staff'];
        final mappedRole = staff['role']?.toString().toUpperCase() == 'CASHIER' 
            ? UserRole.cashier 
            : (staff['role']?.toString().toUpperCase() == 'MANAGER' ? UserRole.manager : UserRole.server);
        return PosUser(
          id: staff['id'] as String,
          name: staff['full_name'] as String,
          role: mappedRole,
          pin: pin,
          terminalId: 'Main Terminal',
          email: staff['email'] as String?,
        );
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Employee verification failed',
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

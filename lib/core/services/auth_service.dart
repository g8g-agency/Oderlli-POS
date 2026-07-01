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
        final dynamic dataField = body['data'];
        final List<dynamic> staffJson;
        if (dataField is Map && dataField.containsKey('staff')) {
          staffJson = (dataField['staff'] as List<dynamic>?) ?? [];
        } else if (dataField is List) {
          staffJson = dataField;
        } else {
          staffJson = [];
        }
        return staffJson.map((raw) {
          final s = raw as Map<String, dynamic>;
          final roleStr = (s['role'] as String? ?? '').toLowerCase();
          final UserRole mappedRole;
          if (roleStr == 'manager' ||
              roleStr == 'owner' ||
              roleStr == 'superadmin' ||
              roleStr == 'restaurant_admin') {
            mappedRole = UserRole.manager;
          } else if (roleStr == 'cashier') {
            mappedRole = UserRole.cashier;
          } else {
            mappedRole = UserRole.server;
          }

          final firstName = s['first_name'] as String? ?? '';
          final lastName = s['last_name'] as String? ?? '';
          final combinedName = '$firstName $lastName'.trim();
          final displayName = (s['name'] ??
                  s['full_name'] ??
                  (combinedName.isNotEmpty ? combinedName : null) ??
                  'Unknown')
              .toString();

          final id = s['id']?.toString();
          if (id == null || id.isEmpty) {
            throw StateError('Staff record missing id');
          }

          return PosUser(
            id: id,
            name: displayName,
            role: mappedRole,
            pin: '',
            terminalId: 'Main Terminal',
            email: s['email']?.toString(),
            employeeId: s['employee_id']?.toString(),
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

  Future<({String runtimeToken, PosUser user})> loginStaff({
    required String tenantId,
    required String branchId,
    required String employeeId,
    required String pin,
    required PosUser staffProfile,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/staff/login',
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
        final data = body['data'] as Map<String, dynamic>;
        final runtimeToken = data['runtime_token'] as String?;
        if (runtimeToken == null || runtimeToken.isEmpty) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Staff login succeeded but no runtime token was returned',
          );
        }
        return (
          runtimeToken: runtimeToken,
          user: staffProfile.copyWith(pin: pin),
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

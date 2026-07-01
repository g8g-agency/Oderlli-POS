// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:orderlli_pos/core/repositories/cart_repository.dart';
import 'package:orderlli_pos/core/services/cart_service.dart';
import 'package:orderlli_pos/core/services/dio_client.dart';
import 'package:orderlli_pos/core/services/connectivity_service.dart';
import 'package:orderlli_pos/core/services/secure_storage_service.dart';
import 'package:orderlli_pos/core/services/device_fingerprint_service.dart';
import 'package:orderlli_pos/models/models.dart';

void main() {
  test('Debug syncCartToBackend E2E', timeout: const Timeout(Duration(seconds: 120)), () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3001',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // 1. Login
    final loginRes = await dio.post(
      '/api/v1/auth/login',
      data: {
        'email': 'testcafe.owner@test.com',
        'password': 'Test@123456',
        'device_fingerprint': 'pos-debug-sync-device-fingerprint',
      },
    );
    expect(loginRes.statusCode, 200);
    final data = loginRes.data['data'] as Map<String, dynamic>;
    final token = data['accessToken'] ?? data['token'] ?? data['access_token'] ?? '';
    final user = data['user'] as Map<String, dynamic>;
    final tenantId = user['tenantId'] ?? user['tenant_id'] ?? '';

    // Set Authorization header
    dio.options.headers['Authorization'] = 'Bearer $token';

    // Fetch tenant current
    final tenantResponse = await dio.get('/api/v1/tenants/current');
    expect(tenantResponse.statusCode, 200);
    final branches = tenantResponse.data['data']['branches'] as List<dynamic>;
    final branchId = branches.first['id'] as String;

    // Fetch menu items to get a valid menuItemId
    final menuResponse = await dio.get('/api/v1/tenants/$tenantId/menu/items', queryParameters: {'branchId': branchId});
    expect(menuResponse.statusCode, 200);
    final menuItemsRaw = menuResponse.data['data']['data'] as List<dynamic>;
    final firstItemRaw = menuItemsRaw.first as Map<String, dynamic>;

    final menuItem = MenuItem(
      id: firstItemRaw['id'],
      name: firstItemRaw['name'],
      categoryId: firstItemRaw['categoryId'] ?? '',
      price: (firstItemRaw['price'] as num).toDouble(),
      modifierGroups: const [],
    );

    // 2. Instantiate CartRepository
    final mockStorage = MockSecureStorageService(token);
    final mockFingerprint = MockDeviceFingerprintService();
    final dioClient = DioClient(mockStorage, mockFingerprint);
    dioClient.dio.options.baseUrl = 'http://localhost:3001';
    // Copy headers/cookies from our authenticated dio
    dioClient.dio.options.headers.addAll(dio.options.headers);

    final cartService = CartService(dioClient);
    final connService = ConnectivityService();
    final cartRepo = CartRepository(cartService, connService);

    // 3. Call syncCartToBackend
    const String tableId = '00000000-0000-0000-0000-000000000001';
    final itemsToSync = [
      {
        'menuItem': menuItem,
        'quantity': 1,
        'notes': 'Sync Test Note',
        'selectedModifiers': <String>[],
      }
    ];

    print('Calling syncCartToBackend...');
    try {
      final cart = await cartRepo.syncCartToBackend(
        tenantId: tenantId,
        branchId: branchId,
        tableId: tableId,
        items: itemsToSync,
      );
      print('Sync successful! Cart ID: ${cart.id}');
    } catch (e) {
      print('Sync failed with error: $e');
      if (e is DioException) {
        print('Response body: ${e.response?.data}');
      }
      rethrow;
    }
  });
}

class MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _cache = {};
  MockSecureStorageService(String accessToken) {
    _cache['accessToken'] = accessToken;
    _cache['staff_jwt_token'] = accessToken;
  }
  @override
  Future<Map<String, String?>> getCredentials() async {
    return {
      'accessToken': _cache['accessToken'],
      'refreshToken': 'mock-refresh',
      'deviceSessionId': 'mock-device-session',
    };
  }
  @override
  Future<String?> getRuntimeToken() async => _cache['accessToken'];
}

class MockDeviceFingerprintService extends DeviceFingerprintService {
  @override
  Future<String> getOrCreateFingerprint() async => 'pos-debug-sync-device-fingerprint';
}


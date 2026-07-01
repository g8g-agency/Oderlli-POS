// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

void main() {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3001',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  const uuid = Uuid();

  group('ORDER-02 Counter Order E2E API Flow', () {
    late String ownerToken;
    late String tenantId;
    late String branchId;
    const String tableId = '00000000-0000-0000-0000-000000000001';
    late String sessionToken;
    late String sessionId;
    late String cartId;
    late String menuItemId;
    late int currentRevision;

    test('Step 0: Owner Login to retrieve Tenant and Branch context', () async {
      final response = await dio.post(
        '/api/v1/auth/login',
        data: {
          'email': 'testcafe.owner@test.com',
          'password': 'Test@123456',
          'device_fingerprint': 'pos-test-device-fingerprint',
        },
      );

      print('Login response data: ${response.data}');

      expect(response.statusCode, 200);
      expect(response.data['success'], true);

      final data = response.data['data'] as Map<String, dynamic>;
      ownerToken = data['accessToken'] ?? data['token'] ?? data['access_token'] ?? '';
      final user = data['user'] as Map<String, dynamic>;
      tenantId = user['tenantId'] ?? user['tenant_id'] ?? '';
      
      // Add Auth header for admin requests
      dio.options.headers['Authorization'] = 'Bearer $ownerToken';
      
      // Fetch branches to get active branch
      final tenantResponse = await dio.get('/api/v1/tenants/current');
      print('Current tenant response: ${tenantResponse.data}');
      expect(tenantResponse.statusCode, 200);
      final branches = tenantResponse.data['data']['branches'] as List<dynamic>;
      expect(branches, isNotEmpty);
      branchId = branches.first['id'] as String;

      print('Authenticated Owner. Tenant: $tenantId, Branch: $branchId');
    });

    test('Step 1: Resolve QR Session token for the Counter table', () async {
      try {
        // 1. Create/Retrieve QR code for signed_payload
        final qrResponse = await dio.post(
          '/api/v1/admin/qr/codes',
          data: {
            'branch_id': branchId,
            'table_id': tableId,
          },
        );
        expect(qrResponse.statusCode, 201);
        final signedPayload = qrResponse.data['data']['signed_payload'] as String;

        // 2. Resolve session token
        final resolveResponse = await dio.post(
          '/api/v1/qr/resolve',
          data: {
            'signed_payload': signedPayload,
            'nonce': 'pos-test-nonce-${DateTime.now().millisecondsSinceEpoch}',
            'device_fingerprint': 'pos-test-fingerprint-id',
          },
        );

        expect(resolveResponse.statusCode, anyOf(200, 201));
        expect(resolveResponse.data['success'], true);
        
        sessionId = resolveResponse.data['data']['session_id'] as String;
        sessionToken = resolveResponse.data['data']['session_token'] as String;
        print('Resolved Session Token: $sessionToken (ID: $sessionId)');
      } on DioException catch (e) {
        print('DioException caught in Step 1! Status: ${e.response?.statusCode}');
        print('Request URL: ${e.requestOptions.uri}');
        print('Request Body: ${e.requestOptions.data}');
        print('Error response body: ${e.response?.data}');
        rethrow;
      }
    });

    test('Step 2: Fetch Menu and Create Cart on Backend', () async {
      // Fetch menu items
      final menuResponse = await dio.get('/api/v1/tenants/$tenantId/menu/items', queryParameters: {'branchId': branchId});
      expect(menuResponse.statusCode, 200);
      final items = menuResponse.data['data']['data'] as List<dynamic>;
      expect(items, isNotEmpty);
      
      // Get the first item
      final item = items.first as Map<String, dynamic>;
      menuItemId = item['id'] as String;

      // 1. Fetch initial cart (to verify/initialize cart)
      final cartResponse = await dio.get(
        '/api/v1/cart',
        options: Options(
          headers: {'X-QR-Session-Token': sessionToken},
        ),
      );
      expect(cartResponse.statusCode, 200);
      final cartDetail = cartResponse.data['data'] as Map<String, dynamic>;
      final cartData = cartDetail['cart'] as Map<String, dynamic>;
      cartId = cartData['id'] as String;
      currentRevision = cartData['version_num'] as int;

      print('Initialized Cart ID: $cartId, Revision: $currentRevision');
    });

    test('Step 3: Add Items to backend Cart', () async {
      final mutationId = uuid.v4();
      final addResponse = await dio.post(
        '/api/v1/cart/items',
        options: Options(
          headers: {
            'X-QR-Session-Token': sessionToken,
            'X-Mutation-Id': mutationId,
            'X-Expected-Cart-Revision': currentRevision.toString(),
          },
        ),
        data: {
          'mutation_id': mutationId,
          'mutation_sequence': 0,
          'runtime_version': 1,
          'session_id': sessionId,
          'tenant_id': tenantId,
          'branch_id': branchId,
          'client_timestamp': DateTime.now().toUtc().toIso8601String(),
          'idempotency_key': mutationId,
          'expected_cart_revision': currentRevision,
          'payload': {
            'menu_item_id': menuItemId,
            'quantity': 2,
          },
        },
      );

      expect(addResponse.statusCode, anyOf(200, 201));
      final updatedCartDetail = addResponse.data['data'] as Map<String, dynamic>;
      final updatedCart = updatedCartDetail['cart'] as Map<String, dynamic>;
      currentRevision = updatedCart['version_num'] as int;
      expect(updatedCartDetail['items'], isNotEmpty);
      print('Added Item. New Cart Revision: $currentRevision');
    });

    test('Step 4: Checkout Counter Order', timeout: const Timeout(Duration(seconds: 60)), () async {
      final mutationId = uuid.v4();
      try {
        final checkoutResponse = await dio.post(
          '/api/v1/orders/checkout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $ownerToken',
              'X-QR-Session-Token': sessionToken,
              'X-Mutation-Id': mutationId,
              'X-Expected-Cart-Revision': currentRevision.toString(),
              'Idempotency-Key': uuid.v4(),
            },
          ),
          data: {
            'mutation_id': mutationId,
            'mutation_sequence': 0,
            'runtime_version': 1,
            'session_id': sessionId,
            'tenant_id': tenantId,
            'branch_id': branchId,
            'client_timestamp': DateTime.now().toUtc().toIso8601String(),
            'idempotency_key': mutationId,
            'expected_cart_revision': currentRevision,
            'payload': {
              'cartId': cartId,
              'tableId': tableId,
              'orderNotes': 'Counter Order Test',
            },
          },
        );

        expect(checkoutResponse.statusCode, anyOf(200, 201));
        expect(checkoutResponse.data['success'], true);
        
        final order = checkoutResponse.data['data']['order'] as Map<String, dynamic>;
        expect(order['id'], isNotEmpty);
        print('🎉 Counter Order checked out successfully! Order ID: ${order['id']}');
      } on DioException catch (e) {
        print('DioException caught in Step 4! Status: ${e.response?.statusCode}');
        print('Error response body: ${e.response?.data}');
        rethrow;
      }
    });
  });
}

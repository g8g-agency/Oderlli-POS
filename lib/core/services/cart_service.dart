import 'package:dio/dio.dart';
import '../../models/models.dart';
import 'dio_client.dart';

class CartService {
  final DioClient? _dioClient;

  CartService(this._dioClient);

  DioClient get dioClient => _dioClient!;


  /// GET /api/v1/cart
  Future<Cart> fetchCart(String qrSessionToken) async {
    if (qrSessionToken.isEmpty ||
        qrSessionToken == 'counter-session-token' ||
        qrSessionToken == '00000000-0000-0000-0000-000000000001') {
      return Cart.empty();
    }
    final response = await dioClient.dio.get(
      '/api/v1/cart',
      options: Options(
        headers: {
          'X-QR-Session-Token': qrSessionToken,
        },
      ),
    );
    _assertSuccess(response);
    return _parseCartResponse(response.data['data']);
  }

  /// POST /api/v1/cart/items
  Future<Cart> addCartItem({
    required String qrSessionToken,
    required String mutationId,
    required int expectedCartRevision,
    required Map<String, dynamic> mutationEnvelopeBody,
  }) async {
    if (qrSessionToken.isEmpty ||
        qrSessionToken == 'counter-session-token' ||
        qrSessionToken == '00000000-0000-0000-0000-000000000001') {
      return Cart.empty();
    }
    final response = await dioClient.dio.post(
      '/api/v1/cart/items',
      data: mutationEnvelopeBody,
      options: Options(
        headers: {
          'X-QR-Session-Token': qrSessionToken,
          'X-Mutation-Id': mutationId,
          'X-Expected-Cart-Revision': expectedCartRevision.toString(),
        },
      ),
    );
    _assertSuccess(response);
    return _parseCartResponse(response.data['data']);
  }

  /// PATCH /api/v1/cart/items/:itemId
  Future<Cart> updateCartItem({
    required String qrSessionToken,
    required String itemId,
    required String mutationId,
    required int expectedCartRevision,
    required Map<String, dynamic> mutationEnvelopeBody,
  }) async {
    if (qrSessionToken.isEmpty ||
        qrSessionToken == 'counter-session-token' ||
        qrSessionToken == '00000000-0000-0000-0000-000000000001') {
      return Cart.empty();
    }
    final response = await dioClient.dio.patch(
      '/api/v1/cart/items/$itemId',
      data: mutationEnvelopeBody,
      options: Options(
        headers: {
          'X-QR-Session-Token': qrSessionToken,
          'X-Mutation-Id': mutationId,
          'X-Expected-Cart-Revision': expectedCartRevision.toString(),
        },
      ),
    );
    _assertSuccess(response);
    return _parseCartResponse(response.data['data']);
  }

  /// DELETE /api/v1/cart/items/:itemId
  Future<Cart> removeCartItem({
    required String qrSessionToken,
    required String itemId,
    required String mutationId,
    required int expectedCartRevision,
    required Map<String, dynamic> mutationEnvelopeBody,
  }) async {
    if (qrSessionToken.isEmpty ||
        qrSessionToken == 'counter-session-token' ||
        qrSessionToken == '00000000-0000-0000-0000-000000000001') {
      return Cart.empty();
    }
    final response = await dioClient.dio.delete(
      '/api/v1/cart/items/$itemId',
      data: mutationEnvelopeBody,
      options: Options(
        headers: {
          'X-QR-Session-Token': qrSessionToken,
          'X-Mutation-Id': mutationId,
          'X-Expected-Cart-Revision': expectedCartRevision.toString(),
        },
      ),
    );
    _assertSuccess(response);
    return _parseCartResponse(response.data['data']);
  }

  /// PATCH /api/v1/cart/notes
  Future<Cart> updateCartNotes({
    required String qrSessionToken,
    required String mutationId,
    required int expectedCartRevision,
    required Map<String, dynamic> mutationEnvelopeBody,
  }) async {
    if (qrSessionToken.isEmpty ||
        qrSessionToken == 'counter-session-token' ||
        qrSessionToken == '00000000-0000-0000-0000-000000000001') {
      return Cart.empty();
    }
    final response = await dioClient.dio.patch(
      '/api/v1/cart/notes',
      data: mutationEnvelopeBody,
      options: Options(
        headers: {
          'X-QR-Session-Token': qrSessionToken,
          'X-Mutation-Id': mutationId,
          'X-Expected-Cart-Revision': expectedCartRevision.toString(),
        },
      ),
    );
    _assertSuccess(response);
    return _parseCartResponse(response.data['data']);
  }

  Cart _parseCartResponse(dynamic responseData) {
    if (responseData == null) {
      throw Exception('Response data is null');
    }
    final rawCart = responseData['cart'] as Map<String, dynamic>;
    final rawItems = (responseData['items'] as List<dynamic>?) ?? [];
    final rawModifiers = (responseData['modifiers'] as List<dynamic>?) ?? [];

    final modifiersList = rawModifiers
        .map((e) => CartModifier.fromJson(e as Map<String, dynamic>))
        .toList();

    final itemsList = rawItems.map((e) {
      final itemJson = e as Map<String, dynamic>;
      final itemId = itemJson['id'] as String;
      final itemModifiers = modifiersList.where((m) => m.cartItemId == itemId).toList();
      return CartItem.fromJson(itemJson, itemModifiers);
    }).toList();

    return Cart.fromJson(rawCart, itemsList);
  }

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null || response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Cart API returned an unexpected response',
      );
    }
  }

  final Map<String, String> tableSessionIds = {};
  final Map<String, Future<String>> activeQrResolutions = {};

  Future<String> resolveQrSessionForTable(String branchId, String tableId) {
    if (tableId == '00000000-0000-0000-0000-000000000001') {
      return Future.value('counter-session-token');
    }

    final existingFuture = activeQrResolutions[tableId];
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = resolveQrSessionForTableRaw(branchId, tableId);
    activeQrResolutions[tableId] = future;

    future.then((_) {
      // Keep it cached/active or clean up as needed
    }).catchError((_) {
      activeQrResolutions.remove(tableId);
    });

    return future;
  }

  Future<String> resolveQrSessionForTableRaw(String branchId, String tableId) async {
    // 1. Create/Retrieve QR Code to get signed_payload
    final qrResponse = await dioClient.dio.post(
      '/api/v1/admin/qr/codes',
      data: {
        'branch_id': branchId,
        'table_id': tableId,
      },
    );
    if (qrResponse.data == null || qrResponse.data['success'] != true) {
      throw DioException(
        requestOptions: qrResponse.requestOptions,
        response: qrResponse,
        message: 'Failed to create QR code for table',
      );
    }
    final signedPayload = qrResponse.data['data']['signed_payload'] as String;

    // 2. Resolve session token
    final resolveResponse = await dioClient.dio.post(
      '/api/v1/qr/resolve',
      data: {
        'signed_payload': signedPayload,
        'nonce': 'pos-client-nonce-${DateTime.now().millisecondsSinceEpoch}',
        'device_fingerprint': 'pos-client-fingerprint-unique-id',
      },
    );

    if (resolveResponse.data == null || resolveResponse.data['success'] != true) {
      throw DioException(
        requestOptions: resolveResponse.requestOptions,
        response: resolveResponse,
        message: 'Failed to resolve QR session token',
      );
    }
    final responseData = resolveResponse.data['data'];
    final sessionToken = responseData['session_token'] as String;
    final sessionId = responseData['session_id'] as String;
    tableSessionIds[tableId] = sessionId;
    return sessionToken;
  }
}

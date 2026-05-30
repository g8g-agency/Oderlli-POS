import 'package:dio/dio.dart';
import '../../models/models.dart';
import 'dio_client.dart';

class CartService {
  final DioClient? _dioClient;

  CartService(this._dioClient);

  DioClient get dioClient => _dioClient!;


  /// GET /api/v1/cart
  Future<Cart> fetchCart(String qrSessionToken) async {
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
}

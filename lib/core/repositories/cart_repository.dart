import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../constants/app_config.dart';
import '../services/cart_service.dart';
import '../services/connectivity_service.dart';

// ─── Exceptions ──────────────────────────────────────────────────────────────

class StaleCartRevisionException implements Exception {
  final String message;
  const StaleCartRevisionException([this.message = 'Cart was modified since your last known revision']);
  @override
  String toString() => message;
}

class CartValidationException implements Exception {
  final String message;
  const CartValidationException(this.message);
  @override
  String toString() => message;
}

class DatabaseSchemaMismatchException implements Exception {
  final String message;
  const DatabaseSchemaMismatchException(this.message);
  @override
  String toString() => message;
}

class OfflineCartException implements Exception {
  final String message;
  const OfflineCartException([this.message = 'Server is offline. Cart operations unavailable.']);
  @override
  String toString() => message;
}

// ─── Repository ─────────────────────────────────────────────────────────────

class CartRepository {
  final CartService _cartService;
  final ConnectivityService _connectivityService;
  final Uuid _uuid = const Uuid();

  // Local cache of QR Session tokens per table
  final Map<String, String> _tableSessionTokens = {};

  // Local in-memory carts for mock fallback (restricted to debug mode only)
  final Map<String, Cart> _mockCarts = {};

  CartRepository(this._cartService, this._connectivityService);

  /// Helper to check if fallback is allowed
  Future<bool> _shouldUseMockFallback() async {
    if (!kDebugMode || !AppConfig.allowMockFallbackInDebug) {
      return false;
    }
    final isReachable = await _connectivityService.isBackendReachable(
      AppConfig.baseUrl,
      AppConfig.healthEndpoint,
    );
    return !isReachable;
  }

  /// Checks if a DioException indicates missing database tables
  void _checkForSchemaMismatch(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'];
      if (error is Map<String, dynamic>) {
        final msg = (error['message'] ?? '').toString().toLowerCase();
        if (msg.contains('relation') && (msg.contains('does not exist') || msg.contains('not found'))) {
          throw DatabaseSchemaMismatchException(
              'Database Schema Mismatch: The backend is missing necessary database tables. Details: ${error['message']}');
        }
      }
      final msg = (responseData['message'] ?? '').toString().toLowerCase();
      if (msg.contains('relation') && (msg.contains('does not exist') || msg.contains('not found'))) {
        throw DatabaseSchemaMismatchException(
            'Database Schema Mismatch: The backend is missing necessary database tables. Details: $msg');
      }
    }
    final errorMsg = e.message?.toLowerCase() ?? '';
    if (errorMsg.contains('relation') && (errorMsg.contains('does not exist') || errorMsg.contains('not found'))) {
      throw DatabaseSchemaMismatchException(
          'Database Schema Mismatch: The backend is missing necessary database tables. Details: ${e.message}');
    }
  }

  /// Handles and wraps DioExceptions into domain exceptions
  void _handleDioException(DioException e) {
    _checkForSchemaMismatch(e);

    if (e.response?.statusCode == 409) {
      throw const StaleCartRevisionException();
    }

    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      String errorMsg = 'Validation Error';
      if (data is Map<String, dynamic> && data['error'] != null) {
        errorMsg = data['error']['message'] ?? errorMsg;
      }
      throw CartValidationException(errorMsg);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const OfflineCartException();
    }

    throw CartValidationException(e.message ?? 'Unknown cart error');
  }

  /// Resolves the QR session token for a table
  Future<String> _getOrResolveSessionToken(String branchId, String tableId) async {
    if (_tableSessionTokens.containsKey(tableId)) {
      return _tableSessionTokens[tableId]!;
    }
    try {
      final token = await _cartService.resolveQrSessionForTable(branchId, tableId);
      _tableSessionTokens[tableId] = token;
      return token;
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      rethrow;
    }
  }

  /// Builds a deterministic mutation envelope for REST request bodies
  Map<String, dynamic> _buildMutationEnvelope({
    required String tenantId,
    required String branchId,
    required String sessionToken,
    required int expectedCartRevision,
    required String mutationId,
    required Map<String, dynamic> payload,
  }) {
    return {
      'mutation_id': mutationId,
      'mutation_sequence': 0,
      'runtime_version': 1,
      'session_id': _uuid.v4(), // Client generated trace session
      'tenant_id': tenantId,
      'branch_id': branchId,
      'client_timestamp': DateTime.now().toUtc().toIso8601String(),
      'idempotency_key': mutationId,
      'expected_cart_revision': expectedCartRevision,
      'payload': payload,
    };
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// GET /api/v1/cart
  Future<Cart> getCart(String tenantId, String branchId, String tableId) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _getOrCreateMockCart(tenantId, branchId, tableId);
    }

    try {
      final sessionToken = await _getOrResolveSessionToken(branchId, tableId);
      return await _cartService.fetchCart(sessionToken);
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _getOrCreateMockCart(tenantId, branchId, tableId);
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// POST /api/v1/cart/items
  Future<Cart> addCartItem({
    required String tenantId,
    required String branchId,
    required String tableId,
    required MenuItem menuItem,
    required int quantity,
    String? itemNotes,
    List<String> selectedModifiers = const [],
    required int expectedCartRevision,
  }) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _addMockCartItem(
        tenantId: tenantId,
        branchId: branchId,
        tableId: tableId,
        menuItem: menuItem,
        quantity: quantity,
        itemNotes: itemNotes,
        selectedModifiers: selectedModifiers,
        expectedCartRevision: expectedCartRevision,
      );
    }

    try {
      final sessionToken = await _getOrResolveSessionToken(branchId, tableId);
      final mutationId = _uuid.v4();

      // Map selected modifiers names to backend group/option ids
      final List<Map<String, dynamic>> modifiersPayload = [];
      for (final modName in selectedModifiers) {
        bool mapped = false;
        for (final group in menuItem.modifierGroups) {
          for (final option in group.options) {
            if (option.name.toLowerCase() == modName.toLowerCase()) {
              modifiersPayload.add({
                'modifier_group_id': group.id,
                'modifier_option_id': option.id,
              });
              mapped = true;
              break;
            }
          }
          if (mapped) break;
        }
        if (!mapped) {
          // Dummy mapping for static UI-only modifiers
          modifiersPayload.add({
            'modifier_group_id': _uuid.v4(),
            'modifier_option_id': _uuid.v4(),
          });
        }
      }

      final payload = {
        'menu_item_id': menuItem.id,
        'quantity': quantity,
        'item_notes': itemNotes,
        'modifiers': modifiersPayload,
      };

      final envelope = _buildMutationEnvelope(
        tenantId: tenantId,
        branchId: branchId,
        sessionToken: sessionToken,
        expectedCartRevision: expectedCartRevision,
        mutationId: mutationId,
        payload: payload,
      );

      return await _cartService.addCartItem(
        qrSessionToken: sessionToken,
        mutationId: mutationId,
        expectedCartRevision: expectedCartRevision,
        mutationEnvelopeBody: envelope,
      );
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _addMockCartItem(
          tenantId: tenantId,
          branchId: branchId,
          tableId: tableId,
          menuItem: menuItem,
          quantity: quantity,
          itemNotes: itemNotes,
          selectedModifiers: selectedModifiers,
          expectedCartRevision: expectedCartRevision,
        );
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// PATCH /api/v1/cart/items/:itemId
  Future<Cart> updateCartItem({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String itemId,
    required int quantity,
    String? itemNotes,
    required int itemVersionNum,
    required int expectedCartRevision,
  }) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _updateMockCartItem(
        tableId: tableId,
        itemId: itemId,
        quantity: quantity,
        itemNotes: itemNotes,
        expectedCartRevision: expectedCartRevision,
      );
    }

    try {
      final sessionToken = await _getOrResolveSessionToken(branchId, tableId);
      final mutationId = _uuid.v4();

      final payload = {
        'quantity': quantity,
        'item_notes': itemNotes,
        'version_num': itemVersionNum,
      };

      final envelope = _buildMutationEnvelope(
        tenantId: tenantId,
        branchId: branchId,
        sessionToken: sessionToken,
        expectedCartRevision: expectedCartRevision,
        mutationId: mutationId,
        payload: payload,
      );

      return await _cartService.updateCartItem(
        qrSessionToken: sessionToken,
        itemId: itemId,
        mutationId: mutationId,
        expectedCartRevision: expectedCartRevision,
        mutationEnvelopeBody: envelope,
      );
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _updateMockCartItem(
          tableId: tableId,
          itemId: itemId,
          quantity: quantity,
          itemNotes: itemNotes,
          expectedCartRevision: expectedCartRevision,
        );
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// DELETE /api/v1/cart/items/:itemId
  Future<Cart> removeCartItem({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String itemId,
    required int itemVersionNum,
    required int expectedCartRevision,
  }) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _removeMockCartItem(
        tableId: tableId,
        itemId: itemId,
        expectedCartRevision: expectedCartRevision,
      );
    }

    try {
      final sessionToken = await _getOrResolveSessionToken(branchId, tableId);
      final mutationId = _uuid.v4();

      final payload = {
        'version_num': itemVersionNum,
      };

      final envelope = _buildMutationEnvelope(
        tenantId: tenantId,
        branchId: branchId,
        sessionToken: sessionToken,
        expectedCartRevision: expectedCartRevision,
        mutationId: mutationId,
        payload: payload,
      );

      return await _cartService.removeCartItem(
        qrSessionToken: sessionToken,
        itemId: itemId,
        mutationId: mutationId,
        expectedCartRevision: expectedCartRevision,
        mutationEnvelopeBody: envelope,
      );
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _removeMockCartItem(
          tableId: tableId,
          itemId: itemId,
          expectedCartRevision: expectedCartRevision,
        );
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// PATCH /api/v1/cart/notes
  Future<Cart> updateCartNotes({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String? orderNotes,
    required int expectedCartRevision,
  }) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _updateMockCartNotes(
        tableId: tableId,
        orderNotes: orderNotes,
        expectedCartRevision: expectedCartRevision,
      );
    }

    try {
      final sessionToken = await _getOrResolveSessionToken(branchId, tableId);
      final mutationId = _uuid.v4();

      final payload = {
        'order_notes': orderNotes,
        'version_num': expectedCartRevision,
      };

      final envelope = _buildMutationEnvelope(
        tenantId: tenantId,
        branchId: branchId,
        sessionToken: sessionToken,
        expectedCartRevision: expectedCartRevision,
        mutationId: mutationId,
        payload: payload,
      );

      return await _cartService.updateCartNotes(
        qrSessionToken: sessionToken,
        mutationId: mutationId,
        expectedCartRevision: expectedCartRevision,
        mutationEnvelopeBody: envelope,
      );
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _updateMockCartNotes(
          tableId: tableId,
          orderNotes: orderNotes,
          expectedCartRevision: expectedCartRevision,
        );
      }
      _handleDioException(e);
      rethrow;
    }
  }

  // ─── Mock Fallback Implementations (Debug Mode Only) ──────────────────────────

  Cart _getOrCreateMockCart(String tenantId, String branchId, String tableId) {
    if (!_mockCarts.containsKey(tableId)) {
      _mockCarts[tableId] = Cart(
        id: _uuid.v4(),
        tenantId: tenantId,
        branchId: branchId,
        tableId: tableId,
        sessionId: _uuid.v4(),
        status: 'open',
        versionNum: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return _mockCarts[tableId]!;
  }

  Cart _addMockCartItem({
    required String tenantId,
    required String branchId,
    required String tableId,
    required MenuItem menuItem,
    required int quantity,
    String? itemNotes,
    List<String> selectedModifiers = const [],
    required int expectedCartRevision,
  }) {
    final current = _getOrCreateMockCart(tenantId, branchId, tableId);
    if (current.versionNum != expectedCartRevision) {
      throw const StaleCartRevisionException();
    }

    final list = List<CartItem>.from(current.items);
    final itemId = _uuid.v4();

    // Map strings to fake CartModifiers
    final List<CartModifier> mockModifiers = [];
    for (final modName in selectedModifiers) {
      mockModifiers.add(CartModifier(
        id: _uuid.v4(),
        tenantId: tenantId,
        cartItemId: itemId,
        modifierGroupId: _uuid.v4(),
        modifierOptionId: _uuid.v4(),
        modifierGroupNameSnapshot: 'Add-on',
        modifierOptionNameSnapshot: modName,
        priceDeltaMinorSnapshot: modName.contains('Cheese') || modName.contains('Meat') ? 150 : 0,
        createdAt: DateTime.now(),
      ));
    }

    final newItem = CartItem(
      id: itemId,
      tenantId: tenantId,
      cartId: current.id,
      menuItemId: menuItem.id,
      itemNameSnapshot: menuItem.name,
      itemSkuSnapshot: menuItem.name.toLowerCase().replaceAll(' ', '-'),
      unitPriceMinorSnapshot: (menuItem.price * 100).toInt(),
      quantity: quantity,
      itemNotes: itemNotes,
      displayOrder: list.length,
      versionNum: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      modifiers: mockModifiers,
    );

    list.add(newItem);

    final updated = current.copyWith(
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
      items: list,
    );
    _mockCarts[tableId] = updated;
    return updated;
  }

  Cart _updateMockCartItem({
    required String tableId,
    required String itemId,
    required int quantity,
    String? itemNotes,
    required int expectedCartRevision,
  }) {
    final current = _mockCarts[tableId];
    if (current == null) {
      throw const StaleCartRevisionException('Mock cart not initialized');
    }
    if (current.versionNum != expectedCartRevision) {
      throw const StaleCartRevisionException();
    }

    final updatedItems = current.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          quantity: quantity,
          itemNotes: itemNotes,
          versionNum: item.versionNum + 1,
          updatedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    final updated = current.copyWith(
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
      items: updatedItems,
    );
    _mockCarts[tableId] = updated;
    return updated;
  }

  Cart _removeMockCartItem({
    required String tableId,
    required String itemId,
    required int expectedCartRevision,
  }) {
    final current = _mockCarts[tableId];
    if (current == null) {
      throw const StaleCartRevisionException('Mock cart not initialized');
    }
    if (current.versionNum != expectedCartRevision) {
      throw const StaleCartRevisionException();
    }

    final updatedItems = current.items.where((item) => item.id != itemId).toList();

    final updated = current.copyWith(
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
      items: updatedItems,
    );
    _mockCarts[tableId] = updated;
    return updated;
  }

  Cart _updateMockCartNotes({
    required String tableId,
    required String? orderNotes,
    required int expectedCartRevision,
  }) {
    final current = _mockCarts[tableId];
    if (current == null) {
      throw const StaleCartRevisionException('Mock cart not initialized');
    }
    if (current.versionNum != expectedCartRevision) {
      throw const StaleCartRevisionException();
    }

    final updated = current.copyWith(
      orderNotes: orderNotes,
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
    );
    _mockCarts[tableId] = updated;
    return updated;
  }
}

// ─── Extra Endpoint Helper in CartService for Repository resolution ───────────

extension CartServiceQrExt on CartService {
  Future<String> resolveQrSessionForTable(String branchId, String tableId) async {
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
    return resolveResponse.data['data']['session_token'] as String;
  }
}

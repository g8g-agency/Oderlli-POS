import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../constants/pos_constants.dart';
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

  // Local cache of QR Session token resolution failures
  final Map<String, String> _tableSessionFailures = {};

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
  Future<String> _getOrResolveSessionToken(
      String branchId, String tableId) async {
    // Counter sentinel — never hits the API
    if (tableId == '00000000-0000-0000-0000-000000000001' ||
        tableId == PosConstants.counterTableId ||
        PosConstants.isCounterTable(tableId)) {
      _tableSessionTokens[tableId] = 'counter-session-token';
      return 'counter-session-token';
    }

    // Return cached token
    if (_tableSessionTokens.containsKey(tableId)) {
      return _tableSessionTokens[tableId]!;
    }

    // Don't retry a known failure (e.g. 404 on /qr/resolve)
    if (_tableSessionFailures.containsKey(tableId)) {
      throw CartValidationException(
        _tableSessionFailures[tableId]!,
      );
    }

    try {
      final future = _cartService.resolveQrSessionForTable(branchId, tableId);
      final token = await future;
      if (_cartService.activeQrResolutions[tableId] == future) {
        _tableSessionTokens[tableId] = token;
      }
      return token;
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      // Cache the failure message to prevent hammering
      final msg = e.response?.statusCode == 404
          ? 'Cart service unavailable: /qr/resolve route not found on backend. Contact your system administrator.'
          : (e.message ?? 'Failed to resolve table session');
      _tableSessionFailures[tableId] = msg;
      throw CartValidationException(msg);
    }
  }

  /// Clears the resolved table session cache (both tokens and failures)
  void clearSessionCache() {
    _tableSessionTokens.clear();
    _tableSessionFailures.clear();
    _cartService.tableSessionIds.clear();
    _cartService.activeQrResolutions.clear();
  }

  /// Evicts the cached session token, failures, in-flight resolutions, and session IDs for a specific table
  void evictTableSession(String tableId) {
    _tableSessionTokens.remove(tableId);
    _tableSessionFailures.remove(tableId);
    _cartService.tableSessionIds.remove(tableId);
    _cartService.activeQrResolutions.remove(tableId);
  }

  /// Executes a cart operation, automatically retrying once with a re-resolved token
  /// if a 401/403 error is returned and the original attempt used a cached token.
  Future<T> _executeWithRetry<T>({
    required String branchId,
    required String tableId,
    required Future<T> Function(String token) operation,
  }) async {
    final wasCached = _tableSessionTokens.containsKey(tableId);
    final token = await _getOrResolveSessionToken(branchId, tableId);

    try {
      return await operation(token);
    } on DioException catch (e) {
      final isUnauthorized = e.response?.statusCode == 401 || e.response?.statusCode == 403;
      if (isUnauthorized && wasCached) {
        // Evict from cache before retry
        evictTableSession(tableId);

        // Re-resolve once. We don't catch exceptions from this call,
        // so any auth failures during resolution will propagate directly.
        final newToken = await _getOrResolveSessionToken(branchId, tableId);

        // Retry the operation with the new token
        return await operation(newToken);
      }
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
    String? tableId,
  }) {
    final sessionId = tableId != null ? _cartService.tableSessionIds[tableId] : null;
    return {
      'mutation_id': mutationId,
      'mutation_sequence': 0,
      'runtime_version': 1,
      'session_id': sessionId ?? _uuid.v4(), // Client generated trace session or cached DB session ID
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
    if (tableId == PosConstants.counterTableId ||
        PosConstants.isCounterTable(tableId)) {
      return _getOrCreateMockCart(tenantId, branchId, tableId);
    }
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _getOrCreateMockCart(tenantId, branchId, tableId);
    }

    try {
      return await _executeWithRetry(
        branchId: branchId,
        tableId: tableId,
        operation: (token) => _cartService.fetchCart(token),
      );
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
    if (tableId == PosConstants.counterTableId ||
        PosConstants.isCounterTable(tableId)) {
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
      return await _executeWithRetry(
        branchId: branchId,
        tableId: tableId,
        operation: (token) async {
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
            'item_notes': itemNotes ?? '',
            'modifiers': modifiersPayload,
          };

          final envelope = _buildMutationEnvelope(
            tenantId: tenantId,
            branchId: branchId,
            sessionToken: token,
            expectedCartRevision: expectedCartRevision,
            mutationId: mutationId,
            payload: payload,
            tableId: tableId,
          );

          return await _cartService.addCartItem(
            qrSessionToken: token,
            mutationId: mutationId,
            expectedCartRevision: expectedCartRevision,
            mutationEnvelopeBody: envelope,
          );
        },
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
    if (tableId == PosConstants.counterTableId ||
        PosConstants.isCounterTable(tableId)) {
      return _updateMockCartItem(
        tableId: tableId,
        itemId: itemId,
        quantity: quantity,
        itemNotes: itemNotes,
        expectedCartRevision: expectedCartRevision,
      );
    }
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
      return await _executeWithRetry(
        branchId: branchId,
        tableId: tableId,
        operation: (token) async {
          final mutationId = _uuid.v4();

          final payload = {
            'quantity': quantity,
            'item_notes': itemNotes ?? '',
            'version_num': itemVersionNum,
          };

          final envelope = _buildMutationEnvelope(
            tenantId: tenantId,
            branchId: branchId,
            sessionToken: token,
            expectedCartRevision: expectedCartRevision,
            mutationId: mutationId,
            payload: payload,
            tableId: tableId,
          );

          return await _cartService.updateCartItem(
            qrSessionToken: token,
            itemId: itemId,
            mutationId: mutationId,
            expectedCartRevision: expectedCartRevision,
            mutationEnvelopeBody: envelope,
          );
        },
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
    if (tableId == PosConstants.counterTableId ||
        PosConstants.isCounterTable(tableId)) {
      return _removeMockCartItem(
        tableId: tableId,
        itemId: itemId,
        expectedCartRevision: expectedCartRevision,
      );
    }
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _removeMockCartItem(
        tableId: tableId,
        itemId: itemId,
        expectedCartRevision: expectedCartRevision,
      );
    }

    try {
      return await _executeWithRetry(
        branchId: branchId,
        tableId: tableId,
        operation: (token) async {
          final mutationId = _uuid.v4();

          final payload = {
            'version_num': itemVersionNum,
          };

          final envelope = _buildMutationEnvelope(
            tenantId: tenantId,
            branchId: branchId,
            sessionToken: token,
            expectedCartRevision: expectedCartRevision,
            mutationId: mutationId,
            payload: payload,
            tableId: tableId,
          );

          return await _cartService.removeCartItem(
            qrSessionToken: token,
            itemId: itemId,
            mutationId: mutationId,
            expectedCartRevision: expectedCartRevision,
            mutationEnvelopeBody: envelope,
          );
        },
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
    if (tableId == PosConstants.counterTableId ||
        PosConstants.isCounterTable(tableId)) {
      return _updateMockCartNotes(
        tableId: tableId,
        orderNotes: orderNotes,
        expectedCartRevision: expectedCartRevision,
      );
    }
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _updateMockCartNotes(
        tableId: tableId,
        orderNotes: orderNotes,
        expectedCartRevision: expectedCartRevision,
      );
    }

    try {
      return await _executeWithRetry(
        branchId: branchId,
        tableId: tableId,
        operation: (token) async {
          final mutationId = _uuid.v4();

          final payload = {
            'order_notes': orderNotes ?? '',
            'version_num': expectedCartRevision,
          };

          final envelope = _buildMutationEnvelope(
            tenantId: tenantId,
            branchId: branchId,
            sessionToken: token,
            expectedCartRevision: expectedCartRevision,
            mutationId: mutationId,
            payload: payload,
            tableId: tableId,
          );

          return await _cartService.updateCartNotes(
            qrSessionToken: token,
            mutationId: mutationId,
            expectedCartRevision: expectedCartRevision,
            mutationEnvelopeBody: envelope,
          );
        },
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

  /// Syncs an in-memory/mock cart to the backend by resolving a session,
  /// initializing/fetching the cart, and inserting all items.
  Future<Cart> syncCartToBackend({
    required String tenantId,
    required String branchId,
    required String tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    // 1. Resolve QR session token for the counter table (real API calls)
    final sessionToken = await _cartService.resolveQrSessionForTableRaw(branchId, tableId);
    
    // 2. Fetch the cart to initialize it on backend
    Cart cart = await _cartService.fetchCart(sessionToken);
    
    // 3. Add all items to the backend cart
    for (final item in items) {
      final menuItem = item['menuItem'] as MenuItem;
      final quantity = item['quantity'] as int;
      final notes = item['notes'] as String?;
      final selectedModifiers = item['selectedModifiers'] as List<String>;

      final mutationId = _uuid.v4();
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
          modifiersPayload.add({
            'modifier_group_id': _uuid.v4(),
            'modifier_option_id': _uuid.v4(),
          });
        }
      }

      final payload = {
        'menu_item_id': menuItem.id,
        'quantity': quantity,
        'item_notes': notes ?? '',
        'modifiers': modifiersPayload,
      };

      final envelope = _buildMutationEnvelope(
        tenantId: tenantId,
        branchId: branchId,
        sessionToken: sessionToken,
        expectedCartRevision: cart.versionNum,
        mutationId: mutationId,
        payload: payload,
        tableId: tableId,
      );

      cart = await _cartService.addCartItem(
        qrSessionToken: sessionToken,
        mutationId: mutationId,
        expectedCartRevision: cart.versionNum,
        mutationEnvelopeBody: envelope,
      );
    }
    
    return cart;
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

  Cart _recalculateMockCartTotals(Cart cart) {
    int subtotalMinor = 0;
    for (final item in cart.items) {
      int itemPriceMinor = item.unitPriceMinorSnapshot;
      for (final mod in item.modifiers) {
        itemPriceMinor += mod.priceDeltaMinorSnapshot;
      }
      subtotalMinor += itemPriceMinor * item.quantity;
    }
    
    // Simple 5% tax calculation for mock
    int taxMinor = (subtotalMinor * 0.05).round();
    int grandTotalMinor = subtotalMinor + taxMinor;
    
    return cart.copyWith(
      subtotalMinor: subtotalMinor,
      totalTaxMinor: taxMinor,
      grandTotalMinor: grandTotalMinor,
    );
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

    final updated = _recalculateMockCartTotals(current.copyWith(
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
      items: list,
    ));
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

    final updated = _recalculateMockCartTotals(current.copyWith(
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
      items: updatedItems,
    ));
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

    final updated = _recalculateMockCartTotals(current.copyWith(
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
      items: updatedItems,
    ));
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

    final updated = _recalculateMockCartTotals(current.copyWith(
      orderNotes: orderNotes,
      versionNum: current.versionNum + 1,
      updatedAt: DateTime.now(),
    ));
    _mockCarts[tableId] = updated;
    return updated;
  }
}


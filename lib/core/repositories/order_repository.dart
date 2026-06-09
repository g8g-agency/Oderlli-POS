import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../constants/app_config.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';
import '../services/connectivity_service.dart';
import '../services/secure_storage_service.dart';
import 'cart_repository.dart'; // Exceptions

class OrderRepository {
  final OrderService _orderService;
  final CartService _cartService;
  final ConnectivityService _connectivityService;
  final SecureStorageService _secureStorage;
  final Uuid _uuid = const Uuid();

  // Local cache of QR Session tokens per table
  final Map<String, String> _tableSessionTokens = {};

  // Mock list of orders for fallback in debug mode only
  final List<Order> _mockOrders = [];

  OrderRepository(
    this._orderService,
    this._cartService,
    this._connectivityService,
    this._secureStorage,
  );

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

    throw CartValidationException(e.message ?? 'Unknown order error');
  }

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
      'session_id': _uuid.v4(),
      'tenant_id': tenantId,
      'branch_id': branchId,
      'client_timestamp': DateTime.now().toUtc().toIso8601String(),
      'idempotency_key': mutationId,
      'expected_cart_revision': expectedCartRevision,
      'payload': payload,
    };
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// POST /api/v1/orders/checkout
  Future<Order> checkout({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String cartId,
    required int expectedCartRevision,
    String? orderNotes,
  }) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _checkoutMock(
        tenantId: tenantId,
        branchId: branchId,
        tableId: tableId,
        cartId: cartId,
        orderNotes: orderNotes,
      );
    }

    try {
      final staffToken = await _secureStorage.getRuntimeToken();
      if (staffToken == null || staffToken.isEmpty) {
        throw const CartValidationException(
          'Not authenticated. Please log in with your PIN again.',
        );
      }

      final sessionToken = await _getOrResolveSessionToken(branchId, tableId);
      final mutationId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      final payload = {
        'cartId': cartId,
        'tableId': tableId,
        'orderNotes': ?orderNotes,
      };

      final envelope = _buildMutationEnvelope(
        tenantId: tenantId,
        branchId: branchId,
        sessionToken: sessionToken,
        expectedCartRevision: expectedCartRevision,
        mutationId: mutationId,
        payload: payload,
      );

      return await _orderService.checkout(
        staffToken: staffToken,
        mutationId: mutationId,
        idempotencyKey: idempotencyKey,
        expectedCartRevision: expectedCartRevision,
        mutationEnvelopeBody: envelope,
      );
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _checkoutMock(
          tenantId: tenantId,
          branchId: branchId,
          tableId: tableId,
          cartId: cartId,
          orderNotes: orderNotes,
        );
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// GET /api/v1/orders
  Future<List<OrderSummary>> getOrders({
    required String branchId,
    String? status,
  }) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _getMockOrderSummaries(status);
    }

    try {
      return await _orderService.fetchOrders(branchId: branchId, status: status);
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _getMockOrderSummaries(status);
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// GET /api/v1/orders/:id
  Future<OrderDetail> getOrderDetail(String orderId) async {
    final useFallback = await _shouldUseMockFallback();
    if (useFallback) {
      return _getMockOrderDetail(orderId);
    }

    try {
      return await _orderService.fetchOrderDetail(orderId);
    } on DioException catch (e) {
      _checkForSchemaMismatch(e);
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _getMockOrderDetail(orderId);
      }
      _handleDioException(e);
      rethrow;
    }
  }

  // ─── Mock Fallback Implementations (Debug Mode Only) ──────────────────────────

  Order _checkoutMock({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String cartId,
    String? orderNotes,
  }) {
    final mockOrder = Order(
      id: 'ord-${_uuid.v4()}',
      tableId: tableId,
      tableNumber: 1, // Default table number
      items: const [],
      createdAt: DateTime.now(),
      status: OrderStatus.pending,
      notes: orderNotes,
      subtotalMinor: 1500,
      taxTotalMinor: 75,
      discountTotalMinor: 0,
      grandTotalMinor: 1575,
    );
    _mockOrders.add(mockOrder);
    return mockOrder;
  }

  List<OrderSummary> _getMockOrderSummaries(String? status) {
    return _mockOrders.where((o) {
      if (status == null) return true;
      return serializeOrderStatus(o.status) == status;
    }).map((o) {
      return OrderSummary(
        id: o.id,
        orderNumber: o.orderNumber ?? 'ORD-MOCK',
        status: o.status,
        createdAt: o.createdAt,
        tableId: o.tableId,
        orderNotes: o.notes,
        grandTotalMinor: o.grandTotalMinor,
      );
    }).toList();
  }

  OrderDetail _getMockOrderDetail(String orderId) {
    final order = _mockOrders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => Order(
        id: orderId,
        tableId: 'table-mock',
        tableNumber: 1,
        items: const [],
        createdAt: DateTime.now(),
        subtotalMinor: 1500,
        taxTotalMinor: 75,
        discountTotalMinor: 0,
        grandTotalMinor: 1575,
      ),
    );
    return OrderDetail(
      id: order.id,
      tenantId: 'tenant-mock',
      branchId: 'branch-mock',
      tableId: order.tableId,
      orderSnapshotId: 'snap-mock',
      orderNumber: order.orderNumber ?? 'ORD-MOCK',
      status: order.status,
      source: 'staff_pos',
      orderNotes: order.notes,
      versionNum: 1,
      createdAt: order.createdAt,
      updatedAt: DateTime.now(),
      subtotalMinor: order.subtotalMinor,
      taxTotalMinor: order.taxTotalMinor,
      discountTotalMinor: order.discountTotalMinor,
      grandTotalMinor: order.grandTotalMinor,
      items: const [],
    );
  }
}

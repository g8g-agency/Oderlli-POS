import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/constants/app_config.dart';
import '../models/kitchen_item.dart';
import '../models/kitchen_item_status.dart';
import '../models/kitchen_ticket.dart';
import '../models/kitchen_ticket_status.dart';
import '../services/kitchen_service.dart';

// ─── Domain exceptions ─────────────────────────────────────────────────────────

/// Thrown when the backend returns 404 for a ticket.
class KitchenTicketNotFoundException implements Exception {
  const KitchenTicketNotFoundException(this.ticketId);
  final String ticketId;
  @override
  String toString() => 'KitchenTicketNotFoundException: ticket $ticketId not found';
}

/// Thrown when the backend returns 409 STALE_RUNTIME_STATE.
class StaleKitchenStateException implements Exception {
  const StaleKitchenStateException();
  @override
  String toString() => 'StaleKitchenStateException: concurrent modification detected — refresh required';
}

/// Thrown for validation errors (invalid FSM transition, etc.).
class KitchenValidationException implements Exception {
  const KitchenValidationException(this.message);
  final String message;
  @override
  String toString() => 'KitchenValidationException: $message';
}

// ─── Repository ────────────────────────────────────────────────────────────────

class KitchenRepository {
  final KitchenService _service;
  final ConnectivityService _connectivity;

  KitchenRepository(this._service, this._connectivity);

  Future<bool> _shouldUseMockFallback() async {
    if (!kDebugMode || !AppConfig.allowMockFallbackInDebug) return false;
    final reachable = await _connectivity.isBackendReachable(
      AppConfig.baseUrl,
      AppConfig.healthEndpoint,
    );
    return !reachable;
  }

  void _handleDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 404) {
      final ticketId = e.requestOptions.path.split('/').lastWhere(
            (s) => s.isNotEmpty,
            orElse: () => 'unknown',
          );
      throw KitchenTicketNotFoundException(ticketId);
    }

    if (statusCode == 409) {
      throw const StaleKitchenStateException();
    }

    if (statusCode == 400 || statusCode == 422) {
      final data = e.response?.data;
      String msg = 'Validation error';
      if (data is Map<String, dynamic> && data['error'] != null) {
        msg = (data['error']['message'] ?? msg) as String;
      }
      throw KitchenValidationException(msg);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const KitchenValidationException('Network unavailable — check your connection');
    }

    throw KitchenValidationException(e.message ?? 'Unknown kitchen error');
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// GET /api/v1/kitchen/tickets
  Future<List<KitchenTicket>> getTickets({
    required String branchId,
    String? status,
    String? stationId,
  }) async {
    if (await _shouldUseMockFallback()) {
      return _mockTickets();
    }

    try {
      return await _service.fetchTickets(
        branchId: branchId,
        status: status,
        stationId: stationId,
      );
    } on DioException catch (e) {
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _mockTickets();
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// GET /api/v1/kitchen/tickets/:id
  Future<KitchenTicket> getTicket(String ticketId) async {
    if (await _shouldUseMockFallback()) {
      return _mockTickets().firstWhere(
        (t) => t.ticketId == ticketId,
        orElse: () => throw KitchenTicketNotFoundException(ticketId),
      );
    }

    try {
      return await _service.fetchTicket(ticketId);
    } on DioException catch (e) {
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        return _mockTickets().first;
      }
      _handleDioException(e);
      rethrow;
    }
  }

  /// PATCH /api/v1/kitchen/tickets/:id/status
  /// Validates the FSM transition before calling the backend.
  Future<KitchenTicket> bumpTicket(
    String ticketId,
    KitchenTicketStatus newStatus,
  ) async {
    if (await _shouldUseMockFallback()) {
      // In mock mode, return a mutated copy
      return KitchenTicket.mock(
        ticketId: ticketId,
        tableNumber: '1',
        orderNumber: 'ORD-MOCK',
        status: newStatus,
        items: const [],
      );
    }

    try {
      return await _service.transitionTicketStatus(ticketId, newStatus);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  /// PATCH /api/v1/kitchen/tickets/:id/items/:itemId/status
  Future<void> bumpItem(
    String ticketId,
    String itemId,
    KitchenItemStatus newStatus,
  ) async {
    if (await _shouldUseMockFallback()) return;

    try {
      await _service.transitionItemStatus(ticketId, itemId, newStatus);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  // ── Mock data (debug fallback) ────────────────────────────────────────────────

  List<KitchenTicket> _mockTickets() => [
        KitchenTicket.mock(
          ticketId: 'kds-mock-001',
          tableNumber: '3',
          orderNumber: 'ORD-1001',
          status: KitchenTicketStatus.pending,
          elapsedSeconds: 120,
          items: [
            KitchenItem.mock(preparationId: 'prep-a1', name: 'Grilled Salmon', quantity: 2),
            KitchenItem.mock(preparationId: 'prep-a2', name: 'Caesar Salad', quantity: 1),
            KitchenItem.mock(preparationId: 'prep-a3', name: 'Sparkling Water', quantity: 2),
          ],
        ),
        KitchenTicket.mock(
          ticketId: 'kds-mock-002',
          tableNumber: '7',
          orderNumber: 'ORD-1002',
          status: KitchenTicketStatus.preparing,
          elapsedSeconds: 900,
          items: [
            KitchenItem.mock(
              preparationId: 'prep-b1',
              name: 'BBQ Ribs Half-Rack',
              quantity: 2,
              notes: 'Extra sauce',
            ),
            KitchenItem.mock(preparationId: 'prep-b2', name: 'Garlic Bread', quantity: 2),
          ],
        ),
        KitchenTicket.mock(
          ticketId: 'kds-mock-003',
          tableNumber: '11',
          orderNumber: 'ORD-1003',
          status: KitchenTicketStatus.ready,
          elapsedSeconds: 1320,
          isOverdue: true,
          priority: 5,
          items: [
            KitchenItem.mock(preparationId: 'prep-c1', name: 'Mushroom Risotto', quantity: 1),
            KitchenItem.mock(preparationId: 'prep-c2', name: 'Tiramisu', quantity: 2),
          ],
        ),
        KitchenTicket.mock(
          ticketId: 'kds-mock-004',
          tableNumber: '5',
          orderNumber: 'ORD-1004',
          status: KitchenTicketStatus.preparing,
          elapsedSeconds: 600,
          items: [
            KitchenItem.mock(preparationId: 'prep-d1', name: 'Margherita Pizza', quantity: 1),
            KitchenItem.mock(
              preparationId: 'prep-d2',
              name: 'Espresso',
              quantity: 2,
              notes: 'Double shot',
            ),
          ],
        ),
      ];
}

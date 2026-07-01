import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/dio_client.dart';
import '../models/kitchen_ticket.dart';
import '../models/kitchen_ticket_status.dart';
import '../models/kitchen_item_status.dart';

class KitchenService {
  final DioClient _dioClient;
  final _uuid = const Uuid();

  KitchenService(this._dioClient);

  DioClient get dioClient => _dioClient;

  // ── GET /api/v1/kitchen/tickets ─────────────────────────────────────────────

  /// Fetches the active kitchen queue. Optionally filter by [status] or [stationId].
  Future<List<KitchenTicket>> fetchTickets({
    required String branchId,
    String? status,
    String? stationId,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/v1/kitchen/tickets',
      queryParameters: {
        'branchId': branchId,
        'status': status,
        'stationId': stationId,
      },
    );
    _assertSuccess(response);

    final rawList = (response.data['data']['queue'] as List<dynamic>?) ?? [];
    return rawList
        .map((e) => KitchenTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /api/v1/kitchen/tickets/:id ─────────────────────────────────────────

  /// Fetches the full details of a single kitchen ticket.
  Future<KitchenTicket> fetchTicket(String ticketId) async {
    final response = await _dioClient.dio.get(
      '/api/v1/kitchen/tickets/$ticketId',
    );
    _assertSuccess(response);

    final rawTicket = response.data['data']['ticket'] as Map<String, dynamic>;
    return KitchenTicket.fromJson(rawTicket);
  }

  // ── PATCH /api/v1/kitchen/tickets/:id/status ─────────────────────────────────

  /// Transitions a ticket header to [newStatus].
  /// Uses MutationEnvelope pattern with [X-Mutation-Id] header.
  Future<KitchenTicket> transitionTicketStatus(
    String ticketId,
    KitchenTicketStatus newStatus, {
    String? mutationId,
  }) async {
    final mid = mutationId ?? _uuid.v4();

    final response = await _dioClient.dio.patch(
      '/api/v1/kitchen/tickets/$ticketId/status',
      data: {
        'status': serializeKitchenTicketStatus(newStatus),
      },
      options: Options(
        headers: {
          'X-Mutation-Id': mid,
        },
      ),
    );
    _assertSuccess(response);

    final rawTicket = response.data['data']['ticket'] as Map<String, dynamic>?;
    if (rawTicket != null) {
      return KitchenTicket.fromJson(rawTicket);
    }
    // Backend may return minimal payload — fetch fresh ticket
    return fetchTicket(ticketId);
  }

  // ── PATCH /api/v1/kitchen/tickets/:id/items/:itemId/status ──────────────────

  /// Transitions a single item preparation to [newStatus].
  Future<void> transitionItemStatus(
    String ticketId,
    String itemId,
    KitchenItemStatus newStatus,
  ) async {
    final mid = _uuid.v4();

    final response = await _dioClient.dio.patch(
      '/api/v1/kitchen/tickets/$ticketId/items/$itemId/status',
      data: {
        'status': serializeKitchenItemStatus(newStatus),
      },
      options: Options(
        headers: {
          'X-Mutation-Id': mid,
        },
      ),
    );
    _assertSuccess(response);
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null ||
        (response.data['success'] != true && response.data['status'] != 'success')) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Kitchen API returned an unexpected response',
      );
    }
  }
}

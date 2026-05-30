import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../models/kitchen_item_status.dart';
import '../models/kitchen_ticket.dart';
import '../models/kitchen_ticket_status.dart';
import '../repositories/kitchen_repository.dart';
import '../services/kitchen_service.dart';

// ─── Sentinel for nullable-copyWith pattern ───────────────────────────────────
const Object _sentinel = Object();

// ─── Infrastructure providers ─────────────────────────────────────────────────

final kitchenServiceProvider = Provider<KitchenService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return KitchenService(dioClient);
});

final kitchenRepositoryProvider = Provider<KitchenRepository>((ref) {
  final service = ref.watch(kitchenServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return KitchenRepository(service, connectivity);
});

// ─── State ────────────────────────────────────────────────────────────────────

class KitchenState {
  const KitchenState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
    this.lastRefreshed,
    this.statusFilter,
    this.stationFilter,
  });

  final List<KitchenTicket> tickets;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshed;
  final KitchenTicketStatus? statusFilter;
  final String? stationFilter;

  List<KitchenTicket> get activeTickets =>
      tickets.where((t) => t.status != KitchenTicketStatus.delivered).toList();

  List<KitchenTicket> get filteredTickets {
    var result = activeTickets;
    if (statusFilter != null) {
      result = result.where((t) => t.status == statusFilter).toList();
    }
    if (stationFilter != null) {
      result = result
          .where((t) => t.items.any((i) => i.stationId == stationFilter))
          .toList();
    }
    return result;
  }

  int get pendingCount =>
      activeTickets.where((t) => t.status == KitchenTicketStatus.pending).length;
  int get preparingCount =>
      activeTickets.where((t) => t.status == KitchenTicketStatus.preparing).length;
  int get readyCount =>
      activeTickets.where((t) => t.status == KitchenTicketStatus.ready).length;
  int get overdueCount => activeTickets.where((t) => t.isOverdue).length;

  KitchenState copyWith({
    List<KitchenTicket>? tickets,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastRefreshed,
    // Use _sentinel to distinguish "not passed" from "explicitly set to null"
    Object? statusFilter = _sentinel,
    Object? stationFilter = _sentinel,
  }) =>
      KitchenState(
        tickets: tickets ?? this.tickets,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        lastRefreshed: lastRefreshed ?? this.lastRefreshed,
        statusFilter: statusFilter == _sentinel
            ? this.statusFilter
            : statusFilter as KitchenTicketStatus?,
        stationFilter: stationFilter == _sentinel
            ? this.stationFilter
            : stationFilter as String?,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class KitchenNotifier extends StateNotifier<KitchenState> {
  final KitchenRepository _repository;

  KitchenNotifier(this._repository) : super(const KitchenState()) {
    loadTickets();
  }

  /// Initial load — shows loading spinner.
  Future<void> loadTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchTickets();
  }

  /// Silent background refresh — no spinner shown.
  Future<void> refreshTickets() async {
    await _fetchTickets(silent: true);
  }

  Future<void> _fetchTickets({bool silent = false}) async {
    try {
      final tickets = await _repository.getTickets(
        status: state.statusFilter != null
            ? serializeKitchenTicketStatus(state.statusFilter!)
            : null,
        stationId: state.stationFilter,
      );
      state = state.copyWith(
        tickets: tickets,
        isLoading: false,
        clearError: true,
        lastRefreshed: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[KitchenNotifier] fetch error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Bumps a ticket to its next FSM state with optimistic update.
  /// On 409 StaleKitchenStateException, refreshes automatically.
  Future<void> bumpTicket(String ticketId, KitchenTicketStatus newStatus) async {
    // 1. Optimistic update — apply locally first
    _applyOptimisticTicketStatus(ticketId, newStatus);

    try {
      // 2. Call backend
      final updated = await _repository.bumpTicket(ticketId, newStatus);

      if (newStatus == KitchenTicketStatus.delivered) {
        // Remove from active queue on confirmation
        state = state.copyWith(
          tickets: state.tickets.where((t) => t.ticketId != ticketId).toList(),
        );
      } else {
        // Replace with server-confirmed ticket
        state = state.copyWith(
          tickets: [
            for (final t in state.tickets)
              if (t.ticketId == ticketId) updated else t,
          ],
        );
      }
    } on StaleKitchenStateException {
      // 3. Stale state — refresh to get latest
      await refreshTickets();
    } catch (e) {
      if (kDebugMode) debugPrint('[KitchenNotifier] bumpTicket error: $e');
      // 4. On any other error — roll back by refreshing
      await refreshTickets();
    }
  }

  /// Bumps an item to a new status, then refreshes to pick up server rollup.
  Future<void> bumpItem(
    String ticketId,
    String itemId,
    KitchenItemStatus newStatus,
  ) async {
    try {
      await _repository.bumpItem(ticketId, itemId, newStatus);
      // Refresh so backend auto-rollup (ticket→ready) is reflected
      await refreshTickets();
    } catch (e) {
      if (kDebugMode) debugPrint('[KitchenNotifier] bumpItem error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Applies a status filter. Pass `null` to clear.
  void setStatusFilter(KitchenTicketStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  /// Applies a station filter. Pass `null` to clear.
  void setStationFilter(String? stationId) {
    state = state.copyWith(stationFilter: stationId);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _applyOptimisticTicketStatus(String ticketId, KitchenTicketStatus newStatus) {
    state = state.copyWith(
      tickets: [
        for (final t in state.tickets)
          if (t.ticketId == ticketId) t.copyWith(status: newStatus) else t,
      ],
    );
  }
}

// ─── Main provider ────────────────────────────────────────────────────────────

final kitchenProvider =
    StateNotifierProvider<KitchenNotifier, KitchenState>((ref) {
  final repo = ref.watch(kitchenRepositoryProvider);
  return KitchenNotifier(repo);
});

// ─── Derived providers ────────────────────────────────────────────────────────

/// Active tickets (excludes delivered).
final activeKitchenTicketsProvider = Provider<List<KitchenTicket>>((ref) {
  return ref.watch(kitchenProvider).activeTickets;
});

/// Tickets filtered by a specific status.
final kitchenTicketsByStatusProvider =
    Provider.family<List<KitchenTicket>, KitchenTicketStatus>((ref, status) {
  return ref
      .watch(kitchenProvider)
      .activeTickets
      .where((t) => t.status == status)
      .toList();
});

/// Overdue tickets only.
final overdueKitchenTicketsProvider = Provider<List<KitchenTicket>>((ref) {
  return ref
      .watch(kitchenProvider)
      .activeTickets
      .where((t) => t.isOverdue)
      .toList();
});

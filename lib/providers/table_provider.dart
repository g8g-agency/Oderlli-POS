import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/services/table_service.dart';
import '../core/repositories/table_repository.dart';
import '../screens/login/employee_login_screen.dart';
import 'auth_provider.dart';
import 'orders_provider.dart';
import 'pos_cart_provider.dart';

// ─── Infrastructure Providers ─────────────────────────────────

final tableServiceProvider = Provider<TableService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TableService(dioClient);
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final service = ref.watch(tableServiceProvider);
  // Recreate repository if auth state changes, effectively clearing the cache on session change
  ref.watch(authProvider);
  final repo = TableRepository(service);
  TableRepository.resetCircuitBreaker(ref: ref);
  return repo;
});

final _tablesSessionIdsProvider = Provider<({String? tenantId, String? branchId})>((ref) {
  final authState = ref.watch(authProvider);
  return (tenantId: authState.tenantId, branchId: authState.branchId);
});

// ─── Metadata Providers ───────────────────────────────────────

final floorsProvider = FutureProvider<List<TableFloor>>((ref) async {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.fetchFloors();
});

final sectionsProvider = FutureProvider<List<TableSection>>((ref) async {
  final repo = ref.watch(tableRepositoryProvider);
  final authState = ref.watch(authProvider);
  return repo.fetchSections(branchId: authState.branchId);
});

// ─── POS Tables State Provider ────────────────────────────────

final posTablesProvider = AsyncNotifierProvider<POSTablesNotifier, List<TableModel>>(
  POSTablesNotifier.new,
);

class POSTablesNotifier extends AsyncNotifier<List<TableModel>> {
  @override
  Future<List<TableModel>> build() async {
    return _fetch();
  }

  Future<List<TableModel>> _fetch() async {
    final ids = ref.watch(_tablesSessionIdsProvider);
    final branchId = ids.branchId;

    if (branchId == null) {
      throw Exception('No branchId context configured. Please verify your login session.');
    }

    try {
      final repo = ref.read(tableRepositoryProvider);
      return await repo.fetchTables(branchId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[posTablesProvider] fetchTables failed: $e');
      }
      rethrow;
    }
  }

  Future<void> refreshTables() async {
    TableRepository.resetCircuitBreaker(force: true);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  // Mutate local state so the UI reflects changes (optimistic updates/mock operations)
  void updateStatus(String tableId, POSTableStatus status) {
    final currentList = state.valueOrNull;
    if (currentList != null) {
      state = AsyncValue.data(
        currentList.map((t) => t.id == tableId ? t.copyWith(status: status) : t).toList(),
      );
    }
  }

  void updateBill(String tableId, double amount) {
    final currentList = state.valueOrNull;
    if (currentList != null) {
      state = AsyncValue.data(
        currentList.map((t) => t.id == tableId ? t.copyWith(billTotal: amount) : t).toList(),
      );
    }
  }

  void seatTable(String tableId, int guestCount, String waiter) {
    final currentList = state.valueOrNull;
    if (currentList != null) {
      state = AsyncValue.data(
        currentList.map((t) => t.id == tableId
            ? t.copyWith(
                status: POSTableStatus.occupied,
                guestCount: guestCount,
                waiterName: waiter,
                occupiedSince: DateTime.now(),
              )
            : t).toList(),
      );
    }
  }

  Future<void> clearTable(String tableId) async {
    // 1. Optimistic update — mark table as available immediately in UI
    final currentList = state.valueOrNull;
    if (currentList != null) {
      state = AsyncValue.data(
        currentList.map((t) =>
          t.id == tableId
              ? t.copyWith(
                  status: POSTableStatus.available,
                  guestCount: 0,
                  waiterName: null,
                  occupiedSince: null,
                  billTotal: 0.0,
                )
              : t
        ).toList(),
      );
    }

    try {
      // 2. Evict QR session cache for this table
      ref.read(cartRepositoryProvider).evictTableSession(tableId);

      // 3. Call backend vacate
      await ref.read(tableRepositoryProvider).vacateTable(tableId);

      // 4. Re-fetch verified state from backend
      await refreshTables();
    } catch (e) {
      // 5. ROLLBACK — revert optimistic update by re-fetching real state
      await refreshTables();
      rethrow;
    }
  }
}

// ─── Filter / Search Providers ────────────────────────────────

final posSelectedSectionProvider = StateProvider<String?>((ref) => null);

final posFilteredTablesProvider = Provider<List<TableModel>>((ref) {
  final tablesAsync = ref.watch(posTablesProvider);
  final tables = tablesAsync.valueOrNull ?? [];
  final section = ref.watch(posSelectedSectionProvider);
  if (section == null) return tables;
  
  if (tables.any((t) => t.sectionName != null)) {
    return tables.where((t) => t.sectionName == section).toList();
  }
  
  if (section == 'Indoor') {
    return tables.where((t) => t.number <= 6).toList();
  } else {
    return tables.where((t) => t.number > 6).toList();
  }
});

final posTableSectionsProvider = Provider<List<String>>((ref) {
  final sectionsAsync = ref.watch(sectionsProvider);
  final sections = sectionsAsync.valueOrNull ?? [];
  if (sections.isEmpty) {
    return ['Indoor', 'Terrace'];
  }
  return sections.map((s) => s.name).toList();
});

// ─── Legacy / Dashboard Bridge Providers ───────────────────────

/// All restaurant tables mapped to RestaurantTable for dashboard components.
final tablesProvider = Provider<List<RestaurantTable>>((ref) {
  final posTablesAsync = ref.watch(posTablesProvider);
  final posTables = posTablesAsync.valueOrNull ?? [];

  return posTables.map((t) {
    TableStatus mapStatus(POSTableStatus status) {
      return switch (status) {
        POSTableStatus.available => TableStatus.available,
        POSTableStatus.occupied => TableStatus.occupied,
        POSTableStatus.preparing => TableStatus.occupied,
        POSTableStatus.ready => TableStatus.occupied,
        POSTableStatus.paymentPending => TableStatus.occupied,
      };
    }

    return RestaurantTable(
      id: t.id,
      number: t.number,
      capacity: t.capacity,
      status: mapStatus(t.status),
      section: t.sectionName,
      currentOrderId: null,
      occupiedSince: t.occupiedSince,
      reservedFor: null,
    );
  }).toList();
});

/// Selected section filter (null = all).
final selectedSectionProvider = StateProvider<String?>((ref) => null);

/// Tables filtered by section.
final filteredTablesProvider = Provider<List<RestaurantTable>>((ref) {
  final tables = ref.watch(tablesProvider);
  final section = ref.watch(selectedSectionProvider);
  if (section == null) return tables;
  return tables.where((t) => t.section == section).toList();
});

/// Unique section names derived from the table list.
final tableSectionsProvider = Provider<List<String>>((ref) {
  final tables = ref.watch(tablesProvider);
  return tables
      .map((t) => t.section)
      .whereType<String>()
      .toSet()
      .toList();
});

final liveTableStatusProvider = Provider<List<TableModel>>((ref) {
  final tables = ref.watch(posTablesProvider).valueOrNull ?? [];
  final orders = ref.watch(ordersProvider);
  final staffList = ref.watch(staffListProvider).valueOrNull ?? [];

  // Build a lookup: tableId -> most-recent active order
  final Map<String, Order> activeOrderByTable = {};
  for (final order in orders) {
    if (order.status == OrderStatus.served ||
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      continue;
    }
    final existing = activeOrderByTable[order.tableId];
    if (existing == null || order.createdAt.isAfter(existing.createdAt)) {
      activeOrderByTable[order.tableId] = order;
    }
  }

  return tables.map((table) {
    String? resolvedWaiterName;
    if (table.assignedWaiterId != null) {
      final waiter = staffList.where((s) => s.id == table.assignedWaiterId).firstOrNull;
      resolvedWaiterName = waiter?.name;
    }

    var enrichedTable = table.copyWith(
      assignedWaiterName: resolvedWaiterName,
    );

    final order = activeOrderByTable[table.id];
    if (order == null) return enrichedTable;

    // Derive status from order when it adds more precision than runtimeState
    POSTableStatus enrichedStatus = table.status;
    if (order.status != OrderStatus.served &&
        order.status != OrderStatus.completed &&
        order.status != OrderStatus.cancelled) {
      if (table.status == POSTableStatus.available) {
        enrichedStatus = POSTableStatus.occupied;
      }
    }

    return enrichedTable.copyWith(
      billTotal: order.total,
      occupiedSince: order.createdAt,
      status: enrichedStatus,
    );
  }).toList();
});

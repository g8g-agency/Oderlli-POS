import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock/mock_pos_data.dart';
import '../core/services/table_service.dart';
import '../core/repositories/table_repository.dart';
import 'auth_provider.dart';

// ─── Infrastructure Providers ─────────────────────────────────

final tableServiceProvider = Provider<TableService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TableService(dioClient);
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final service = ref.watch(tableServiceProvider);
  // Recreate repository if auth state changes, effectively clearing the cache on session change
  ref.watch(authProvider);
  return TableRepository(service);
});

final _tablesSessionIdsProvider = FutureProvider<({String? tenantId, String? branchId})>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final credentials = await secureStorage.getCredentials();
  final userJson = credentials['userJson'];
  if (userJson == null) return (tenantId: null, branchId: null);
  try {
    final decoded = jsonDecode(userJson) as Map<String, dynamic>;
    final backendUser = BackendUser.fromJson(decoded);
    final tenantId = backendUser.tenantId;
    final branchId = backendUser.branchIds.isNotEmpty ? backendUser.branchIds.first : null;
    return (tenantId: tenantId, branchId: branchId);
  } catch (e) {
    if (kDebugMode) debugPrint('[tablesProvider] Could not parse stored user: $e');
    return (tenantId: null, branchId: null);
  }
});

// ─── Metadata Providers ───────────────────────────────────────

final floorsProvider = FutureProvider<List<TableFloor>>((ref) async {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.fetchFloors();
});

final sectionsProvider = FutureProvider<List<TableSection>>((ref) async {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.fetchSections();
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
    final ids = await ref.watch(_tablesSessionIdsProvider.future);
    final branchId = ids.branchId;

    if (branchId == null) {
      if (kDebugMode) {
        debugPrint('[posTablesProvider] No branchId — using mock tables');
      }
      return MockPOSData.tables;
    }

    try {
      final repo = ref.read(tableRepositoryProvider);
      return await repo.fetchTables(branchId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[posTablesProvider] fetchTables failed ($e) — falling back to mock');
        return MockPOSData.tables;
      }
      rethrow;
    }
  }

  Future<void> refreshTables() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  // No-op local mutations as tables are read-only and backend is the sole source of truth
  void updateStatus(String tableId, POSTableStatus status) {
    if (kDebugMode) {
      debugPrint('[posTablesProvider] updateStatus ignored (read-only mode)');
    }
  }

  void updateBill(String tableId, double amount) {
    if (kDebugMode) {
      debugPrint('[posTablesProvider] updateBill ignored (read-only mode)');
    }
  }

  void seatTable(String tableId, int guestCount, String waiter) {
    if (kDebugMode) {
      debugPrint('[posTablesProvider] seatTable ignored (read-only mode)');
    }
  }

  void clearTable(String tableId) {
    if (kDebugMode) {
      debugPrint('[posTablesProvider] clearTable ignored (read-only mode)');
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

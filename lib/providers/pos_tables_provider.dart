import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock/mock_pos_data.dart';

/// All POS restaurant tables provider using [TableModel].
final posTablesProvider =
    StateNotifierProvider<POSTablesNotifier, List<TableModel>>(
  (ref) => POSTablesNotifier(MockPOSData.tables),
);

class POSTablesNotifier extends StateNotifier<List<TableModel>> {
  POSTablesNotifier(super.state);

  void updateStatus(String tableId, POSTableStatus status) {
    state = [
      for (final t in state)
        if (t.id == tableId) t.copyWith(status: status) else t,
    ];
  }

  void updateBill(String tableId, double amount) {
    state = [
      for (final t in state)
        if (t.id == tableId) t.copyWith(billTotal: amount) else t,
    ];
  }

  void seatTable(String tableId, int guestCount, String waiter) {
    state = [
      for (final t in state)
        if (t.id == tableId)
          t.copyWith(
            status: POSTableStatus.occupied,
            guestCount: guestCount,
            waiterName: waiter,
            occupiedSince: DateTime.now(),
            billTotal: 0.00,
          )
        else
          t,
    ];
  }

  void clearTable(String tableId) {
    state = [
      for (final t in state)
        if (t.id == tableId)
          t.copyWith(
            status: POSTableStatus.available,
            guestCount: 0,
            waiterName: null,
            occupiedSince: null,
            billTotal: 0.00,
          )
        else
          t,
    ];
  }
}

/// Selected floor plan section filter (null = all sections).
final posSelectedSectionProvider = StateProvider<String?>((ref) => null);

/// Filtered list of TableModel items.
final posFilteredTablesProvider = Provider<List<TableModel>>((ref) {
  final tables = ref.watch(posTablesProvider);
  final section = ref.watch(posSelectedSectionProvider);
  if (section == null) return tables;
  // Hardcoded sections mapping for mock tables (Indoor, Terrace)
  if (section == 'Indoor') {
    return tables.where((t) => t.number <= 6).toList();
  } else {
    return tables.where((t) => t.number > 6).toList();
  }
});

/// Unique floor plan sections.
final posTableSectionsProvider = Provider<List<String>>((ref) {
  return ['Indoor', 'Terrace'];
});

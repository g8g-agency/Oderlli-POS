import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';

/// All restaurant tables.
final tablesProvider =
    StateNotifierProvider<TablesNotifier, List<RestaurantTable>>(
  (ref) => TablesNotifier(MockData.tables),
);

class TablesNotifier extends StateNotifier<List<RestaurantTable>> {
  TablesNotifier(super.state);

  void updateStatus(String tableId, TableStatus status) {
    state = [
      for (final t in state)
        if (t.id == tableId) t.copyWith(status: status) else t,
    ];
  }

  void assignOrder(String tableId, String orderId) {
    state = [
      for (final t in state)
        if (t.id == tableId)
          t.copyWith(
            status: TableStatus.occupied,
            currentOrderId: orderId,
            occupiedSince: DateTime.now(),
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
            status: TableStatus.cleaning,
            currentOrderId: null,
            occupiedSince: null,
          )
        else
          t,
    ];
  }
}

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

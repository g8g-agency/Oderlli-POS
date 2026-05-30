import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../services/table_service.dart';

class TableRepository {
  final TableService _tableService;

  // Session-based caching of floors and sections
  List<TableFloor>? _cachedFloors;
  List<TableSection>? _cachedSections;

  TableRepository(this._tableService);

  /// Fetches floors, utilizing session cache if available.
  Future<List<TableFloor>> fetchFloors() async {
    if (_cachedFloors != null) {
      return _cachedFloors!;
    }
    try {
      final floors = await _tableService.fetchFloors();
      _cachedFloors = floors;
      return floors;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TableRepository] fetchFloors failed: $e');
      }
      rethrow;
    }
  }

  /// Fetches sections, utilizing session cache if available.
  Future<List<TableSection>> fetchSections() async {
    if (_cachedSections != null) {
      return _cachedSections!;
    }
    try {
      final sections = await _tableService.fetchSections();
      _cachedSections = sections;
      return sections;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TableRepository] fetchSections failed: $e');
      }
      rethrow;
    }
  }

  /// Fetches all active tables for the given branch and maps them to [TableModel].
  /// Enriches the tables with section and floor friendly names by resolving cached lists.
  Future<List<TableModel>> fetchTables(String branchId) async {
    try {
      // Fetch floors and sections in parallel (using cache when available)
      final results = await Future.wait([
        fetchFloors(),
        fetchSections(),
        _tableService.fetchTables(branchId),
      ]);

      final floors = results[0] as List<TableFloor>;
      final sections = results[1] as List<TableSection>;
      final apiTables = results[2] as List<PosTable>;

      final floorMap = {for (final f in floors) f.id: f.name};
      final sectionMap = {for (final s in sections) s.id: s.name};

      final List<TableModel> mappedTables = [];
      for (int i = 0; i < apiTables.length; i++) {
        final t = apiTables[i];
        final sectionName = t.sectionId != null ? sectionMap[t.sectionId] : null;
        final floorName = t.floorId != null ? floorMap[t.floorId] : null;

        mappedTables.add(
          TableModel(
            id: t.id,
            number: _parseTableNumber(t.tableNumber, i),
            capacity: t.capacity,
            status: _mapRuntimeState(t.runtimeState),
            guestCount: 0, // In backend runtime_state is derived; guestCount is read-only projection
            waiterName: null, // assignedWaiterId can be mapped to staff or left null if not needed
            occupiedSince: null, // Read-only from API, initialized to null if not exposed
            billTotal: 0.0,
            sectionName: sectionName,
            floorName: floorName,
          ),
        );
      }

      return mappedTables;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TableRepository] fetchTables failed: $e');
      }
      rethrow;
    }
  }

  POSTableStatus _mapRuntimeState(String? state) {
    if (state == null) return POSTableStatus.available;
    return switch (state.toUpperCase()) {
      'FREE' => POSTableStatus.available,
      'ACTIVE_GUESTS' => POSTableStatus.occupied,
      'ORDERING' => POSTableStatus.preparing,
      'PAYMENT_PENDING' => POSTableStatus.paymentPending,
      'ASSISTANCE_REQUESTED' => POSTableStatus.ready,
      _ => POSTableStatus.available,
    };
  }

  int _parseTableNumber(String tableNum, int index) {
    final parsed = int.tryParse(tableNum);
    if (parsed != null) return parsed;

    final digits = RegExp(r'\d+').firstMatch(tableNum)?.group(0);
    if (digits != null) {
      final parsedDigits = int.tryParse(digits);
      if (parsedDigits != null) return parsedDigits;
    }

    return index + 1;
  }
}

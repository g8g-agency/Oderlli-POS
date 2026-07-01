import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/providers.dart';

class RealtimeSyncService {
  RealtimeChannel? _channel;

  void subscribe(String branchId, Ref ref) {
    // Unsubscribe from any existing subscription first to prevent duplicates
    dispose();

    debugPrint('[RealtimeSyncService] Subscribing to realtime for branch: $branchId');
    try {
      _channel = Supabase.instance.client
          .channel('pos:branch:$branchId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tables',
            callback: (payload) {
              debugPrint('[RealtimeSyncService] Postgres changes detected on tables. Invalidating posTablesProvider.');
              ref.invalidate(posTablesProvider);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'table_runtime_projections',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'branch_id',
              value: branchId,
            ),
            callback: (payload) {
              debugPrint('[RealtimeSyncService] Postgres changes detected on table_runtime_projections. Refreshing posTablesProvider.');
              ref.read(posTablesProvider.notifier).refreshTables();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'branch_id',
              value: branchId,
            ),
            callback: (payload) {
              debugPrint('[RealtimeSyncService] Postgres changes detected on orders. Re-fetching orders.');
              ref.read(ordersProvider.notifier).fetchOrders();
            },
          );

      _channel!.subscribe((status, [error]) {
        if (error != null) {
          debugPrint('[RealtimeSyncService] Supabase subscription failed: $error');
        } else {
          debugPrint('[RealtimeSyncService] Supabase subscription status: $status');
        }
      });
    } catch (e, stack) {
      debugPrint('[RealtimeSyncService] Failed to initialize Supabase realtime subscription: $e\n$stack');
    }
  }

  void dispose() {
    if (_channel != null) {
      debugPrint('[RealtimeSyncService] Disposing realtime channel.');
      try {
        _channel!.unsubscribe();
      } catch (e) {
        debugPrint('[RealtimeSyncService] Error unsubscribing from channel: $e');
      }
      _channel = null;
    }
  }
}

final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

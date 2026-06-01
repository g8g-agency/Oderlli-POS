import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';
import '../core/services/order_service.dart';
import '../core/repositories/order_repository.dart';
import '../core/repositories/cart_repository.dart';
import 'pos_cart_provider.dart';
import 'table_provider.dart';
import 'auth_provider.dart';

// ─── Infrastructure Providers ─────────────────────────────────────────────────

final orderServiceProvider = Provider<OrderService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OrderService(dioClient);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final service = ref.watch(orderServiceProvider);
  final cartService = ref.watch(cartServiceProvider);
  final conn = ref.watch(connectivityServiceProvider);
  return OrderRepository(service, cartService, conn);
});

// ─── Orders Provider & Notifier ───────────────────────────────────────────────

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Order>>(
  (ref) {
    final repo = ref.watch(orderRepositoryProvider);
    return OrdersNotifier(ref, repo);
  },
);

class OrdersNotifier extends StateNotifier<List<Order>> {
  final Ref ref;
  final OrderRepository repository;

  OrdersNotifier(this.ref, this.repository) : super([]) {
    // Proactively fetch orders when initialized
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final sessionIds = ref.read(cartSessionIdsProvider).valueOrNull;
    final branchId = sessionIds?.branchId;
    if (branchId == null) {
      if (kDebugMode) {
        state = MockData.orders;
      }
      return;
    }

    try {
      final summaryList = await repository.getOrders(branchId: branchId);
      final tables = ref.read(posTablesProvider).valueOrNull ?? [];

      final orderList = summaryList.map((summary) {
        final tableNum = tables.firstWhere(
          (t) => t.id == summary.tableId,
          orElse: () => TableModel(
            id: summary.tableId,
            number: 1,
            capacity: 4,
            status: POSTableStatus.available,
            sectionName: '',
            floorName: '',
          ),
        ).number;

        return Order(
          id: summary.id,
          tableId: summary.tableId,
          tableNumber: tableNum,
          items: const [], // Summary list has empty items
          createdAt: summary.createdAt,
          status: summary.status,
          notes: summary.orderNotes,
          grandTotalMinor: summary.grandTotalMinor,
        );
      }).toList();

      state = orderList;
    } catch (e) {
      if (kDebugMode) {
        state = MockData.orders;
      }
    }
  }

  /// Perform Checkout action
  Future<Order> checkout({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String cartId,
    required int expectedCartRevision,
    String? orderNotes,
  }) async {
    // 1. Pre-condition Validation
    final cartState = ref.read(posCartProvider);
    if (cartState.items.isEmpty) {
      throw const CartValidationException('Pre-checkout Validation Failed: Cart is empty.');
    }

    final selectedTableId = ref.read(cartSelectedTableProvider);
    if (selectedTableId == null || selectedTableId != tableId) {
      throw const CartValidationException('Pre-checkout Validation Failed: Selected table mismatch.');
    }

    try {
      // 2. Perform checkout REST API request via repository
      final newOrder = await repository.checkout(
        tenantId: tenantId,
        branchId: branchId,
        tableId: tableId,
        cartId: cartId,
        expectedCartRevision: expectedCartRevision,
        orderNotes: orderNotes,
      );

      // 3. Clear/Refresh active cart
      ref.read(posCartProvider.notifier).clear();

      // 4. Refresh POS tables so floor plan is updated
      ref.read(posTablesProvider.notifier).refreshTables();

      // 5. Re-fetch branch orders list
      await fetchOrders();

      return newOrder;
    } catch (e) {
      rethrow;
    }
  }

  void addOrder(Order order) {
    state = [...state, order];
  }

  void updateStatus(String orderId, OrderStatus status) {
    state = [
      for (final o in state)
        if (o.id == orderId)
          o.copyWith(status: status, updatedAt: DateTime.now())
        else
          o,
    ];
  }

  void addItemToOrder(String orderId, OrderItem item) {
    state = [
      for (final o in state)
        if (o.id == orderId)
          o.copyWith(items: [...o.items, item])
        else
          o,
    ];
  }

  void removeItemFromOrder(String orderId, String itemId) {
    state = [
      for (final o in state)
        if (o.id == orderId)
          o.copyWith(
              items: o.items.where((i) => i.id != itemId).toList())
        else
          o,
    ];
  }

  void cancelOrder(String orderId) {
    updateStatus(orderId, OrderStatus.cancelled);
  }
}

// ─── Active & Filtered Orders Providers ──────────────────────────────────────

/// Active orders (not completed / cancelled).
final activeOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersProvider).where((o) {
    return o.status != OrderStatus.served &&
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled;
  }).toList();
});

/// Orders by status.
final ordersByStatusProvider =
    Provider.family<List<Order>, OrderStatus>((ref, status) {
  return ref.watch(ordersProvider).where((o) => o.status == status).toList();
});

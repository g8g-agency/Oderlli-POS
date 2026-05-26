import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';

/// All orders (mock — will be replaced with real API calls).
final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Order>>(
  (ref) => OrdersNotifier(MockData.orders),
);

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier(super.state);

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

/// Active orders (not cancelled / served).
final activeOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersProvider).where((o) {
    return o.status != OrderStatus.served &&
        o.status != OrderStatus.cancelled;
  }).toList();
});

/// Orders by status.
final ordersByStatusProvider =
    Provider.family<List<Order>, OrderStatus>((ref, status) {
  return ref.watch(ordersProvider).where((o) => o.status == status).toList();
});

import '../models/models.dart';

/// ─── Mock POS Data Set ──────────────────────────────────────────────────────
///
/// Predefined mock lists of TableModel, OrderModel, and BillModel records
/// representing live active restaurant states.
abstract final class MockPOSData {
  // ── Mock Tables ────────────────────────────────────────────────────────────
  static List<TableModel> get tables => [
        TableModel(
          id: 't-1',
          number: 1,
          capacity: 2,
          status: POSTableStatus.available,
          guestCount: 0,
        ),
        TableModel(
          id: 't-2',
          number: 2,
          capacity: 4,
          status: POSTableStatus.occupied,
          guestCount: 3,
          waiterName: 'Sarah',
          occupiedSince: DateTime.now().subtract(const Duration(minutes: 42)),
          billTotal: 65.50,
        ),
        TableModel(
          id: 't-3',
          number: 3,
          capacity: 4,
          status: POSTableStatus.preparing,
          guestCount: 2,
          waiterName: 'Michael',
          occupiedSince: DateTime.now().subtract(const Duration(minutes: 18)),
          billTotal: 48.00,
        ),
        TableModel(
          id: 't-4',
          number: 4,
          capacity: 6,
          status: POSTableStatus.ready,
          guestCount: 4,
          waiterName: 'Sarah',
          occupiedSince: DateTime.now().subtract(const Duration(minutes: 55)),
          billTotal: 92.20,
        ),
        TableModel(
          id: 't-5',
          number: 5,
          capacity: 8,
          status: POSTableStatus.paymentPending,
          guestCount: 6,
          waiterName: 'Jessica',
          occupiedSince: DateTime.now().subtract(const Duration(minutes: 75)),
          billTotal: 178.40,
        ),
        TableModel(
          id: 't-6',
          number: 6,
          capacity: 4,
          status: POSTableStatus.available,
          guestCount: 0,
        ),
        TableModel(
          id: 't-7',
          number: 7,
          capacity: 2,
          status: POSTableStatus.occupied,
          guestCount: 2,
          waiterName: 'Michael',
          occupiedSince: DateTime.now().subtract(const Duration(minutes: 10)),
          billTotal: 18.50,
        ),
        TableModel(
          id: 't-8',
          number: 8,
          capacity: 6,
          status: POSTableStatus.paymentPending,
          guestCount: 5,
          waiterName: 'Jessica',
          occupiedSince: DateTime.now().subtract(const Duration(minutes: 90)),
          billTotal: 142.30,
        ),
      ];

  // ── Mock Active Orders ──────────────────────────────────────────────────────
  static List<OrderModel> get orders => [
        OrderModel(
          id: 'ord-101',
          tableNumber: 2,
          waiterName: 'Sarah',
          createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
          status: 'served',
          guestCount: 3,
          items: const [
            OrderItemModel(name: 'Bruschetta al Pomodoro', qty: 2, price: 7.50),
            OrderItemModel(name: 'Grilled Salmon Fillet', qty: 2, price: 22.00),
            OrderItemModel(name: 'Fresh Orange Juice', qty: 3, price: 3.50),
          ],
        ),
        OrderModel(
          id: 'ord-102',
          tableNumber: 3,
          waiterName: 'Michael',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          status: 'preparing',
          guestCount: 2,
          items: const [
            OrderItemModel(name: 'Soup of the Day', qty: 1, price: 6.00),
            OrderItemModel(name: '8oz Sirloin Steak', qty: 1, price: 28.00, notes: 'Medium rare'),
            OrderItemModel(name: 'Tiramisu', qty: 1, price: 7.50),
            OrderItemModel(name: 'Espresso', qty: 1, price: 2.80),
          ],
        ),
        OrderModel(
          id: 'ord-103',
          tableNumber: 4,
          waiterName: 'Sarah',
          createdAt: DateTime.now().subtract(const Duration(minutes: 55)),
          status: 'ready',
          guestCount: 4,
          items: const [
            OrderItemModel(name: 'Margherita Pizza', qty: 2, price: 12.00),
            OrderItemModel(name: 'Pepperoni Feast Pizza', qty: 2, price: 14.50),
            OrderItemModel(name: 'Chocolate Fondant', qty: 2, price: 8.00),
            OrderItemModel(name: 'House Red Wine (Glass)', qty: 4, price: 6.50),
          ],
        ),
        OrderModel(
          id: 'ord-104',
          tableNumber: 5,
          waiterName: 'Jessica',
          createdAt: DateTime.now().subtract(const Duration(minutes: 75)),
          status: 'served',
          guestCount: 6,
          items: const [
            OrderItemModel(name: 'Prawn Cocktail', qty: 3, price: 11.00),
            OrderItemModel(name: 'Chicken Tikka Masala', qty: 4, price: 16.50),
            OrderItemModel(name: 'Mushroom Risotto', qty: 2, price: 14.00),
            OrderItemModel(name: 'Tiramisu', qty: 4, price: 7.50),
            OrderItemModel(name: 'Sparkling Water (500ml)', qty: 6, price: 2.50),
          ],
        ),
      ];

  // ── Mock Bills ─────────────────────────────────────────────────────────────
  static List<BillModel> get bills => [
        BillModel(
          id: 'bill-201',
          tableNumber: 2,
          waiterName: 'Sarah',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          subtotal: 62.50,
          discount: 0.00,
          tax: 3.12,
          total: 65.62,
          isPaid: false,
        ),
        BillModel(
          id: 'bill-202',
          tableNumber: 4,
          waiterName: 'Sarah',
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
          subtotal: 90.00,
          discount: 5.00,
          tax: 4.25,
          total: 89.25,
          isPaid: false,
        ),
        BillModel(
          id: 'bill-203',
          tableNumber: 5,
          waiterName: 'Jessica',
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
          subtotal: 175.00,
          discount: 10.00,
          tax: 8.25,
          total: 173.25,
          paymentMethod: 'Visa',
          isPaid: true,
        ),
      ];
}

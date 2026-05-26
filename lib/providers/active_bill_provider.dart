import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'orders_provider.dart';
import 'pos_tables_provider.dart';

/// Tracks the active table being checked out.
final activeTableIdProvider = StateProvider<String?>((ref) => null);

/// Looks up the active order for the selected table.
final activeTableOrderProvider = Provider<Order?>((ref) {
  final tableId = ref.watch(activeTableIdProvider);
  final orders = ref.watch(ordersProvider);
  
  if (tableId == null) {
    // Default fallback to Table 2 (occupied with active order)
    return orders.firstWhere(
      (o) => o.tableNumber == 2 && o.status != OrderStatus.served && o.status != OrderStatus.cancelled,
      orElse: () => orders.first,
    );
  }
  
  final tables = ref.watch(posTablesProvider);
  final table = tables.firstWhere((t) => t.id == tableId, orElse: () => tables.first);
  
  return orders.firstWhere(
    (o) => o.tableNumber == table.number && o.status != OrderStatus.served && o.status != OrderStatus.cancelled,
    orElse: () => orders.firstWhere(
      (o) => o.tableNumber == table.number,
      orElse: () => orders.first,
    ),
  );
});

/// A single payment transaction record on a bill.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.method,
    required this.amount,
    required this.timestamp,
    required this.waiterName,
  });

  final String id;
  final String method; // 'Cash', 'Card', 'Mobile'
  final double amount;
  final DateTime timestamp;
  final String waiterName;
}

/// Checkout/billing details state.
class ActiveBillState {
  const ActiveBillState({
    required this.order,
    this.discountPercent = 0.0,
    this.serviceChargePercent = 10.0, // 10% default
    this.payments = const [],
  });

  final Order order;
  final double discountPercent;
  final double serviceChargePercent;
  final List<PaymentRecord> payments;

  double get subtotal => order.subtotal;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (order.taxPercent / 100);
  double get serviceChargeAmount => taxableAmount * (serviceChargePercent / 100);
  double get total => taxableAmount + taxAmount + serviceChargeAmount;

  double get amountPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get amountRemaining => total - amountPaid;

  bool get isPaid => amountRemaining <= 0.01;
  bool get isPartiallyPaid => amountPaid > 0 && amountRemaining > 0.01;

  String get settlementStatus {
    if (isPaid) return 'Settled';
    if (isPartiallyPaid) return 'Partially Paid';
    return 'Unpaid';
  }

  ActiveBillState copyWith({
    Order? order,
    double? discountPercent,
    double? serviceChargePercent,
    List<PaymentRecord>? payments,
  }) =>
      ActiveBillState(
        order: order ?? this.order,
        discountPercent: discountPercent ?? this.discountPercent,
        serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
        payments: payments ?? this.payments,
      );
}

/// Notifier that manages the active checkout bill.
class ActiveBillNotifier extends StateNotifier<ActiveBillState?> {
  ActiveBillNotifier(this._ref) : super(null) {
    // Listen to selected table order to update bill state dynamically
    _ref.listen<Order?>(activeTableOrderProvider, (previous, next) {
      if (next != null) {
        setOrder(next);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  void setOrder(Order order) {
    if (state?.order.id == order.id) {
      state = state!.copyWith(order: order);
    } else {
      // Mock past partial payment for Table 2 (Sarah) to make "Partially Paid" visible
      final initialPayments = order.tableNumber == 2
          ? [
              PaymentRecord(
                id: 'pay-101',
                method: 'Cash',
                amount: 20.00,
                timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
                waiterName: order.servedBy ?? 'Sarah',
              )
            ]
          : const <PaymentRecord>[];

      state = ActiveBillState(
        order: order,
        payments: initialPayments,
      );
    }
  }

  void applyDiscount(double percent) {
    if (state != null) {
      state = state!.copyWith(discountPercent: percent);
    }
  }

  void applyServiceCharge(double percent) {
    if (state != null) {
      state = state!.copyWith(serviceChargePercent: percent);
    }
  }

  void addPayment(String method, double amount) {
    final currentState = state;
    if (currentState != null) {
      final newPayment = PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: method,
        amount: amount,
        timestamp: DateTime.now(),
        waiterName: currentState.order.servedBy ?? 'Sarah',
      );
      final updatedPayments = [...currentState.payments, newPayment];
      state = currentState.copyWith(payments: updatedPayments);

      final newRemaining = currentState.total - (currentState.amountPaid + amount);
      if (newRemaining <= 0.01) {
        // Fully paid! Update table status and clear it
        _ref.read(posTablesProvider.notifier).updateStatus(currentState.order.tableId, POSTableStatus.available);
        _ref.read(posTablesProvider.notifier).clearTable(currentState.order.tableId);
        // Update order status to served
        _ref.read(ordersProvider.notifier).updateStatus(currentState.order.id, OrderStatus.served);
      } else {
        // Partially paid, mark as payment pending
        _ref.read(posTablesProvider.notifier).updateStatus(currentState.order.tableId, POSTableStatus.paymentPending);
      }
    }
  }

  void clear() {
    state = null;
  }
}

/// Provider exposing the active billing/checkout state.
final activeBillProvider = StateNotifierProvider<ActiveBillNotifier, ActiveBillState?>((ref) {
  return ActiveBillNotifier(ref);
});

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// ─── Table Status Enum ──────────────────────────────────────────────────────
enum POSTableStatus {
  available,
  occupied,
  preparing,
  ready,
  paymentPending,
}

extension POSTableStatusX on POSTableStatus {
  String get label => switch (this) {
        POSTableStatus.available => 'Available',
        POSTableStatus.occupied => 'Occupied',
        POSTableStatus.preparing => 'Preparing',
        POSTableStatus.ready => 'Ready',
        POSTableStatus.paymentPending => 'Payment Pending',
      };

  Color get color => switch (this) {
        POSTableStatus.available => AppColors.success,
        POSTableStatus.occupied => AppColors.primary,
        POSTableStatus.preparing => AppColors.statusPreparing,
        POSTableStatus.ready => AppColors.statusReady,
        POSTableStatus.paymentPending => AppColors.cash,
      };
}

/// ─── Table Model ────────────────────────────────────────────────────────────
class TableModel {
  const TableModel({
    required this.id,
    required this.number,
    required this.capacity,
    this.status = POSTableStatus.available,
    this.guestCount = 0,
    this.waiterName,
    this.assignedWaiterId,
    this.assignedWaiterName,
    this.occupiedSince,
    this.billTotal = 0.0,
    this.sectionName,
    this.floorName,
  });

  final String id;
  final int number;
  final int capacity;
  final POSTableStatus status;
  final int guestCount;
  final String? waiterName;
  final String? assignedWaiterId;
  final String? assignedWaiterName;
  final DateTime? occupiedSince;
  final double billTotal;
  final String? sectionName;
  final String? floorName;

  /// Returns the elapsed minutes since the table was occupied.
  int get elapsedMinutes {
    if (occupiedSince == null) return 0;
    return DateTime.now().difference(occupiedSince!).inMinutes;
  }

  TableModel copyWith({
    String? id,
    int? number,
    int? capacity,
    POSTableStatus? status,
    int? guestCount,
    String? waiterName,
    String? assignedWaiterId,
    String? assignedWaiterName,
    DateTime? occupiedSince,
    double? billTotal,
    String? sectionName,
    String? floorName,
  }) =>
      TableModel(
        id: id ?? this.id,
        number: number ?? this.number,
        capacity: capacity ?? this.capacity,
        status: status ?? this.status,
        guestCount: guestCount ?? this.guestCount,
        waiterName: waiterName ?? this.waiterName,
        assignedWaiterId: assignedWaiterId ?? this.assignedWaiterId,
        assignedWaiterName: assignedWaiterName ?? this.assignedWaiterName,
        occupiedSince: occupiedSince ?? this.occupiedSince,
        billTotal: billTotal ?? this.billTotal,
        sectionName: sectionName ?? this.sectionName,
        floorName: floorName ?? this.floorName,
      );
}

/// ─── Order Item Model ────────────────────────────────────────────────────────
class OrderItemModel {
  const OrderItemModel({
    required this.name,
    required this.qty,
    required this.price,
    this.notes,
  });

  final String name;
  final int qty;
  final double price;
  final String? notes;

  double get subtotal => price * qty;
}

/// ─── Order Model ────────────────────────────────────────────────────────────
class OrderModel {
  const OrderModel({
    required this.id,
    required this.tableNumber,
    required this.waiterName,
    required this.items,
    required this.createdAt,
    this.status = 'preparing',
    this.guestCount = 1,
  });

  final String id;
  final int tableNumber;
  final String waiterName;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final String status; // 'pending', 'preparing', 'ready', 'served'
  final int guestCount;

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get elapsedMinutes => DateTime.now().difference(createdAt).inMinutes;
}

/// ─── Bill Model ─────────────────────────────────────────────────────────────
class BillModel {
  const BillModel({
    required this.id,
    required this.tableNumber,
    required this.waiterName,
    required this.createdAt,
    required this.subtotal,
    this.discount = 0.0,
    required this.tax,
    required this.total,
    this.paymentMethod,
    this.isPaid = false,
  });

  final String id;
  final int tableNumber;
  final String waiterName;
  final DateTime createdAt;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String? paymentMethod; // 'Cash', 'Visa', 'Mastercard', etc.
  final bool isPaid;
}

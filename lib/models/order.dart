import 'menu_item.dart';

enum OrderStatus { pending, preparing, ready, served, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.served => 'Served',
        OrderStatus.cancelled => 'Cancelled',
      };
}

/// A single line-item within an [Order].
class OrderItem {
  const OrderItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.notes,
    this.modifiers = const [],
  });

  final String id;
  final MenuItem menuItem;
  final int quantity;
  final String? notes;
  final List<String> modifiers; // e.g. "No onions", "Extra cheese"

  double get subtotal => menuItem.price * quantity;

  OrderItem copyWith({
    String? id,
    MenuItem? menuItem,
    int? quantity,
    String? notes,
    List<String>? modifiers,
  }) =>
      OrderItem(
        id: id ?? this.id,
        menuItem: menuItem ?? this.menuItem,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        modifiers: modifiers ?? this.modifiers,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OrderItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A full order placed at a table (or takeaway).
class Order {
  const Order({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.items,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.updatedAt,
    this.servedBy,
    this.discountPercent = 0,
    this.taxPercent = 5,
    this.notes,
  });

  final String id;
  final String tableId;
  final int tableNumber;
  final List<OrderItem> items;
  final DateTime createdAt;
  final OrderStatus status;
  final DateTime? updatedAt;
  final String? servedBy;
  final double discountPercent;
  final double taxPercent;
  final String? notes;

  // ── Computed totals ─────────────────────────────────────────────────────
  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxPercent / 100);
  double get total => taxableAmount + taxAmount;
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  Order copyWith({
    String? id,
    String? tableId,
    int? tableNumber,
    List<OrderItem>? items,
    DateTime? createdAt,
    OrderStatus? status,
    DateTime? updatedAt,
    String? servedBy,
    double? discountPercent,
    double? taxPercent,
    String? notes,
  }) =>
      Order(
        id: id ?? this.id,
        tableId: tableId ?? this.tableId,
        tableNumber: tableNumber ?? this.tableNumber,
        items: items ?? this.items,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        servedBy: servedBy ?? this.servedBy,
        discountPercent: discountPercent ?? this.discountPercent,
        taxPercent: taxPercent ?? this.taxPercent,
        notes: notes ?? this.notes,
      );

  @override
  String toString() =>
      'Order(id: $id, table: $tableNumber, status: ${status.label}, total: $total)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

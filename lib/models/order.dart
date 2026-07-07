import 'menu_item.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  served,
  completed,
  cancelled,
  syncConflict
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.served => 'Served',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.syncConflict => 'Sync Conflict',
      };
}

OrderStatus parseOrderStatus(String statusStr) {
  return switch (statusStr.toLowerCase()) {
    'pending' => OrderStatus.pending,
    'accepted' => OrderStatus.accepted,
    'preparing' => OrderStatus.preparing,
    'ready' => OrderStatus.ready,
    'delivered' => OrderStatus.served,
    'completed' => OrderStatus.completed,
    'cancelled' => OrderStatus.cancelled,
    'sync_conflict' => OrderStatus.syncConflict,
    _ => OrderStatus.pending,
  };
}

String serializeOrderStatus(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'pending',
    OrderStatus.accepted => 'accepted',
    OrderStatus.preparing => 'preparing',
    OrderStatus.ready => 'ready',
    OrderStatus.served => 'delivered',
    OrderStatus.completed => 'completed',
    OrderStatus.cancelled => 'cancelled',
    OrderStatus.syncConflict => 'sync_conflict',
  };
}

/// A single line-item within an [Order].
class OrderItem {
  OrderItem({
    required this.id,
    String? menuItemId,
    String? itemNameSnapshot,
    int? unitPriceMinor,
    required this.quantity,
    this.notes,
    this.modifiers = const [],
    MenuItem? menuItem,
  })  : menuItemId = menuItemId ?? (menuItem != null ? menuItem.id : ''),
        itemNameSnapshot = itemNameSnapshot ?? (menuItem != null ? menuItem.name : ''),
        unitPriceMinor = unitPriceMinor ?? (menuItem != null ? (menuItem.price * 100).toInt() : 0);

  final String id;
  final String menuItemId;
  final String itemNameSnapshot;
  final int unitPriceMinor; // Internally integer minor unit
  final int quantity;
  final String? notes;
  final List<String> modifiers;

  double get unitPrice => unitPriceMinor / 100.0;
  double get subtotal => (unitPriceMinor * quantity) / 100.0;
  int get subtotalMinor => unitPriceMinor * quantity;

  // Compatibility helper: MenuItem getter
  MenuItem get menuItem => MenuItem(
        id: menuItemId,
        name: itemNameSnapshot,
        categoryId: '',
        price: unitPrice,
        modifierGroups: const [],
      );

  factory OrderItem.fromJson(Map<String, dynamic> json, [List<dynamic> modsJson = const []]) {
    final modNames = modsJson
        .map((m) => (m['modifier_option_name_snapshot'] ?? m.toString()) as String)
        .toList();
    return OrderItem(
      id: (json['id'] ?? '') as String,
      menuItemId: (json['menu_item_id'] ?? '') as String,
      itemNameSnapshot: (json['item_name_snapshot'] ?? '') as String,
      unitPriceMinor: (json['unit_price_minor'] ?? 0) as int,
      quantity: (json['quantity'] ?? 0) as int,
      notes: json['item_notes'] as String?,
      modifiers: modNames,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_item_id': menuItemId,
        'item_name_snapshot': itemNameSnapshot,
        'unit_price_minor': unitPriceMinor,
        'quantity': quantity,
        'item_notes': notes ?? '',
      };

  OrderItem copyWith({
    String? id,
    String? menuItemId,
    String? itemNameSnapshot,
    int? unitPriceMinor,
    int? quantity,
    String? notes,
    List<String>? modifiers,
  }) =>
      OrderItem(
        id: id ?? this.id,
        menuItemId: menuItemId ?? this.menuItemId,
        itemNameSnapshot: itemNameSnapshot ?? this.itemNameSnapshot,
        unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
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
    this.discountPercent = 0.0,
    this.taxPercent = 5.0,
    this.notes,
    this.versionNum = 1,
    this.orderSnapshotId,
    this.orderNumber,
    this.subtotalMinor = 0,
    this.taxTotalMinor = 0,
    this.discountTotalMinor = 0,
    this.grandTotalMinor = 0,
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
  final int versionNum;
  final String? orderSnapshotId;
  final String? orderNumber;
  
  // Stored internally as integer minor units
  final int subtotalMinor;
  final int taxTotalMinor;
  final int discountTotalMinor;
  final int grandTotalMinor;

  // ── Computed totals (double getters for backward compatibility) ────────────
  double get subtotal => subtotalMinor > 0 ? subtotalMinor / 100.0 : items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get discountAmount => discountTotalMinor > 0 ? discountTotalMinor / 100.0 : subtotal * (discountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxTotalMinor > 0 ? taxTotalMinor / 100.0 : taxableAmount * (taxPercent / 100);
  double get total => grandTotalMinor > 0 ? grandTotalMinor / 100.0 : taxableAmount + taxAmount;
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
    int? versionNum,
    String? orderSnapshotId,
    String? orderNumber,
    int? subtotalMinor,
    int? taxTotalMinor,
    int? discountTotalMinor,
    int? grandTotalMinor,
    String? customerPaymentIntent,
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
        versionNum: versionNum ?? this.versionNum,
        orderSnapshotId: orderSnapshotId ?? this.orderSnapshotId,
        orderNumber: orderNumber ?? this.orderNumber,
        subtotalMinor: subtotalMinor ?? this.subtotalMinor,
        taxTotalMinor: taxTotalMinor ?? this.taxTotalMinor,
        discountTotalMinor: discountTotalMinor ?? this.discountTotalMinor,
        grandTotalMinor: grandTotalMinor ?? this.grandTotalMinor,
        customerPaymentIntent: customerPaymentIntent ?? this.customerPaymentIntent,
      );

  factory Order.fromJson(Map<String, dynamic> json, [List<OrderItem> items = const [], int tableNum = 0]) {
    final statusStr = (json['status'] ?? 'pending') as String;
    final parsedStatus = parseOrderStatus(statusStr);
    
    return Order(
      id: (json['id'] ?? '') as String,
      tableId: (json['table_id'] ?? '') as String,
      tableNumber: tableNum,
      items: items,
      createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
      status: parsedStatus,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      servedBy: json['served_by'] as String?,
      discountPercent: (json['discount_percent'] ?? 0.0) as double,
      taxPercent: (json['tax_percent'] ?? 5.0) as double,
      notes: json['order_notes'] as String?,
      versionNum: (json['version_num'] ?? 1) as int,
      orderSnapshotId: json['order_snapshot_id'] as String?,
      orderNumber: json['order_number'] as String?,
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      taxTotalMinor: (json['tax_total_minor'] as num?)?.toInt() ?? 0,
      discountTotalMinor: (json['discount_total_minor'] as num?)?.toInt() ?? 0,
      grandTotalMinor: (json['grand_total_minor'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'status': serializeOrderStatus(status),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'served_by': servedBy,
        'discount_percent': discountPercent,
        'tax_percent': taxPercent,
        'order_notes': notes ?? '',
        'version_num': versionNum,
        'order_snapshot_id': orderSnapshotId,
        'order_number': orderNumber,
        'subtotal_minor': subtotalMinor,
        'tax_total_minor': taxTotalMinor,
        'discount_total_minor': discountTotalMinor,
        'grand_total_minor': grandTotalMinor,
      };

  @override
  String toString() =>
      'Order(id: $id, table: $tableNumber, status: ${status.label}, total: $total)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class OrderSummary {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final DateTime createdAt;
  final String tableId;
  final String? orderNotes;
  final int grandTotalMinor;
  final String? customerPaymentIntent;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.tableId,
    this.orderNotes,
    this.grandTotalMinor = 0,
    this.customerPaymentIntent,
  });

  double get total => grandTotalMinor / 100.0;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: (json['id'] ?? '') as String,
      orderNumber: (json['order_number'] ?? '') as String,
      status: parseOrderStatus((json['status'] ?? 'pending') as String),
      createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
      tableId: (json['table_id'] ?? '') as String,
      orderNotes: json['order_notes'] as String?,
      grandTotalMinor: (json['grand_total_minor'] as num?)?.toInt() ?? 0,
      customerPaymentIntent: json['customer_payment_intent'] as String?,
    );
  }
}

class OrderDetail {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableId;
  final String? sessionId;
  final String? cartId;
  final String orderSnapshotId;
  final String orderNumber;
  final OrderStatus status;
  final String source;
  final String? idempotencyKey;
  final String? orderNotes;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final DateTime? acceptedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final int versionNum;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  
  // Internally integer minor units
  final int subtotalMinor;
  final int taxTotalMinor;
  final int discountTotalMinor;
  final int grandTotalMinor;
  final String? customerPaymentIntent;

  const OrderDetail({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableId,
    this.sessionId,
    this.cartId,
    required this.orderSnapshotId,
    required this.orderNumber,
    required this.status,
    required this.source,
    this.idempotencyKey,
    this.orderNotes,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.deliveredAt,
    this.completedAt,
    required this.versionNum,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.subtotalMinor = 0,
    this.taxTotalMinor = 0,
    this.discountTotalMinor = 0,
    this.grandTotalMinor = 0,
  });

  double get subtotal => subtotalMinor / 100.0;
  double get discountAmount => discountTotalMinor / 100.0;
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxTotalMinor / 100.0;
  double get total => grandTotalMinor / 100.0;

  factory OrderDetail.fromJson(Map<String, dynamic> json, [List<OrderItem>? items]) {
    final List<OrderItem> parsedItems;
    if (items != null) {
      parsedItems = items;
    } else if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((itemJson) => OrderItem.fromJson(
                itemJson as Map<String, dynamic>,
                itemJson['modifiers'] is List ? itemJson['modifiers'] : const [],
              ))
          .toList();
    } else {
      parsedItems = const [];
    }

    return OrderDetail(
      id: (json['id'] ?? '') as String,
      tenantId: (json['tenant_id'] ?? '') as String,
      branchId: (json['branch_id'] ?? '') as String,
      tableId: (json['table_id'] ?? '') as String,
      sessionId: json['session_id'] as String?,
      cartId: json['cart_id'] as String?,
      orderSnapshotId: (json['order_snapshot_id'] ?? '') as String,
      orderNumber: (json['order_number'] ?? '') as String,
      status: parseOrderStatus((json['status'] ?? 'pending') as String),
      source: (json['source'] ?? '') as String,
      idempotencyKey: json['idempotency_key'] as String?,
      orderNotes: json['order_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at'] as String) : null,
      preparingAt: json['preparing_at'] != null ? DateTime.parse(json['preparing_at'] as String) : null,
      readyAt: json['ready_at'] != null ? DateTime.parse(json['ready_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      versionNum: (json['version_num'] ?? 1) as int,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['updated_at'] ?? DateTime.now().toIso8601String()) as String),
      items: parsedItems,
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      taxTotalMinor: (json['tax_total_minor'] as num?)?.toInt() ?? 0,
      discountTotalMinor: (json['discount_total_minor'] as num?)?.toInt() ?? 0,
      grandTotalMinor: (json['grand_total_minor'] as num?)?.toInt() ?? 0,
      customerPaymentIntent: json['customer_payment_intent'] as String?,
    );
  }
}

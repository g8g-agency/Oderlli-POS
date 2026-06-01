import 'kitchen_item.dart';
import 'kitchen_item_status.dart';
import 'kitchen_ticket_status.dart';

/// Ticket metrics sub-object from the backend projection.
class KitchenTicketMetrics {
  const KitchenTicketMetrics({
    required this.totalItems,
    required this.completedItems,
    required this.prepProgressPercentage,
  });

  final int totalItems;
  final int completedItems;
  final double prepProgressPercentage;

  factory KitchenTicketMetrics.fromJson(Map<String, dynamic> json) {
    return KitchenTicketMetrics(
      totalItems: (json['totalItems'] ?? json['total_items'] ?? 0) as int,
      completedItems: (json['completedItems'] ?? json['completed_items'] ?? 0) as int,
      prepProgressPercentage:
          ((json['prepProgressPercentage'] ?? json['prep_progress_percentage'] ?? 0.0) as num)
              .toDouble(),
    );
  }

  factory KitchenTicketMetrics.empty() =>
      const KitchenTicketMetrics(totalItems: 0, completedItems: 0, prepProgressPercentage: 0.0);
}

/// Maps to the `ActiveKitchenOrderProjection` DTO from the KDS backend.
class KitchenTicket {
  const KitchenTicket({
    required this.ticketId,
    required this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    required this.status,
    required this.priority,
    required this.estimatedPrepSeconds,
    required this.elapsedSeconds,
    required this.isOverdue,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.metrics,
    this.notes,
  });

  final String ticketId;
  final String orderId;
  final String orderNumber;
  final String tableNumber;
  final KitchenTicketStatus status;
  final int priority;
  final int estimatedPrepSeconds;
  final int elapsedSeconds;
  final bool isOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<KitchenItem> items;
  final KitchenTicketMetrics metrics;
  final String? notes;

  int get elapsedMinutes => elapsedSeconds ~/ 60;

  factory KitchenTicket.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    final items = rawItems
        .map((e) => KitchenItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawMetrics = json['metrics'] as Map<String, dynamic>?;
    final metrics = rawMetrics != null
        ? KitchenTicketMetrics.fromJson(rawMetrics)
        : KitchenTicketMetrics.empty();

    return KitchenTicket(
      ticketId: (json['ticketId'] ?? json['ticket_id'] ?? '') as String,
      orderId: (json['orderId'] ?? json['order_id'] ?? '') as String,
      orderNumber: (json['orderNumber'] ?? json['order_number'] ?? '') as String,
      tableNumber: (json['tableNumber'] ?? json['table_number'] ?? '').toString(),
      status: parseKitchenTicketStatus((json['status'] ?? 'pending') as String),
      priority: (json['priority'] ?? 10) as int,
      estimatedPrepSeconds: (json['estimatedPrepSeconds'] ?? json['estimated_prep_seconds'] ?? 0) as int,
      elapsedSeconds: (json['elapsedSeconds'] ?? json['elapsed_seconds'] ?? 0) as int,
      isOverdue: (json['isOverdue'] ?? json['is_overdue'] ?? false) as bool,
      createdAt: DateTime.parse(
          (json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse(
          (json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()) as String),
      items: items,
      metrics: metrics,
      notes: json['notes'] as String?,
    );
  }

  KitchenTicket copyWith({
    String? ticketId,
    String? orderId,
    String? orderNumber,
    String? tableNumber,
    KitchenTicketStatus? status,
    int? priority,
    int? estimatedPrepSeconds,
    int? elapsedSeconds,
    bool? isOverdue,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<KitchenItem>? items,
    KitchenTicketMetrics? metrics,
    String? notes,
  }) =>
      KitchenTicket(
        ticketId: ticketId ?? this.ticketId,
        orderId: orderId ?? this.orderId,
        orderNumber: orderNumber ?? this.orderNumber,
        tableNumber: tableNumber ?? this.tableNumber,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        estimatedPrepSeconds: estimatedPrepSeconds ?? this.estimatedPrepSeconds,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isOverdue: isOverdue ?? this.isOverdue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        items: items ?? this.items,
        metrics: metrics ?? this.metrics,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KitchenTicket && ticketId == other.ticketId;

  @override
  int get hashCode => ticketId.hashCode;

  // ── Mock factory for debug fallback ─────────────────────────────────────────
  factory KitchenTicket.mock({
    required String ticketId,
    required String tableNumber,
    required String orderNumber,
    required KitchenTicketStatus status,
    required List<KitchenItem> items,
    int elapsedSeconds = 0,
    bool isOverdue = false,
    int priority = 10,
    String? notes,
  }) =>
      KitchenTicket(
        ticketId: ticketId,
        orderId: 'order-mock-$ticketId',
        orderNumber: orderNumber,
        tableNumber: tableNumber,
        status: status,
        priority: priority,
        estimatedPrepSeconds: 900,
        elapsedSeconds: elapsedSeconds,
        isOverdue: isOverdue,
        createdAt: DateTime.now().subtract(Duration(seconds: elapsedSeconds)),
        updatedAt: DateTime.now(),
        items: items,
        metrics: KitchenTicketMetrics(
          totalItems: items.length,
          completedItems: items.where((i) => i.status.isTerminal).length,
          prepProgressPercentage: items.isEmpty
              ? 0.0
              : items.where((i) => i.status.isTerminal).length / items.length * 100.0,
        ),
        notes: notes,
      );
}

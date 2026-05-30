import 'kitchen_item_status.dart';

/// Maps to the `ActiveItemPrepProjection` DTO from the KDS backend.
class KitchenItem {
  const KitchenItem({
    required this.preparationId,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.completedQuantity,
    required this.status,
    this.notes,
    this.modifiers,
    this.stationId,
    this.stationName,
    this.preparedAt,
    this.completedAt,
  });

  final String preparationId;
  final String itemId;
  final String name;
  final int quantity;
  final int completedQuantity;
  final KitchenItemStatus status;
  final String? notes;
  final String? modifiers;
  final String? stationId;
  final String? stationName;
  final DateTime? preparedAt;
  final DateTime? completedAt;

  int get remainingQuantity => quantity - completedQuantity;
  bool get isComplete => status.isTerminal;

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    return KitchenItem(
      preparationId: (json['preparationId'] ?? json['preparation_id'] ?? '') as String,
      itemId: (json['itemId'] ?? json['item_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      quantity: (json['quantity'] ?? 0) as int,
      completedQuantity: (json['completedQuantity'] ?? json['completed_quantity'] ?? 0) as int,
      status: parseKitchenItemStatus((json['status'] ?? 'pending') as String),
      notes: json['notes'] as String?,
      modifiers: json['modifiers'] as String?,
      stationId: (json['stationId'] ?? json['station_id']) as String?,
      stationName: (json['stationName'] ?? json['station_name']) as String?,
      preparedAt: _parseDate(json['preparedAt'] ?? json['prepared_at']),
      completedAt: _parseDate(json['completedAt'] ?? json['completed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'preparationId': preparationId,
        'itemId': itemId,
        'name': name,
        'quantity': quantity,
        'completedQuantity': completedQuantity,
        'status': serializeKitchenItemStatus(status),
        'notes': notes,
        'modifiers': modifiers,
        'stationId': stationId,
        'stationName': stationName,
        'preparedAt': preparedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  KitchenItem copyWith({
    String? preparationId,
    String? itemId,
    String? name,
    int? quantity,
    int? completedQuantity,
    KitchenItemStatus? status,
    String? notes,
    String? modifiers,
    String? stationId,
    String? stationName,
    DateTime? preparedAt,
    DateTime? completedAt,
  }) =>
      KitchenItem(
        preparationId: preparationId ?? this.preparationId,
        itemId: itemId ?? this.itemId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        completedQuantity: completedQuantity ?? this.completedQuantity,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        modifiers: modifiers ?? this.modifiers,
        stationId: stationId ?? this.stationId,
        stationName: stationName ?? this.stationName,
        preparedAt: preparedAt ?? this.preparedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KitchenItem && preparationId == other.preparationId;

  @override
  int get hashCode => preparationId.hashCode;

  // ── Mock factory for debug fallback ─────────────────────────────────────────
  factory KitchenItem.mock({
    required String preparationId,
    required String name,
    int quantity = 1,
    String? notes,
  }) =>
      KitchenItem(
        preparationId: preparationId,
        itemId: 'item-mock-$preparationId',
        name: name,
        quantity: quantity,
        completedQuantity: 0,
        status: KitchenItemStatus.pending,
        notes: notes,
      );
}

DateTime? _parseDate(dynamic value) {
  if (value == null || value is! String) return null;
  return DateTime.tryParse(value);
}

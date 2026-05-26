enum TableStatus { available, occupied, reserved, cleaning }

extension TableStatusX on TableStatus {
  String get label => switch (this) {
        TableStatus.available => 'Available',
        TableStatus.occupied => 'Occupied',
        TableStatus.reserved => 'Reserved',
        TableStatus.cleaning => 'Cleaning',
      };

  bool get isAvailable => this == TableStatus.available;
}

/// Represents a physical table in the restaurant.
class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    this.status = TableStatus.available,
    this.section,
    this.currentOrderId,
    this.occupiedSince,
    this.reservedFor,
  });

  final String id;
  final int number;
  final int capacity;
  final TableStatus status;
  final String? section; // e.g. "Terrace", "Indoor"
  final String? currentOrderId;
  final DateTime? occupiedSince;
  final String? reservedFor; // Customer name

  RestaurantTable copyWith({
    String? id,
    int? number,
    int? capacity,
    TableStatus? status,
    String? section,
    String? currentOrderId,
    DateTime? occupiedSince,
    String? reservedFor,
  }) =>
      RestaurantTable(
        id: id ?? this.id,
        number: number ?? this.number,
        capacity: capacity ?? this.capacity,
        status: status ?? this.status,
        section: section ?? this.section,
        currentOrderId: currentOrderId ?? this.currentOrderId,
        occupiedSince: occupiedSince ?? this.occupiedSince,
        reservedFor: reservedFor ?? this.reservedFor,
      );

  @override
  String toString() =>
      'RestaurantTable(id: $id, number: $number, status: ${status.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RestaurantTable && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

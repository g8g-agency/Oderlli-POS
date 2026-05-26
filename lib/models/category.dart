/// A menu category (e.g. Starters, Mains, Beverages).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
    this.itemCount = 0,
  });

  final String id;
  final String name;
  final String icon; // emoji or asset path
  final int? color; // ARGB int for Color(...)
  final int itemCount;

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    int? itemCount,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        itemCount: itemCount ?? this.itemCount,
      );

  @override
  String toString() => 'Category(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

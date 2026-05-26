/// A single item on the restaurant's menu.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isVegan = false,
    this.allergens = const [],
    this.preparationTimeMinutes = 10,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final List<String> allergens;
  final int preparationTimeMinutes;
  final List<String> tags;

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isVegan,
    List<String>? allergens,
    int? preparationTimeMinutes,
    List<String>? tags,
  }) =>
      MenuItem(
        id: id ?? this.id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        price: price ?? this.price,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        isVegetarian: isVegetarian ?? this.isVegetarian,
        isVegan: isVegan ?? this.isVegan,
        allergens: allergens ?? this.allergens,
        preparationTimeMinutes:
            preparationTimeMinutes ?? this.preparationTimeMinutes,
        tags: tags ?? this.tags,
      );

  @override
  String toString() =>
      'MenuItem(id: $id, name: $name, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

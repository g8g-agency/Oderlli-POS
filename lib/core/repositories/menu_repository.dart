import 'package:flutter/foundation.dart' hide Category;
import '../../models/models.dart';
import '../services/menu_service.dart';

// ─── Category emoji mapping ───────────────────────────────────
// The backend has no emoji field. We pick a sensible default by
// matching on the slug/name, then fall back to a food emoji.
String _emojiForCategory(String name, String? slug) {
  final key = (slug ?? name).toLowerCase();
  if (key.contains('starter') || key.contains('appetizer') || key.contains('salad')) return '🥗';
  if (key.contains('main') || key.contains('entree')) return '🍽️';
  if (key.contains('grill') || key.contains('bbq') || key.contains('steak')) return '🥩';
  if (key.contains('pasta') || key.contains('noodle')) return '🍝';
  if (key.contains('pizza')) return '🍕';
  if (key.contains('dessert') || key.contains('sweet')) return '🍮';
  if (key.contains('beverage') || key.contains('drink') || key.contains('juice')) return '🥤';
  if (key.contains('side') || key.contains('extra') || key.contains('add')) return '🍟';
  if (key.contains('soup')) return '🍜';
  if (key.contains('sushi') || key.contains('japanese')) return '🍣';
  if (key.contains('burger') || key.contains('sandwich')) return '🍔';
  if (key.contains('chicken') || key.contains('poultry')) return '🍗';
  if (key.contains('seafood') || key.contains('fish')) return '🐟';
  if (key.contains('vegan') || key.contains('vegetarian')) return '🥦';
  return '🍴';
}

// ─── Repository ───────────────────────────────────────────────

class MenuRepository {
  final MenuService _menuService;

  MenuRepository(this._menuService);

  /// Fetches the category tree from the backend, flattens it, and maps to [Category] objects.
  Future<List<Category>> fetchCategories(String tenantId) async {
    try {
      final tree = await _menuService.fetchCategoryTree(tenantId);
      final List<Category> flatList = [];
      _flattenCategories(tree, flatList);
      return flatList;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MenuRepository] fetchCategories failed: $e');
      }
      rethrow;
    }
  }

  void _flattenCategories(List<MenuCategory> source, List<Category> destination) {
    final sortedSource = List<MenuCategory>.from(source)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final cat in sortedSource) {
      if (cat.isActive) {
        destination.add(
          Category(
            id: cat.id,
            name: cat.name,
            icon: _emojiForCategory(cat.name, cat.slug),
          ),
        );
        if (cat.children.isNotEmpty) {
          _flattenCategories(cat.children, destination);
        }
      }
    }
  }

  /// Fetches the effective branch menu and maps to [MenuItem] objects.
  /// The `isVegetarian` / `isVegan` flags are derived from `dietaryTags`.
  Future<List<MenuItem>> fetchMenuItems(
    String tenantId,
    String branchId,
  ) async {
    try {
      final apiItems = await _menuService.fetchEffectiveMenu(tenantId, branchId);
      return apiItems
          .map(
            (a) => MenuItem(
              id: a.id,
              name: a.name,
              categoryId: a.categoryId,
              price: a.effectivePrice,
              description: a.description ?? a.shortDescription,
              imageUrl: a.imageUrl ?? a.thumbnailUrl,
              isAvailable: a.isAvailable,
              isVegetarian: a.dietaryTags.contains('vegetarian'),
              isVegan: a.dietaryTags.contains('vegan'),
              preparationTimeMinutes: a.prepTimeMinutes ?? 10,
              tags: [
                if (a.isFeatured) 'popular',
                if (a.spiceLevel != 'none') a.spiceLevel,
                ...a.dietaryTags,
              ],
              modifierGroups: a.modifierGroups,
            ),
          )
          .toList();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MenuRepository] fetchMenuItems failed: $e');
      }
      rethrow;
    }
  }
}

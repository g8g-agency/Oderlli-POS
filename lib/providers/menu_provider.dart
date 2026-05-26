import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';

/// Exposes the full list of menu categories.
final categoriesProvider = Provider<List<Category>>((ref) {
  return MockData.categories;
});

/// Exposes all menu items.
final menuItemsProvider = Provider<List<MenuItem>>((ref) {
  return MockData.menuItems;
});

/// Selected category ID for filtering.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Menu items filtered by the selected category.
final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final items = ref.watch(menuItemsProvider);
  final selectedId = ref.watch(selectedCategoryProvider);
  if (selectedId == null) return items;
  return items.where((item) => item.categoryId == selectedId).toList();
});

/// Menu search query.
final menuSearchQueryProvider = StateProvider<String>((ref) => '');

/// Menu items filtered by both category and search query.
final searchedMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final items = ref.watch(filteredMenuItemsProvider);
  final query = ref.watch(menuSearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return items;
  return items
      .where((item) =>
          item.name.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false))
      .toList();
});

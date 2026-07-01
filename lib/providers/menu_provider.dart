import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/services/menu_service.dart';
import '../core/repositories/menu_repository.dart';
import 'auth_provider.dart';

// ─── Infrastructure Providers ─────────────────────────────────

final menuServiceProvider = Provider<MenuService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MenuService(dioClient);
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final service = ref.watch(menuServiceProvider);
  return MenuRepository(service);
});

// ─── Tenant + Branch resolution ───────────────────────────────
// Reads tenantId and branchId from the restored BackendUser stored in
// secure storage. Falls back to null when offline / no session.

final _sessionIdsProvider = Provider<({String? tenantId, String? branchId})>((ref) {
  final authState = ref.watch(authProvider);
  return (tenantId: authState.tenantId, branchId: authState.branchId);
});

// ─── Categories ───────────────────────────────────────────────

/// Async provider that loads categories from the API.
/// Falls back to mock data when offline / tenantId unavailable (debug only).
final categoriesProvider = AsyncNotifierProvider<_CategoriesNotifier, List<Category>>(
  _CategoriesNotifier.new,
);

class _CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    if (ref.read(authProvider).user == null) return const [];
    final ids = ref.watch(_sessionIdsProvider);
    final tenantId = ids.tenantId;

    if (tenantId == null) {
      throw Exception('No tenantId context configured. Please verify your login session.');
    }

    try {
      final repo = ref.watch(menuRepositoryProvider);
      return await repo.fetchCategories(tenantId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MenuProvider] fetchCategories failed: $e');
      }
      rethrow;
    }
  }
}

// ─── Menu Items ───────────────────────────────────────────────

/// Async provider that loads the full effective branch menu.
/// Falls back to mock data when offline / IDs unavailable (debug only).
final menuItemsProvider = AsyncNotifierProvider<_MenuItemsNotifier, List<MenuItem>>(
  _MenuItemsNotifier.new,
);

class _MenuItemsNotifier extends AsyncNotifier<List<MenuItem>> {
  @override
  Future<List<MenuItem>> build() async {
    if (ref.read(authProvider).user == null) return const [];
    final ids = ref.watch(_sessionIdsProvider);
    final tenantId = ids.tenantId;
    final branchId = ids.branchId;

    if (tenantId == null || branchId == null) {
      throw Exception('No tenantId/branchId context configured. Please verify your login session.');
    }

    try {
      final repo = ref.watch(menuRepositoryProvider);
      return await repo.fetchMenuItems(tenantId, branchId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MenuProvider] fetchMenuItems failed: $e');
      }
      rethrow;
    }
  }
}

// ─── Filter / Search Providers ────────────────────────────────
// These are pure synchronous filters on top of the async data.
// They resolve the AsyncValue themselves and expose plain lists
// so that MenuScreen needs zero changes to its filter/search logic.

/// Selected category ID for filtering (null = All).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Menu search query string.
final menuSearchQueryProvider = StateProvider<String>((ref) => '');

/// Items filtered by the selected category only.
final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final itemsAsync = ref.watch(menuItemsProvider);
  final selectedId = ref.watch(selectedCategoryProvider);

  final items = itemsAsync.valueOrNull ?? [];
  if (selectedId == null) return items;
  return items.where((item) => item.categoryId == selectedId).toList();
});

/// Items filtered by category AND search query — consumed by MenuScreen.
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

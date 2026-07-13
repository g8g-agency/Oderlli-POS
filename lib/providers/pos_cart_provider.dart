import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../constants/pos_constants.dart';
import '../core/services/cart_service.dart';
import '../core/services/order_service.dart';
import '../core/repositories/cart_repository.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'menu_provider.dart';
import 'inactivity_provider.dart';

/// State provider for selected table in the cart screen.
final cartSelectedTableProvider = StateProvider<String?>((ref) => null);



// ─── POS Cart Item Wrapper ───────────────────────────────────────────────────

class POSCartItem {
  const POSCartItem({
    required this.menuItem,
    this.qty = 1,
    this.notes,
    this.selectedModifiers = const [],
    this.backendId,
    this.versionNum = 1,
  });

  final MenuItem menuItem;
  final int qty;
  final String? notes;
  final List<String> selectedModifiers;
  final String? backendId; // backend CartItem id
  final int versionNum; // backend CartItem version_num

  double get subtotal => menuItem.price * qty;

  POSCartItem copyWith({
    MenuItem? menuItem,
    int? qty,
    String? notes,
    List<String>? selectedModifiers,
    String? backendId,
    int? versionNum,
  }) =>
      POSCartItem(
        menuItem: menuItem ?? this.menuItem,
        qty: qty ?? this.qty,
        notes: notes ?? this.notes,
        selectedModifiers: selectedModifiers ?? this.selectedModifiers,
        backendId: backendId ?? this.backendId,
        versionNum: versionNum ?? this.versionNum,
      );
}

// ─── POS Cart State Wrapper ──────────────────────────────────────────────────

class POSCartState {
  const POSCartState({
    this.items = const [],
    this.discountPercent = 0.0,
    this.taxPercent = 5.0,
    this.isLoading = false,
    this.errorMessage,
    this.isSchemaMismatch = false,
    this.backendCartVersionNum = 1,
    this.backendCartId,
  });

  final List<POSCartItem> items;
  final double discountPercent;
  final double taxPercent;
  final bool isLoading;
  final String? errorMessage;
  final bool isSchemaMismatch; // If true, displays blocking config mismatch error
  final int backendCartVersionNum; // expectedCartRevision version_num
  final String? backendCartId;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxPercent / 100);
  double get total => taxableAmount + taxAmount;
  int get totalQty => items.fold(0, (sum, item) => sum + item.qty);

  POSCartState copyWith({
    List<POSCartItem>? items,
    double? discountPercent,
    double? taxPercent,
    bool? isLoading,
    ValueGetter<String?>? errorMessage,
    bool? isSchemaMismatch,
    int? backendCartVersionNum,
    String? backendCartId,
  }) =>
      POSCartState(
        items: items ?? this.items,
        discountPercent: discountPercent ?? this.discountPercent,
        taxPercent: taxPercent ?? this.taxPercent,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
        isSchemaMismatch: isSchemaMismatch ?? this.isSchemaMismatch,
        backendCartVersionNum: backendCartVersionNum ?? this.backendCartVersionNum,
        backendCartId: backendCartId ?? this.backendCartId,
      );
}

// ─── Infrastructure Providers ─────────────────────────────────────────────────

final cartServiceProvider = Provider<CartService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CartService(dioClient);
});

final orderServiceProvider = Provider<OrderService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OrderService(dioClient);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final service = ref.watch(cartServiceProvider);
  final conn = ref.watch(connectivityServiceProvider);
  return CartRepository(service, conn);
});

final cartSessionIdsProvider = Provider<({String? tenantId, String? branchId})>((ref) {
  final authState = ref.watch(authProvider);
  return (tenantId: authState.tenantId, branchId: authState.branchId);
});

// ─── POS Cart Notifier ────────────────────────────────────────────────────────

class POSCartNotifier extends StateNotifier<POSCartState> {
  final Ref? ref;
  final CartRepository repository;
  final String? tenantId;
  final String? branchId;
  final String? tableId;
  final _secureStorage = const FlutterSecureStorage();

  POSCartNotifier({
    required this.ref,
    required this.repository,
    required this.tenantId,
    required this.branchId,
    required this.tableId,
  })  : super(const POSCartState());

  /// Load cart details from the backend/repository
  Future<void> loadCart() async {
    if (ref == null) return;
    final user = ref!.read(authProvider).user;
    if (user == null) return;

    if (tenantId == null || branchId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: () => null, isSchemaMismatch: false);
    try {
      final cart = await repository.getCart(
        tenantId!,
        branchId!,
        tableId ?? PosConstants.counterTableId,
      );
      _updateStateFromCart(cart);
    } on DatabaseSchemaMismatchException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSchemaMismatch: true,
        errorMessage: () => e.message,
      );
    } on OfflineCartException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  /// Bumps expectedCartRevision and loads latest state
  Future<void> refreshCart() async {
    await loadCart();
    ref?.read(inactivityServiceProvider).resetTimer();
  }

  /// Frontend validator check for modifier groups
  void _validateModifiers(MenuItem menuItem, List<String> selectedModifiers) {
    for (final group in menuItem.modifierGroups) {
      final selectedOptionsInGroup = group.options.where((opt) {
        return selectedModifiers.any((m) => m.toLowerCase() == opt.name.toLowerCase());
      }).toList();

      final count = selectedOptionsInGroup.length;

      if (group.isRequired && count == 0) {
        throw CartValidationException('Modifier group "${group.name}" is required. Please select at least 1 option.');
      }
      if (count < group.minSelect) {
        throw CartValidationException('Please select at least ${group.minSelect} option(s) for "${group.name}".');
      }
      if (group.maxSelect != null && count > group.maxSelect!) {
        throw CartValidationException('Please select at most ${group.maxSelect} option(s) for "${group.name}".');
      }
    }
  }

  /// Add item to cart
  Future<void> addItem(MenuItem menuItem) async {
    if (tenantId == null || branchId == null) return;

    // Check if the item already exists with exact same modifiers (none, by default when adding from book)
    final existingIndex = state.items.indexWhere(
        (i) => i.menuItem.id == menuItem.id && i.selectedModifiers.isEmpty);

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      Cart updatedCart;
      if (existingIndex >= 0) {
        final existingItem = state.items[existingIndex];
        updatedCart = await repository.updateCartItem(
          tenantId: tenantId!,
          branchId: branchId!,
          tableId: tableId ?? PosConstants.counterTableId,
          itemId: existingItem.backendId ?? '',
          quantity: existingItem.qty + 1,
          itemNotes: existingItem.notes,
          itemVersionNum: existingItem.versionNum,
          expectedCartRevision: state.backendCartVersionNum,
        );
      } else {
        // Validate modifier constraints (defaulting to empty modifier selection)
        _validateModifiers(menuItem, []);

        updatedCart = await repository.addCartItem(
          tenantId: tenantId!,
          branchId: branchId!,
          tableId: tableId ?? PosConstants.counterTableId,
          menuItem: menuItem,
          quantity: 1,
          expectedCartRevision: state.backendCartVersionNum,
        );
      }
      _updateStateFromCart(updatedCart);
      ref?.read(inactivityServiceProvider).resetTimer();
    } on StaleCartRevisionException {
      // Recovery step: reload the cart and throw conflict message
      await refreshCart();
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'OCC Conflict: Cart updated by another terminal. Reloaded. Please retry.',
      );
    } on CartValidationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.toString());
    }
  }

  /// Decrement or remove item from cart
  Future<void> removeItem(MenuItem menuItem) async {
    if (tenantId == null || branchId == null) return;

    // Remove the last matching item by ID
    final existingIndex = state.items.lastIndexWhere((i) => i.menuItem.id == menuItem.id);
    if (existingIndex < 0) return;

    final existingItem = state.items[existingIndex];
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      Cart updatedCart;
      if (existingItem.qty > 1) {
        updatedCart = await repository.updateCartItem(
          tenantId: tenantId!,
          branchId: branchId!,
          tableId: tableId ?? PosConstants.counterTableId,
          itemId: existingItem.backendId ?? '',
          quantity: existingItem.qty - 1,
          itemNotes: existingItem.notes,
          itemVersionNum: existingItem.versionNum,
          expectedCartRevision: state.backendCartVersionNum,
        );
      } else {
        updatedCart = await repository.removeCartItem(
          tenantId: tenantId!,
          branchId: branchId!,
          tableId: tableId ?? PosConstants.counterTableId,
          itemId: existingItem.backendId ?? '',
          itemVersionNum: existingItem.versionNum,
          expectedCartRevision: state.backendCartVersionNum,
        );
      }
      _updateStateFromCart(updatedCart);
      ref?.read(inactivityServiceProvider).resetTimer();
    } on StaleCartRevisionException {
      await refreshCart();
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'OCC Conflict: Cart was updated. Reloaded. Please retry.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.toString());
    }
  }

  /// Update item notes
  Future<void> updateNotes(String menuItemId, String notes) async {
    if (tenantId == null || branchId == null) return;

    final existingIndex = state.items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (existingIndex < 0) return;

    final existingItem = state.items[existingIndex];
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final updatedCart = await repository.updateCartItem(
        tenantId: tenantId!,
        branchId: branchId!,
        tableId: tableId ?? PosConstants.counterTableId,
        itemId: existingItem.backendId ?? '',
        quantity: existingItem.qty,
        itemNotes: notes,
        itemVersionNum: existingItem.versionNum,
        expectedCartRevision: state.backendCartVersionNum,
      );
      _updateStateFromCart(updatedCart);
      ref?.read(inactivityServiceProvider).resetTimer();
    } on StaleCartRevisionException {
      await refreshCart();
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'OCC Conflict: Cart was updated. Reloaded. Please retry.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.toString());
    }
  }

  /// Toggle modifiers.
  /// Backend doesn't support modifier patching directly on items,
  /// so we resolve this by deleting the existing item and re-adding it with new modifiers.
  Future<void> toggleModifier(String menuItemId, String modifier) async {
    if (tenantId == null || branchId == null || tableId == null) return;

    final existingIndex = state.items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (existingIndex < 0) return;

    final existingItem = state.items[existingIndex];
    final currentModifiers = List<String>.from(existingItem.selectedModifiers);

    if (currentModifiers.contains(modifier)) {
      currentModifiers.remove(modifier);
    } else {
      currentModifiers.add(modifier);
    }

    // Perform validation check on the new modifier list
    try {
      _validateModifiers(existingItem.menuItem, currentModifiers);
    } on CartValidationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.message);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      // Step 1: Remove original item
      var updatedCart = await repository.removeCartItem(
        tenantId: tenantId!,
        branchId: branchId!,
        tableId: tableId ?? PosConstants.counterTableId,
        itemId: existingItem.backendId ?? '',
        itemVersionNum: existingItem.versionNum,
        expectedCartRevision: state.backendCartVersionNum,
      );

      // Step 2: Add item with new modifiers list
      updatedCart = await repository.addCartItem(
        tenantId: tenantId!,
        branchId: branchId!,
        tableId: tableId ?? PosConstants.counterTableId,
        menuItem: existingItem.menuItem,
        quantity: existingItem.qty,
        itemNotes: existingItem.notes,
        selectedModifiers: currentModifiers,
        expectedCartRevision: updatedCart.versionNum, // Use new version num from DELETE response
      );

      _updateStateFromCart(updatedCart);
      ref?.read(inactivityServiceProvider).resetTimer();
    } on StaleCartRevisionException {
      await refreshCart();
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'OCC Conflict: Cart was updated. Reloaded. Please retry.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.toString());
    }
  }

  /// Apply discount
  void applyDiscount(double percent) {
    state = state.copyWith(discountPercent: percent);
  }

  Future<Order> checkoutOrder({required OrderService orderService}) async {
    final staffToken = await _secureStorage.read(key: 'staff_jwt_token');
    if (staffToken == null || staffToken.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }
    if (state.backendCartId == null) {
      throw Exception('No active cart to check out.');
    }
    final order = await orderService.checkout(
      staffToken: staffToken,
      mutationId: const Uuid().v4(),
      idempotencyKey: const Uuid().v4(),
      expectedCartRevision: state.backendCartVersionNum,
      mutationEnvelopeBody: {
        'cart_id': state.backendCartId,
        'discount_percent': state.discountPercent,
        'tax_percent': state.taxPercent,
      },
    );
    ref?.read(inactivityServiceProvider).resetTimer();
    return order;
  }

  /// Clear the cart completely (locally / session reset)
  void clear() {
    if (tableId != null) {
      repository.evictTableSession(tableId!);
    }
    state = const POSCartState();
  }

  /// Map backend Cart structure back to POSCartState
  void _updateStateFromCart(Cart cart) {
    final menuItems = ref?.read(menuItemsProvider).valueOrNull ?? [];

    final mappedItems = cart.items.map((item) {
      final menuItem = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => MenuItem(
          id: item.menuItemId,
          name: item.itemNameSnapshot,
          categoryId: '',
          price: item.unitPrice,
          modifierGroups: const [],
        ),
      );

      return POSCartItem(
        menuItem: menuItem,
        qty: item.quantity,
        notes: item.itemNotes,
        selectedModifiers: item.modifiers.map((m) => m.modifierOptionNameSnapshot).toList(),
        backendId: item.id,
        versionNum: item.versionNum,
      );
    }).toList();

    state = POSCartState(
      items: mappedItems,
      discountPercent: state.discountPercent,
      taxPercent: state.taxPercent,
      isLoading: false,
      errorMessage: null,
      isSchemaMismatch: false,
      backendCartVersionNum: cart.versionNum,
      backendCartId: cart.id,
    );
  }
}

// ─── Riverpod Provider Hook ───────────────────────────────────────────────────

final posCartProvider = StateNotifierProvider<POSCartNotifier, POSCartState>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  final sessionIds = ref.watch(cartSessionIdsProvider);
  final selectedTableId = ref.watch(cartSelectedTableProvider);

  final notifier = POSCartNotifier(
    ref: ref,
    repository: repository,
    tenantId: sessionIds.tenantId,
    branchId: sessionIds.branchId,
    tableId: selectedTableId,
  );

  // Only load from backend when we have a real table selected.
  // Counter orders and null table start with an empty local cart.
  final isRealTable = selectedTableId != null &&
      !PosConstants.isCounterTable(selectedTableId);

  if (isRealTable &&
      sessionIds.tenantId != null &&
      sessionIds.branchId != null) {
    notifier.loadCart();
  }

  return notifier;
});

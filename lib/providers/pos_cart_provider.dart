import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class POSCartItem {
  const POSCartItem({
    required this.menuItem,
    this.qty = 1,
    this.notes,
    this.selectedModifiers = const [],
  });

  final MenuItem menuItem;
  final int qty;
  final String? notes;
  final List<String> selectedModifiers;

  double get subtotal => menuItem.price * qty;

  POSCartItem copyWith({
    MenuItem? menuItem,
    int? qty,
    String? notes,
    List<String>? selectedModifiers,
  }) =>
      POSCartItem(
        menuItem: menuItem ?? this.menuItem,
        qty: qty ?? this.qty,
        notes: notes ?? this.notes,
        selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      );
}

class POSCartState {
  const POSCartState({
    this.items = const [],
    this.discountPercent = 0.0,
    this.taxPercent = 5.0,
  });

  final List<POSCartItem> items;
  final double discountPercent;
  final double taxPercent;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxPercent / 100);
  double get total => taxableAmount + taxAmount;
  int get totalQty => items.fold(0, (sum, item) => sum + item.qty);
}

class POSCartNotifier extends StateNotifier<POSCartState> {
  POSCartNotifier() : super(const POSCartState());

  void addItem(MenuItem menuItem) {
    final existingIndex = state.items.indexWhere((i) => i.menuItem.id == menuItem.id);
    if (existingIndex >= 0) {
      final updatedItems = List<POSCartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        qty: updatedItems[existingIndex].qty + 1,
      );
      state = POSCartState(
        items: updatedItems,
        discountPercent: state.discountPercent,
        taxPercent: state.taxPercent,
      );
    } else {
      state = POSCartState(
        items: [...state.items, POSCartItem(menuItem: menuItem)],
        discountPercent: state.discountPercent,
        taxPercent: state.taxPercent,
      );
    }
  }

  void removeItem(MenuItem menuItem) {
    final existingIndex = state.items.indexWhere((i) => i.menuItem.id == menuItem.id);
    if (existingIndex >= 0) {
      final updatedItems = List<POSCartItem>.from(state.items);
      if (updatedItems[existingIndex].qty > 1) {
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          qty: updatedItems[existingIndex].qty - 1,
        );
        state = POSCartState(
          items: updatedItems,
          discountPercent: state.discountPercent,
          taxPercent: state.taxPercent,
        );
      } else {
        updatedItems.removeAt(existingIndex);
        state = POSCartState(
          items: updatedItems,
          discountPercent: state.discountPercent,
          taxPercent: state.taxPercent,
        );
      }
    }
  }

  void updateNotes(String menuItemId, String notes) {
    state = POSCartState(
      items: [
        for (final item in state.items)
          if (item.menuItem.id == menuItemId) item.copyWith(notes: notes) else item,
      ],
      discountPercent: state.discountPercent,
      taxPercent: state.taxPercent,
    );
  }

  void toggleModifier(String menuItemId, String modifier) {
    state = POSCartState(
      items: [
        for (final item in state.items)
          if (item.menuItem.id == menuItemId)
            item.copyWith(
              selectedModifiers: item.selectedModifiers.contains(modifier)
                  ? item.selectedModifiers.where((m) => m != modifier).toList()
                  : [...item.selectedModifiers, modifier],
            )
          else
            item,
      ],
      discountPercent: state.discountPercent,
      taxPercent: state.taxPercent,
    );
  }

  void applyDiscount(double percent) {
    state = POSCartState(
      items: state.items,
      discountPercent: percent,
      taxPercent: state.taxPercent,
    );
  }

  void clear() {
    state = const POSCartState();
  }
}

/// State notifier provider for the active cart.
final posCartProvider = StateNotifierProvider<POSCartNotifier, POSCartState>(
  (ref) => POSCartNotifier(),
);

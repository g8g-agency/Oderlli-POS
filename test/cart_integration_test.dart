import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/core/repositories/cart_repository.dart';
import 'package:orderlli_pos/core/services/cart_service.dart';
import 'package:orderlli_pos/core/services/connectivity_service.dart';
import 'package:orderlli_pos/models/models.dart';
import 'package:orderlli_pos/providers/pos_cart_provider.dart';

// Dummy MockCartService extending CartService
class MockCartService extends CartService {
  MockCartService() : super(null as dynamic);

  @override
  Future<Cart> fetchCart(String qrSessionToken) async {
    throw UnimplementedError();
  }
}

// Dummy MockConnectivityService extending ConnectivityService
class MockConnectivityService extends ConnectivityService {
  @override
  Future<bool> isBackendReachable(String baseUrl, String healthEndpoint) async {
    return false; // Force mock fallback in debug mode
  }
}

void main() {
  group('Cart Integration Model Tests', () {
    test('CartModifier fromJson maps minor-units correctly', () {
      final json = {
        'id': 'mod-1',
        'tenant_id': 'tenant-1',
        'cart_item_id': 'item-1',
        'modifier_group_id': 'group-1',
        'modifier_option_id': 'option-1',
        'modifier_group_name_snapshot': 'Sauces',
        'modifier_option_name_snapshot': 'Ketchup',
        'price_delta_minor_snapshot': 150,
        'created_at': DateTime.now().toIso8601String(),
      };

      final modifier = CartModifier.fromJson(json);
      expect(modifier.priceDeltaMinorSnapshot, 150);
      expect(modifier.priceDelta, 1.50); // $1.50
    });

    test('CartItem fromJson maps fields and aggregates correctly', () {
      final itemJson = {
        'id': 'item-1',
        'tenant_id': 'tenant-1',
        'cart_id': 'cart-1',
        'menu_item_id': 'menu-item-1',
        'item_name_snapshot': 'Crispy Fries',
        'item_sku_snapshot': 'crispy-fries',
        'unit_price_minor_snapshot': 500,
        'quantity': 2,
        'item_notes': 'Extra salt',
        'display_order': 0,
        'version_num': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final modifiers = [
        CartModifier(
          id: 'mod-1',
          tenantId: 'tenant-1',
          cartItemId: 'item-1',
          modifierGroupId: 'group-1',
          modifierOptionId: 'option-1',
          modifierGroupNameSnapshot: 'Add-ons',
          modifierOptionNameSnapshot: 'Cheese',
          priceDeltaMinorSnapshot: 100, // +$1.00
          createdAt: DateTime.now(),
        ),
      ];

      final item = CartItem.fromJson(itemJson, modifiers);
      expect(item.unitPrice, 5.00);
      expect(item.totalModifiersPrice, 1.00);
      expect(item.totalPrice, 12.00); // ($5.00 + $1.00) * 2
    });
  });

  group('CartRepository Mock Fallback and OCC Tests', () {
    late CartRepository repository;

    setUp(() {
      repository = CartRepository(MockCartService(), MockConnectivityService());
    });

    test('Cart creation and OCC version checks', () async {
      // 1. Get empty cart
      final cart = await repository.getCart('tenant-1', 'branch-1', 'table-1');
      expect(cart.versionNum, 1);
      expect(cart.items, isEmpty);

      // 2. Add item using correct revision
      final menuItem = const MenuItem(
        id: 'item-1',
        name: 'Burger',
        categoryId: 'cat-1',
        price: 8.50,
      );

      final cart2 = await repository.addCartItem(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        tableId: 'table-1',
        menuItem: menuItem,
        quantity: 1,
        expectedCartRevision: 1,
      );

      expect(cart2.versionNum, 2);
      expect(cart2.items, hasLength(1));
      expect(cart2.items.first.unitPrice, 8.50);

      // 3. Add item using STALE revision (OCC mismatch)
      expect(
        () => repository.addCartItem(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          tableId: 'table-1',
          menuItem: menuItem,
          quantity: 1,
          expectedCartRevision: 1, // Stale! Expected 2.
        ),
        throwsA(isA<StaleCartRevisionException>()),
      );
    });
  });

  group('Frontend Modifier Validation Tests', () {
    final menuItemWithModifiers = MenuItem(
      id: 'item-1',
      name: 'Burger',
      categoryId: 'cat-1',
      price: 10.00,
      modifierGroups: [
        const ModifierGroup(
          id: 'group-1',
          tenantId: 'tenant-1',
          name: 'Cheese Options',
          isRequired: true,
          minSelect: 1,
          maxSelect: 2,
          isActive: true,
          sortOrder: 0,
          options: [
            ModifierOption(
              id: 'opt-cheddar',
              tenantId: 'tenant-1',
              modifierGroupId: 'group-1',
              name: 'Cheddar',
              priceDelta: 1.0,
              isDefault: true,
              isActive: true,
              sortOrder: 0,
            ),
            ModifierOption(
              id: 'opt-swiss',
              tenantId: 'tenant-1',
              modifierGroupId: 'group-1',
              name: 'Swiss',
              priceDelta: 1.0,
              isDefault: false,
              isActive: true,
              sortOrder: 1,
            ),
          ],
        ),
      ],
    );

    // Dummy notifier wrapping validate
    POSCartNotifier buildNotifier() {
      return POSCartNotifier(
        ref: null,
        repository: CartRepository(MockCartService(), MockConnectivityService()),
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        tableId: 'table-1',
      );
    }

    test('Required group validation fails when nothing is selected', () async {
      final notifier = buildNotifier();
      await notifier.addItem(menuItemWithModifiers);
      expect(
        notifier.state.errorMessage,
        contains('is required. Please select at least 1 option'),
      );
    });

    test('Validation succeeds when selections satisfy constraints', () async {
      final notifier = buildNotifier();
      // Should not throw when valid Cheddar option is toggled/validated
      await notifier.addItem(menuItemWithModifiers.copyWith(modifierGroups: []));
      expect(notifier.state.errorMessage, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:orderlli_pos/core/constants/app_config.dart';
import 'package:orderlli_pos/core/repositories/cart_repository.dart';
import 'package:orderlli_pos/core/services/cart_service.dart';
import 'package:orderlli_pos/core/services/dio_client.dart';
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

// Mock service for Counter Table QR Resolution Bypass
class CounterBypassCartService extends CartService {
  CounterBypassCartService() : super(null as dynamic);

  String? receivedSessionToken;

  @override
  Future<Cart> fetchCart(String qrSessionToken) async {
    receivedSessionToken = qrSessionToken;
    return Cart(
      id: 'cart-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      tableId: '00000000-0000-0000-0000-000000000001',
      sessionId: 'session-1',
      status: 'open',
      versionNum: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<String> resolveQrSessionForTable(String branchId, String tableId) async {
    throw UnsupportedError('Should not be called for counter table');
  }
}

class LiveConnectivityService extends ConnectivityService {
  @override
  Future<bool> isBackendReachable(String baseUrl, String healthEndpoint) async {
    return true; // Live mode, no mock fallback
  }
}

void main() {
  setUpAll(() {
    AppConfig.allowMockFallbackInDebug = true;
  });

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

  group('CartRepository Counter Table Bypass Tests', () {
    test('Counter table bypasses QR session resolution and uses in-memory token', () async {
      final mockService = CounterBypassCartService();
      final repository = CartRepository(mockService, LiveConnectivityService());

      final cart = await repository.getCart('tenant-1', 'branch-1', '00000000-0000-0000-0000-000000000001');

      expect(cart.tableId, '00000000-0000-0000-0000-000000000001');
      expect(mockService.receivedSessionToken, isNull);
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

  group('CartRepository Session Resolution Failure Caching Tests', () {
    test('Known failure (e.g. 404) is cached and not retried', () async {
      final dio = Dio();
      int callCount = 0;
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          callCount++;
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
            ),
          ));
        },
      ));

      final stubDioClient = StubDioClient(dio);
      final mockService = FailureCartService(stubDioClient);
      final repository = CartRepository(mockService, LiveConnectivityService());

      // First call should trigger resolveQrSessionForTable and fail
      dynamic firstError;
      try {
        await repository.getCart('tenant-1', 'branch-1', 'table-1');
      } catch (e) {
        firstError = e;
      }
      expect(firstError, isA<CartValidationException>());
      expect(callCount, 1);

      // Second call should fail immediately from negative cache without calling resolveQrSessionForTable again
      dynamic secondError;
      try {
        await repository.getCart('tenant-1', 'branch-1', 'table-1');
      } catch (e) {
        secondError = e;
      }
      expect(secondError, isA<CartValidationException>());
      expect(callCount, 1); // Still 1!

      // Clear cache and call again — should retry
      repository.clearSessionCache();
      dynamic thirdError;
      try {
        await repository.getCart('tenant-1', 'branch-1', 'table-1');
      } catch (e) {
        thirdError = e;
      }
      expect(thirdError, isA<CartValidationException>());
      expect(callCount, 2);
    });
  });

  group('CartRepository Retry and Eviction Tests', () {
    late bool originalAllowMockFallback;

    setUp(() {
      originalAllowMockFallback = AppConfig.allowMockFallbackInDebug;
      AppConfig.allowMockFallbackInDebug = false;
    });

    tearDown(() {
      AppConfig.allowMockFallbackInDebug = originalAllowMockFallback;
    });

    test('401 error on cached token evicts cache and retries once', () async {
      final mockService = RetryCartService();
      final repository = CartRepository(mockService, LiveConnectivityService());

      mockService.getCartStatusCodes = [200, 401, 200];

      // Step 1: Prime the cache (resolves token-1)
      final cart1 = await repository.getCart('tenant-1', 'branch-1', 'table-1');
      expect(mockService.resolveCount, 1);
      expect(mockService.getCartCount, 1);
      expect(cart1.id, 'cart-1');

      // Step 2: Next call uses cached token, gets 401, evicts, resolves new token-2, retries, gets 200
      final cart2 = await repository.getCart('tenant-1', 'branch-1', 'table-1');
      expect(mockService.resolveCount, 2);
      expect(mockService.getCartCount, 3);
      expect(cart2.id, 'cart-1');
    });

    test('If retried cart operation also fails, it propagates the error and does not loop', () async {
      final mockService = RetryCartService();
      final repository = CartRepository(mockService, LiveConnectivityService());

      mockService.getCartStatusCodes = [200, 401, 401];

      // Prime the cache
      await repository.getCart('tenant-1', 'branch-1', 'table-1');

      // Second call fails twice
      dynamic error;
      try {
        await repository.getCart('tenant-1', 'branch-1', 'table-1');
      } catch (e) {
        error = e;
      }
      expect(error, isA<CartValidationException>());
      expect(mockService.resolveCount, 2);
      expect(mockService.getCartCount, 3);
    });

    test('If token was not cached, a 401 error does not trigger retry', () async {
      final mockService = RetryCartService();
      final repository = CartRepository(mockService, LiveConnectivityService());

      mockService.getCartStatusCodes = [401];

      dynamic error;
      try {
        await repository.getCart('tenant-1', 'branch-1', 'table-1');
      } catch (e) {
        error = e;
      }
      expect(error, isA<CartValidationException>());
      expect(mockService.resolveCount, 1);
      expect(mockService.getCartCount, 1);
    });

    test('If re-resolution itself throws 401, it propagates the failure without looping', () async {
      final mockService = RetryCartService();
      final repository = CartRepository(mockService, LiveConnectivityService());

      mockService.getCartStatusCodes = [200, 401];
      // Prime the cache
      await repository.getCart('tenant-1', 'branch-1', 'table-1');

      // Make next resolution fail
      mockService.failResolveWith401 = true;

      dynamic error;
      try {
        await repository.getCart('tenant-1', 'branch-1', 'table-1');
      } catch (e) {
        error = e;
      }
      expect(error, isA<CartValidationException>());
      expect(mockService.resolveCount, 2);
      // Fetch cart was only called for the initial check (1) and the second check using cached token (1), total 2
      expect(mockService.getCartCount, 2);
    });
  });
}

class FailureCartService extends CartService {
  FailureCartService(super.dioClient);
}

class RetryCartService extends CartService {
  int resolveCount = 0;
  int getCartCount = 0;
  List<int> getCartStatusCodes = [];
  bool failResolveWith401 = false;

  RetryCartService() : super(null as dynamic);

  @override
  Future<String> resolveQrSessionForTableRaw(String branchId, String tableId) async {
    resolveCount++;
    if (failResolveWith401) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/qr/resolve'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/qr/resolve'),
          statusCode: 401,
        ),
      );
    }
    return 'token-$resolveCount';
  }

  @override
  Future<Cart> fetchCart(String qrSessionToken) async {
    final index = getCartCount;
    getCartCount++;
    if (index < getCartStatusCodes.length) {
      final code = getCartStatusCodes[index];
      if (code == 200) {
        return Cart(
          id: 'cart-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          tableId: 'table-1',
          sessionId: 'session-1',
          status: 'open',
          versionNum: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/v1/cart'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/cart'),
            statusCode: code,
          ),
        );
      }
    }
    return Cart(
      id: 'cart-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      tableId: 'table-1',
      sessionId: 'session-1',
      status: 'open',
      versionNum: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class StubDioClient implements DioClient {
  @override
  final Dio dio;

  StubDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}



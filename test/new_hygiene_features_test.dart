import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orderlli_pos/models/models.dart';
import 'package:orderlli_pos/providers/active_bill_provider.dart';
import 'package:orderlli_pos/providers/auth_provider.dart';
import 'package:orderlli_pos/providers/orders_provider.dart';
import 'package:orderlli_pos/core/repositories/order_repository.dart';
import 'package:orderlli_pos/core/services/secure_storage_service.dart';
import 'package:orderlli_pos/core/services/dio_client.dart';
import 'package:orderlli_pos/widgets/manager_override_dialog.dart';

// Mock Secure Storage Service
class MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveRuntimeToken(String token) async {
    _data['staff_jwt_token'] = token;
  }

  @override
  Future<String?> getRuntimeToken() async {
    return _data['staff_jwt_token'];
  }
}

// Mock Order Repository
class MockOrderRepository implements OrderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<OrderDetail> getOrderDetail(String orderId) async {
    return OrderDetail(
      id: orderId,
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      tableId: 'table-1',
      orderSnapshotId: 'snap-1',
      orderNumber: 'ORD-123',
      status: OrderStatus.pending,
      source: 'staff_pos',
      versionNum: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [
        OrderItem(
          id: 'item-1',
          menuItemId: 'menu-item-1',
          itemNameSnapshot: 'Burger',
          unitPriceMinor: 15000, // ₹150.00
          quantity: 2,
        ),
      ],
      subtotalMinor: 30000,
      taxTotalMinor: 1500,
      discountTotalMinor: 3000,
      grandTotalMinor: 28500,
    );
  }
}

// Mock Auth Notifier
class MockAuthNotifier extends AuthNotifier {
  // ignore: use_super_parameters
  MockAuthNotifier(Ref ref, AuthState initialState) : super(ref) {
    state = initialState;
  }

  @override
  Future<void> loadSession() async {
    // Overridden to prevent SharedPreferences and restoreSession from running during test
  }
}

// Stub Dio Client for Mocking API Responses
class StubDioClient implements DioClient {
  @override
  final Dio dio;
  StubDioClient(this.dio);
  
  @override
  final onSessionExpired = Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Orders list parsing tests', () {
    test('Order fromJson parses subtotal_minor and grand_total_minor correctly', () {
      final json = {
        'id': 'order-123',
        'table_id': 'table-1',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'subtotal_minor': 15000,
        'grand_total_minor': 15750,
      };

      final order = Order.fromJson(json);
      expect(order.subtotalMinor, 15000);
      expect(order.grandTotalMinor, 15750);
      expect(order.subtotal, 150.0);
      expect(order.total, 157.5);
    });

    test('OrderSummary fromJson parses grand_total_minor and total correctly', () {
      final json = {
        'id': 'order-123',
        'order_number': 'ORD-25597287',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'table_id': 'table-1',
        'grand_total_minor': 25000,
      };

      final summary = OrderSummary.fromJson(json);
      expect(summary.grandTotalMinor, 25000);
      expect(summary.total, 250.0);
    });
  });

  group('ActiveBillProvider and Payments Tests', () {
    late ProviderContainer container;
    late MockSecureStorageService mockSecureStorage;
    late Dio mockDio;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      mockDio = Dio();
      mockSecureStorage.saveRuntimeToken('dummy-runtime-token');

      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          orderRepositoryProvider.overrideWithValue(MockOrderRepository()),
          dioClientProvider.overrideWithValue(StubDioClient(mockDio)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Payment persist success state updates correctly', () async {
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'success': true,
              'data': {
                'payment': {
                  'id': 'payment-id-123',
                }
              }
            },
          ));
        },
      ));

      final activeBill = container.read(activeBillProvider.notifier);
      final initialOrder = Order(
        id: 'order-123',
        tableId: 'table-1',
        tableNumber: 1,
        items: const [],
        createdAt: DateTime(2026, 6, 19),
      );

      activeBill.setOrder(initialOrder);
      await Future.delayed(Duration.zero);

      expect(container.read(activeBillProvider)!.isSubmittingPayment, false);

      final addPaymentFuture = activeBill.addPayment('Card', 100.0);
      expect(container.read(activeBillProvider)!.isSubmittingPayment, true);

      await addPaymentFuture;

      final state = container.read(activeBillProvider)!;
      expect(state.isSubmittingPayment, false);
      expect(state.paymentError, null);
      expect(state.payments.length, 1);
      expect(state.payments.first.amount, 100.0);
      expect(state.payments.first.method, 'Card');
    });

    test('Payment persist failure sets paymentError correctly', () async {
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'success': false,
                'message': 'Insufficient funds',
              },
            ),
          ));
        },
      ));

      final activeBill = container.read(activeBillProvider.notifier);
      final initialOrder = Order(
        id: 'order-123',
        tableId: 'table-1',
        tableNumber: 1,
        items: const [],
        createdAt: DateTime(2026, 6, 19),
      );

      activeBill.setOrder(initialOrder);
      await Future.delayed(Duration.zero);

      await activeBill.addPayment('Card', 100.0);

      final state = container.read(activeBillProvider)!;
      expect(state.isSubmittingPayment, false);
      expect(state.paymentError, contains('Payment declined: Insufficient funds'));
    });
  });

  group('Manager PIN Verification Tests', () {
    testWidgets('Manager Override Dialog with wrong PIN blocks approval and shows error', (WidgetTester tester) async {
      final mockDio = Dio();
      final mockSecureStorage = MockSecureStorageService();
      
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/staff/login') {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
              ),
            ));
          } else {
            handler.next(options);
          }
        },
      ));

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          dioClientProvider.overrideWithValue(StubDioClient(mockDio)),
          authProvider.overrideWith((ref) => MockAuthNotifier(
            ref,
            const AuthState(
              user: PosUser(
                id: 'user-1',
                name: 'Staff',
                role: UserRole.cashier,
                pin: '',
                terminalId: 'POS Terminal',
              ),
              isLoading: false,
              isLocked: false,
              lockedUser: null,
              errorMessage: null,
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              availableBranches: [],
              isOrgAuthenticated: true,
            ),
          )),
        ],
      );

      bool? result;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(1024, 768),
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const ManagerOverrideDialog(
                          actionName: 'Test Discount',
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ManagerOverrideDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'manager-123');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-pin');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approve'));
      await tester.pump(); 
      await tester.pump(); 
      await tester.pumpAndSettle();

      expect(find.byType(ManagerOverrideDialog), findsOneWidget);
      expect(find.text('Incorrect ID or PIN. Try again.'), findsOneWidget);
      expect(result, null);
    });
  });
}

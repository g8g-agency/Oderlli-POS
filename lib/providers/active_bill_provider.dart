import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'orders_provider.dart';
import 'table_provider.dart';
import 'shift_provider.dart';
import 'inactivity_provider.dart';

/// Tracks the active table being checked out.
final activeTableIdProvider = StateProvider<String?>((ref) => null);

/// Looks up the active order for the selected table.
final activeTableOrderProvider = Provider<Order?>((ref) {
  final tableId = ref.watch(activeTableIdProvider);
  final orders = ref.watch(ordersProvider);

  if (orders.isEmpty || tableId == null) return null;

  // Match by tableId directly (most accurate — avoids the old tableNumber lookup)
  for (final o in orders) {
    if (o.tableId == tableId &&
        o.status != OrderStatus.served &&
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled) {
      return o;
    }
  }

  return null;
});

/// A single payment transaction record on a bill.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.method,
    required this.amount,
    required this.timestamp,
    required this.waiterName,
    required this.amountMinor,
    this.idempotencyKey,
  });

  final String id;
  final String method; // 'Cash', 'Card', 'Mobile', etc.
  final double amount;
  final DateTime timestamp;
  final String waiterName;
  final int amountMinor;
  final String? idempotencyKey;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final rawMethod = json['method'] as String? ?? 'cash';
    String displayMethod = 'Cash';
    if (rawMethod.toLowerCase() == 'card') {
      displayMethod = 'Card';
    } else if (rawMethod.toLowerCase() == 'qr_pay') {
      displayMethod = 'UPI';
    } else if (rawMethod.toLowerCase() == 'upi') {
      displayMethod = 'UPI';
    } else {
      displayMethod = rawMethod.isNotEmpty
          ? rawMethod[0].toUpperCase() + rawMethod.substring(1)
          : 'Cash';
    }

    final amountMinor = json['amount_minor'] as int? ?? 0;
    final createdAtStr = json['created_at'] as String? ??
        json['completed_at'] as String? ??
        DateTime.now().toIso8601String();

    return PaymentRecord(
      id: json['id']?.toString() ?? '',
      method: displayMethod,
      amount: amountMinor / 100.0,
      timestamp: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
      waiterName: 'Staff',
      amountMinor: amountMinor,
      idempotencyKey: json['idempotency_key'] as String?,
    );
  }
}

/// Checkout/billing details state.
class ActiveBillState {
  const ActiveBillState({
    required this.order,
    this.discountPercent = 0.0,
    this.serviceChargePercent = 10.0, // 10% default
    this.payments = const [],
    this.isSubmittingPayment = false,
    this.paymentError,
    this.paymentsHydrated = false,
  });

  final Order order;
  final double discountPercent;
  final double serviceChargePercent;
  final List<PaymentRecord> payments;
  final bool isSubmittingPayment;

  /// Non-null when the last payment attempt failed. Cleared on next
  /// successful submission or via [ActiveBillNotifier.clearPaymentError].
  final String? paymentError;
  final bool paymentsHydrated;

  double get subtotal => order.subtotal;

  int get subtotalPaise => (subtotal * 100).round();
  int get discountPaise => (subtotalPaise * discountPercent / 100).round();
  int get taxablePaise => subtotalPaise - discountPaise;
  int get taxPaise => (taxablePaise * order.taxPercent / 100).round();
  int get serviceChargePaise => (taxablePaise * serviceChargePercent / 100).round();
  int get grandTotalPaise => taxablePaise + taxPaise + serviceChargePaise;

  double get discountAmount => discountPaise / 100.0;
  double get taxableAmount => taxablePaise / 100.0;
  double get taxAmount => taxPaise / 100.0;
  double get serviceChargeAmount => serviceChargePaise / 100.0;
  double get total => grandTotalPaise / 100.0;

  int get amountPaidPaise => payments.fold(0, (sum, p) => sum + p.amountMinor);
  int get amountRemainingPaise => grandTotalPaise - amountPaidPaise;

  double get amountPaid => amountPaidPaise / 100.0;
  double get amountRemaining => amountRemainingPaise / 100.0;

  bool get isPaid => amountRemainingPaise <= 0;
  bool get isPartiallyPaid => amountPaidPaise > 0 && amountRemainingPaise > 0;

  String get settlementStatus {
    if (isPaid) return 'Settled';
    if (isPartiallyPaid) return 'Partially Paid';
    return 'Unpaid';
  }

  String get lastPaymentMethod =>
      payments.isNotEmpty ? payments.last.method : 'Cash';

  ActiveBillState copyWith({
    Order? order,
    double? discountPercent,
    double? serviceChargePercent,
    List<PaymentRecord>? payments,
    bool? isSubmittingPayment,
    String? Function()? paymentError,
    bool? paymentsHydrated,
  }) =>
      ActiveBillState(
        order: order ?? this.order,
        discountPercent: discountPercent ?? this.discountPercent,
        serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
        payments: payments ?? this.payments,
        isSubmittingPayment: isSubmittingPayment ?? this.isSubmittingPayment,
        paymentError: paymentError != null ? paymentError() : this.paymentError,
        paymentsHydrated: paymentsHydrated ?? this.paymentsHydrated,
      );
}

/// Notifier that manages the active checkout bill.
class ActiveBillNotifier extends StateNotifier<ActiveBillState?> {
  ActiveBillNotifier(this._ref) : super(null) {
    // Listen to selected table order to update bill state dynamically
    _ref.listen<Order?>(activeTableOrderProvider, (previous, next) {
      if (next != null) {
        setOrder(next);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  void setOrder(Order order) async {
    final currentState = state;
    if (currentState != null && currentState.order.id == order.id) {
      // Keep existing items/totals, but merge in status/update info from tables provider/orders list
      final mergedOrder = currentState.order.copyWith(
        status: order.status,
        versionNum: order.versionNum,
        updatedAt: order.updatedAt,
      );
      state = currentState.copyWith(order: mergedOrder);
      if (currentState.paymentsHydrated) {
        return; // Already fetched and hydrated
      }
    } else {
      state = ActiveBillState(
        order: order,
        payments: const <PaymentRecord>[],
        paymentsHydrated: false,
      );
    }

    // Load full order details and payments from backend
    await _fetchFullOrderAndPayments(order.id, order.tableNumber);
  }

  Future<void> _fetchFullOrderAndPayments(String orderId, int tableNumber) async {
    try {
      final orderDetail = await _ref.read(orderRepositoryProvider).getOrderDetail(orderId);
      final fullOrder = Order(
        id: orderDetail.id,
        tableId: orderDetail.tableId,
        tableNumber: tableNumber,
        items: orderDetail.items,
        createdAt: orderDetail.createdAt,
        status: orderDetail.status,
        updatedAt: orderDetail.updatedAt,
        servedBy: orderDetail.createdBy,
        discountPercent: orderDetail.discountTotalMinor > 0 && orderDetail.subtotalMinor > 0 
            ? (orderDetail.discountTotalMinor / orderDetail.subtotalMinor) * 100 
            : 0.0,
        taxPercent: orderDetail.taxTotalMinor > 0 && (orderDetail.subtotalMinor - orderDetail.discountTotalMinor) > 0
            ? (orderDetail.taxTotalMinor / (orderDetail.subtotalMinor - orderDetail.discountTotalMinor)) * 100
            : 5.0,
        notes: orderDetail.orderNotes,
        versionNum: orderDetail.versionNum,
        orderSnapshotId: orderDetail.orderSnapshotId,
        orderNumber: orderDetail.orderNumber,
        subtotalMinor: orderDetail.subtotalMinor,
        taxTotalMinor: orderDetail.taxTotalMinor,
        discountTotalMinor: orderDetail.discountTotalMinor,
        grandTotalMinor: orderDetail.grandTotalMinor,
      );

      // Verify order ID hasn't changed while request was in-flight
      if (state == null || state!.order.id != orderId) return;

      state = state!.copyWith(order: fullOrder);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveBillNotifier] Failed to fetch full order detail: $e');
      }
    }

    // Load payments
    await loadPayments();
  }

  Future<void> loadPayments() async {
    final currentState = state;
    if (currentState == null) return;
    final orderId = currentState.order.id;

    try {
      final secureStorage = _ref.read(secureStorageProvider);
      final staffToken = await secureStorage.getRuntimeToken();
      if (staffToken == null || staffToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.get(
        '/api/v1/orders/$orderId/payments',
        options: Options(
          headers: {
            'Authorization': 'Bearer $staffToken',
          },
        ),
      );

      // Protect against race conditions: verify order ID hasn't changed while request was in-flight
      if (state == null || state!.order.id != orderId) return;

      if (response.data != null) {
        // If data is a list directly or wrapped in a success payload
        final List<dynamic> rawList = response.data is List
            ? response.data
            : (response.data['data'] as List<dynamic>? ?? []);
        
        final payments = rawList.map((item) => PaymentRecord.fromJson(item as Map<String, dynamic>)).toList();
        
        state = state!.copyWith(
          payments: payments,
          paymentsHydrated: true,
        );
      } else {
        throw Exception('Response data is null');
      }
    } catch (e) {
      // If the fetch fails (network error or 404): set state.payments = [] and state.paymentsHydrated = false — do not crash, silently start fresh
      if (state != null && state!.order.id == orderId) {
        state = state!.copyWith(
          payments: const <PaymentRecord>[],
          paymentsHydrated: false,
        );
      }
    }
  }

  void applyDiscount(double percent) {
    if (state != null) {
      state = state!.copyWith(discountPercent: percent);
    }
  }

  /// Logs a manager override action to the shift activity log.
  void auditManagerOverride({
    required double discountPercent,
    required String approvedByPin,
    required String cashierName,
  }) {
    final currentState = state;
    if (currentState == null) return;

    final orderId = currentState.order.orderNumber ?? currentState.order.id;
    final now = DateTime.now();

    final activity = ShiftActivity(
      id: 'override-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.xReport,
      timestamp: now,
      amount: 0.0,
      title: 'Manager Override: ${discountPercent.toStringAsFixed(0)}% Discount',
      subtitle: 'Order $orderId — approved by manager PIN '
          '•••• — cashier: $cashierName',
      performedBy: 'Manager',
    );

    _ref.read(shiftProvider.notifier).state =
        _ref.read(shiftProvider.notifier).state.copyWith(
              activities: [
                activity,
                ..._ref.read(shiftProvider.notifier).state.activities,
              ],
            );
  }

  void applyServiceCharge(double percent) {
    if (state != null) {
      state = state!.copyWith(serviceChargePercent: percent);
    }
  }

  Future<void> addPayment(String method, double amount) async {
    final currentState = state;
    if (currentState == null) return;

    final orderId = currentState.order.id;
    final previousState = currentState;

    // Set loading/submitting flag and clear any prior error
    state = currentState.copyWith(
      isSubmittingPayment: true,
      paymentError: () => null,
    );

    try {
      final secureStorage = _ref.read(secureStorageProvider);
      final staffToken = await secureStorage.getRuntimeToken();
      if (staffToken == null || staffToken.isEmpty) {
        throw Exception('Not authenticated. Please log in again.');
      }

      final idempotencyKey = const Uuid().v4();
      final amountMinor = (amount * 100).round();

      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.post(
        '/api/v1/orders/$orderId/payments',
        data: {
          'method': method,
          'amount_minor': amountMinor,
          'idempotency_key': idempotencyKey,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $staffToken',
            'Idempotency-Key': idempotencyKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data == null ||
          (response.data['success'] != true && response.data['status'] != 'success')) {
        throw Exception('Payment API failed');
      }

      final newPayment = PaymentRecord(
        id: response.data['data']?['payment']?['id']?.toString() ??
            'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: method,
        amount: amount,
        timestamp: DateTime.now(),
        waiterName: currentState.order.servedBy ?? (_ref.read(authProvider).user?.name ?? 'Staff'),
        amountMinor: amountMinor,
      );
      final updatedPayments = [...currentState.payments, newPayment];
      
      state = currentState.copyWith(
        payments: updatedPayments,
        isSubmittingPayment: false,
        paymentError: () => null,
      );

      _ref.read(inactivityServiceProvider).resetTimer();

      // Perform local side effects on success
      if (method == 'Cash') {
        _ref.read(shiftProvider.notifier).addCashSale(
              amount,
              currentState.order.orderNumber ?? currentState.order.id,
            );
      }

      final currentRemaining = state?.amountRemainingPaise ?? 0;
      if (currentRemaining <= 0) {
        final tableId = currentState.order.tableId;
        const counterTableId = '00000000-0000-0000-0000-000000000001';
        if (tableId != counterTableId) {
          _ref.read(posTablesProvider.notifier).clearTable(tableId);
        }
        _ref.read(ordersProvider.notifier).updateStatus(currentState.order.id, OrderStatus.served);
      } else {
        _ref.read(posTablesProvider.notifier).updateStatus(currentState.order.tableId, POSTableStatus.paymentPending);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        // Treat as success, but skip adding duplicate to local state
        state = previousState.copyWith(
          isSubmittingPayment: false,
          paymentError: () => null,
        );
        return;
      }

      final serverMsg = e.response?.data is Map
          ? (e.response!.data['message'] as String?) ?? ''
          : '';

      String userMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        userMessage = 'Payment timed out. Check connection and retry.';
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        userMessage = serverMsg.isNotEmpty
            ? 'Payment declined: $serverMsg'
            : 'Payment failed. Please verify details and retry.';
      } else {
        userMessage = 'Payment failed. Check connection and retry.';
      }

      state = previousState.copyWith(
        isSubmittingPayment: false,
        paymentError: () => userMessage,
      );
    } catch (e) {
      state = previousState.copyWith(
        isSubmittingPayment: false,
        paymentError: () => e.toString().contains('Not authenticated')
            ? 'Session expired. Please log in again.'
            : 'Payment failed. Check connection and retry.',
      );
    }
  }

  /// Resets [ActiveBillState.paymentError] to null so the UI banner is
  /// dismissed without triggering a new payment attempt.
  void clearPaymentError() {
    if (state != null) {
      state = state!.copyWith(paymentError: () => null);
    }
  }

  void clear() {
    state = null;
  }
}

/// Provider exposing the active billing/checkout state.
final activeBillProvider = StateNotifierProvider<ActiveBillNotifier, ActiveBillState?>((ref) {
  return ActiveBillNotifier(ref);
});

/// Branch-level receipt metadata (GSTIN/FSSAI can be wired from API later).
class BranchConfig {
  const BranchConfig({
    required this.restaurantName,
    required this.branchName,
    this.gstin,
    this.fssai,
  });

  final String restaurantName;
  final String branchName;
  final String? gstin;
  final String? fssai;

  BranchConfig copyWith({
    String? restaurantName,
    String? branchName,
    String? gstin,
    String? fssai,
  }) =>
      BranchConfig(
        restaurantName: restaurantName ?? this.restaurantName,
        branchName: branchName ?? this.branchName,
        gstin: gstin ?? this.gstin,
        fssai: fssai ?? this.fssai,
      );
}

final branchConfigProvider = Provider<BranchConfig>((ref) {
  final auth = ref.watch(authProvider);
  return BranchConfig(
    restaurantName: auth.branchName ?? 'Orderlli Restaurant',
    branchName: auth.branchName ?? 'Main Branch',
    gstin: auth.gstin,
    fssai: auth.fssai,
  );
});

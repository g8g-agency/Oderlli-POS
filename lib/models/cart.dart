import 'cart_item.dart';

class Cart {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableId;
  final String sessionId;
  final String status; // 'open' | 'locked' | 'submitted' | 'abandoned'
  final String? checkoutIdempotencyKey;
  final DateTime? lockedAt;
  final DateTime? submittedAt;
  final DateTime? abandonedAt;
  final String? orderNotes;
  final int versionNum;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItem> items;
  final int subtotalMinor;
  final int discountMinor;
  final int totalTaxMinor;
  final int grandTotalMinor;

  const Cart({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableId,
    required this.sessionId,
    required this.status,
    this.checkoutIdempotencyKey,
    this.lockedAt,
    this.submittedAt,
    this.abandonedAt,
    this.orderNotes,
    required this.versionNum,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.subtotalMinor = 0,
    this.discountMinor = 0,
    this.totalTaxMinor = 0,
    this.grandTotalMinor = 0,
  });

  factory Cart.empty() => Cart(
        id: '',
        tenantId: '',
        branchId: '',
        tableId: '',
        sessionId: '',
        status: 'open',
        versionNum: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [],
      );

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalQty => items.fold(0, (sum, item) => sum + item.quantity);

  Cart copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? tableId,
    String? sessionId,
    String? status,
    String? checkoutIdempotencyKey,
    DateTime? lockedAt,
    DateTime? submittedAt,
    DateTime? abandonedAt,
    String? orderNotes,
    int? versionNum,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CartItem>? items,
    int? subtotalMinor,
    int? discountMinor,
    int? totalTaxMinor,
    int? grandTotalMinor,
  }) =>
      Cart(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        branchId: branchId ?? this.branchId,
        tableId: tableId ?? this.tableId,
        sessionId: sessionId ?? this.sessionId,
        status: status ?? this.status,
        checkoutIdempotencyKey: checkoutIdempotencyKey ?? this.checkoutIdempotencyKey,
        lockedAt: lockedAt ?? this.lockedAt,
        submittedAt: submittedAt ?? this.submittedAt,
        abandonedAt: abandonedAt ?? this.abandonedAt,
        orderNotes: orderNotes ?? this.orderNotes,
        versionNum: versionNum ?? this.versionNum,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        items: items ?? this.items,
        subtotalMinor: subtotalMinor ?? this.subtotalMinor,
        discountMinor: discountMinor ?? this.discountMinor,
        totalTaxMinor: totalTaxMinor ?? this.totalTaxMinor,
        grandTotalMinor: grandTotalMinor ?? this.grandTotalMinor,
      );

  factory Cart.fromJson(Map<String, dynamic> json, [List<CartItem> cartItems = const [], Map<String, dynamic>? totals]) => Cart(
        id: (json['id'] ?? '') as String,
        tenantId: (json['tenant_id'] ?? '') as String,
        branchId: (json['branch_id'] ?? '') as String,
        tableId: (json['table_id'] ?? '') as String,
        sessionId: (json['session_id'] ?? '') as String,
        status: (json['status'] ?? 'open') as String,
        checkoutIdempotencyKey: json['checkout_idempotency_key'] as String?,
        lockedAt: json['locked_at'] != null ? DateTime.parse(json['locked_at'] as String) : null,
        submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
        abandonedAt: json['abandoned_at'] != null ? DateTime.parse(json['abandoned_at'] as String) : null,
        orderNotes: json['order_notes'] as String?,
        versionNum: (json['version_num'] ?? 0) as int,
        createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
        updatedAt: DateTime.parse((json['updated_at'] ?? DateTime.now().toIso8601String()) as String),
        items: cartItems,
        subtotalMinor: (totals?['subtotal_minor'] ?? 0) as int,
        discountMinor: (totals?['discount_minor'] ?? 0) as int,
        totalTaxMinor: (totals?['total_tax_minor'] ?? 0) as int,
        grandTotalMinor: (totals?['grand_total_minor'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'branch_id': branchId,
        'table_id': tableId,
        'session_id': sessionId,
        'status': status,
        'checkout_idempotency_key': checkoutIdempotencyKey,
        'locked_at': lockedAt?.toIso8601String(),
        'submitted_at': submittedAt?.toIso8601String(),
        'abandoned_at': abandonedAt?.toIso8601String(),
        'order_notes': orderNotes,
        'version_num': versionNum,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

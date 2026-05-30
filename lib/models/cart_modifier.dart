class CartModifier {
  final String id;
  final String tenantId;
  final String cartItemId;
  final String modifierGroupId;
  final String modifierOptionId;
  final String modifierGroupNameSnapshot;
  final String modifierOptionNameSnapshot;
  final int priceDeltaMinorSnapshot;
  final DateTime createdAt;

  const CartModifier({
    required this.id,
    required this.tenantId,
    required this.cartItemId,
    required this.modifierGroupId,
    required this.modifierOptionId,
    required this.modifierGroupNameSnapshot,
    required this.modifierOptionNameSnapshot,
    required this.priceDeltaMinorSnapshot,
    required this.createdAt,
  });

  double get priceDelta => priceDeltaMinorSnapshot / 100.0;

  factory CartModifier.fromJson(Map<String, dynamic> json) => CartModifier(
        id: (json['id'] ?? '') as String,
        tenantId: (json['tenant_id'] ?? '') as String,
        cartItemId: (json['cart_item_id'] ?? '') as String,
        modifierGroupId: (json['modifier_group_id'] ?? '') as String,
        modifierOptionId: (json['modifier_option_id'] ?? '') as String,
        modifierGroupNameSnapshot: (json['modifier_group_name_snapshot'] ?? '') as String,
        modifierOptionNameSnapshot: (json['modifier_option_name_snapshot'] ?? '') as String,
        priceDeltaMinorSnapshot: (json['price_delta_minor_snapshot'] ?? 0) as int,
        createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'cart_item_id': cartItemId,
        'modifier_group_id': modifierGroupId,
        'modifier_option_id': modifierOptionId,
        'modifier_group_name_snapshot': modifierGroupNameSnapshot,
        'modifier_option_name_snapshot': modifierOptionNameSnapshot,
        'price_delta_minor_snapshot': priceDeltaMinorSnapshot,
        'created_at': createdAt.toIso8601String(),
      };
}

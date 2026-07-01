import 'cart_modifier.dart';

class CartItem {
  final String id;
  final String tenantId;
  final String cartId;
  final String menuItemId;
  final String itemNameSnapshot;
  final String? itemSkuSnapshot;
  final int unitPriceMinorSnapshot;
  final int quantity;
  final String? itemNotes;
  final int displayOrder;
  final int versionNum;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartModifier> modifiers;

  const CartItem({
    required this.id,
    required this.tenantId,
    required this.cartId,
    required this.menuItemId,
    required this.itemNameSnapshot,
    this.itemSkuSnapshot,
    required this.unitPriceMinorSnapshot,
    required this.quantity,
    this.itemNotes,
    required this.displayOrder,
    required this.versionNum,
    required this.createdAt,
    required this.updatedAt,
    this.modifiers = const [],
  });

  double get unitPrice => unitPriceMinorSnapshot / 100.0;
  double get totalModifiersPrice => modifiers.fold(0.0, (sum, mod) => sum + mod.priceDelta);
  double get totalPrice => (unitPrice + totalModifiersPrice) * quantity;

  CartItem copyWith({
    String? id,
    String? tenantId,
    String? cartId,
    String? menuItemId,
    String? itemNameSnapshot,
    String? itemSkuSnapshot,
    int? unitPriceMinorSnapshot,
    int? quantity,
    String? itemNotes,
    int? displayOrder,
    int? versionNum,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CartModifier>? modifiers,
  }) =>
      CartItem(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        cartId: cartId ?? this.cartId,
        menuItemId: menuItemId ?? this.menuItemId,
        itemNameSnapshot: itemNameSnapshot ?? this.itemNameSnapshot,
        itemSkuSnapshot: itemSkuSnapshot ?? this.itemSkuSnapshot,
        unitPriceMinorSnapshot: unitPriceMinorSnapshot ?? this.unitPriceMinorSnapshot,
        quantity: quantity ?? this.quantity,
        itemNotes: itemNotes ?? this.itemNotes,
        displayOrder: displayOrder ?? this.displayOrder,
        versionNum: versionNum ?? this.versionNum,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        modifiers: modifiers ?? this.modifiers,
      );

  factory CartItem.fromJson(Map<String, dynamic> json, [List<CartModifier> itemModifiers = const []]) => CartItem(
        id: (json['id'] ?? '') as String,
        tenantId: (json['tenant_id'] ?? '') as String,
        cartId: (json['cart_id'] ?? '') as String,
        menuItemId: (json['menu_item_id'] ?? '') as String,
        itemNameSnapshot: (json['item_name_snapshot'] ?? '') as String,
        itemSkuSnapshot: json['item_sku_snapshot'] as String?,
        unitPriceMinorSnapshot: (json['unit_price_minor_snapshot'] ?? 0) as int,
        quantity: (json['quantity'] ?? 0) as int,
        itemNotes: json['item_notes'] as String?,
        displayOrder: (json['display_order'] ?? 0) as int,
        versionNum: (json['version_num'] ?? 0) as int,
        createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
        updatedAt: DateTime.parse((json['updated_at'] ?? DateTime.now().toIso8601String()) as String),
        modifiers: itemModifiers,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'cart_id': cartId,
        'menu_item_id': menuItemId,
        'item_name_snapshot': itemNameSnapshot,
        'item_sku_snapshot': itemSkuSnapshot,
        'unit_price_minor_snapshot': unitPriceMinorSnapshot,
        'quantity': quantity,
        'item_notes': itemNotes ?? '',
        'display_order': displayOrder,
        'version_num': versionNum,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

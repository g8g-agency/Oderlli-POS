class ModifierOption {
  final String id;
  final String tenantId;
  final String modifierGroupId;
  final String name;
  final double priceDelta;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;

  const ModifierOption({
    required this.id,
    required this.tenantId,
    required this.modifierGroupId,
    required this.name,
    required this.priceDelta,
    required this.isDefault,
    required this.isActive,
    required this.sortOrder,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      id: (json['id'] ?? '') as String,
      tenantId: (json['tenant_id'] ?? '') as String,
      modifierGroupId: (json['modifier_group_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      priceDelta: ((json['price_delta'] ?? 0) as num).toDouble(),
      isDefault: (json['is_default'] ?? false) as bool,
      isActive: (json['is_active'] ?? true) as bool,
      sortOrder: (json['sort_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'modifier_group_id': modifierGroupId,
      'name': name,
      'price_delta': priceDelta,
      'is_default': isDefault,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

import 'modifier_group.dart';

class EffectiveMenuItem {
  final String id;
  final String tenantId;
  final String branchId;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final double effectivePrice;
  final String pricingType;
  final String? effectiveTaxGroupId;
  final List<String> dietaryTags;
  final String spiceLevel;
  final int? prepTimeMinutes;
  final bool isAvailable;
  final bool isFeatured;
  final String? imageUrl;
  final String? thumbnailUrl;
  final int sortOrder;
  final List<ModifierGroup> modifierGroups;

  const EffectiveMenuItem({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    this.sku,
    required this.effectivePrice,
    required this.pricingType,
    this.effectiveTaxGroupId,
    this.dietaryTags = const [],
    required this.spiceLevel,
    this.prepTimeMinutes,
    required this.isAvailable,
    required this.isFeatured,
    this.imageUrl,
    this.thumbnailUrl,
    required this.sortOrder,
    this.modifierGroups = const [],
  });

  factory EffectiveMenuItem.fromJson(Map<String, dynamic> json) {
    return EffectiveMenuItem(
      id: (json['id'] ?? '') as String,
      tenantId: (json['tenant_id'] ?? '') as String,
      branchId: (json['branch_id'] ?? '') as String,
      categoryId: (json['category_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      sku: json['sku'] as String?,
      effectivePrice:
          ((json['effective_price'] ?? json['base_price'] ?? 0) as num)
              .toDouble(),
      pricingType: (json['pricing_type'] ?? 'fixed') as String,
      effectiveTaxGroupId: json['effective_tax_group_id'] as String?,
      dietaryTags: (json['dietary_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      spiceLevel: (json['spice_level'] ?? 'none') as String,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      isAvailable: (json['is_available'] ?? true) as bool,
      isFeatured: (json['is_featured'] ?? false) as bool,
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      sortOrder: (json['sort_order'] ?? 0) as int,
      modifierGroups: (json['modifier_groups'] as List<dynamic>?)
              ?.map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'category_id': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'sku': sku,
      'effective_price': effectivePrice,
      'pricing_type': pricingType,
      'effective_tax_group_id': effectiveTaxGroupId,
      'dietary_tags': dietaryTags,
      'spice_level': spiceLevel,
      'prep_time_minutes': prepTimeMinutes,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'sort_order': sortOrder,
      'modifier_groups': modifierGroups.map((e) => e.toJson()).toList(),
    };
  }
}

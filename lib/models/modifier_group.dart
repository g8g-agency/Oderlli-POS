import 'modifier_option.dart';

class ModifierGroup {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final bool isRequired;
  final int minSelect;
  final int? maxSelect;
  final bool isActive;
  final int sortOrder;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.isRequired,
    required this.minSelect,
    this.maxSelect,
    required this.isActive,
    required this.sortOrder,
    this.options = const [],
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: (json['id'] ?? '') as String,
      tenantId: (json['tenant_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      isRequired: (json['is_required'] ?? false) as bool,
      minSelect: (json['min_select'] ?? 0) as int,
      maxSelect: json['max_select'] as int?,
      isActive: (json['is_active'] ?? true) as bool,
      sortOrder: (json['sort_order'] ?? 0) as int,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'is_required': isRequired,
      'min_select': minSelect,
      'max_select': maxSelect,
      'is_active': isActive,
      'sort_order': sortOrder,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

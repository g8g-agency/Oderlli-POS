class MenuCategory {
  final String id;
  final String tenantId;
  final String? parentId;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final int versionNum;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<MenuCategory> children;

  const MenuCategory({
    required this.id,
    required this.tenantId,
    this.parentId,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.versionNum,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.children = const [],
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: (json['id'] ?? '') as String,
      tenantId: (json['tenant_id'] ?? '') as String,
      parentId: json['parent_id'] as String?,
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] ?? 0) as int,
      isActive: (json['is_active'] ?? true) as bool,
      versionNum: (json['version_num'] ?? 0) as int,
      createdAt: (json['created_at'] ?? '') as String,
      updatedAt: (json['updated_at'] ?? '') as String,
      deletedAt: json['deleted_at'] as String?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'parent_id': parentId,
      'name': name,
      'slug': slug,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'version_num': versionNum,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}

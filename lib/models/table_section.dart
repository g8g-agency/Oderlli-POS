class TableSection {
  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final int sortOrder;

  const TableSection({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    required this.sortOrder,
  });

  factory TableSection.fromJson(Map<String, dynamic> json) => TableSection(
        id: (json['id'] ?? '') as String,
        tenantId: (json['tenant_id'] ?? '') as String,
        branchId: (json['branch_id'] ?? '') as String,
        name: (json['name'] ?? 'Unnamed Section') as String,
        sortOrder: (json['sort_order'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'branch_id': branchId,
        'name': name,
        'sort_order': sortOrder,
      };
}

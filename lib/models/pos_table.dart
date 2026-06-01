class PosTable {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableNumber;
  final String? displayName;
  final int capacity;
  final String? floorId;
  final String? sectionId;
  final int sortOrder;
  final String? assignedWaiterId;
  final String? notes;
  final bool isActive;
  final int versionNum;
  final String? runtimeState;

  const PosTable({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableNumber,
    this.displayName,
    required this.capacity,
    this.floorId,
    this.sectionId,
    required this.sortOrder,
    this.assignedWaiterId,
    this.notes,
    required this.isActive,
    required this.versionNum,
    this.runtimeState,
  });

  factory PosTable.fromJson(Map<String, dynamic> json) => PosTable(
        id: (json['id'] ?? '') as String,
        tenantId: (json['tenant_id'] ?? '') as String,
        branchId: (json['branch_id'] ?? '') as String,
        tableNumber: (json['table_number'] ?? '') as String,
        displayName: json['display_name'] as String?,
        capacity: (json['capacity'] ?? 0) as int,
        floorId: json['floor_id'] as String?,
        sectionId: json['section_id'] as String?,
        sortOrder: (json['sort_order'] ?? 0) as int,
        assignedWaiterId: json['assigned_waiter_id'] as String?,
        notes: json['notes'] as String?,
        isActive: (json['is_active'] ?? true) as bool,
        versionNum: (json['version_num'] ?? 0) as int,
        runtimeState: json['runtime_state'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'branch_id': branchId,
        'table_number': tableNumber,
        'display_name': displayName,
        'capacity': capacity,
        'floor_id': floorId,
        'section_id': sectionId,
        'sort_order': sortOrder,
        'assigned_waiter_id': assignedWaiterId,
        'notes': notes,
        'is_active': isActive,
        'version_num': versionNum,
        'runtime_state': runtimeState,
      };
}

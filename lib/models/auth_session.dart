class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String deviceSessionId;
  final int expiresIn;
  final BackendUser user;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.deviceSessionId,
    required this.expiresIn,
    required this.user,
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'device_session_id': deviceSessionId,
        'expires_in': expiresIn,
        'user': user.toJson(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        deviceSessionId: json['device_session_id'] as String,
        expiresIn: json['expires_in'] as int,
        user: BackendUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class BackendUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? tenantId;
  final List<String> branchIds;
  final List<String> permissions;

  BackendUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.tenantId,
    required this.branchIds,
    required this.permissions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'tenantId': tenantId,
        'branchIds': branchIds,
        'permissions': permissions,
      };

  factory BackendUser.fromJson(Map<String, dynamic> json) => BackendUser(
        id: (json['id'] ?? json['userId']) as String,
        email: json['email'] as String,
        fullName: (json['full_name'] ?? json['fullName']) as String,
        role: json['role'] as String,
        tenantId: (json['tenantId'] ?? json['tenant_id']) as String?,
        branchIds: json['branchIds'] is List
            ? (json['branchIds'] as List<dynamic>).map((e) => e as String).toList()
            : [],
        permissions: json['permissions'] is List
            ? (json['permissions'] as List<dynamic>).map((e) => e as String).toList()
            : [],
      );
}

class BranchInfo {
  final String id;
  final String name;
  final String timezone;
  final String? tenantId;
  final String? gstin;
  final String? fssai;

  const BranchInfo({
    required this.id,
    required this.name,
    required this.timezone,
    this.tenantId,
    this.gstin,
    this.fssai,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timezone': timezone,
        if (tenantId != null) 'tenantId': tenantId,
        'gstin': gstin,
        'fssai_license_number': fssai,
      };

  factory BranchInfo.fromJson(Map<String, dynamic> json) => BranchInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        timezone: (json['timezone'] ?? 'UTC') as String,
        tenantId: (json['tenantId'] ?? json['tenant_id']) as String?,
        gstin: json['gstin'] as String?,
        fssai: (json['fssai_license_number'] ?? json['fssai']) as String?,
      );
}

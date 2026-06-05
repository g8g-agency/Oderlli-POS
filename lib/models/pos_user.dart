import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'auth_session.dart';

/// Roles defining permissions in the Orderlyy POS.
enum UserRole {
  manager,
  cashier,
  server,
}

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.manager => 'Manager Access',
        UserRole.cashier => 'Cashier Terminal',
        UserRole.server => 'Floor Service',
      };

  String get description => switch (this) {
        UserRole.manager => 'Full control',
        UserRole.cashier => 'Operational billing',
        UserRole.server => 'Floor operations',
      };

  Color get color => switch (this) {
        UserRole.manager => AppColors.primary,
        UserRole.cashier => AppColors.info,
        UserRole.server => AppColors.success,
      };
}

/// Represents an operational user session identity.
class PosUser {
  const PosUser({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    required this.terminalId,
    this.email,
    this.permissions = const [],
  });

  final String id;
  final String name;
  final UserRole role;
  final String pin;
  final String terminalId;
  final String? email;
  final List<String> permissions;

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Helper maps for JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'pin': pin,
        'terminalId': terminalId,
        'email': email,
        'permissions': permissions,
      };

  factory PosUser.fromJson(Map<String, dynamic> json) => PosUser(
        id: json['id'] as String,
        name: json['name'] as String,
        role: UserRole.values.byName(json['role'] as String),
        pin: json['pin'] as String,
        terminalId: json['terminalId'] as String,
        email: json['email'] as String?,
        permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );

  factory PosUser.fromBackendUser(BackendUser backendUser) {
    UserRole mappedRole;
    final r = backendUser.role.toUpperCase();
    if (r == 'MANAGER' || r == 'RESTAURANT_ADMIN' || r == 'SUPER_ADMIN') {
      mappedRole = UserRole.manager;
    } else if (r == 'CASHIER') {
      mappedRole = UserRole.cashier;
    } else {
      mappedRole = UserRole.server;
    }

    return PosUser(
      id: backendUser.id,
      name: backendUser.fullName,
      role: mappedRole,
      pin: '', // Pin not stored in plain text user model
      terminalId: 'Main Terminal',
      email: backendUser.email,
      permissions: backendUser.permissions,
    );
  }

  /// Mock users database with associated emails
  static const List<PosUser> mockUsers = [
    PosUser(
      id: 'usr-alexander',
      name: 'Alexander',
      role: UserRole.manager,
      pin: '1111',
      terminalId: 'Terminal 1',
      email: 'alexander@orderlyy.com',
    ),
    PosUser(
      id: 'usr-sarah',
      name: 'Sarah',
      role: UserRole.cashier,
      pin: '2222',
      terminalId: 'Front Counter',
      email: 'sarah@orderlyy.com',
    ),
    PosUser(
      id: 'usr-michael',
      name: 'Michael',
      role: UserRole.cashier,
      pin: '3333',
      terminalId: 'Bar Terminal',
      email: 'michael@orderlyy.com',
    ),
    PosUser(
      id: 'usr-jessica',
      name: 'Jessica',
      role: UserRole.server,
      pin: '4444',
      terminalId: 'Floor Service',
      email: 'jessica@orderlyy.com',
    ),
  ];
}

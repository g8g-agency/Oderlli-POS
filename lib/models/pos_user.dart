import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Roles defining permissions in the Orderlli POS.
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
  });

  final String id;
  final String name;
  final UserRole role;
  final String pin;
  final String terminalId;

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
      };

  factory PosUser.fromJson(Map<String, dynamic> json) => PosUser(
        id: json['id'] as String,
        name: json['name'] as String,
        role: UserRole.values.byName(json['role'] as String),
        pin: json['pin'] as String,
        terminalId: json['terminalId'] as String,
      );

  /// Mock users database
  static const List<PosUser> mockUsers = [
    PosUser(
      id: 'usr-alexander',
      name: 'Alexander',
      role: UserRole.manager,
      pin: '1111',
      terminalId: 'Terminal 1',
    ),
    PosUser(
      id: 'usr-sarah',
      name: 'Sarah',
      role: UserRole.cashier,
      pin: '2222',
      terminalId: 'Front Counter',
    ),
    PosUser(
      id: 'usr-michael',
      name: 'Michael',
      role: UserRole.cashier,
      pin: '3333',
      terminalId: 'Bar Terminal',
    ),
    PosUser(
      id: 'usr-jessica',
      name: 'Jessica',
      role: UserRole.server,
      pin: '4444',
      terminalId: 'Floor Service',
    ),
  ];
}

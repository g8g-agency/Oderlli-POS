import '../../models/pos_user.dart';

/// Centralized security checks mapping roles to system capabilities.
abstract final class RolePermissions {
  /// Reports and Analytics access (Manager only).
  static bool canAccessReports(UserRole role) => role == UserRole.manager;

  /// Settings and configurations (Manager only).
  static bool canManageSettings(UserRole role) => role == UserRole.manager;

  /// Shift closing operations (Manager only, Cashier/Server requires override).
  static bool canCloseShift(UserRole role) => role == UserRole.manager;

  /// Issuing billing refunds (Manager only, Cashier requires override, Server blocked).
  static bool canProcessRefunds(UserRole role) => role == UserRole.manager;

  /// Employee permissions management (Manager only).
  static bool canManageEmployees(UserRole role) => role == UserRole.manager;

  /// Billing, payments, and checkout screens (Manager and Cashiers).
  static bool canAccessPayments(UserRole role) =>
      role == UserRole.manager || role == UserRole.cashier;

  /// Editing item prices or applying custom discounts (Manager only).
  static bool canModifyPrices(UserRole role) => role == UserRole.manager;

  /// Creating orders and floor plan actions (All users).
  static bool canCreateOrders(UserRole role) => true;

  /// Voiding/cancelling active orders (Manager only).
  static bool canVoidOrders(UserRole role) => role == UserRole.manager;
}

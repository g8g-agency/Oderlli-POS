/// Application route name constants for Orderlyy POS.
abstract final class AppRoutes {
  // Splash / Authentication
  static const String splash = '/';
  static const String login = '/login';
  static const String selectBranch = '/select-branch';
  static const String employeeLogin = '/employee-login';

  // Top-level Dashboard / Side navigation routes
  static const String dashboard = '/dashboard';
  static const String floor = '/floor';
  static const String orders = '/orders';
  static const String kitchen = '/kitchen';
  static const String shifts = '/shifts';
  static const String settings = '/settings';
  static const String reviews = '/reviews';
  static const String menu = '/menu';
  static const String posMenu = '/pos/menu';
  static const String tableSelection = '/table-selection';
  static const String cart = '/cart';

  // Checkout nested shell routes
  static const String billing = '/checkout';
  static const String payments = '/checkout/payment';
  static const String splitBilling = '/checkout/split-billing';
  static const String refunds = '/checkout/refund';
}


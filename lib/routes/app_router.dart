import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/floor/floor_screen.dart';
import '../screens/orders/orders_screen.dart';
// NOTE: kitchen_screen.dart import removed — the route is disabled but the file,
// models, enums, and providers are preserved for future backend integration.
import '../screens/shifts/shifts_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_shell.dart';
import '../screens/checkout/billing_screen.dart';
import '../screens/checkout/payments_screen.dart';
import '../screens/checkout/split_billing_screen.dart';
import '../screens/checkout/refunds_screen.dart';
import '../screens/shell/main_shell.dart';
import 'app_routes.dart';

/// GoRouter configuration for the Orderlli POS.
///
/// Configures top-level screens (Splash, Login), persistent main shell sidebar,
/// and a nested payment checkout layout for Billing, Payments, Split, and Refunds.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    // ── Splash ────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Login ─────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Main Shell with Persistent Sidebar Navigation ─────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.floor,
          name: 'floor',
          builder: (context, state) => const FloorScreen(),
        ),
        GoRoute(
          path: AppRoutes.orders,
          name: 'orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        // Kitchen KDS route disabled. Screen, models, enums and providers are intact.
        // Re-add this GoRoute to restore KDS navigation when the backend is ready.
        // GoRoute(
        //   path: AppRoutes.kitchen,
        //   name: 'kitchen',
        //   builder: (context, state) => const KitchenScreen(),
        // ),
        GoRoute(
          path: AppRoutes.shifts,
          name: 'shifts',
          builder: (context, state) => const ShiftsScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.cart,
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
      ],
    ),

    // ── Standalone Menu (New Order Screen) ────────────────────────────────
    GoRoute(
      path: AppRoutes.menu,
      name: 'menu',
      builder: (context, state) => const MenuScreen(),
    ),

    // ── Nested Checkout/Payment Shell ─────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => CheckoutShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.billing,
          name: 'billing',
          pageBuilder: (context, state) => _buildHorizontalSlideTransitionPage(
            key: state.pageKey,
            child: const BillingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.payments,
          name: 'payments',
          pageBuilder: (context, state) => _buildHorizontalSlideTransitionPage(
            key: state.pageKey,
            child: const PaymentsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.splitBilling,
          name: 'split-billing',
          pageBuilder: (context, state) => _buildHorizontalSlideTransitionPage(
            key: state.pageKey,
            child: const SplitBillingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.refunds,
          name: 'refunds',
          pageBuilder: (context, state) => _buildHorizontalSlideTransitionPage(
            key: state.pageKey,
            child: const RefundsScreen(),
          ),
        ),
      ],
    ),
  ],

  // ── Error Page ──────────────────────────────────────────────────────────
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.uri}',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  ),
);

/// Reusable helper function to build horizontal slide page transitions.
CustomTransitionPage<void> _buildHorizontalSlideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../core/utils/role_permissions.dart';
import '../theme/theme.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/branch_selection_screen.dart';
import '../screens/login/employee_login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/floor/floor_screen.dart';
import '../screens/floor/table_selection_screen.dart';
import '../screens/orders/orders_screen.dart';
// import '../screens/kitchen/kitchen_screen.dart';
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

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    ref.listen(authProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((ref) {
  return RouterRefreshListenable(ref);
});

/// GoRouter configuration provider for the Orderlyy POS.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshListenableProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isOrgAuthenticated = authState.isOrgAuthenticated;
      final hasBranchSelected = authState.branchId != null && authState.branchId!.isNotEmpty;
      final isEmployeeLoggedIn = authState.user != null;

      final isSplash = state.uri.path == AppRoutes.splash;
      final isLogin = state.uri.path == AppRoutes.login;
      final isSelectBranch = state.uri.path == AppRoutes.selectBranch;
      final isEmployeeLogin = state.uri.path == AppRoutes.employeeLogin;

      // 1. If not authenticated at the organization level, redirect to /login
      if (!isOrgAuthenticated) {
        if (!isLogin && !isSplash) {
          return AppRoutes.login;
        }
        return null;
      }

      // 2. If organization is authenticated but no branch is selected, redirect to /select-branch
      if (!hasBranchSelected) {
        if (!isSelectBranch) {
          return AppRoutes.selectBranch;
        }
        return null;
      }

      // 3. If branch is selected but no employee is logged in (or locked), redirect to /employee-login
      if (!isEmployeeLoggedIn) {
        if (!isEmployeeLogin) {
          return AppRoutes.employeeLogin;
        }
        return null;
      }

      // 4. Redirect fully authenticated users away from Splash and Login/Select Branch screens
      if (isSplash || isLogin || isSelectBranch || isEmployeeLogin) {
        return AppRoutes.dashboard;
      }

      // Enforce Role-Based Navigation Guards
      final role = authState.user!.role;
      final path = state.uri.path;

      // 1. Settings Configuration: Manager Only
      if (path.startsWith(AppRoutes.settings)) {
        if (!RolePermissions.canManageSettings(role)) {
          return AppRoutes.dashboard;
        }
      }

      // 2. Shift Audit Screen: Manager Only
      if (path.startsWith(AppRoutes.shifts)) {
        if (!RolePermissions.canCloseShift(role)) {
          return AppRoutes.dashboard;
        }
      }

      // 3. Refunds Screen: Manager and Cashiers (Server Blocked)
      if (path.startsWith(AppRoutes.refunds)) {
        if (role == UserRole.server) {
          return AppRoutes.dashboard;
        }
      }

      // 4. Payment Checkout Shell: Manager and Cashiers (Server Blocked)
      if (path.startsWith('/checkout')) {
        if (!RolePermissions.canAccessPayments(role)) {
          return AppRoutes.dashboard;
        }
      }

      // 5. Kitchen Screen: Manager and Server Only (Cashiers Blocked)
      if (path.startsWith(AppRoutes.kitchen)) {
        if (role != UserRole.manager && role != UserRole.server) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },
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

      // ── Select Branch ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.selectBranch,
        name: 'select-branch',
        builder: (context, state) => const BranchSelectionScreen(),
      ),

      // ── Employee Login ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.employeeLogin,
        name: 'employee-login',
        builder: (context, state) => const EmployeeLoginScreen(),
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
            path: AppRoutes.tableSelection,
            name: 'table-selection',
            builder: (context, state) => const TableSelectionScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            name: 'orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          // Kitchen route — hidden from POS nav, re-enable when KDS integration is ready
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
      GoRoute(
        path: AppRoutes.posMenu,
        name: 'pos-menu',
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
        ],
      ),
      GoRoute(
        path: AppRoutes.refunds,
        name: 'refunds',
        pageBuilder: (context, state) => _buildHorizontalSlideTransitionPage(
          key: state.pageKey,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              title: const Text('Refund Transaction'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const RefundsScreen(),
          ),
        ),
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
});


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

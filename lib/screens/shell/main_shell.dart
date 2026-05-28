import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/widgets.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';
import '../../core/utils/role_permissions.dart';
import '../../models/models.dart';

/// The persistent sidebar + content shell used by all main sections.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVertical = context.isVerticalLayout;
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (isVertical) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Row(
            children: [
              Text(
                'Orderlli POS',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                ),
              ),
              const Spacer(),
              if (user != null) ...[
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.role.color,
                  ),
                ),
                Gap(8.w),
                Text(
                  '${user.name} • ${user.role.label}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          elevation: 0,
        ),
        drawer: Drawer(
          width: AppConstants.sidebarWidth.w,
          child: const _Sidebar(isDrawer: true),
        ),
        body: POSAlertOverlay(
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: POSAlertOverlay(
        child: Row(
          children: [
            // ── Sidebar ──────────────────────────────────────────────────────
            const _Sidebar(isDrawer: false),
            // ── Main content ─────────────────────────────────────────────────
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.isDrawer = false});
  final bool isDrawer;

  Widget _buildSidebarUserProfile(PosUser user) {
    final roleColor = user.role.color;
    return Container(
      height: AppConstants.topBarHeight.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: roleColor,
            child: Text(
              user.initials,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.role.label} · ${user.terminalId}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final role = user?.role ?? UserRole.server;

    // Filter main navigation items
    final visibleNavItems = _navItems.where((item) {
      if (item.route == AppRoutes.shifts) {
        return RolePermissions.canCloseShift(role);
      }
      return true;
    }).toList();

    return Container(
      width: isDrawer ? double.infinity : AppConstants.sidebarWidth.w,
      height: double.infinity,
      color: AppColors.sidebarBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSpacer = constraints.maxHeight > 560;
          final content = Column(
            children: [
              // Logo or Active User Profile Card
              if (user != null) ...[
                _buildSidebarUserProfile(user),
              ] else ...[
                _SidebarLogo(),
              ],
              const Divider(color: AppColors.sidebarDivider, thickness: 1, height: 1),
              Gap(16.h),

              // Nav items
              ...visibleNavItems.map(
                (item) => _SidebarNavItem(
                  item: item,
                  isActive: location.startsWith(item.route),
                ),
              ),

              if (showSpacer) const Spacer() else Gap(20.h),

              // Settings (Only show if Manager)
              if (RolePermissions.canManageSettings(role)) ...[
                _SidebarNavItem(
                  item: _NavItem(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    route: AppRoutes.settings,
                  ),
                  isActive: location.startsWith(AppRoutes.settings),
                ),
                Gap(8.h),
              ],

              // Lock Terminal Quick Action (For all roles)
              _SidebarNavItem(
                item: const _NavItem(
                  label: 'Lock Terminal',
                  icon: Icons.lock_outline,
                  activeIcon: Icons.lock,
                  route: '/lock',
                ),
                isActive: false,
                onTap: () {
                  ref.read(authProvider.notifier).lock();
                  context.go('/login');
                },
              ),
              Gap(8.h),

              // ── Alert System Demo trigger ────────────────────────────
              _AlertsDemoButton(),
              Gap(16.h),
            ],
          );

          return showSpacer
              ? content
              : SingleChildScrollView(child: content);
        },
      ),
    );
  }

  static final List<_NavItem> _navItems = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: AppRoutes.dashboard,
    ),
    _NavItem(
      label: 'Floor Plan',
      icon: Icons.table_restaurant_outlined,
      activeIcon: Icons.table_restaurant,
      route: AppRoutes.floor,
    ),
    _NavItem(
      label: 'New Order',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      route: AppRoutes.menu,
    ),
    _NavItem(
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      route: AppRoutes.orders,
    ),
    _NavItem(
      label: 'Shifts',
      icon: Icons.vpn_key_outlined,
      activeIcon: Icons.vpn_key,
      route: AppRoutes.shifts,
    ),
  ];
}

class _SidebarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.topBarHeight.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.restaurant, color: Colors.white, size: 18.sp),
          ),
          Gap(10.w),
          Expanded(
            child: Text(
              'Orderlli',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontSize: 18.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap ?? () {
            context.go(item.route);
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
          child: AnimatedContainer(
            duration: AppConstants.animFast,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? AppColors.sidebarActive
                      : AppColors.sidebarText,
                  size: 20.sp,
                ),
                Gap(12.w),
                Expanded(
                  child: Text(
                    item.label,
                    style: isActive
                        ? AppTextStyles.sidebarItemActive
                        : AppTextStyles.sidebarItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4.r,
                    height: 4.r,
                    decoration: const BoxDecoration(
                      color: AppColors.sidebarActive,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}

// ─── Alert Demo Button ────────────────────────────────────────────────────────
// Cycles through all 5 alert types on repeated taps.
// Remove this widget (and its call in _Sidebar) in production.

class _AlertsDemoButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AlertsDemoButton> createState() => _AlertsDemoButtonState();
}

class _AlertsDemoButtonState extends ConsumerState<_AlertsDemoButton> {
  int _step = 0;

  static const _labels = [
    'Reconnecting',
    'Syncing',
    'Payment Fail',
    'Delayed Order',
    'Stale State',
    'Clear All',
  ];

  static const _icons = [
    Icons.wifi_off_rounded,
    Icons.sync_rounded,
    Icons.credit_card_off_rounded,
    Icons.timer_off_rounded,
    Icons.warning_amber_rounded,
    Icons.notifications_off_rounded,
  ];

  void _trigger() {
    final notifier = ref.read(posAlertsProvider.notifier);
    switch (_step % 6) {
      case 0:
        notifier.showReconnecting();
        // Auto-clear reconnecting after 4 s so the demo doesn't get stuck
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) notifier.clearReconnecting();
        });
      case 1:
        notifier.showSyncing(message: 'Syncing 24 pending order updates…');
      case 2:
        notifier.showPaymentFailure(
          message: 'Card terminal timeout. PX-4 did not respond within 30s.',
          onRetry: () => debugPrint('[Demo] Retrying payment…'),
        );
      case 3:
        notifier.showDelayedOrder(
          tableLabel: 'Table 07',
          delayMinutes: 32,
          onViewOrder: () => debugPrint('[Demo] Viewing delayed order…'),
        );
      case 4:
        notifier.showStaleState(
          message: 'Floor plan last refreshed 8 minutes ago.',
          onRefresh: () => notifier.dismissAll(),
        );
      case 5:
        notifier.dismissAll();
        notifier.clearReconnecting();
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _step % 6;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Tooltip(
        message: 'Alert System Demo',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: _trigger,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(_icons[idx], color: AppColors.primary, size: 16.sp),
                  Gap(10.w),
                  Expanded(
                    child: Text(
                      _labels[idx],
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  Icon(Icons.play_circle_outline_rounded,
                      color: AppColors.primary.withValues(alpha: 0.6), size: 14.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

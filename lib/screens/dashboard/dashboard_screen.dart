import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrders = ref.watch(activeOrdersProvider);
    final tables = ref.watch(tablesProvider);
    final liveTables = ref.watch(liveTableStatusProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final role = user?.role ?? UserRole.server;

    final occupiedCount =
        liveTables.where((t) => t.status != POSTableStatus.available).length;

    // Filter active orders based on role mapping
    final myAssignedOrders = activeOrders.where((o) => o.servedBy == user?.name).toList();
    final unassignedOrders = activeOrders.where((o) => o.servedBy == null || o.servedBy!.isEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width > 1600
              ? 5
              : (width > 1200
                  ? 4
                  : (width > 900
                      ? 3
                      : 2));
          final childAspectRatio = context.isVerticalLayout
              ? 1.8
              : (width > 1200 ? 1.35 : 1.45);

          return CustomScrollView(
            slivers: [
              // ── Top bar ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _TopBar(user: user),
              ),
              // ── Stats row ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                  child: _StatsRow(
                    role: role,
                    occupiedCount: occupiedCount,
                    totalTables: tables.length,
                    activeOrders: activeOrders.length,
                  ),
                ),
              ),
              


              // ── Dynamic Section Lists based on Role ──────────────────────────
              if (role == UserRole.server) ...[
                // Server Partitions: My Orders & Service Queue
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                    child: Text(
                      'My Assigned Orders (${myAssignedOrders.length})',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                if (myAssignedOrders.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: const EmptyStateWidget(
                        icon: Icons.assignment_ind_outlined,
                        title: 'No Assigned Orders',
                        description: 'You are not serving any active tables. Select a table from the Floor Plan to start an order.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _OrderCard(order: myAssignedOrders[index]),
                        childCount: myAssignedOrders.length,
                      ),
                    ),
                  ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    child: Text(
                      'Service Queue (Unassigned / Other)',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                if (unassignedOrders.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: const EmptyStateWidget(
                        icon: Icons.playlist_add_check_circle_outlined,
                        title: 'Queue Cleared',
                        description: 'No unassigned orders require floor service at the moment.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _OrderCard(order: unassignedOrders[index]),
                        childCount: unassignedOrders.length,
                      ),
                    ),
                  ),
              ] else ...[
                // Manager & Cashier View: All active orders
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                    child: Text(
                      role == UserRole.cashier ? 'Active Billing Queue' : 'Active Orders',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                if (activeOrders.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Active Orders',
                        description: role == UserRole.cashier
                            ? 'All orders are fully checked out. Open Floor Plan to seat guests or New Order to checkout.'
                            : 'No active orders in the system.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _OrderCard(order: activeOrders[index]),
                        childCount: activeOrders.length,
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user});

  final PosUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = user?.name ?? 'Staff';
    final displayRole = user?.role ?? UserRole.manager;
    final greeting = ref.watch(greetingProvider);
    final authState = ref.watch(authProvider);
    final shiftState = ref.watch(shiftProvider);
    
    final branchName = authState.branchName ?? 'Main Branch';
    final isShiftActive = shiftState.isShiftActive;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName 👋',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      'Dashboard',
                      style: AppTextStyles.dashboardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(8.w),
                    Text(
                      '·',
                      style: AppTextStyles.dashboardTitle.copyWith(color: AppColors.textSecondary),
                    ),
                    Gap(8.w),
                    Text(
                      branchName,
                      style: AppTextStyles.dashboardTitle.copyWith(
                        color: const Color(0xFFBA0013),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(12.w),
                    // Colored Access Chip accent
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: displayRole.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100.r),
                        border: Border.all(color: displayRole.color.withValues(alpha: 0.24)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: displayRole.color,
                            ),
                          ),
                          Gap(6.w),
                          Text(
                            displayRole.label.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: displayRole.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(8.w),
                    // Shift Status Chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isShiftActive 
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100.r),
                        border: Border.all(
                          color: isShiftActive 
                              ? AppColors.success.withValues(alpha: 0.24)
                              : AppColors.error.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isShiftActive ? AppColors.success : AppColors.error,
                            ),
                          ),
                          Gap(6.w),
                          Text(
                            isShiftActive ? 'SHIFT ACTIVE' : 'SHIFT CLOSED',
                            style: AppTypography.labelSmall.copyWith(
                              color: isShiftActive ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Gap(16.w),
          Text(
            DateTime.now().timeLabel,
            style: AppTextStyles.dashboardTitle.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(16.w),
          GestureDetector(
            onTap: () {
              // Click avatar to quickly lock terminal session
              ref.read(authProvider.notifier).lock();
              context.go('/employee-login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terminal locked.')),
              );
            },
            child: Tooltip(
              message: 'Lock Session',
              child: _TopBarAvatar(user: user),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarAvatar extends StatelessWidget {
  const _TopBarAvatar({required this.user});

  final PosUser? user;

  @override
  Widget build(BuildContext context) {
    final roleColor = user?.role.color ?? AppColors.primary;
    final initials = user?.initials ?? 'A';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
          width: 2.r,
        ),
      ),
      padding: EdgeInsets.all(2.r),
      child: CircleAvatar(
        radius: 16.r,
        backgroundColor: roleColor,
        child: Text(
          initials,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow({
    required this.role,
    required this.occupiedCount,
    required this.totalTables,
    required this.activeOrders,
  });

  final UserRole role;
  final int occupiedCount;
  final int totalTables;
  final int activeOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVertical = context.isVerticalLayout;
    final orders = ref.watch(ordersProvider);

    final now = DateTime.now();
    final todayOrders = orders.where((o) {
      final isSameDay = o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
      // Use completed/served orders only for actual revenue
      final isCompleted = o.status == OrderStatus.served || o.status == OrderStatus.completed;
      return isSameDay && isCompleted;
    }).toList();

    final totalRevenue = todayOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final avgOrderValue = todayOrders.isEmpty ? 0.0 : totalRevenue / todayOrders.length;

    final revenueTile = MetricTile(
      label: 'Today\'s Revenue',
      value: totalRevenue.asCurrency,
      icon: Icons.currency_rupee,
      color: AppColors.success,
    );

    final activeOrdersTile = MetricTile(
      label: 'Active Orders',
      value: '$activeOrders',
      icon: Icons.receipt_long,
      color: AppColors.primary,
    );

    final tablesTile = MetricTile(
      label: 'Tables Occupied',
      value: '$occupiedCount / $totalTables',
      icon: Icons.table_restaurant,
      color: AppColors.info,
    );

    final aovTile = MetricTile(
      label: 'Avg. Order Value',
      value: avgOrderValue.asCurrency,
      icon: Icons.trending_up,
      color: AppColors.cash,
    );

    // Filter tiles visible by role permissions
    final cards = <Widget>[];
    if (role == UserRole.manager) {
      cards.addAll([revenueTile, activeOrdersTile, tablesTile, aovTile]);
    } else if (role == UserRole.cashier) {
      cards.addAll([revenueTile, activeOrdersTile, tablesTile]);
    } else {
      // Server
      cards.addAll([activeOrdersTile, tablesTile]);
    }

    if (isVertical) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cards.length > 2 ? 2 : cards.length,
        crossAxisSpacing: AppSpacing.sm.w,
        mainAxisSpacing: AppSpacing.sm.h,
        childAspectRatio: 1.8,
        children: cards,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) Gap(AppSpacing.md.w),
        ]
      ],
    );
  }
}


// ── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return POSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Table ${order.tableNumber}',
                  style: AppTypography.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(AppSpacing.xs.w),
              StatusChip(label: order.status.label, color: statusColor),
            ],
          ),
          Gap(AppSpacing.xs.h),
          Text(
            '${order.itemCount} items · ${order.total.asCurrency}',
            style: AppTypography.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 13.sp,
                color: AppColors.textSecondary,
              ),
              Gap(AppSpacing.xxs.w),
              Expanded(
                child: Text(
                  order.createdAt.minutesAgoLabel,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (order.servedBy != null && order.servedBy!.isNotEmpty) ...[
                Gap(8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    order.servedBy!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.pending,
        OrderStatus.accepted => AppColors.preparing,
        OrderStatus.preparing => AppColors.preparing,
        OrderStatus.ready => AppColors.ready,
        OrderStatus.served => AppColors.statusServed,
        OrderStatus.completed => AppColors.ready,
        OrderStatus.cancelled => AppColors.statusCancelled,
        OrderStatus.syncConflict => AppColors.statusCancelled,
      };
}

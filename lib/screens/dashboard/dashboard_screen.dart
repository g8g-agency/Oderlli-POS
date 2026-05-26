import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theme/theme.dart';
import '../../mock/mock_data.dart';
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
    final stats = MockData.dashboardStats;

    final occupiedCount =
        tables.where((t) => t.status == TableStatus.occupied).length;

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
                child: _TopBar(),
              ),
              // ── Stats row ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                  child: _StatsRow(
                    stats: stats,
                    occupiedCount: occupiedCount,
                    totalTables: tables.length,
                    activeOrders: activeOrders.length,
                  ),
                ),
              ),
              // ── Section title ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: Text(
                    'Active Orders', 
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              // ── Active orders grid ───────────────────────────────────────────
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
          );
        },
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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
                  'Good Evening 👋', 
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Dashboard', 
                  style: AppTextStyles.dashboardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          _TopBarAvatar(),
        ],
      ),
    );
  }
}

class _TopBarAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2.r,
        ),
      ),
      padding: EdgeInsets.all(2.r),
      child: CircleAvatar(
        radius: 16.r,
        backgroundColor: AppColors.primary,
        child: Text(
          'A',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.occupiedCount,
    required this.totalTables,
    required this.activeOrders,
  });

  final Map<String, dynamic> stats;
  final int occupiedCount;
  final int totalTables;
  final int activeOrders;

  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;

    final cards = [
      MetricTile(
        label: 'Today\'s Revenue',
        value: (stats['totalRevenue'] as double).asCurrency,
        icon: Icons.attach_money,
        color: AppColors.success,
      ),
      MetricTile(
        label: 'Active Orders',
        value: '$activeOrders',
        icon: Icons.receipt_long,
        color: AppColors.primary,
      ),
      MetricTile(
        label: 'Tables Occupied',
        value: '$occupiedCount / $totalTables',
        icon: Icons.table_restaurant,
        color: AppColors.info,
      ),
      MetricTile(
        label: 'Avg. Order Value',
        value: (stats['avgOrderValue'] as double).asCurrency,
        icon: Icons.trending_up,
        color: AppColors.cash,
      ),
    ];

    if (isVertical) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm.w,
        mainAxisSpacing: AppSpacing.sm.h,
        childAspectRatio: 1.8,
        children: cards,
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        Gap(AppSpacing.md.w),
        Expanded(child: cards[1]),
        Gap(AppSpacing.md.w),
        Expanded(child: cards[2]),
        Gap(AppSpacing.md.w),
        Expanded(child: cards[3]),
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
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.pending,
        OrderStatus.preparing => AppColors.preparing,
        OrderStatus.ready => AppColors.ready,
        OrderStatus.served => AppColors.statusServed,
        OrderStatus.cancelled => AppColors.statusCancelled,
      };
}

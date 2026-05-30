import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'All', status: null),
    (label: 'Pending', status: OrderStatus.pending),
    (label: 'Preparing', status: OrderStatus.preparing),
    (label: 'Ready', status: OrderStatus.ready),
    (label: 'Served', status: OrderStatus.served),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                SizedBox(
                  height: 72.h,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      children: [
                        Text('Orders', style: AppTextStyles.headlineMedium),
                        Gap(12.w),
                        _CountBadge(count: allOrders.length),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _tabs
                      .map((t) => Tab(
                            child: Row(
                              children: [
                                Text(t.label),
                                if (t.status != null) ...[
                                  Gap(6.w),
                                  _CountBadge(
                                    count: allOrders
                                        .where((o) => o.status == t.status)
                                        .length,
                                    small: true,
                                  ),
                                ],
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // ── Tab views ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((t) {
                final filtered = t.status == null
                    ? allOrders
                    : allOrders.where((o) => o.status == t.status).toList();
                return _OrderList(orders: filtered);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order list ────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48.sp, color: AppColors.textDisabled),
            Gap(12.h),
            Text('No orders', style: AppTextStyles.bodyLarge),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(24.r),
      itemCount: orders.length,
      separatorBuilder: (_, _) => Gap(12.h),
      itemBuilder: (context, i) => _OrderRow(order: orders[i]),
    );
  }
}

// ── Single order row ──────────────────────────────────────────────────────────

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(order.status);
    final isCompact = context.screenWidth < 850;

    if (isCompact) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: 4.w,
              height: 64.h,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Table ${order.tableNumber}',
                        style: AppTextStyles.titleLarge,
                      ),
                      Text(
                        order.total.asCurrency,
                        style: AppTextStyles.priceTag,
                      ),
                    ],
                  ),
                  Gap(4.h),
                  Text(
                    order.items
                        .map((i) => '${i.quantity}× ${i.menuItem.name}')
                        .join(', '),
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.createdAt.minutesAgoLabel,
                        style: AppTextStyles.bodySmall,
                      ),
                      _StatusPill(status: order.status, color: statusColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4.w,
            height: 56.h,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          Gap(16.w),
          // Table + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table ${order.tableNumber}',
                style: AppTextStyles.titleLarge,
              ),
              Gap(4.h),
              Text(
                order.createdAt.minutesAgoLabel,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          Gap(24.w),
          // Items summary — Flexible prevents overflow at narrow widths
          Flexible(
            child: Text(
              order.items
                  .map((i) => '${i.quantity}× ${i.menuItem.name}')
                  .join(', '),
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap(16.w),
          // Total
          Text(order.total.asCurrency, style: AppTextStyles.priceTag),
          Gap(16.w),
          // Status badge — passive display only, no interaction
          // Cashiers can SEE KDS status but cannot change it from this screen.
          _StatusPill(status: order.status, color: statusColor),
        ],
      ),
    );
  }


  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.statusPending,
        OrderStatus.accepted => AppColors.statusPreparing,
        OrderStatus.preparing => AppColors.statusPreparing,
        OrderStatus.ready => AppColors.statusReady,
        OrderStatus.served => AppColors.statusServed,
        OrderStatus.completed => AppColors.statusReady,
        OrderStatus.cancelled => AppColors.statusCancelled,
        OrderStatus.syncConflict => AppColors.statusCancelled,
      };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final OrderStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.small = false});
  final int count;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6.w : 8.w, vertical: small ? 2.h : 3.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.badgeText.copyWith(
          fontSize: small ? 9.sp : 11.sp,
        ),
      ),
    );
  }
}

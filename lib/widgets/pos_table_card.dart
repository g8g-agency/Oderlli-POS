import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../core/extensions/extensions.dart';
import 'widgets.dart';

/// ─── Orderlyy POS · Table Card Widget ───────────────────────────────────────
///
/// A premium dining table card optimized for POS tablet grids.
/// Displays table status, guest capacity, active elapsed timers, assigned waiter,
/// bill amount, and corresponding status chips with pulsing indicators.
class POSTableCard extends StatelessWidget {
  const POSTableCard({
    super.key,
    required this.table,
    this.onTap,
    this.isSelected = false,
  });

  final TableModel table;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Map POSTableStatus to OperationalStatus
    final opStatus = _mapToOperationalStatus(table.status);
    final statusColor = opStatus.color;

    return POSCard(
      onTap: onTap,
      isSelected: isSelected,
      padding: EdgeInsets.zero, // Zero padding to handle top border bar inside
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 140.h),
        child: Stack(
          children: [
            // ── Top color indicator bar based on table status (Animated) ───────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                height: 5.h,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLG.r - 1.r),
                  ),
                ),
              ),
            ),
            // ── Card Content ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(4.h),
                  // Header: Table Number & Capacity
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TABLE ${table.number}',
                            style: AppTypography.tableLabel,
                          ),
                          if (table.assignedWaiterName != null) ...[
                            Gap(2.h),
                            Text(
                              table.assignedWaiterName!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people_outline,
                        size: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                      Gap(4.w),
                      Text(
                        table.status == POSTableStatus.available
                            ? '${table.capacity}'
                            : '${table.guestCount}/${table.capacity}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Gap(6.h),
                  // Middle: Timer & Waiter / Vacant Details (Animated Switcher)
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: table.status != POSTableStatus.available
                          ? Column(
                              key: ValueKey('active_${table.id}_${table.status}'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 13.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                    Gap(4.w),
                                    Expanded(
                                      child: Text(
                                        '${table.elapsedMinutes}m elapsed',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Gap(8.w),
                                    Text(
                                      table.waiterName ?? '',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Gap(6.h),
                                // Bill Amount - formatted using brand consistent currency format
                                Text(
                                  table.billTotal.asCurrency,
                                  style: AppTypography.priceTag.copyWith(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Align(
                              key: ValueKey('vacant_${table.id}'),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Table is vacant',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textDisabled,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                  ),
                  // Footer: Operational Status Chip & Payment Intent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OperationalStatusChip(status: opStatus),
                      if (table.customerPaymentIntent != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.statusReady.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: AppColors.statusReady.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            table.customerPaymentIntent!.toUpperCase(),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.statusReady,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps internal table status enum to the central operational status system.
  OperationalStatus _mapToOperationalStatus(POSTableStatus status) {
    return switch (status) {
      POSTableStatus.available => OperationalStatus.available,
      POSTableStatus.occupied => OperationalStatus.occupied,
      POSTableStatus.preparing => OperationalStatus.preparing,
      POSTableStatus.ready => OperationalStatus.ready,
      POSTableStatus.paymentPending => OperationalStatus.paymentPending,
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// ─── Orderlli POS · Metric Tile ─────────────────────────────────────────────
///
/// A premium key performance metric card for displaying financial data (e.g., revenue,
/// average ticket size) with trends and color indicators.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositiveTrend = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositiveTrend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container (reduced from 44r to 36r)
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Gap(AppSpacing.sm.w), // reduced from md.w to sm.w
          // Metric Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: AppTextStyles.metricValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trend != null) ...[
                      Gap(4.w),
                      Icon(
                        isPositiveTrend
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 11.sp,
                        color: isPositiveTrend ? AppColors.profit : AppColors.loss,
                      ),
                      Text(
                        trend!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isPositiveTrend ? AppColors.profit : AppColors.loss,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                Gap(1.h),
                Text(
                  label,
                  style: AppTextStyles.metricLabel,
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
}

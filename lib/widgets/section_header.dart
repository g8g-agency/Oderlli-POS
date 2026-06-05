import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// ─── Orderlyy POS · Section Header ──────────────────────────────────────────
///
/// Standardized header layout for sections (e.g. Menu categories, active lists).
/// Displays a title, an optional counts badge, and a trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.action,
  });

  final String title;
  final int? count;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall,
        ),
        if (count != null) ...[
          Gap(AppSpacing.xs.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?action,
      ],
    );
  }
}

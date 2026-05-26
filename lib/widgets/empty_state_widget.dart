import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// ─── Orderlli POS · Empty State Widget ──────────────────────────────────────
///
/// A premium empty state layout displaying an icon, headline, supporting text,
/// and an optional custom action button. Perfect for unoccupied tables, empty carts,
/// or no active orders lists.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon backdrop
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5.w),
              ),
              child: Icon(
                icon,
                size: 36.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Gap(AppSpacing.md.h),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(AppSpacing.xs.h),
            Container(
              constraints: BoxConstraints(maxWidth: 320.w),
              child: Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionText != null && onActionPressed != null) ...[
              Gap(AppSpacing.lg.h),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 160.w),
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    minimumSize: Size(160.w, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                    ),
                  ),
                  child: Text(
                    actionText!,
                    style: AppTypography.buttonText.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

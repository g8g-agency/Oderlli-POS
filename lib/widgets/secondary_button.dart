import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// ─── Orderlli POS · Secondary Button ────────────────────────────────────────
///
/// Tablet-optimized secondary action button with a large touch target (52px height)
/// and flat outline design. Commonly used for auxiliary tasks.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 20.sp,
            color: onPressed == null ? AppColors.textDisabled : AppColors.textPrimary,
          ),
          SizedBox(width: AppSpacing.sm.w),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: AppTypography.buttonText.copyWith(
                color: onPressed == null
                    ? AppColors.textDisabled
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(fullWidth ? double.infinity : 0, height ?? 52.h),
          side: BorderSide(
            color: onPressed == null ? AppColors.borderSubtle : AppColors.border,
            width: 1.5,
          ),
          backgroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg.w,
            vertical: AppSpacing.md.h,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}

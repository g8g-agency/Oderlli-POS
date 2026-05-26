import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// ─── Orderlli POS · Danger Button ───────────────────────────────────────────
///
/// Tablet-optimized danger action button with a large touch target (52px height)
/// and a high-contrast loss/error red fill. Used for voiding, deleting, or cancelling.
class DangerButton extends StatelessWidget {
  const DangerButton({
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
        ] else if (icon != null) ...[
          Icon(icon, size: 20.sp, color: AppColors.textOnPrimary),
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
                    : AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(fullWidth ? double.infinity : 0, height ?? 52.h),
          backgroundColor: AppColors.loss,
          disabledBackgroundColor: AppColors.surfaceVariant,
          elevation: 0,
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

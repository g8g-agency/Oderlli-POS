import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// ─── Orderlyy POS · POS Card ────────────────────────────────────────────────
///
/// A premium container component matching the dark operational system scheme.
/// Supports selection highlighting, custom borders, paddings, and tap handlers.
class POSCard extends StatelessWidget {
  const POSCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.isSelected = false,
    this.borderColor,
    this.backgroundColor,
    this.elevation = 0.0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? borderColor;
  final Color? backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final defaultBorder = Border.all(
      color: isSelected
          ? AppColors.primary
          : (borderColor ?? AppColors.border),
      width: isSelected ? 2.w : 1.w,
    );

    if (onTap != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
          border: defaultBorder,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: AppColors.shadowDeep.withValues(alpha: 0.15),
                    blurRadius: elevation * 2,
                    offset: Offset(0, elevation),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r - (isSelected ? 2.r : 1.r)),
            hoverColor: AppColors.primary.withValues(alpha: 0.05),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: padding ?? EdgeInsets.all(AppSpacing.md.r),
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
        border: defaultBorder,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.shadowDeep.withValues(alpha: 0.15),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                )
              ]
            : null,
      ),
      child: child,
    );
  }
}

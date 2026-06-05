import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// ─── Orderlyy POS · Loading Overlay ──────────────────────────────────────────
///
/// A premium overlay component that blocks interactions while performing async tasks
/// (e.g. sending orders, processing receipts). Displays a modal loading animation.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  final Widget child;
  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isLoading,
            child: AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Stack(
                children: [
                  // Semi-transparent blocker backdrop
                  ModalBarrier(
                    dismissible: false,
                    color: AppColors.background.withValues(alpha: 0.7),
                  ),
                  // Loader box
                  Center(
                    child: AnimatedScale(
                      scale: isLoading ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg.w,
                          vertical: AppSpacing.md.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowDeep.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 36.w,
                              height: 36.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5.w,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            if (message != null) ...[
                              Gap(AppSpacing.md.h),
                              Text(
                                message!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

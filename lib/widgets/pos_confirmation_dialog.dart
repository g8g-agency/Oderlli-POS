import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import 'primary_button.dart';
import 'secondary_button.dart';
import 'danger_button.dart';

/// Shows a premium, custom animated confirmation dialog with a glassmorphic blurred backdrop.
Future<bool?> showPOSConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  String confirmText = 'CONFIRM',
  String cancelText = 'CANCEL',
  bool isDanger = false,
  IconData icon = Icons.help_outline,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'POSConfirmationDialog',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Scale and Fade animation curves
      final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
      );
      final opacity = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: scale,
            child: AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
                side: const BorderSide(color: AppColors.border),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 380.w,
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title block with Icon
                    Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: isDanger 
                                ? AppColors.error.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: isDanger ? AppColors.error : AppColors.primary,
                            size: 22.sp,
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(20.h),
                    // Description
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    Gap(24.h),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            text: cancelText,
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: isDanger
                              ? DangerButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  text: confirmText,
                                )
                              : PrimaryButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  text: confirmText,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

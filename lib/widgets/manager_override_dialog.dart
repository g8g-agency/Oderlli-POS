import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import 'primary_button.dart';

class ManagerOverrideDialog extends StatefulWidget {
  const ManagerOverrideDialog({super.key, required this.actionName});

  final String actionName;

  @override
  State<ManagerOverrideDialog> createState() => _ManagerOverrideDialogState();
}

class _ManagerOverrideDialogState extends State<ManagerOverrideDialog> {
  String _pin = '';
  bool _isError = false;
  bool _isLoading = false;

  void _onKeyPress(String val) {
    if (_pin.length < 4 && !_isLoading) {
      setState(() {
        _pin += val;
        _isError = false;
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isLoading) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  void _onClear() {
    if (!_isLoading) {
      setState(() {
        _pin = '';
        _isError = false;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (_pin.length != 4 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    // Simulate network credential validation delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Alexander is the Manager with PIN '1111'
    if (_pin == '1111') {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        setState(() {
          _pin = '';
          _isError = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Manager PIN. Authorization failed.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r)),
      child: Container(
        width: 380.w,
        padding: EdgeInsets.all(AppSpacing.lg.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 24.sp),
                Gap(12.w),
                Expanded(
                  child: Text(
                    'Manager Override Required',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Gap(8.h),
            Text(
              'Authorize: "${widget.actionName}"',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            Gap(20.h),
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final hasDigit = index < _pin.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                  width: 18.r,
                  height: 18.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLoading
                        ? AppColors.textDisabled
                        : (_isError
                            ? AppColors.error
                            : (hasDigit ? AppColors.primary : AppColors.surfaceVariant)),
                    border: Border.all(
                      color: _isError
                          ? AppColors.error
                          : (hasDigit ? AppColors.primary : AppColors.border),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            Gap(24.h),
            // PIN Keyboard Grid
            SizedBox(
              height: 240.h,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm.w,
                  mainAxisSpacing: AppSpacing.sm.h,
                  childAspectRatio: 1.6,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return _KeyButton(
                      label: 'CLEAR',
                      onTap: _onClear,
                      isAlt: true,
                    );
                  }
                  if (index == 10) {
                    return _KeyButton(
                      label: '0',
                      onTap: () => _onKeyPress('0'),
                    );
                  }
                  if (index == 11) {
                    return _KeyButton(
                      icon: Icons.backspace_outlined,
                      onTap: _onBackspace,
                      isAlt: true,
                    );
                  }
                  final number = index + 1;
                  return _KeyButton(
                    label: '$number',
                    onTap: () => _onKeyPress('$number'),
                  );
                },
              ),
            ),
            Gap(16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 44.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                      ),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: PrimaryButton(
                    onPressed: _pin.length == 4 && !_isLoading ? _onSubmit : null,
                    text: _isLoading ? 'VERIFYING...' : 'AUTHORIZE',
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.onTap,
    this.label,
    this.icon,
    this.isAlt = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAlt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAlt ? Colors.transparent : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
            border: Border.all(
              color: isAlt ? AppColors.borderSubtle : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: AppColors.textPrimary, size: 20.sp)
              : Text(
                  label!,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: label!.length > 1 ? 12.sp : 18.sp,
                    color: isAlt ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

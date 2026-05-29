import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

class SessionExpiredDialog extends ConsumerStatefulWidget {
  const SessionExpiredDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SessionExpiredDialog(),
    );
  }

  @override
  ConsumerState<SessionExpiredDialog> createState() => _SessionExpiredDialogState();
}

class _SessionExpiredDialogState extends ConsumerState<SessionExpiredDialog>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4 && !_isLoading && !_isError) {
      setState(() {
        _pin += digit;
      });
      if (_pin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isLoading && !_isError) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClear() {
    if (!_isLoading && !_isError) {
      setState(() {
        _pin = '';
      });
    }
  }

  Future<void> _submitPin() async {
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).unlock(_pin);

    if (mounted) {
      if (success) {
        navigator.pop();
      } else {
        final authState = ref.read(authProvider);
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = authState.errorMessage ?? 'Authentication failed';
          _pin = '';
        });
        _shakeController.forward(from: 0);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isError = false;
              _errorMessage = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.lockedUser ?? authState.user;
    final primaryColor = user?.role.color ?? AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Center(
        child: Container(
          width: 320.w,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.floatingPanelShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorContainer.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_clock_rounded,
                  color: AppColors.error,
                  size: 24.sp,
                ),
              ),
              Gap(16.h),
              // Headline
              Text(
                'Session Expired',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(4.h),
              Text(
                user != null
                    ? 'Enter PIN to unlock session for ${user.name}'
                    : 'Enter PIN to continue operations',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(20.h),

              // PIN Dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final hasDigit = index < _pin.length;
                    final Color dotColor;
                    final Color borderColor;

                    if (_isError) {
                      dotColor = AppColors.error;
                      borderColor = AppColors.error;
                    } else if (hasDigit) {
                      dotColor = primaryColor;
                      borderColor = primaryColor;
                    } else {
                      dotColor = Colors.transparent;
                      borderColor = AppColors.borderSubtle;
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        border: Border.all(color: borderColor, width: 2),
                      ),
                    );
                  }),
                ),
              ),

              // Feedback/Error message
              Gap(12.h),
              SizedBox(
                height: 18.h,
                child: _errorMessage != null
                    ? Text(
                        _errorMessage!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : _isLoading
                        ? Text(
                            'Authenticating...',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
              ),
              Gap(12.h),

              // Keypad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                  childAspectRatio: 1.6,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return _KeypadBtn(
                      label: 'CLEAR',
                      onTap: _onClear,
                      isAlt: true,
                    );
                  }
                  if (index == 10) {
                    return _KeypadBtn(
                      label: '0',
                      onTap: () => _onKeyPress('0'),
                    );
                  }
                  if (index == 11) {
                    return _KeypadBtn(
                      icon: Icons.backspace_outlined,
                      onTap: _onBackspace,
                      isAlt: true,
                    );
                  }
                  final number = index + 1;
                  return _KeypadBtn(
                    label: '$number',
                    onTap: () => _onKeyPress('$number'),
                  );
                },
              ),
              Gap(12.h),
              // Logout fallback button
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await ref.read(authProvider.notifier).logout();
                  navigator.pop();
                },
                child: Text(
                  'LOG OUT COMPLETELY',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadBtn extends StatelessWidget {
  const _KeypadBtn({
    this.label,
    this.icon,
    required this.onTap,
    this.isAlt = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAlt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAlt ? Colors.transparent : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        onTap: onTap,
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: 18.sp,
                  color: AppColors.textSecondary,
                )
              : Text(
                  label!,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isAlt ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: label == 'CLEAR' ? 10.sp : 16.sp,
                  ),
                ),
        ),
      ),
    );
  }
}

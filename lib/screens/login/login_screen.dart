import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String? _selectedStaff;

  final List<String> _staffList = [
    'Alexander (Manager)',
    'Sarah (Cashier A)',
    'Michael (Cashier B)',
    'Jessica (Server)',
  ];

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _pin = '';
    });
  }

  void _onLogin() {
    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member first.')),
      );
      return;
    }
    if (_pin.length == 4) {
      // Simulate quick login
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit PIN.')),
      );
    }
  }

  Widget _buildStaffCard(String staff, bool isSelected) {
    return POSCard(
      onTap: () => setState(() => _selectedStaff = staff),
      isSelected: isSelected,
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant,
            child: Icon(
              Icons.person,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
          Gap(16.w),
          Expanded(
            child: Text(
              staff,
              style: AppTypography.titleMedium.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;

    final staffListWidget = Container(
      color: AppColors.sidebarBg,
      padding: EdgeInsets.all(AppSpacing.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Orderlli POS',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Gap(8.h),
          Text(
            'Select your profile to sign in',
            style: AppTypography.bodySmall,
          ),
          Gap(AppSpacing.lg.h),
          if (isVertical)
            SizedBox(
              height: 90.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _staffList.length,
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  final isSelected = _selectedStaff == staff;
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: SizedBox(
                      width: 240.w,
                      child: _buildStaffCard(staff, isSelected),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _staffList.length,
                separatorBuilder: (_, _) => Gap(AppSpacing.sm.h),
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  final isSelected = _selectedStaff == staff;
                  return _buildStaffCard(staff, isSelected);
                },
              ),
            ),
        ],
      ),
    );

    final pinPadWidget = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isVertical ? 24.w : 48.w,
          vertical: isVertical ? 20.h : 32.h,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter PIN Code',
              style: AppTypography.headlineMedium,
            ),
            Gap(16.h),
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final hasDigit = index < _pin.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasDigit ? AppColors.primary : AppColors.surfaceVariant,
                    border: Border.all(
                      color: hasDigit ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            Gap(AppSpacing.xl.h),
            // Keyboard Grid — fixed height for scrollability
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320.w,
                maxHeight: 320.h,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.md.w,
                  mainAxisSpacing: AppSpacing.md.h,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return _PinButton(
                      label: 'CLEAR',
                      onTap: _onClear,
                      isAlt: true,
                    );
                  }
                  if (index == 10) {
                    return _PinButton(
                      label: '0',
                      onTap: () => _onKeyPress('0'),
                    );
                  }
                  if (index == 11) {
                    return _PinButton(
                      icon: Icons.backspace_outlined,
                      onTap: _onBackspace,
                      isAlt: true,
                    );
                  }
                  final number = index + 1;
                  return _PinButton(
                    label: '$number',
                    onTap: () => _onKeyPress('$number'),
                  );
                },
              ),
            ),
            Gap(16.h),
            // Sign In Button
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 320.w),
              child: PrimaryButton(
                onPressed: _pin.length == 4 && _selectedStaff != null
                    ? _onLogin
                    : null,
                text: 'SIGN IN',
              ),
            ),
          ],
        ),
      ),
    );

    if (isVertical) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              staffListWidget,
              Container(height: 1.h, color: AppColors.border),
              Expanded(child: pinPadWidget),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: staffListWidget,
          ),
          // Divider
          Container(width: 1.w, color: AppColors.border),
          Expanded(
            flex: 5,
            child: pinPadWidget,
          ),
        ],
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({
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
      color: isAlt ? AppColors.background : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
            border: Border.all(
              color: isAlt ? AppColors.borderSubtle : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: AppColors.textPrimary, size: 24.sp)
              : Text(
                  label!,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isAlt ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

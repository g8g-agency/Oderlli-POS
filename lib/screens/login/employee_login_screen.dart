import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';

/// Loads branch-scoped staff. Only re-fetches when tenant/branch changes —
/// not on every auth tick (isLoading, lock state, etc.).
final staffListProvider = FutureProvider<List<PosUser>>((ref) async {
  final tenantId = ref.watch(authProvider.select((s) => s.tenantId));
  final branchId = ref.watch(authProvider.select((s) => s.branchId));

  if (tenantId == null ||
      tenantId.isEmpty ||
      branchId == null ||
      branchId.isEmpty) {
    return [];
  }

  final repo = ref.read(authRepositoryProvider);
  return repo.fetchStaff(
    tenantId: tenantId,
    branchId: branchId,
  );
});

class EmployeeLoginScreen extends ConsumerStatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  ConsumerState<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends ConsumerState<EmployeeLoginScreen>
    with TickerProviderStateMixin {
  // ── UI State ────────────────────────────────────────────────────────────────
  String _pin = '';
  PosUser? _selectedUser;
  bool _isError = false;
  String _feedbackText = '';

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _avatarController;
  late final Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();

    // Horizontal shake on PIN error
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );

    // Avatar scale pulse on profile selection
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _avatarScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  // ── Keyboard Support ─────────────────────────────────────────────────────────
  String? _digitFromKey(LogicalKeyboardKey key) {
    final map = {
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };
    return map[key];
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final auth = ref.read(authProvider);
    if (auth.isLoading || _isError) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _onLogin();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _onClear();
      return KeyEventResult.handled;
    }
    final digit = _digitFromKey(event.logicalKey);
    if (digit != null) {
      _onKeyPress(digit);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onKeyPress(String val) {
    final auth = ref.read(authProvider);
    if (_pin.length < 4 && !auth.isLoading && !_isError) {
      setState(() { _pin += val; });
    }
  }

  void _onBackspace() {
    final auth = ref.read(authProvider);
    if (_pin.isNotEmpty && !auth.isLoading && !_isError) {
      setState(() { _pin = _pin.substring(0, _pin.length - 1); });
    }
  }

  void _onClear() {
    final auth = ref.read(authProvider);
    if (!auth.isLoading && !_isError) {
      setState(() { _pin = ''; });
    }
  }

  Future<void> _onLogin() async {
    final auth = ref.read(authProvider);
    final user = auth.isLocked ? auth.lockedUser : _selectedUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee profile first.')),
      );
      return;
    }

    if (_pin.length == 4) {
      setState(() {
        _feedbackText = auth.isLocked ? 'Unlocking terminal...' : 'Authenticating employee...';
      });

      bool success = false;
      if (auth.isLocked) {
        // Unlock mode: check user PIN, or allow Manager PIN override
        success = await ref.read(authProvider.notifier).unlock(_pin);
        if (!success) {
          final staffListAsync = ref.read(staffListProvider);
          final firstManager = staffListAsync.valueOrNull?.firstWhere(
            (u) => u.role == UserRole.manager,
            orElse: () => user,
          );
          if (firstManager != null) {
            success = await ref.read(authProvider.notifier).unlock(_pin, managerOverride: firstManager);
          }
        }
      } else {
        success = await ref.read(authProvider.notifier).loginEmployee(user, _pin);
      }

      if (success) {
        if (mounted) {
          setState(() => _feedbackText = 'Welcome back, ${user.name}! ✓');
          await Future.delayed(const Duration(milliseconds: 380));
          if (mounted) {
            context.go('/dashboard');
          }
        }
      } else {
        if (mounted) {
          final updatedAuth = ref.read(authProvider);
          setState(() {
            _isError = true;
            _feedbackText = updatedAuth.errorMessage ?? 'Incorrect PIN. Please try again.';
            _pin = '';
          });
          _shakeController.forward(from: 0);
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              setState(() {
                _isError = false;
                _feedbackText = '';
              });
            }
          });
        }
      }
    }
  }

  Future<void> _onSwitchBranch() async {
    // Let user return to branch selection
    await ref.read(authProvider.notifier).selectBranch('', '');
  }

  Future<void> _onResetSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset Terminal Session'),
        content: const Text('Are you sure you want to log out of this organization completely? This will clear all local branch caches.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Widget _buildStaffCard(PosUser user, bool isSelected, bool isDisabled) {
    final roleColor = user.role.color;

    return Semantics(
      label: '${user.name}, ${user.role.label}. ${isSelected ? 'Selected.' : ''}',
      button: true,
      selected: isSelected,
      excludeSemantics: false,
      child: Opacity(
        opacity: isDisabled ? 0.38 : 1.0,
        child: MouseRegion(
          cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    setState(() {
                      _selectedUser = user;
                      _pin = '';
                      _feedbackText = '';
                    });
                    _avatarController.forward(from: 0);
                  },
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeOut,
              constraints: BoxConstraints(minHeight: 72.h),
              decoration: BoxDecoration(
                color: isSelected && !isDisabled
                    ? roleColor.withValues(alpha: 0.055)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: isSelected && !isDisabled
                    ? [
                        BoxShadow(
                          color: roleColor.withValues(alpha: 0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : AppShadows.cardShadow,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      width: 3,
                      decoration: BoxDecoration(
                        color: isSelected && !isDisabled ? roleColor : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.radiusMD.r),
                          bottomLeft: Radius.circular(AppSpacing.radiusMD.r),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _avatarScale,
                          builder: (context, child) => Transform.scale(
                            scale: isSelected ? _avatarScale.value : 1.0,
                            child: child,
                          ),
                          child: Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected && !isDisabled ? roleColor : AppColors.surfaceVariant,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user.initials,
                              style: AppTypography.titleMedium.copyWith(
                                color: isSelected && !isDisabled ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Gap(12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected && !isDisabled ? roleColor : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Gap(4.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull.r),
                                  border: Border.all(color: roleColor.withValues(alpha: 0.24)),
                                ),
                                child: Text(
                                  user.role.name.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: roleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9.sp,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected && !isDisabled) ...[
                          Gap(8.w),
                          Icon(
                            Icons.check_circle_rounded,
                            color: roleColor,
                            size: 18.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(AuthState auth, PosUser? activeUser, List<PosUser> staff, bool isVertical) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(6, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 26.h, 22.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!auth.isLocked) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _onSwitchBranch,
                      ),
                      Gap(12.w),
                    ],
                    const _PosLogo(),
                  ],
                ),
                Gap(8.h),
                Text(
                  auth.branchName ?? 'Branch Store',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBA0013),
                  ),
                ),
                Gap(4.h),
                Text(
                  auth.isLocked ? '⚠ TERMINAL LOCKED' : 'Select employee profile to sign in',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: auth.isLocked ? FontWeight.w700 : FontWeight.w400,
                    color: auth.isLocked ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isVertical)
            SizedBox(
              height: 100.h.clamp(96.0, 130.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                itemCount: staff.length,
                itemBuilder: (context, index) {
                  final user = staff[index];
                  final isSelected = activeUser?.id == user.id;
                  final isDisabled = auth.isLocked && user.id != auth.lockedUser?.id;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: SizedBox(
                      width: 210.w.clamp(180.0, 300.0),
                      child: _buildStaffCard(user, isSelected, isDisabled),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
                itemCount: staff.length,
                separatorBuilder: (context, index) => Gap(8.h),
                itemBuilder: (context, index) {
                  final user = staff[index];
                  final isSelected = activeUser?.id == user.id;
                  final isDisabled = auth.isLocked && user.id != auth.lockedUser?.id;
                  return _buildStaffCard(user, isSelected, isDisabled);
                },
              ),
            ),
          if (!isVertical) _buildTerminalFooter(),
        ],
      ),
    );
  }

  Widget _buildRightPanel(AuthState auth, PosUser? activeUser, bool isVertical) {
    final buttonColor = activeUser?.role.color ?? AppColors.primary;
    final canSignIn = _pin.length == 4 && activeUser != null;

    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -90,
          child: Container(
            width: 300.r,
            height: 300.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isVertical ? 20.w : 40.w,
              vertical: 28.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 310.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (auth.isLocked) ...[
                    Container(
                      width: 60.r,
                      height: 60.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.errorContainer.withValues(alpha: 0.6),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.lock_rounded,
                        color: AppColors.error,
                        size: 26.sp,
                      ),
                    ),
                    Gap(12.h),
                    Text(
                      'Terminal Locked',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(3.h),
                    Text(
                      '${auth.lockedUser?.name} · ${auth.lockedUser?.role.label}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (activeUser != null) ...[
                    AnimatedBuilder(
                      animation: _avatarScale,
                      builder: (context, child) => Transform.scale(
                        scale: _avatarScale.value,
                        child: child,
                      ),
                      child: Container(
                        width: 58.r,
                        height: 58.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeUser.role.color,
                          boxShadow: [
                            BoxShadow(
                              color: activeUser.role.color.withValues(alpha: 0.30),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          activeUser.initials,
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Gap(12.h),
                    Text(
                      'Welcome back, ${activeUser.name}',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(3.h),
                    Text(
                      activeUser.role.label,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ] else ...[
                    Container(
                      width: 60.r,
                      height: 60.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 28.sp,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Gap(12.h),
                    Text(
                      'Enter PIN Code',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(3.h),
                    Text(
                      'Select profile to begin',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                  Gap(20.h),
                  _buildPinDots(activeUser),
                  SizedBox(
                    height: 22.h,
                    child: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      child: _feedbackText.isNotEmpty
                          ? Text(
                              _feedbackText,
                              key: ValueKey(_feedbackText),
                              style: AppTypography.labelMedium.copyWith(
                                color: _isError
                                    ? AppColors.error
                                    : _feedbackText.startsWith('Welcome')
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(key: ValueKey('feedback-empty')),
                    ),
                  ),
                  Gap(16.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 1.52,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) {
                        return _KeypadButton(
                          label: 'CLEAR',
                          onTap: _onClear,
                          isAlt: true,
                        );
                      }
                      if (index == 10) {
                        return _KeypadButton(
                          label: '0',
                          onTap: () => _onKeyPress('0'),
                        );
                      }
                      if (index == 11) {
                        return _KeypadButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onBackspace,
                          isAlt: true,
                        );
                      }
                      final number = index + 1;
                      return _KeypadButton(
                        label: '$number',
                        onTap: () => _onKeyPress('$number'),
                      );
                    },
                  ),
                  Gap(14.h),
                  auth.isLoading
                      ? SizedBox(
                          height: 52.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: Semantics(
                            label: auth.isLocked ? 'Unlock Terminal' : 'Sign In',
                            button: true,
                            child: PrimaryButton(
                              onPressed: canSignIn ? _onLogin : null,
                              text: auth.isLocked ? 'UNLOCK TERMINAL' : 'SIGN IN',
                              backgroundColor: canSignIn ? buttonColor : null,
                            ),
                          ),
                        ),
                  Gap(10.h),
                  // Lock/Reset options
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: TextButton.icon(
                      onPressed: _onResetSession,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFBA0013),
                      ),
                      label: const Text(
                        'LOGOUT ORGANIZATION',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA0013)),
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

  Widget _buildPinDots(PosUser? activeUser) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
      ),
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
            final roleColor = activeUser?.role.color ?? AppColors.primary;
            dotColor = roleColor;
            borderColor = roleColor;
          } else {
            dotColor = Colors.transparent;
            borderColor = AppColors.borderSubtle;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            width: 13.r,
            height: 13.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: Border.all(color: borderColor, width: 2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTerminalFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, size: 12.sp, color: AppColors.success),
          Gap(5.w),
          Text(
            'Cloud Synced',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10.sp,
            ),
          ),
          const Spacer(),
          Container(
            width: 6.r,
            height: 6.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          Gap(4.w),
          Text(
            'Online',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;
    final auth = ref.watch(authProvider);
    final staffAsync = ref.watch(staffListProvider);

    ref.listen<PosUser?>(
      authProvider.select((s) => s.isLocked ? s.lockedUser : null),
      (previous, lockedUser) {
        if (lockedUser != null && _selectedUser?.id != lockedUser.id) {
          setState(() => _selectedUser = lockedUser);
        }
      },
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: staffAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA0013)),
              ),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  Gap(16.h),
                  Text('Failed to load branch staff', style: AppTypography.titleMedium),
                  Gap(8.h),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(staffListProvider),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
            data: (staff) {
              final activeUser = auth.isLocked ? auth.lockedUser : _selectedUser;

              final leftWidth = (context.screenWidth * 0.36).clamp(270.0, 390.0);

              return isVertical
                  ? Column(
                      children: [
                        Expanded(child: _buildLeftPanel(auth, activeUser, staff, true)),
                        Container(height: 1, color: AppColors.borderSubtle),
                        Expanded(child: _buildRightPanel(auth, activeUser, true)),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: leftWidth,
                          child: _buildLeftPanel(auth, activeUser, staff, false),
                        ),
                        Container(width: 1, color: AppColors.borderSubtle),
                        Expanded(child: _buildRightPanel(auth, activeUser, false)),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _PosLogo extends StatelessWidget {
  const _PosLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 14.sp,
          ),
        ),
        Gap(9.w),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Orderlli',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              TextSpan(
                text: ' POS',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatefulWidget {
  const _KeypadButton({
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
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 75),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onTap();
    await _pressController.forward();
    if (mounted) await _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label ?? 'Backspace',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _pressScale,
            builder: (context, child) => Transform.scale(
              scale: _pressScale.value,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              constraints: BoxConstraints(minHeight: 48.h),
              decoration: BoxDecoration(
                color: widget.isAlt
                    ? (_isHovered ? AppColors.surfaceVariant : AppColors.background)
                    : (_isHovered ? AppColors.surfaceElevated : AppColors.surface),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                border: Border.all(
                  color: _isHovered ? AppColors.border.withValues(alpha: 0.6) : AppColors.borderSubtle,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    )
                  : Text(
                      widget.label!,
                      style: widget.isAlt
                          ? AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            )
                          : AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

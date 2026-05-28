import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — Premium Enterprise POS Authentication
// Visual redesign only. All business logic, RBAC, auth providers,
// and routing are PRESERVED and UNCHANGED.
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── UI State ────────────────────────────────────────────────────────────────
  String _pin = '';
  PosUser? _selectedUser;
  bool _isError = false;
  String _feedbackText = '';
  bool _showPasscode = false;

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _avatarController;
  late final Animation<double> _avatarScale;

  late final AnimationController _splashController;
  late final AnimationController _floatController;
  late final Animation<double> _logoAnim;
  late final Animation<double> _headlineAnim;
  late final Animation<double> _subtitleAnim;
  late final Animation<double> _mockupAnim;
  late final Animation<double> _featuresAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _buttonAnim;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();

    final auth = ref.read(authProvider);
    if (auth.isLocked) {
      _showPasscode = true;
    }

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

    // Splash and float animation controllers
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (kIsWeb) {
      _floatController.repeat();
    } else {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _floatController.repeat();
      }
    }

    _logoAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _headlineAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.08, 0.63, curve: Curves.easeOut),
    );
    _subtitleAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.13, 0.68, curve: Curves.easeOut),
    );
    _mockupAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.20, 0.75, curve: Curves.easeOut),
    );
    _featuresAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOut),
    );
    _taglineAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.37, 0.92, curve: Curves.easeOut),
    );
    _buttonAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.43, 0.98, curve: Curves.easeOut),
    );
    _footerAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showPasscode) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) {
            _splashController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _avatarController.dispose();
    _splashController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ── Keyboard Support ─────────────────────────────────────────────────────────
  /// Maps physical keyboard digit keys (number row + numpad) to string digits.
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

  // ── Business Logic ── PRESERVED, DO NOT MODIFY ────────────────────────────
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
        const SnackBar(content: Text('Please select a profile first.')),
      );
      return;
    }

    if (_pin.length == 4) {
      // Visual feedback state — no logic change
      setState(() {
        _feedbackText = auth.isLocked ? 'Unlocking terminal...' : 'Signing in...';
      });

      bool success = false;
      if (auth.isLocked) {
        // PRESERVED: Unlock mode: check user PIN, or allow Manager PIN override
        success = await ref.read(authProvider.notifier).unlock(_pin);
        if (!success) {
          success = await ref.read(authProvider.notifier)
              .unlock(_pin, managerOverride: PosUser.mockUsers.first);
        }
      } else {
        // PRESERVED: Normal login mode
        success = await ref.read(authProvider.notifier).authenticate(user, _pin);
      }

      if (success) {
        if (mounted) {
          setState(() => _feedbackText = 'Welcome back, ${user.name}! ✓');
          await Future.delayed(const Duration(milliseconds: 380));
          if (mounted) {
            context.go('/dashboard'); // PRESERVED: route unchanged
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isError = true;
            _feedbackText = 'Incorrect PIN. Please try again.';
            _pin = '';
          });
          _shakeController.forward(from: 0);
          // PRESERVED: 1000ms error flash, then reset
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

  Future<void> _onSwitchUser() async {
    // PRESERVED: Requires manager override to switch a locked terminal
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ManagerOverrideDialog(
        actionName: 'Unlock & Switch User Session',
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      setState(() {
        _selectedUser = null;
        _pin = '';
        _feedbackText = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terminal session reset. New user may log in.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // ── Staff Card ──────────────────────────────────────────────────────────────
  Widget _buildStaffCard(
    PosUser user,
    bool isSelected,
    bool isDisabled,
  ) {
    final roleColor = user.role.color;

    return Semantics(
      label: '${user.name}, ${user.role.label}. ${isSelected ? 'Selected.' : ''}',
      button: true,
      selected: isSelected,
      excludeSemantics: false,
      child: Opacity(
        opacity: isDisabled ? 0.38 : 1.0,
        child: MouseRegion(
          cursor: isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
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
                  // Left accent bar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      width: 3,
                      decoration: BoxDecoration(
                        color: isSelected && !isDisabled
                            ? roleColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.radiusMD.r),
                          bottomLeft: Radius.circular(AppSpacing.radiusMD.r),
                        ),
                      ),
                    ),
                  ),
                  // Content padding and row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        // Avatar — pulses on selection
                        AnimatedBuilder(
                          animation: _avatarScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSelected ? _avatarScale.value : 1.0,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected && !isDisabled
                                  ? roleColor
                                  : AppColors.surfaceVariant,
                              boxShadow: isSelected && !isDisabled
                                  ? [
                                      BoxShadow(
                                        color: roleColor.withValues(alpha: 0.28),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user.initials,
                              style: AppTypography.titleMedium.copyWith(
                                color: isSelected && !isDisabled
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Gap(12.w),
                        // Name + role badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected && !isDisabled
                                      ? roleColor
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Gap(4.h),
                              // Capsule role badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.10),
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusFull.r),
                                  border: Border.all(
                                    color: roleColor.withValues(alpha: 0.24),
                                  ),
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
                        // Selection checkmark
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

  // ── Terminal Footer ─────────────────────────────────────────────────────────
  Widget _buildTerminalFooter() {
    String terminalName = 'Terminal 01';
    if (!kIsWeb) {
      terminalName = Platform.environment['TERMINAL_ID'] ??
          Platform.environment['TERMINAL_NAME'] ??
          'Terminal 01';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_done_outlined,
            size: 12.sp,
            color: AppColors.success,
          ),
          Gap(5.w),
          Text(
            'Cloud Synced',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10.sp,
            ),
          ),
          const Spacer(),
          Text(
            terminalName,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10.sp,
            ),
          ),
          Gap(8.w),
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

  // ── Left Panel ──────────────────────────────────────────────────────────────
  Widget _buildLeftPanel(AuthState auth, PosUser? activeUser, bool isVertical) {
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
          // Logo + subtitle
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
                        onPressed: () {
                          setState(() {
                            _showPasscode = false;
                          });
                          _splashController.forward(from: 0);
                        },
                      ),
                      Gap(12.w),
                    ],
                    const _PosLogo(),
                  ],
                ),
                Gap(6.h),
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Text(
                    auth.isLocked
                        ? '⚠  TERMINAL LOCKED'
                        : 'Select your profile to sign in',
                    key: ValueKey(auth.isLocked),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight:
                          auth.isLocked ? FontWeight.w700 : FontWeight.w400,
                      color: auth.isLocked
                          ? AppColors.error
                          : AppColors.textSecondary,
                      letterSpacing: auth.isLocked ? 0.5 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile list
          if (isVertical)
            SizedBox(
              height: 86.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                itemCount: PosUser.mockUsers.length,
                itemBuilder: (context, index) {
                  final user = PosUser.mockUsers[index];
                  final isSelected = activeUser?.id == user.id;
                  final isDisabled =
                      auth.isLocked && user.id != auth.lockedUser?.id;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: SizedBox(
                      width: 210.w,
                      child: _buildStaffCard(user, isSelected, isDisabled),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding:
                    EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
                itemCount: PosUser.mockUsers.length,
                separatorBuilder: (context, index) => Gap(8.h),
                itemBuilder: (context, index) {
                  final user = PosUser.mockUsers[index];
                  final isSelected = activeUser?.id == user.id;
                  final isDisabled =
                      auth.isLocked && user.id != auth.lockedUser?.id;
                  return _buildStaffCard(user, isSelected, isDisabled);
                },
              ),
            ),
          // Footer — landscape only
          if (!isVertical) _buildTerminalFooter(),
        ],
      ),
    );
  }

  // ── PIN Dot Indicators ──────────────────────────────────────────────────────
  Widget _buildPinDots(PosUser? activeUser) {
    return AnimatedBuilder(
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

  // ── Right Panel ─────────────────────────────────────────────────────────────
  Widget _buildRightPanel(AuthState auth, PosUser? activeUser, bool isVertical) {
    // Role-aware button color
    final buttonColor = activeUser?.role.color ?? AppColors.primary;
    final canSignIn = _pin.length == 4 && activeUser != null;

    return Stack(
      children: [
        // ── Subtle background depth blobs ──────────────────────────────────
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
        Positioned(
          bottom: -60,
          left: -50,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.borderSubtle.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // ── Main scrollable content ────────────────────────────────────────
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
                  // ── Profile header ────────────────────────────────────────
                  if (auth.isLocked) ...[
                    // Locked state
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
                      '${auth.lockedUser?.name} · ${auth.lockedUser?.terminalId}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (activeUser != null) ...[
                    // Profile selected
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
                              color: activeUser.role.color
                                  .withValues(alpha: 0.30),
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
                      activeUser.terminalId,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ] else ...[
                    // No profile selected — empty state
                    Container(
                      width: 60.r,
                      height: 60.r,
                      decoration: BoxDecoration(
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
                      'Select a profile to begin →',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],

                  Gap(20.h),

                  // ── PIN indicators ────────────────────────────────────────
                  _buildPinDots(activeUser),

                  // ── Auth feedback text ────────────────────────────────────
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
                          : const SizedBox.shrink(
                              key: ValueKey('feedback-empty'),
                            ),
                    ),
                  ),

                  Gap(16.h),

                  // ── Keyboard hint ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_outlined,
                        size: 11.sp,
                        color: AppColors.textTertiary,
                      ),
                      Gap(4.w),
                      Flexible(
                        child: Text(
                          'Keyboard & numpad supported',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Gap(16.h),

                  // ── Numeric keypad ────────────────────────────────────────
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

                  // ── Sign In button ────────────────────────────────────────
                  auth.isLoading
                      ? SizedBox(
                          height: 52.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  buttonColor),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: Semantics(
                            label: auth.isLocked
                                ? 'Unlock Terminal'
                                : 'Sign In',
                            button: true,
                            child: PrimaryButton(
                              onPressed: canSignIn ? _onLogin : null,
                              text: auth.isLocked
                                  ? 'UNLOCK TERMINAL'
                                  : 'SIGN IN',
                              backgroundColor:
                                  canSignIn ? buttonColor : null,
                            ),
                          ),
                        ),

                  // ── Lock mode: switch user ────────────────────────────────
                  if (auth.isLocked && !auth.isLoading) ...[
                    Gap(10.h),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: TextButton.icon(
                        onPressed: _onSwitchUser,
                        icon: const Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'RESET SESSION / SWITCH USER',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],

                  Gap(14.h),

                  // ── Security footer ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 10.sp,
                        color: AppColors.textTertiary,
                      ),
                      Gap(4.w),
                      Flexible(
                        child: Text(
                          'Secure restaurant terminal access',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Root Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;
    final auth = ref.watch(authProvider);
    // PRESERVED: active user resolution logic unchanged
    final activeUser = auth.isLocked ? auth.lockedUser : _selectedUser;

    // Left panel width: 36% of screen, clamped for tablet/ultrawide safety
    final leftWidth =
        (context.screenWidth * 0.36).clamp(270.0, 390.0);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F0),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: !_showPasscode
                ? _buildSplashLayout(context)
                : _buildPasscodeLayout(auth, activeUser, isVertical, leftWidth),
          ),
        ),
      ),
    );
  }

  // ── Passcode Layout Helper ──────────────────────────────────────────────────
  Widget _buildPasscodeLayout(
    AuthState auth,
    PosUser? activeUser,
    bool isVertical,
    double leftWidth,
  ) {
    return KeyedSubtree(
      key: const ValueKey('passcode'),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: isVertical
                ? Column(
                    children: [
                      _buildLeftPanel(auth, activeUser, true),
                      Container(height: 1, color: AppColors.borderSubtle),
                      Expanded(
                          child:
                              _buildRightPanel(auth, activeUser, true)),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: _buildLeftPanel(auth, activeUser, false),
                      ),
                      Container(
                          width: 1, color: AppColors.borderSubtle),
                      Expanded(
                        child:
                            _buildRightPanel(auth, activeUser, false),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Background Blobs ────────────────────────────────────────────────────────
  Widget _buildBgBlobs() {
    return Stack(
      children: [
        Positioned(
          left: -100.w,
          top: -100.h,
          child: Container(
            width: 340.r,
            height: 340.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF7A00).withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          right: -80.w,
          top: -50.h,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB478).withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          right: -90.w,
          bottom: -90.h,
          child: Container(
            width: 280.r,
            height: 280.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF7A00).withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ── Fade & Slide Entrance Helper ──────────────────────────────────────────
  Widget _buildFadeSlide({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = animation.value;
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 18 * (1.0 - val)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ── Splash Screen Layout ─────────────────────────────────────────────────────
  Widget _buildSplashLayout(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('splash'),
      child: Stack(
        children: [
          _buildBgBlobs(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30.r,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(32.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Logo Row
                        _buildFadeSlide(
                          animation: _logoAnim,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42.r,
                                height: 42.r,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A00),
                                  borderRadius: BorderRadius.circular(11.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF7A00).withValues(alpha: 0.40),
                                      blurRadius: 16.r,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              Gap(10.w),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Orderlli',
                                      style: TextStyle(
                                        color: const Color(0xFF111827),
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' POS',
                                      style: TextStyle(
                                        color: const Color(0xFFFF7A00),
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap(24.h),

                        // 2. Headlines
                        _buildFadeSlide(
                          animation: _headlineAnim,
                          child: Text(
                            'Welcome to Orderlli POS',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Gap(4.h),
                        _buildFadeSlide(
                          animation: _subtitleAnim,
                          child: Text(
                            'Your Restaurant Command Center',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF7A00),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Gap(28.h),

                        // 3. Device Mockup Layout
                        _buildFadeSlide(
                          animation: _mockupAnim,
                          child: _buildMockups(),
                        ),
                        Gap(24.h),

                        // 4. Feature Cards Grid
                        _buildFadeSlide(
                          animation: _featuresAnim,
                          child: _buildFeatureCards(),
                        ),
                        Gap(20.h),

                        // 5. Tagline
                        _buildFadeSlide(
                          animation: _taglineAnim,
                          child: Text(
                            'Manage tables, orders, and settlements in real-time.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Gap(20.h),

                        // 6. CTA Button
                        _buildFadeSlide(
                          animation: _buttonAnim,
                          child: SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7A00).withValues(alpha: 0.40),
                                    blurRadius: 20.r,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showPasscode = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7A00),
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: 15.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Login / Sign Up',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Gap(8.w),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Gap(14.h),

                        // 7. Footer
                        _buildFadeSlide(
                          animation: _footerAnim,
                          child: Text(
                            'One app for all your restaurant operations.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overlapping Devices Layout ──────────────────────────────────────────────
  Widget _buildMockups() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tablet Mockup with Float animation
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatVal = 6 * sin(_floatController.value * 2 * pi);
              return Positioned(
                left: 0,
                top: 10 + floatVal,
                width: 236,
                child: child!,
              );
            },
            child: _buildTabletMockup(),
          ),
          // Phone Mockup with Float animation (offset phase)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatVal = 8 * sin((_floatController.value * 2 * pi) + 0.8);
              return Positioned(
                right: 0,
                top: 30 + floatVal,
                width: 128,
                child: child!,
              );
            },
            child: _buildPhoneMockup(),
          ),
        ],
      ),
    );
  }

  // ── Tablet Interface Mockup ─────────────────────────────────────────────────
  Widget _buildTabletMockup() {
    final statusColors = {
      'active': const Color(0xFFFF7A00),
      'billdue': const Color(0xFFEF4444),
      'ordering': const Color(0xFFF59E0B),
      'open': const Color(0xFFD1FAE5),
    };

    final mockTables = [
      {'num': 'T-01', 'amount': '₹2,840', 'status': 'active'},
      {'num': 'T-02', 'amount': '₹1,250', 'status': 'ordering'},
      {'num': 'T-03', 'amount': '₹4,120', 'status': 'billdue'},
      {'num': 'T-04', 'amount': '₹0', 'status': 'open'},
      {'num': 'T-05', 'amount': '₹1,890', 'status': 'active'},
      {'num': 'T-06', 'amount': '₹0', 'status': 'open'},
      {'num': 'T-07', 'amount': '₹3,034', 'status': 'billdue'},
      {'num': 'T-08', 'amount': '₹950', 'status': 'ordering'},
      {'num': 'T-09', 'amount': '₹3,410', 'status': 'active'},
      {'num': 'T-10', 'amount': '₹0', 'status': 'open'},
      {'num': 'T-11', 'amount': '₹2,150', 'status': 'active'},
      {'num': 'T-12', 'amount': '₹680', 'status': 'ordering'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tablet Header
            Container(
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFECEAE4), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))),
                      const Gap(2.5),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF59E0B))),
                      const Gap(2.5),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7A00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(3),
                      const Text(
                        'Floor Management',
                        style: TextStyle(
                          fontSize: 6.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
            // Tablet Grid
            Container(
              color: const Color(0xFFF5F4F0),
              padding: const EdgeInsets.all(4),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final table = mockTables[index];
                  final status = table['status']!;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 1.5,
                          color: statusColors[status],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  table['num']!,
                                  style: const TextStyle(
                                    fontSize: 5.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    table['amount']!,
                                    style: const TextStyle(
                                      fontSize: 4.8,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Tablet Footer
            Container(
              height: 14,
              color: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '14/18 Tables',
                    style: TextStyle(
                      fontSize: 5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        '₹48.2K Today',
                        style: TextStyle(
                          fontSize: 5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A00),
                        ),
                      ),
                      const Gap(3),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phone Interface Mockup ──────────────────────────────────────────────────
  Widget _buildPhoneMockup() {
    final phoneItems = [
      {'name': 'Chicken Tikka', 'price': '₹760'},
      {'name': 'Paneer Tikka', 'price': '₹320'},
      {'name': 'Butter Chicken', 'price': '₹480'},
      {'name': 'Dal Makhani', 'price': '₹280'},
      {'name': 'Lamb Biryani', 'price': '₹550'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone Header
            Container(
              height: 18,
              color: const Color(0xFFFF7A00),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Bill #2847',
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'T-07',
                    style: TextStyle(
                      fontSize: 5.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFF0E0),
                    ),
                  ),
                ],
              ),
            ),
            // Phone Items List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: phoneItems.map((item) {
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name']!,
                          style: const TextStyle(
                            fontSize: 5.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          item['price']!,
                          style: const TextStyle(
                            fontSize: 5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            // Phone Total Bar
            Container(
              height: 15,
              color: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 5.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '₹3,034',
                    style: TextStyle(
                      fontSize: 5.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                ],
              ),
            ),
            // Phone Bottom Bar
            Container(
              height: 16,
              color: const Color(0xFFFF7A00),
              alignment: Alignment.center,
              child: const Text(
                'Settle Payment',
                style: TextStyle(
                  fontSize: 5.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature Cards Row ───────────────────────────────────────────────────────
  Widget _buildFeatureCards() {
    final features = [
      {'label': 'Floor Map', 'painter': FloorMapPainter()},
      {'label': 'New Orders', 'painter': NewOrdersPainter()},
      {'label': 'Billing', 'painter': BillingPainter()},
      {'label': 'Kitchen', 'painter': KitchenPainter()},
      {'label': 'Live Sync', 'painter': LiveSyncPainter()},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: features.map((f) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: _InteractiveFeatureCard(
              label: f['label'] as String,
              painter: f['painter'] as CustomPainter,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Splash Icons
// ─────────────────────────────────────────────────────────────────────────────

class FloorMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.125, size.height * 0.25)
      ..lineTo(size.width * 0.375, size.height * 0.125)
      ..lineTo(size.width * 0.625, size.height * 0.25)
      ..lineTo(size.width * 0.875, size.height * 0.125)
      ..lineTo(size.width * 0.875, size.height * 0.75)
      ..lineTo(size.width * 0.625, size.height * 0.875)
      ..lineTo(size.width * 0.375, size.height * 0.75)
      ..lineTo(size.width * 0.125, size.height * 0.875)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(size.width * 0.375, size.height * 0.125), Offset(size.width * 0.375, size.height * 0.75), paint);
    canvas.drawLine(Offset(size.width * 0.625, size.height * 0.25), Offset(size.width * 0.625, size.height * 0.875), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NewOrdersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.05)
      ..lineTo(size.width * 0.2, size.height * 0.05)
      ..lineTo(size.width * 0.3, size.height * 0.6)
      ..lineTo(size.width * 0.85, size.height * 0.6)
      ..lineTo(size.width * 0.95, size.height * 0.25)
      ..lineTo(size.width * 0.25, size.height * 0.25);

    canvas.drawPath(path, paint);
    
    final fillPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.82), 2.5, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.77, size.height * 0.82), 2.5, fillPaint);
    
    canvas.drawLine(Offset(size.width * 0.45, size.height * 0.42), Offset(size.width * 0.65, size.height * 0.42), paint);
    canvas.drawLine(Offset(size.width * 0.55, size.height * 0.32), Offset(size.width * 0.55, size.height * 0.52), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BillingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(size.width * 0.08, size.height * 0.22, size.width * 0.84, size.height * 0.56);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.44), Offset(size.width * 0.92, size.height * 0.44), paint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.33), 1.5, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KitchenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.72)
      ..lineTo(size.width * 0.25, size.height * 0.85)
      ..arcToPoint(Offset(size.width * 0.75, size.height * 0.85), radius: const Radius.circular(2), clockwise: false)
      ..lineTo(size.width * 0.75, size.height * 0.72);
    canvas.drawPath(path, paint);

    final hatPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.15)
      ..cubicTo(size.width * 0.2, size.height * 0.15, size.width * 0.15, size.height * 0.45, size.width * 0.25, size.height * 0.72)
      ..lineTo(size.width * 0.75, size.height * 0.72)
      ..cubicTo(size.width * 0.85, size.height * 0.45, size.width * 0.8, size.height * 0.15, size.width * 0.5, size.height * 0.15);
    canvas.drawPath(hatPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LiveSyncPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.5), radius: size.width * 0.32);
    canvas.drawArc(rect, 0.2, 2.2 * pi / 2, false, paint);
    canvas.drawArc(rect, pi + 0.2, 2.2 * pi / 2, false, paint);

    final path1 = Path()
      ..moveTo(size.width * 0.75, size.height * 0.2)
      ..lineTo(size.width * 0.88, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.42);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.25, size.height * 0.8)
      ..lineTo(size.width * 0.12, size.height * 0.65)
      ..lineTo(size.width * 0.35, size.height * 0.58);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _InteractiveFeatureCard
// ─────────────────────────────────────────────────────────────────────────────

class _InteractiveFeatureCard extends StatefulWidget {
  const _InteractiveFeatureCard({
    required this.label,
    required this.painter,
  });

  final String label;
  final CustomPainter painter;

  @override
  State<_InteractiveFeatureCard> createState() => _InteractiveFeatureCardState();
}

class _InteractiveFeatureCardState extends State<_InteractiveFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F3),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _isHovered ? const Color(0xFFFF7A00) : const Color(0xFFFFE4CC),
            width: 1.5,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(22, 22),
              painter: widget.painter,
            ),
            Gap(6.h),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PosLogo — Brand identifier component
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// _KeypadButton — Premium enterprise keypad key with hover + press animations
// ─────────────────────────────────────────────────────────────────────────────

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

class _KeypadButtonState extends State<_KeypadButton>
    with SingleTickerProviderStateMixin {
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
                    ? (_isHovered
                        ? AppColors.surfaceVariant
                        : AppColors.background)
                    : (_isHovered
                        ? AppColors.surfaceElevated
                        : AppColors.surface),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMD.r),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.border.withValues(alpha: 0.6)
                      : AppColors.borderSubtle,
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

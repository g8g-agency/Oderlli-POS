import 'dart:async';
import 'dart:io';
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
import 'welcome_splash_layout.dart';

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

  }

  @override
  void dispose() {
    _shakeController.dispose();
    _avatarController.dispose();
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
          // Read updated state for potential backend error messages
          final updatedAuth = ref.read(authProvider);
          setState(() {
            _isError = true;
            _feedbackText = updatedAuth.errorMessage ?? 'Incorrect PIN. Please try again.';
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



  // ── Splash Screen Layout ─────────────────────────────────────────────────────
  Widget _buildSplashLayout(BuildContext context) {
    return WelcomeSplashLayout(
      onLoginPressed: () {
        setState(() {
          _showPasscode = true;
        });
      },
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
                text: 'Orderlyy',
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

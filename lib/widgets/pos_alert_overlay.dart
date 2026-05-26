import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../theme/theme.dart';
import '../providers/pos_alerts_provider.dart';

// ─── Orderlli POS · Operational Alert Overlay ────────────────────────────────
//
// Renders a layered set of non-blocking operational alerts over the POS UI:
//
//  ┌─────────────────────────────────────────────────────────────┐
//  │  [STALE / SYNCING banner — top edge]                        │
//  │                                                             │
//  │   ┌─────────────────────────────────────────┐              │
//  │   │   Normal app content (child)             │  [delay card]│
//  │   └─────────────────────────────────────────┘              │
//  │                                                             │
//  │              [payment failure toast — bottom-right]         │
//  └─────────────────────────────────────────────────────────────┘
//
//  If reconnecting: full-screen dim + animated pulse overlay (blocking).
//
// Usage:
//   POSAlertOverlay(child: Scaffold(...))
//
// Trigger:
//   ref.read(posAlertsProvider.notifier).showPaymentFailure(message: '...')

class POSAlertOverlay extends ConsumerWidget {
  const POSAlertOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(posAlertsProvider);

    final reconnecting = alerts.where((a) => a.type == POSAlertType.reconnecting).firstOrNull;
    final syncing      = alerts.where((a) => a.type == POSAlertType.syncing).firstOrNull;
    final stale        = alerts.where((a) => a.type == POSAlertType.staleState).firstOrNull;
    final payFails     = alerts.where((a) => a.type == POSAlertType.paymentFailure).toList();
    final delays       = alerts.where((a) => a.type == POSAlertType.delayedOrder).toList();

    // Determine which top-banner shows (stale wins over syncing if both active)
    final topBanner = stale ?? syncing;

    return Stack(
      children: [
        // ── App body ──────────────────────────────────────────────────────────
        child,

        // ── Top banner (stale state / syncing) (Animated) ────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: topBanner != null
                ? _TopBannerAlert(
                    key: ValueKey(topBanner.id),
                    alert: topBanner,
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // ── Delayed order cards — stacked top-right ───────────────────────────
        Positioned(
          top: (topBanner != null ? 52.h : 0) + 12.h,
          right: 12.w,
          child: _DelayedOrderStack(delays: delays),
        ),

        // ── Payment failure toasts — stacked bottom-right ─────────────────────
        Positioned(
          bottom: 16.h,
          right: 16.w,
          width: 340.w,
          child: _PaymentFailureStack(payFails: payFails),
        ),

        // ── Reconnecting overlay (blocking — must be last/topmost) ────────────
        if (reconnecting != null)
          _ReconnectingOverlay(alert: reconnecting),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. RECONNECTING OVERLAY  (full-screen blocking)
// ─────────────────────────────────────────────────────────────────────────────

class _ReconnectingOverlay extends StatefulWidget {
  const _ReconnectingOverlay({required this.alert});
  final POSAlert alert;

  @override
  State<_ReconnectingOverlay> createState() => _ReconnectingOverlayState();
}

class _ReconnectingOverlayState extends State<_ReconnectingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false, // blocks all interaction underneath
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width: 320.w,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated pulsing icon ring (compact sizes)
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Transform.rotate(
                            angle: -_rotate.value,
                            child: Container(
                              width: 72.w,
                              height: 72.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.20),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          // Mid ring
                          Transform.rotate(
                            angle: _rotate.value * 0.6,
                            child: Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warning.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Core icon
                          Container(
                            width: 42.w,
                            height: 42.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceElevated,
                              border: Border.all(color: AppColors.warning, width: 1.2),
                            ),
                            child: Icon(
                              Icons.wifi_off_rounded,
                              color: AppColors.warning,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Gap(18.h),
                Text(
                  'Reconnecting',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Gap(6.h),
                Text(
                  widget.alert.message ?? 'Connection lost. Reconnecting to server…',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Gap(24.h),
                // Animated 3-dot loading indicator
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final phase = (_ctrl.value + i * 0.33) % 1.0;
                        final opacity = (math.sin(phase * math.pi)).clamp(0.25, 1.0);
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning.withValues(alpha: opacity),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TOP BANNER  (syncing / stale state)
// ─────────────────────────────────────────────────────────────────────────────

class _TopBannerAlert extends ConsumerStatefulWidget {
  const _TopBannerAlert({super.key, required this.alert});
  final POSAlert alert;

  @override
  ConsumerState<_TopBannerAlert> createState() => _TopBannerAlertState();
}

class _TopBannerAlertState extends ConsumerState<_TopBannerAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = widget.alert.type == POSAlertType.syncing;
    final accentColor = isSyncing ? AppColors.info : AppColors.warning;
    final bgColor = isSyncing ? AppColors.infoContainer : AppColors.warningContainer;
    final icon = isSyncing ? Icons.sync_rounded : Icons.warning_amber_rounded;
    final label = isSyncing ? 'SYNCING' : 'DATA STALE';

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              // Icon — spins if syncing
              isSyncing
                  ? _SpinningIcon(icon: icon, color: accentColor, size: 16.sp)
                  : Icon(icon, color: accentColor, size: 16.sp),
              Gap(10.w),
              // Label badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  widget.alert.message ?? '',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Linear progress only for syncing
              if (isSyncing) ...[
                Gap(16.w),
                SizedBox(
                  width: 80.w,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.infoContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                    borderRadius: BorderRadius.circular(4.r),
                    minHeight: 3.h,
                  ),
                ),
                Gap(12.w),
              ],
              // Action button (if any)
              if (widget.alert.actionLabel != null && widget.alert.onAction != null)
                _BannerActionButton(
                  label: widget.alert.actionLabel!,
                  color: accentColor,
                  onTap: widget.alert.onAction!,
                ),
              // Dismiss
              if (widget.alert.isDismissible) ...[
                Gap(8.w),
                GestureDetector(
                  onTap: () => ref.read(posAlertsProvider.notifier).dismiss(widget.alert.id),
                  child: Icon(Icons.close_rounded, size: 16.sp, color: AppColors.textSecondary),
                ),
                Gap(4.w),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. PAYMENT FAILURE TOASTS  (bottom-right stack)
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentFailureStack extends StatelessWidget {
  const _PaymentFailureStack({required this.payFails});
  final List<POSAlert> payFails;

  @override
  Widget build(BuildContext context) {
    if (payFails.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: payFails
          .map((alert) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _PaymentFailureToast(alert: alert),
              ))
          .toList(),
    );
  }
}

class _PaymentFailureToast extends ConsumerStatefulWidget {
  const _PaymentFailureToast({required this.alert});
  final POSAlert alert;

  @override
  ConsumerState<_PaymentFailureToast> createState() => _PaymentFailureToastState();
}

class _PaymentFailureToastState extends ConsumerState<_PaymentFailureToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    if (widget.alert.autoDismissAfter != null) {
      final delay = widget.alert.autoDismissAfter! - const Duration(milliseconds: 380);
      final finalDelay = delay < Duration.zero ? Duration.zero : delay;
      _dismissTimer = Timer(finalDelay, () {
        if (mounted) {
          _handleDismiss();
        }
      });
    }
  }

  void _handleDismiss() {
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) {
        ref.read(posAlertsProvider.notifier).dismiss(widget.alert.id);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.shadowDeep.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.payment_rounded, color: AppColors.error, size: 14.sp),
                    ),
                    Gap(10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAYMENT DECLINED',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          _elapsedLabel(widget.alert.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _handleDismiss,
                      child: Icon(Icons.close_rounded, size: 16.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alert.message ?? 'Transaction failed.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                    if (widget.alert.actionLabel != null && widget.alert.onAction != null) ...[
                      Gap(12.h),
                      Row(
                        children: [
                          _ToastActionButton(
                            label: widget.alert.actionLabel!,
                            color: AppColors.error,
                            onTap: () {
                              widget.alert.onAction!();
                              _handleDismiss();
                            },
                          ),
                          Gap(8.w),
                          _ToastActionButton(
                            label: 'DISMISS',
                            color: AppColors.textSecondary,
                            outlined: false,
                            onTap: _handleDismiss,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. DELAYED ORDER CARDS  (top-right side stack)
// ─────────────────────────────────────────────────────────────────────────────

class _DelayedOrderStack extends StatelessWidget {
  const _DelayedOrderStack({required this.delays});
  final List<POSAlert> delays;

  @override
  Widget build(BuildContext context) {
    if (delays.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: delays
          .map((alert) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _DelayedOrderCard(alert: alert),
              ))
          .toList(),
    );
  }
}

class _DelayedOrderCard extends ConsumerStatefulWidget {
  const _DelayedOrderCard({required this.alert});
  final POSAlert alert;

  @override
  ConsumerState<_DelayedOrderCard> createState() => _DelayedOrderCardState();
}

class _DelayedOrderCardState extends ConsumerState<_DelayedOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _pulse;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    if (widget.alert.autoDismissAfter != null) {
      final delay = widget.alert.autoDismissAfter! - const Duration(milliseconds: 400);
      final finalDelay = delay < Duration.zero ? Duration.zero : delay;
      _dismissTimer = Timer(finalDelay, () {
        if (mounted) {
          _handleDismiss();
        }
      });
    }
  }

  void _handleDismiss() {
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) {
        ref.read(posAlertsProvider.notifier).dismiss(widget.alert.id);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: 220.w,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(-2, 4),
              ),
              BoxShadow(
                color: AppColors.shadowDeep.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amber accent strip
              Container(
                height: 3.h,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9.r)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Blinking warning icon
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, child) => Transform.scale(
                            scale: _pulse.value,
                            child: Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.timer_off_rounded,
                                color: AppColors.warning,
                                size: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        Gap(8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SLA BREACH',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            if (widget.alert.tableLabel != null)
                              Text(
                                widget.alert.tableLabel!,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _handleDismiss,
                          child: Icon(Icons.close_rounded,
                              size: 14.sp, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Gap(8.h),
                    Text(
                      widget.alert.message ?? '',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    if (widget.alert.actionLabel != null && widget.alert.onAction != null) ...[
                      Gap(10.h),
                      GestureDetector(
                        onTap: () {
                          widget.alert.onAction!();
                          _handleDismiss();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 7.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${widget.alert.actionLabel} ORDER →',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers / micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Continuously spinning icon (used for syncing indicator)
class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({
    required this.icon,
    required this.color,
    required this.size,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.rotate(
        angle: _ctrl.value * 2 * math.pi,
        child: Icon(widget.icon, color: widget.color, size: widget.size),
      ),
    );
  }
}

/// Action button in a banner
class _BannerActionButton extends StatelessWidget {
  const _BannerActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// Action / dismiss button inside a toast card
class _ToastActionButton extends StatelessWidget {
  const _ToastActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = true,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: outlined ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(7.r),
            border: outlined
                ? Border.all(color: color.withValues(alpha: 0.35))
                : Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: outlined ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Formats a relative time label (e.g. "just now", "2 min ago")
String _elapsedLabel(DateTime from) {
  final diff = DateTime.now().difference(from).inSeconds;
  if (diff < 10) return 'just now';
  if (diff < 60) return '${diff}s ago';
  return '${diff ~/ 60}m ago';
}

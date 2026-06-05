import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import '../models/models.dart';

/// ─── Orderlyy POS · Operational Status Chip ─────────────────────────────────
///
/// A highly polished, color-coded status chip with micro-animations.
/// Features a continuous spinning icon for [OperationalStatus.syncing] and a
/// pulsing attention-seeking glow indicator for [OperationalStatus.delayed],
/// [OperationalStatus.failed], and [OperationalStatus.reconnecting].
class OperationalStatusChip extends StatefulWidget {
  const OperationalStatusChip({
    super.key,
    required this.status,
    this.onTap,
  });

  final OperationalStatus status;
  final VoidCallback? onTap;

  @override
  State<OperationalStatusChip> createState() => _OperationalStatusChipState();
}

class _OperationalStatusChipState extends State<OperationalStatusChip>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    // Setup spin controller for syncing state
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Setup pulse controller for attention states
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _updateAnimationStates();
  }

  @override
  void didUpdateWidget(covariant OperationalStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimationStates();
  }

  void _updateAnimationStates() {
    // Manage spin animation
    if (widget.status.hasSpinEffect) {
      _spinController.repeat();
    } else {
      _spinController.stop();
    }

    // Manage pulse animation
    if (widget.status.hasPulseEffect) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final color = status.color;

    Widget iconWidget = Icon(
      status.icon,
      size: 15.sp,
      color: color,
    );

    // Apply spin transition if required
    if (status.hasSpinEffect) {
      iconWidget = RotationTransition(
        turns: _spinController,
        child: iconWidget,
      );
    }

    // Build pulsing dot for attention states
    Widget? pulseIndicator;
    if (status.hasPulseEffect) {
      pulseIndicator = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding ring
              Transform.scale(
                scale: _pulseScale.value,
                child: Opacity(
                  opacity: _pulseOpacity.value,
                  child: Container(
                    width: 7.w,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Inner solid dot
              Container(
                width: 7.w,
                height: 7.h,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      );
    }

    final chipBody = Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulse Dot
          if (pulseIndicator != null) ...[
            pulseIndicator,
            Gap(6.w),
          ],
          // Icon
          iconWidget,
          Gap(6.w),
          // Label
          Flexible(
            child: Text(
              status.label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: chipBody,
        ),
      );
    }

    return chipBody;
  }
}

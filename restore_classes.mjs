import fs from 'fs';
import path from 'path';

const loginFile = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let login = fs.readFileSync(loginFile, 'utf-8');

// The classes to append:
const missingCode = `

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
    super.key,
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
`;

fs.writeFileSync(loginFile, login + missingCode);
console.log('Restored classes');

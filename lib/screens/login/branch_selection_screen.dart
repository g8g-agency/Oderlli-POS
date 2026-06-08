import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';

class BranchSelectionScreen extends ConsumerStatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  ConsumerState<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends ConsumerState<BranchSelectionScreen> {
  String? _selectedBranchId;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    // Refresh branches list on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).fetchBranches();
    });
  }

  Future<void> _handleBranchSelect(String id, String name) async {
    setState(() {
      _selectedBranchId = id;
      _isTransitioning = true;
    });

    // Short delay for visual selection feedback animation
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      await ref.read(authProvider.notifier).selectBranch(id, name);
    }
  }

  Future<void> _handleBack() async {
    // Allows switching organization
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brandRed = Color(0xFFBA0013);
    final authState = ref.watch(authProvider);
    final branches = authState.availableBranches;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF191C1D) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 384.w,
              height: 384.h,
              decoration: BoxDecoration(
                color: brandRed.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandRed.withValues(alpha: 0.05),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800.w),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back to org login / sign out button
                      Align(
                        alignment: Alignment.topLeft,
                        child: TextButton.icon(
                          onPressed: _isTransitioning ? null : _handleBack,
                          icon: const Icon(Icons.arrow_back_rounded, color: brandRed),
                          label: Text(
                            'Switch Organization',
                            style: GoogleFonts.plusJakartaSans(
                              color: brandRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: brandRed,
                          ),
                        ),
                      ),
                      Gap(20.h),
                      
                      // Title / Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.point_of_sale_rounded, color: brandRed, size: 36),
                          const SizedBox(width: 12),
                          Text(
                            'Orderlyy ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : const Color(0xFF191C1D),
                            ),
                          ),
                          Text(
                            'POS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: brandRed,
                            ),
                          ),
                        ],
                      ),
                      Gap(16.h),
                      Text(
                        'Select Active Branch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF191C1D),
                        ),
                      ),
                      Gap(8.h),
                      Text(
                        'Choose the store branch to initialize terminal session',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      Gap(40.h),

                      // Branch List Grid/List
                      Expanded(
                        child: authState.errorMessage != null
                            ? SingleChildScrollView(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: brandRed,
                                        size: 48,
                                      ),
                                      Gap(16.h),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: Text(
                                          authState.errorMessage!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.sp,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Gap(24.h),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ref.read(authProvider.notifier).fetchBranches();
                                        },
                                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                        label: Text(
                                          'Try Again',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brandRed,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24.w,
                                            vertical: 12.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : branches.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(brandRed),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 2 : 1,
                                      crossAxisSpacing: 16.w,
                                      mainAxisSpacing: 16.h,
                                      childAspectRatio: 2.3,
                                    ),
                                    itemCount: branches.length,
                                    itemBuilder: (context, index) {
                                      final branch = branches[index];
                                      final isSelected = _selectedBranchId == branch.id;
                                      
                                      return _BranchCard(
                                        name: branch.name,
                                        timezone: branch.timezone,
                                        isSelected: isSelected,
                                        onTap: _isTransitioning
                                            ? null
                                            : () => _handleBranchSelect(branch.id, branch.name),
                                        isDark: isDark,
                                        brandRed: brandRed,
                                      );
                                    },
                                  ),
                      ),

                      if (_isTransitioning) ...[
                        Gap(20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(brandRed),
                              ),
                            ),
                            Gap(10.w),
                            Text(
                              'Initializing branch context...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatefulWidget {
  final String name;
  final String timezone;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;
  final Color brandRed;

  const _BranchCard({
    required this.name,
    required this.timezone,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.brandRed,
  });

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _animCtrl.forward().then((_) => _animCtrl.reverse());
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: MouseRegion(
        cursor: widget.onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap != null ? _handleTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? (widget.isSelected
                      ? widget.brandRed.withValues(alpha: 0.12)
                      : (_isHovered ? const Color(0xFF2E3132) : const Color(0xFF232627)))
                  : (widget.isSelected
                      ? widget.brandRed.withValues(alpha: 0.05)
                      : (_isHovered ? Colors.white : const Color(0xFFF1F3F4))),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.isSelected
                    ? widget.brandRed
                    : (widget.isDark ? Colors.white10 : const Color(0xFFE1E3E4)),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.05),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF191C1D) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: widget.isSelected ? widget.brandRed : AppColors.textSecondary,
                    size: 28.sp,
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark ? Colors.white : const Color(0xFF191C1D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(4.h),
                      Text(
                        'Timezone: ${widget.timezone}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          color: widget.isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.brandRed,
                    size: 20.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

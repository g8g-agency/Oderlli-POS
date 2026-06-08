import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final success = await ref.read(authProvider.notifier).loginOrganization(email, password);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).errorMessage ?? 'Invalid organization credentials',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _fillDemoCredentials(String email) {
    setState(() {
      _emailCtrl.text = email;
      _passwordCtrl.text = 'Test@123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brandRed = Color(0xFFBA0013);
    final authState = ref.watch(authProvider);

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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 460.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Section
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
                        'Organization Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF191C1D),
                        ),
                      ),
                      Gap(8.h),
                      Text(
                        'Enter your credentials to manage active branches and staff',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      Gap(32.h),

                      // Credentials Form Card
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF232627) : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE1E3E4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              Text(
                                'Organization Email',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Gap(8.h),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                                decoration: InputDecoration(
                                  hintText: 'name@organization.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter email address';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              Gap(20.h),

                              // Password Field
                              Text(
                                'Password',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Gap(8.h),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              Gap(24.h),

                              // Submit Button
                              authState.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(brandRed),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 52.h,
                                      child: FilledButton(
                                        onPressed: _handleLogin,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: brandRed,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        ),
                                        child: Text(
                                          'Sign In Organization',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      Gap(28.h),

                      // Demo / Seed Accounts Helper Widget
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2122) : const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE1E3E4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '💡 DEMO ACCOUNTS (SEED DATA)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: brandRed,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gap(12.h),
                            _buildDemoAccountButton(
                              'Royal Tandoor (Owner)',
                              'royaltandoor.owner@test.com',
                              isDark,
                            ),
                            Gap(8.h),
                            _buildDemoAccountButton(
                              'Test Cafe (Owner)',
                              'testcafe.owner@test.com',
                              isDark,
                            ),
                            Gap(8.h),
                            _buildDemoAccountButton(
                              'Ocean Bite (Owner)',
                              'oceanbite.owner@test.com',
                              isDark,
                            ),
                            Gap(10.h),
                            Text(
                              'Password: Test@123456',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildDemoAccountButton(String label, String email, bool isDark) {
    return SizedBox(
      height: 38.h,
      child: OutlinedButton(
        onPressed: () => _fillDemoCredentials(email),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 14.sp),
          ],
        ),
      ),
    );
  }
}

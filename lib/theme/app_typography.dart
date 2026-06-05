import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ─── Orderlyy POS · Typography System ───────────────────────────────────────
///
/// Responsive typography configurations using Google Fonts (Inter).
/// Font sizes are defined using ScreenUtil `.sp` units to ensure perfect scaling
/// on different tablet screen resolutions.
abstract final class AppTypography {
  // ── Display Styles ────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 48.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 36.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 30.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Headline Styles ───────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Title Styles ──────────────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  // ── Body Styles ───────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── Label Styles ──────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textDisabled,
        letterSpacing: 0.5,
      );

  // ── POS-Specific Custom Styles ────────────────────────────────────────────
  static TextStyle get priceTag => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get priceLarge => GoogleFonts.inter(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get orderNumber => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get tableLabel => GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get badgeText => GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get sidebarItem => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.sidebarText,
      );

  static TextStyle get sidebarItemActive => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.sidebarTextActive,
      );

  // ── Unified Semantic Text Styles ──────────────────────────────────────────
  
  /// Dashboard main view title style
  static TextStyle get dashboardTitle => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Metrics text value style
  static TextStyle get metricValue => GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Metrics text label style
  static TextStyle get metricLabel => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Sidebar label in normal/inactive state
  static TextStyle get sidebarLabel => sidebarItem;

  /// Sidebar label in active state
  static TextStyle get sidebarLabelActive => sidebarItemActive;

  /// Subtitle styling for order and table cards
  static TextStyle get cardSubtitle => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── TextTheme Generator ───────────────────────────────────────────────────
  /// Returns a full Material 3 TextTheme populated with Google Fonts Inter styles.
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'design_tokens.dart';
import 'app_typography.dart';

/// ─── Orderlli POS · Material 3 Theme System ──────────────────────────────────
///
/// Light operational theme designed for high contrast, clean workspace structure,
/// and fast, clear visual feedback under busy restaurant environments.
abstract final class AppTheme {
  // ── Shared radius tokens ─────────────────────────────────────────────────
  static const double radiusXS = AppRadius.sm / 2;
  static const double radiusSM = AppRadius.sm;
  static const double radiusMD = AppRadius.md;
  static const double radiusLG = AppRadius.lg;
  static const double radiusXL = AppRadius.xl;
  static const double radiusXXL = AppRadius.xl * 1.4;
  static const double radiusFull = AppRadius.full;

  // ── Shared elevation tokens ──────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 2;
  static const double elevationHigh = 4;

  /// Light operational theme configuration for Orderlli POS.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: _appBarTheme,
        cardTheme: _cardTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        chipTheme: _chipTheme,
        dividerTheme: _dividerTheme,
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
        tabBarTheme: _tabBarTheme,
        bottomNavigationBarTheme: _bottomNavTheme,
        floatingActionButtonTheme: _fabTheme,
        snackBarTheme: _snackBarTheme,
        dialogTheme: _dialogTheme,
      );

  /// Keep dark getter pointing to light theme or configure it if needed
  static ThemeData get dark => light;

  // ── Color Scheme ─────────────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.textPrimary,
    
    secondary: AppColors.neutral,
    onSecondary: AppColors.textOnPrimary,
    secondaryContainer: AppColors.neutralContainer,
    onSecondaryContainer: AppColors.textPrimary,
    
    tertiary: AppColors.cash,
    onTertiary: AppColors.textOnWarning,
    tertiaryContainer: AppColors.cashContainer,
    onTertiaryContainer: AppColors.textPrimary,
    
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.textPrimary,
    
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    
    outline: AppColors.border,
    outlineVariant: AppColors.borderSubtle,
    shadow: AppColors.shadowDeep,
    scrim: AppColors.shadowDeep,
    inverseSurface: AppColors.textOnPrimary,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primaryLight,
  );

  // ── AppBar Theme ──────────────────────────────────────────────────────────
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.sidebarBg,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Card Theme ─────────────────────────────────────────────────────────────
  static final CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.borderSubtle, width: 1),
    ),
    margin: EdgeInsets.zero,
  );

  // ── ElevatedButton Theme (Large Touch Targets for POS Tablets) ─────────────
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryContainer,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      minimumSize: const Size(88, 48), // Ensure minimum 48px touch target
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppTypography.buttonText,
    ),
  );

  // ── OutlinedButton Theme ────────────────────────────────────────────────────
  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
      minimumSize: const Size(88, 48), // Ensure minimum 48px touch target
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppTypography.buttonText,
    ),
  );

  // ── TextButton Theme ────────────────────────────────────────────────────────
  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(64, 48), // Ensure minimum 48px touch target
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppTypography.buttonText,
    ),
  );

  // ── InputDecoration Theme ───────────────────────────────────────────────────
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.labelMedium,
        hintStyle: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      );

  // ── Chip Theme ─────────────────────────────────────────────────────────────
  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.surfaceVariant,
    selectedColor: AppColors.primary,
    labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    side: BorderSide.none,
  );

  // ── Divider Theme ──────────────────────────────────────────────────────────
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 0,
  );

  // ── TabBar Theme ───────────────────────────────────────────────────────────
  static TabBarThemeData get _tabBarTheme => TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.labelMedium,
      );

  // ── BottomNavigationBar Theme ──────────────────────────────────────────────
  static const BottomNavigationBarThemeData _bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textDisabled,
    elevation: 8,
    type: BottomNavigationBarType.fixed,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  );

  // ── FAB Theme ──────────────────────────────────────────────────────────────
  static final FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  );

  // ── SnackBar Theme ─────────────────────────────────────────────────────────
  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.surfaceElevated,
    contentTextStyle: AppTypography.bodyMedium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    behavior: SnackBarBehavior.floating,
  );

  // ── Dialog Theme ───────────────────────────────────────────────────────────
  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.surface,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
  );
}

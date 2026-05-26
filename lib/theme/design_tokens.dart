import 'package:flutter/material.dart';

/// ─── Orderlli POS · Design Tokens ───────────────────────────────────────────
///
/// Centralized design tokens serving as the single source of truth for POS layout,
/// sizes, animations, and shadows.

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  // ── Compatibility Aliases ─────────────────────────────────────────────────
  static const double xxs = xs;
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 28.0;
  static const double radiusFull = 100.0;
}

abstract final class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 100.0;
}

abstract final class AppShadows {
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> sidebarShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 8,
      offset: const Offset(2, 0),
    ),
  ];

  static final List<BoxShadow> floatingPanelShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

abstract final class AppLayoutConstants {
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double orderPanelWidth = 360.0;
  static const double topBarHeight = 64.0;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

abstract final class AppIconSizes {
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
}

/// App-wide constant values.
abstract final class AppConstants {
  // ── Design / layout ─────────────────────────────────────────────────────
  static const double sidebarWidth = 280;
  static const double sidebarCollapsedWidth = 72;
  static const double orderPanelWidth = 360;
  static const double topBarHeight = 64;

  // ── Tablet breakpoints ───────────────────────────────────────────────────
  static const double tabletSmall = 600;
  static const double tabletLarge = 900;
  static const double desktop = 1200;

  // ── ScreenUtil design size (10-inch tablet landscape) ───────────────────
  static const double designWidth = 1024;
  static const double designHeight = 768;

  // ── Animation durations ──────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  // ── Currency ─────────────────────────────────────────────────────────────
  static const String currencySymbol = '£';
  static const String currencyCode = 'GBP';

  // ── Tax ──────────────────────────────────────────────────────────────────
  static const double defaultTaxPercent = 5.0;

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int pageSize = 20;
}

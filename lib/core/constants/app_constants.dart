/// App-wide constant values.
abstract final class AppConstants {
  // ── Design / layout ─────────────────────────────────────────────────────
  static const double sidebarWidth = 280;
  static const double sidebarCollapsedWidth = 72;
  static const double orderPanelWidth = 360;
  static const double topBarHeight = 64;

  // ── Tablet breakpoints ───────────────────────────────────────────────────
  /// < 700: Compact tablet portrait
  static const double tabletSmall = 700;
  /// 700–900: Tablet narrow landscape
  static const double tabletMedium = 900;
  /// 900–1200: Tablet standard
  static const double tabletLarge = 1200;
  /// 1200–1440: Large tablet / desktop
  static const double desktop = 1440;

  // ── ScreenUtil design size (10-inch tablet landscape) ───────────────────
  static const double designWidth = 1024;
  static const double designHeight = 768;

  // ── Animation durations ──────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  // ── Currency (Indian Rupee) ──────────────────────────────────────────────
  /// Do NOT use this symbol directly in widgets — use CurrencyFormatter instead.
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String currencyLocale = 'en_IN';

  // ── Tax ──────────────────────────────────────────────────────────────────
  static const double defaultTaxPercent = 5.0;

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int pageSize = 20;
}

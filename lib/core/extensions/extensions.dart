import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

extension BuildContextX on BuildContext {
  // ── Theme shortcuts ──────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ── MediaQuery shortcuts ──────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  bool get isTablet => screenWidth >= 600;
  bool get isLargeTablet => screenWidth >= 900;
  bool get isDesktop => screenWidth >= 1200;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  bool get isVerticalLayout => screenWidth < 850 || screenWidth < screenHeight;

  /// Returns a grid column count based on defined POS breakpoints.
  ///
  /// | Width     | Mode                 |
  /// |-----------|----------------------|
  /// | < 700     | Compact portrait     |
  /// | 700–900   | Tablet narrow        |
  /// | 900–1200  | Tablet standard      |
  /// | 1200–1440 | Large tablet/desktop |
  /// | > 1440    | Desktop wide         |
  int responsiveColumns({
    required int mobile,
    required int tablet,
    required int desktop,
    int? largeDesktop,
  }) {
    if (screenWidth >= 1440) return largeDesktop ?? desktop;
    if (screenWidth >= 1200) return desktop;
    if (screenWidth >= 900) return tablet;
    if (screenWidth >= 700) return mobile + 1;
    return mobile;
  }

  // ── Snack helpers ────────────────────────────────────────────────────────
  void showSuccessSnack(String message) => ScaffoldMessenger.of(this)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
    ));

  void showErrorSnack(String message) => ScaffoldMessenger.of(this)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
    ));

  void showInfoSnack(String message) => ScaffoldMessenger.of(this)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.info,
    ));
}

extension StringX on String {
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => split(' ').map((w) => w.capitalised).join(' ');
}

extension DoubleX on double {
  /// Formats this value as an Indian Rupee string with lakh/crore grouping.
  /// Delegates to [CurrencyFormatter.format] — do not hardcode '₹' in widgets.
  ///
  /// Example: `125000.5.asCurrency` → `'₹1,25,000.50'`
  String get asCurrency => CurrencyFormatter.format(this);
}

extension DateTimeX on DateTime {
  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get shortDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '$day ${months[month - 1]}';
  }

  String get minutesAgoLabel {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes == 1) return '1 min ago';
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    return '${diff.inHours}h ago';
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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

  int responsiveColumns({
    required int mobile,
    required int tablet,
    required int desktop,
    int? largeDesktop,
  }) {
    if (screenWidth >= 1400) return largeDesktop ?? desktop;
    if (screenWidth >= 1200) return desktop;
    if (screenWidth >= 750) return tablet;
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
  String get asCurrency => '£${toStringAsFixed(2)}';
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

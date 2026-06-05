import 'package:intl/intl.dart';

/// ─── Orderlyy POS · Currency Formatter ──────────────────────────────────────
///
/// Centralized, locale-aware INR currency formatter for the Orderlyy POS.
///
/// All money values in the app are formatted through this class.
/// Never hardcode '₹' or currency strings directly in widget files.
///
/// Usage:
///   CurrencyFormatter.format(1250.0)      →  '₹1,250.00'
///   CurrencyFormatter.format(125000.0)    →  '₹1,25,000.00'
///   CurrencyFormatter.format(12500000.0)  →  '₹1,25,00,000.00'
///   CurrencyFormatter.symbol              →  '₹'
abstract final class CurrencyFormatter {
  /// The ISO 4217 currency code for Indian Rupee.
  static const String currencyCode = 'INR';

  /// The Unicode currency symbol for Indian Rupee.
  static const String symbol = '₹';

  /// Full-precision formatter: `₹1,25,000.50`
  ///
  /// Uses the `en_IN` locale which natively produces the Indian
  /// number grouping system (lakhs and crores).
  static final NumberFormat _fullFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 2,
  );

  /// Compact formatter for metric tiles: `₹1.25L`
  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 2,
  );

  /// Formats [value] as a full Indian Rupee string.
  ///
  /// Examples:
  /// - `format(450.0)` → `'₹450.00'`
  /// - `format(125000.5)` → `'₹1,25,000.50'`
  static String format(num value) => _fullFormat.format(value);

  /// Formats [value] in compact notation, useful for dashboard metric tiles.
  ///
  /// Examples:
  /// - `formatCompact(125000)` → `'₹1.25L'`
  /// - `formatCompact(10000000)` → `'₹1Cr.'`
  static String formatCompact(num value) => _compactFormat.format(value);

  /// Formats a discount or negative value as `'-₹1,250.00'`.
  static String formatNegative(num value) => '-${format(value.abs())}';

  /// Formats a positive delta as `'+₹1,250.00'` for ledger display.
  static String formatPositive(num value) => '+${format(value.abs())}';
}

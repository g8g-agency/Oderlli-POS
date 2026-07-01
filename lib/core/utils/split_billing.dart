/// Splits [total] (in rupees) into [splits] parts with no
/// rounding error. Each part is floored to 2 decimal places;
/// the last part absorbs the remainder so all parts sum
/// exactly to [total].
///
/// Throws [ArgumentError] if splits < 1 or total < 0.
List<double> calculateSplitAmounts(double total, int splits) {
  if (splits < 1) {
    throw ArgumentError('splits must be >= 1, got $splits');
  }
  if (total < 0) {
    throw ArgumentError('total must be >= 0, got $total');
  }
  if (splits == 1) return [_round2(total)];

  // Work in integer minor units (paise) to avoid float drift.
  final totalMinor = (total * 100).round();
  final baseMinor = totalMinor ~/ splits;
  final remainder = totalMinor - baseMinor * splits;

  final amounts = List<double>.filled(splits, baseMinor / 100.0);
  // Last split absorbs the leftover paise
  amounts[splits - 1] = _round2((baseMinor + remainder) / 100.0);

  return amounts;
}

double _round2(double v) => (v * 100).round() / 100.0;

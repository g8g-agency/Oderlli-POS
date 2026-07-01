import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/core/utils/split_billing.dart';

void main() {
  void expectExactSum(List<double> parts, double total) {
    final sumMinor = parts.map((p) => (p * 100).round()).reduce((a, b) => a + b);
    final totalMinor = (total * 100).round();
    expect(sumMinor, equals(totalMinor),
        reason: 'Parts $parts do not sum to $total');
    for (final p in parts) {
      expect(p, greaterThanOrEqualTo(0.0));
    }
  }

  group('calculateSplitAmounts', () {
    test('₹333.34 / 3 → [111.11, 111.11, 111.12]', () {
      final result = calculateSplitAmounts(333.34, 3);
      expect(result.length, 3);
      expect(result[0], equals(111.11));
      expect(result[1], equals(111.11));
      expect(result[2], equals(111.12));
      expectExactSum(result, 333.34);
    });

    test('₹100.00 / 3 → [33.33, 33.33, 33.34]', () {
      final result = calculateSplitAmounts(100.00, 3);
      expect(result.length, 3);
      expect(result[0], equals(33.33));
      expect(result[1], equals(33.33));
      expect(result[2], equals(33.34));
      expectExactSum(result, 100.00);
    });

    test('₹0.03 / 2 → [0.01, 0.02]', () {
      final result = calculateSplitAmounts(0.03, 2);
      expect(result.length, 2);
      expect(result[0], equals(0.01));
      expect(result[1], equals(0.02));
      expectExactSum(result, 0.03);
    });

    test('₹99.99 / 4 → [24.99, 24.99, 24.99, 25.02] (last absorbs)', () {
      final result = calculateSplitAmounts(99.99, 4);
      expect(result.length, 4);
      expect(result[0], equals(24.99));
      expect(result[1], equals(24.99));
      expect(result[2], equals(24.99));
      expect(result[3], equals(25.02));
      expectExactSum(result, 99.99);
    });

    test('₹100.00 / 1 → [100.00] (single split)', () {
      final result = calculateSplitAmounts(100.00, 1);
      expect(result, equals([100.00]));
      expectExactSum(result, 100.00);
    });

    test('₹0.00 / 3 → [0.00, 0.00, 0.00]', () {
      final result = calculateSplitAmounts(0.00, 3);
      expect(result, equals([0.00, 0.00, 0.00]));
      expectExactSum(result, 0.00);
    });

    test('splits < 1 throws ArgumentError', () {
      expect(
        () => calculateSplitAmounts(100.00, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('negative total throws ArgumentError', () {
      expect(
        () => calculateSplitAmounts(-1.00, 2),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/constants/pos_constants.dart';

void main() {
  test('counter table id matches sentinel UUID', () {
    expect(
      PosConstants.counterTableId,
      '00000000-0000-0000-0000-000000000001',
    );
    expect(PosConstants.isCounterTable(PosConstants.counterTableId), isTrue);
    expect(
      PosConstants.isCounterTable('550e8400-e29b-41d4-a716-446655440000'),
      isFalse,
    );
  });
}

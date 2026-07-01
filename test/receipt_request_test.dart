import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/models/receipt_request.dart';
import 'package:orderlli_pos/models/order.dart';

Order _sampleOrder({
  int tableNumber = 3,
  double discountPercent = 0,
}) {
  return Order(
    id: 'abc12345-0000-0000-0000-000000000001',
    tableId: 'table-1',
    tableNumber: tableNumber,
    items: [
      OrderItem(
        id: 'item-1',
        itemNameSnapshot: 'Paneer Tikka',
        unitPriceMinor: 9000,
        quantity: 2,
        modifiers: const ['Extra spicy'],
        notes: 'No onion',
      ),
    ],
    createdAt: DateTime(2026, 6, 9, 14, 32),
    discountPercent: discountPercent,
    taxPercent: 5,
  );
}

void main() {
  test('receipt number defaults from order id', () {
    final request = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'Grand Spice',
      branchName: 'Downtown',
      cashierName: 'Priya',
      paymentMethod: 'Cash',
      amountPaid: 300,
    );
    expect(request.receiptNumber, 'RCP-ABC12345');
  });

  test('changeGiven is never negative', () {
    final request = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'Grand Spice',
      branchName: 'Downtown',
      cashierName: 'Priya',
      paymentMethod: 'Cash',
      amountPaid: 100,
    );
    expect(request.changeGiven, 0);
  });

  test('counter orders show Counter in receipt text', () {
    final request = ReceiptRequest(
      order: _sampleOrder(tableNumber: 0),
      restaurantName: 'Grand Spice',
      branchName: 'Downtown',
      cashierName: 'Priya',
      paymentMethod: 'Cash',
      amountPaid: 200,
    );
    expect(request.toReceiptText(), contains('Counter'));
    expect(request.toReceiptText(), isNot(contains('Table 0')));
  });

  test('discount block only when discountPercent > 0', () {
    final noDiscount = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'R',
      branchName: 'B',
      cashierName: 'C',
      paymentMethod: 'Cash',
      amountPaid: 200,
    );
    expect(noDiscount.toReceiptText(), isNot(contains('Discount')));

    final withDiscount = ReceiptRequest(
      order: _sampleOrder(discountPercent: 10),
      restaurantName: 'R',
      branchName: 'B',
      cashierName: 'C',
      paymentMethod: 'Cash',
      amountPaid: 200,
    );
    expect(withDiscount.toReceiptText(), contains('Discount (10%)'));
    expect(withDiscount.toReceiptText(), contains('Taxable amount:'));
  });

  test('item modifiers and notes appear indented', () {
    final text = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'R',
      branchName: 'B',
      cashierName: 'C',
      paymentMethod: 'Cash',
      amountPaid: 200,
    ).toReceiptText();

    expect(text, contains('  + Extra spicy'));
    expect(text, contains('  Note: No onion'));
  });

  test('GSTIN and FSSAI only when provided', () {
    final without = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'R',
      branchName: 'B',
      cashierName: 'C',
      paymentMethod: 'Cash',
      amountPaid: 200,
    ).toReceiptText();
    expect(without, isNot(contains('GSTIN:')));
    expect(without, isNot(contains('FSSAI:')));

    final withLegal = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'R',
      branchName: 'B',
      cashierName: 'C',
      paymentMethod: 'Cash',
      amountPaid: 200,
      gstin: '29ABCDE1234F1Z5',
      fssai: '12345678901234',
    ).toReceiptText();
    expect(withLegal, contains('GSTIN: 29ABCDE1234F1Z5'));
    expect(withLegal, contains('FSSAI: 12345678901234'));
  });

  test('GSTIN present and FSSAI absent', () {
    final request = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'Grand Spice',
      branchName: 'Downtown',
      cashierName: 'Priya',
      paymentMethod: 'Cash',
      amountPaid: 200,
      gstin: '29ABCDE1234F1Z5',
    );
    final text = request.toReceiptText();
    expect(text, contains('Branch: Downtown | Table 3'));
    expect(text, contains('GSTIN: 29ABCDE1234F1Z5'));
    expect(text, isNot(contains('FSSAI:')));
  });

  test('GSTIN absent and FSSAI present', () {
    final request = ReceiptRequest(
      order: _sampleOrder(),
      restaurantName: 'Grand Spice',
      branchName: 'Downtown',
      cashierName: 'Priya',
      paymentMethod: 'Cash',
      amountPaid: 200,
      fssai: '12345678901234',
    );
    final text = request.toReceiptText();
    expect(text, isNot(contains('GSTIN:')));
    expect(text, contains('FSSAI: 12345678901234'));
  });
}

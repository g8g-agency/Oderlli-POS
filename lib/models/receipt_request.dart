import 'order.dart';

class ReceiptRequest {
  ReceiptRequest({
    required this.order,
    required this.restaurantName,
    required this.branchName,
    required this.cashierName,
    required this.paymentMethod,
    required this.amountPaid,
    this.gstin,
    this.fssai,
    String? receiptNumber,
  }) : receiptNumber = receiptNumber ??
            'RCP-${order.id.substring(0, 8).toUpperCase()}';

  final Order order;
  final String restaurantName;
  final String branchName;
  final String cashierName;
  final String paymentMethod; // 'Cash' | 'Card' | 'UPI'
  final double amountPaid;
  final String? gstin;
  final String? fssai;
  final String receiptNumber;

  double get changeGiven => (amountPaid - order.total).clamp(0.0, double.infinity);

  /// Formats the full receipt as plain text for ESC/POS or PDF.
  String toReceiptText() {
    final buf = StringBuffer();
    final tableLabel = order.tableNumber == 0
        ? 'Counter'
        : 'Table ${order.tableNumber}';
    final date = order.createdAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')} '
        '${_month(date.month)} ${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    // ── Header ──────────────────────────────────────────────
    buf.writeln(_center('═' * 40));
    buf.writeln(_center(restaurantName.toUpperCase()));
    buf.writeln(_center('Branch: $branchName | $tableLabel'));
    if (gstin != null && gstin!.isNotEmpty) {
      buf.writeln(_center('GSTIN: $gstin'));
    }
    if (fssai != null && fssai!.isNotEmpty) {
      buf.writeln(_center('FSSAI: $fssai'));
    }
    buf.writeln(_center('═' * 40));
    buf.writeln('Date: $dateStr        Time: $timeStr');
    buf.writeln('Receipt #: $receiptNumber');
    buf.writeln('Order #:   ${order.orderNumber ?? order.id}');
    buf.writeln('Cashier:   $cashierName');
    buf.writeln('-' * 40);

    // ── Items ───────────────────────────────────────────────
    buf.writeln(
      '${'Item'.padRight(22)}${'Qty'.padLeft(4)}${'Amount'.padLeft(10)}',
    );
    buf.writeln('-' * 40);
    for (final item in order.items) {
      final name = item.itemNameSnapshot.length > 22
          ? '${item.itemNameSnapshot.substring(0, 19)}...'
          : item.itemNameSnapshot;
      final amount = '₹${item.subtotal.toStringAsFixed(2)}';
      buf.writeln(
        '${name.padRight(22)}${item.quantity.toString().padLeft(4)}'
        '${amount.padLeft(10)}',
      );
      for (final mod in item.modifiers) {
        buf.writeln('  + $mod');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        buf.writeln('  Note: ${item.notes}');
      }
    }
    buf.writeln('-' * 40);

    // ── Totals ──────────────────────────────────────────────
    buf.writeln(_row('Subtotal:', '₹${order.subtotal.toStringAsFixed(2)}'));
    if (order.discountPercent > 0) {
      buf.writeln(_row(
        'Discount (${order.discountPercent.toStringAsFixed(0)}%):',
        '-₹${order.discountAmount.toStringAsFixed(2)}',
      ));
      buf.writeln(_row(
        'Taxable amount:',
        '₹${order.taxableAmount.toStringAsFixed(2)}',
      ));
    }
    buf.writeln(_row(
      'GST (${order.taxPercent.toStringAsFixed(0)}%):',
      '₹${order.taxAmount.toStringAsFixed(2)}',
    ));
    buf.writeln('=' * 40);
    buf.writeln(_row('TOTAL:', '₹${order.total.toStringAsFixed(2)}'));
    buf.writeln('=' * 40);

    // ── Payment ─────────────────────────────────────────────
    buf.writeln('Payment:      $paymentMethod');
    buf.writeln(_row('Amount paid:', '₹${amountPaid.toStringAsFixed(2)}'));
    buf.writeln(_row('Change:', '₹${changeGiven.toStringAsFixed(2)}'));
    buf.writeln('=' * 40);

    // ── Footer ──────────────────────────────────────────────
    buf.writeln(_center('Thank you for dining with us!'));
    buf.writeln(_center('Visit again soon!'));
    buf.writeln(_center('Powered by Orderlyy'));

    return buf.toString();
  }

  String _center(String s, [int width = 40]) {
    if (s.length >= width) return s;
    final pad = (width - s.length) ~/ 2;
    return ' ' * pad + s;
  }

  String _row(String label, String value, [int width = 40]) {
    final space = width - label.length - value.length;
    return space > 0 ? '$label${' ' * space}$value' : '$label $value';
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class PaymentRecord {
  final String method;
  final int amountMinor;
  final DateTime createdAt;
  final String type;

  PaymentRecord({
    required this.method,
    required this.amountMinor,
    required this.createdAt,
    required this.type,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      method: (json['method'] ?? '') as String,
      amountMinor: (json['amount_minor'] ?? 0) as int,
      createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String()) as String),
      type: (json['type'] ?? '') as String,
    );
  }
}

class PaymentLedger {
  final int cashTotal;
  final int cardTotal;
  final int upiTotal;
  final int refundTotal;

  const PaymentLedger({
    required this.cashTotal,
    required this.cardTotal,
    required this.upiTotal,
    required this.refundTotal,
  });

  factory PaymentLedger.fromRecords(List<PaymentRecord> records) {
    int cash = 0;
    int card = 0;
    int upi = 0;
    int refund = 0;

    for (final record in records) {
      if (record.type.toLowerCase() == 'refund') {
        refund += record.amountMinor;
      } else {
        final method = record.method.toLowerCase();
        if (method == 'cash') {
          cash += record.amountMinor;
        } else if (method == 'card') {
          card += record.amountMinor;
        } else if (method == 'upi') {
          upi += record.amountMinor;
        }
      }
    }

    return PaymentLedger(
      cashTotal: cash,
      cardTotal: card,
      upiTotal: upi,
      refundTotal: refund,
    );
  }
}

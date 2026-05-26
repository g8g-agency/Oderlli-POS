import 'shift_transaction_type.dart';

/// Structured activity entry in the cash drawer audit log.
class ShiftActivity {
  final String id;
  final ShiftTransactionType type;
  final DateTime timestamp;
  final double amount;
  final String title;
  final String subtitle;
  final String performedBy;

  ShiftActivity({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.amount,
    required this.title,
    required this.subtitle,
    required this.performedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
        'amount': amount,
        'title': title,
        'subtitle': subtitle,
        'performedBy': performedBy,
      };

  factory ShiftActivity.fromJson(Map<String, dynamic> json) => ShiftActivity(
        id: json['id'] as String,
        type: ShiftTransactionType.values[json['type'] as int],
        timestamp: DateTime.parse(json['timestamp'] as String),
        amount: (json['amount'] as num).toDouble(),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        performedBy: json['performedBy'] as String,
      );
}

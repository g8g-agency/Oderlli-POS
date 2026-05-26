import 'shift_activity.dart';

/// Structured shift session properties for drawer reconciliation.
class ShiftSession {
  final String shiftId;
  final String terminalId;
  final String cashierName;
  final DateTime shiftStart;
  final DateTime? shiftEnd;
  final double openingCash;
  final double netCashSales;
  final double payouts;
  final double cashInTotal;
  final double cashDropTotal;
  final List<ShiftActivity> activities;
  final bool isShiftActive;

  ShiftSession({
    required this.shiftId,
    required this.terminalId,
    required this.cashierName,
    required this.shiftStart,
    this.shiftEnd,
    required this.openingCash,
    required this.netCashSales,
    required this.payouts,
    required this.cashInTotal,
    required this.cashDropTotal,
    required this.activities,
    required this.isShiftActive,
  });

  double get expectedCash =>
      openingCash + netCashSales + cashInTotal - cashDropTotal - payouts;

  ShiftSession copyWith({
    String? shiftId,
    String? terminalId,
    String? cashierName,
    DateTime? shiftStart,
    DateTime? shiftEnd,
    double? openingCash,
    double? netCashSales,
    double? payouts,
    double? cashInTotal,
    double? cashDropTotal,
    List<ShiftActivity>? activities,
    bool? isShiftActive,
  }) {
    return ShiftSession(
      shiftId: shiftId ?? this.shiftId,
      terminalId: terminalId ?? this.terminalId,
      cashierName: cashierName ?? this.cashierName,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      openingCash: openingCash ?? this.openingCash,
      netCashSales: netCashSales ?? this.netCashSales,
      payouts: payouts ?? this.payouts,
      cashInTotal: cashInTotal ?? this.cashInTotal,
      cashDropTotal: cashDropTotal ?? this.cashDropTotal,
      activities: activities ?? this.activities,
      isShiftActive: isShiftActive ?? this.isShiftActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'shiftId': shiftId,
        'terminalId': terminalId,
        'cashierName': cashierName,
        'shiftStart': shiftStart.toIso8601String(),
        'shiftEnd': shiftEnd?.toIso8601String(),
        'openingCash': openingCash,
        'netCashSales': netCashSales,
        'payouts': payouts,
        'cashInTotal': cashInTotal,
        'cashDropTotal': cashDropTotal,
        'activities': activities.map((a) => a.toJson()).toList(),
        'isShiftActive': isShiftActive,
      };

  factory ShiftSession.fromJson(Map<String, dynamic> json) => ShiftSession(
        shiftId: json['shiftId'] as String,
        terminalId: json['terminalId'] as String,
        cashierName: json['cashierName'] as String,
        shiftStart: DateTime.parse(json['shiftStart'] as String),
        shiftEnd: json['shiftEnd'] != null
            ? DateTime.parse(json['shiftEnd'] as String)
            : null,
        openingCash: (json['openingCash'] as num).toDouble(),
        netCashSales: (json['netCashSales'] as num).toDouble(),
        payouts: (json['payouts'] as num).toDouble(),
        cashInTotal: (json['cashInTotal'] as num).toDouble(),
        cashDropTotal: (json['cashDropTotal'] as num).toDouble(),
        activities: (json['activities'] as List<dynamic>)
            .map((a) => ShiftActivity.fromJson(a as Map<String, dynamic>))
            .toList(),
        isShiftActive: json['isShiftActive'] as bool,
      );
}

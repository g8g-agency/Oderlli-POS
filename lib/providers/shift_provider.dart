import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Provider for managing POS active/closed shifts.
final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftSession>((ref) {
  final notifier = ShiftNotifier();
  notifier.loadSession();
  return notifier;
});

class ShiftNotifier extends StateNotifier<ShiftSession> {
  static const _prefKey = 'active_shift_session';

  ShiftNotifier() : super(_initialSession());

  static ShiftSession _initialSession() {
    final now = DateTime.now();
    return ShiftSession(
      shiftId: 'shift-${now.millisecondsSinceEpoch}',
      terminalId: 'TER-01',
      cashierName: 'Alexander',
      shiftStart: now.subtract(const Duration(hours: 4, minutes: 30)),
      openingCash: 15000.0,
      netCashSales: 43550.0,
      payouts: 4500.0,
      cashInTotal: 0.0,
      cashDropTotal: 0.0,
      isShiftActive: true,
      activities: [
        ShiftActivity(
          id: 'act-init-1',
          type: ShiftTransactionType.payout,
          timestamp: now.subtract(const Duration(minutes: 60)),
          amount: -4500.0,
          title: 'Cash Out / Payout',
          subtitle: 'Supplier pay (Fresh veg)',
          performedBy: 'Alexander',
        ),
        ShiftActivity(
          id: 'act-init-2',
          type: ShiftTransactionType.cashIn,
          timestamp: now.subtract(const Duration(hours: 2, minutes: 18)),
          amount: 8420.0,
          title: 'Cash Sale',
          subtitle: 'Bill #23048',
          performedBy: 'Alexander',
        ),
        ShiftActivity(
          id: 'act-init-3',
          type: ShiftTransactionType.shiftOpened,
          timestamp: now.subtract(const Duration(hours: 4, minutes: 30)),
          amount: 15000.0,
          title: 'Shift Opened',
          subtitle: 'Opening drawer verify',
          performedBy: 'Alexander',
        ),
      ],
    );
  }

  /// Loads the persisted shift state from SharedPreferences.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_prefKey);
      if (dataStr != null) {
        final decoded = jsonDecode(dataStr) as Map<String, dynamic>;
        state = ShiftSession.fromJson(decoded);
      }
    } catch (e) {
      // Fallback silently to initial session if storage fails
    }
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = jsonEncode(state.toJson());
      await prefs.setString(_prefKey, dataStr);
    } catch (e) {
      // Fallback silently if storage fails
    }
  }

  /// Appends a payout expense and updates total payouts.
  void addPayout(double amount, String category, String reason, String? notes) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final newActivity = ShiftActivity(
      id: 'tx-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.payout,
      timestamp: now,
      amount: -amount,
      title: 'Cash Out / Payout',
      subtitle: '$category: $reason${notes != null && notes.isNotEmpty ? " ($notes)" : ""}',
      performedBy: state.cashierName,
    );

    // Enforce newest-first order
    state = state.copyWith(
      payouts: state.payouts + amount,
      activities: [newActivity, ...state.activities],
    );
    _saveSession();
  }

  /// Logs a cash-in operation to drawer.
  void addCashIn(double amount, String reason, String? notes) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final newActivity = ShiftActivity(
      id: 'tx-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.cashIn,
      timestamp: now,
      amount: amount,
      title: 'Cash In',
      subtitle: '$reason${notes != null && notes.isNotEmpty ? " ($notes)" : ""}',
      performedBy: state.cashierName,
    );

    state = state.copyWith(
      cashInTotal: state.cashInTotal + amount,
      activities: [newActivity, ...state.activities],
    );
    _saveSession();
  }

  /// Logs a cash-drop operation (withdrawal from expected cash).
  void addCashDrop(double amount, String reason, String? notes) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final newActivity = ShiftActivity(
      id: 'tx-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.cashDrop,
      timestamp: now,
      amount: -amount,
      title: 'Cash Drop',
      subtitle: '$reason${notes != null && notes.isNotEmpty ? " ($notes)" : ""}',
      performedBy: state.cashierName,
    );

    state = state.copyWith(
      cashDropTotal: state.cashDropTotal + amount,
      activities: [newActivity, ...state.activities],
    );
    _saveSession();
  }

  /// Logs print or export X report events.
  void logXReport(bool isPdf) {
    final now = DateTime.now();
    final newActivity = ShiftActivity(
      id: 'tx-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.xReport,
      timestamp: now,
      amount: 0.0,
      title: isPdf ? 'X Report Exported' : 'X Report Printed',
      subtitle: 'Audit summary printed to terminal',
      performedBy: state.cashierName,
    );

    state = state.copyWith(
      activities: [newActivity, ...state.activities],
    );
    _saveSession();
  }

  /// Closes the active shift and locks cashier out.
  void closeShift() {
    final now = DateTime.now();
    final newActivity = ShiftActivity(
      id: 'tx-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.shiftClosed,
      timestamp: now,
      amount: 0.0,
      title: 'Shift Closed',
      subtitle: 'Terminal locked and audited',
      performedBy: state.cashierName,
    );

    state = state.copyWith(
      shiftEnd: now,
      isShiftActive: false,
      activities: [newActivity, ...state.activities],
    );
    _saveSession();
  }

  /// Resets the shift session back to initial values (starts a new shift).
  Future<void> startNewShift() async {
    state = _initialSession();
    await _saveSession();
  }
}

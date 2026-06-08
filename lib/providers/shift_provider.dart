import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// Provider for managing POS active/closed shifts.
final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftSession>((ref) {
  final notifier = ShiftNotifier(ref);
  notifier.loadSession();
  return notifier;
});

class ShiftNotifier extends StateNotifier<ShiftSession> {
  static const _prefKey = 'active_shift_session';
  final Ref _ref;

  ShiftNotifier(this._ref) : super(_initialSession(null)) {
    // Listen to auth state to update cashier name when user logs in
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        final newName = next.user!.name;
        if (state.cashierName != newName) {
          state = state.copyWith(
            cashierName: newName,
            activities: state.activities.map((act) {
              if (act.performedBy == 'Staff' || act.performedBy == 'Alexander') {
                return ShiftActivity(
                  id: act.id,
                  type: act.type,
                  timestamp: act.timestamp,
                  amount: act.amount,
                  title: act.title,
                  subtitle: act.subtitle,
                  performedBy: newName,
                );
              }
              return act;
            }).toList(),
          );
          _saveSession();
        }
      }
    });
  }

  static ShiftSession _initialSession(String? cashierName) {
    final now = DateTime.now();
    final name = cashierName ?? 'Staff';
    return ShiftSession(
      shiftId: 'shift-${now.millisecondsSinceEpoch}',
      terminalId: 'Main Terminal',
      cashierName: name,
      shiftStart: now,
      openingCash: 5000.0,
      netCashSales: 0.0,
      payouts: 0.0,
      cashInTotal: 0.0,
      cashDropTotal: 0.0,
      isShiftActive: true,
      activities: [
        ShiftActivity(
          id: 'act-init-3',
          type: ShiftTransactionType.shiftOpened,
          timestamp: now,
          amount: 5000.0,
          title: 'Shift Opened',
          subtitle: 'Opening drawer verify',
          performedBy: name,
        ),
      ],
    );
  }

  /// Loads the persisted shift state from SharedPreferences.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_prefKey);
      final authState = _ref.read(authProvider);
      final currentUserName = authState.user?.name ?? authState.lockedUser?.name;

      if (dataStr != null) {
        final decoded = jsonDecode(dataStr) as Map<String, dynamic>;
        final loadedSession = ShiftSession.fromJson(decoded);

        // Discard any session that contains mock activities or is owned by Alexander
        final containsMock = loadedSession.activities.any((a) =>
            a.title.contains('Fresh veg') ||
            a.subtitle.contains('Fresh veg') ||
            a.performedBy == 'Alexander');

        if (containsMock) {
          state = _initialSession(currentUserName);
          await _saveSession();
        } else {
          // If cashierName is 'Staff' or 'Alexander', update it to the logged in user if available
          if ((loadedSession.cashierName == 'Staff' || loadedSession.cashierName == 'Alexander') && currentUserName != null) {
            state = loadedSession.copyWith(
              cashierName: currentUserName,
              activities: loadedSession.activities.map((act) {
                if (act.performedBy == 'Staff' || act.performedBy == 'Alexander') {
                  return ShiftActivity(
                    id: act.id,
                    type: act.type,
                    timestamp: act.timestamp,
                    amount: act.amount,
                    title: act.title,
                    subtitle: act.subtitle,
                    performedBy: currentUserName,
                  );
                }
                return act;
              }).toList(),
            );
            await _saveSession();
          } else {
            state = loadedSession;
          }
        }
      } else {
        state = _initialSession(currentUserName);
      }
    } catch (e) {
      // Fallback silently if storage fails
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

  /// Logs a cash sale to the drawer and updates netCashSales.
  void addCashSale(double amount, String orderNumber) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final newActivity = ShiftActivity(
      id: 'tx-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.cashIn,
      timestamp: now,
      amount: amount,
      title: 'Cash Sale',
      subtitle: 'Order #$orderNumber',
      performedBy: state.cashierName,
    );

    state = state.copyWith(
      netCashSales: state.netCashSales + amount,
      activities: [newActivity, ...state.activities],
    );
    _saveSession();
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
    final authState = _ref.read(authProvider);
    final currentUserName = authState.user?.name ?? authState.lockedUser?.name;
    state = _initialSession(currentUserName);
    await _saveSession();
  }
}

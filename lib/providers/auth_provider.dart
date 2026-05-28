import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'shift_provider.dart';

/// State representation of the active POS session.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLocked = false,
    this.lockedUser,
  });

  final PosUser? user;
  final bool isLoading;
  final bool isLocked;
  final PosUser? lockedUser;

  AuthState copyWith({
    PosUser? Function()? user,
    bool? isLoading,
    bool? isLocked,
    PosUser? Function()? lockedUser,
  }) {
    return AuthState(
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
      isLocked: isLocked ?? this.isLocked,
      lockedUser: lockedUser != null ? lockedUser() : this.lockedUser,
    );
  }
}

/// Provider for managing terminal authentication and active user session.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);
  notifier.loadSession();
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;
  static const _userPrefKey = 'active_pos_user';
  static const _lockedPrefKey = 'is_terminal_locked';

  /// Loads persisted user and locked state from storage on app start.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userPrefKey);
      final isLocked = prefs.getBool(_lockedPrefKey) ?? false;

      if (userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        final user = PosUser.fromJson(decoded);
        if (isLocked) {
          state = AuthState(
            user: null,
            isLocked: true,
            lockedUser: user,
          );
        } else {
          state = AuthState(user: user);
        }
      }
    } catch (e) {
      // Fallback silently if storage fails
    }
  }

  /// Attempts login/unlock with a PIN code.
  Future<bool> authenticate(PosUser user, String pin) async {
    state = state.copyWith(isLoading: true);
    
    // Simulate realistic enterprise network authentication delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (user.pin == pin) {
      state = AuthState(
        user: user,
        isLoading: false,
        isLocked: false,
        lockedUser: null,
      );
      await _saveSession();

      // Log login activity to the active shift log
      _logToShift(
        type: ShiftTransactionType.cashIn, // Map login as operational log
        title: 'User Authenticated',
        subtitle: '${user.name} logged into ${user.terminalId}',
        performedBy: user.name,
      );

      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Lock screen - preserves session info but redirects to PIN entry.
  void lock() {
    final activeUser = state.user;
    if (activeUser == null) return;

    state = AuthState(
      user: null,
      isLocked: true,
      lockedUser: activeUser,
    );
    _saveSession();

    _logToShift(
      type: ShiftTransactionType.xReport, // Audit/Terminal status log
      title: 'Terminal Locked',
      subtitle: '${activeUser.name} locked ${activeUser.terminalId} (Inactivity/Manual)',
      performedBy: activeUser.name,
    );
  }

  /// Unlock screen for currently locked terminal user.
  Future<bool> unlock(String pin, {PosUser? managerOverride}) async {
    final targetUser = managerOverride ?? state.lockedUser;
    if (targetUser == null) return false;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Allow the original locked user or any Manager override PIN to unlock
    if (targetUser.pin == pin || (managerOverride != null && managerOverride.role == UserRole.manager && managerOverride.pin == pin)) {
      final userToRestore = state.lockedUser ?? targetUser;
      state = AuthState(
        user: userToRestore,
        isLoading: false,
        isLocked: false,
        lockedUser: null,
      );
      await _saveSession();

      _logToShift(
        type: ShiftTransactionType.cashIn,
        title: 'Terminal Unlocked',
        subtitle: managerOverride != null
            ? '${userToRestore.name} unlocked via Manager Override (${managerOverride.name})'
            : '${userToRestore.name} unlocked ${userToRestore.terminalId}',
        performedBy: userToRestore.name,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Log out of active session completely.
  Future<void> logout() async {
    final oldUser = state.user ?? state.lockedUser;
    if (oldUser != null) {
      _logToShift(
        type: ShiftTransactionType.shiftClosed,
        title: 'User Signed Out',
        subtitle: '${oldUser.name} closed session on ${oldUser.terminalId}',
        performedBy: oldUser.name,
      );
    }

    state = const AuthState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPrefKey);
    await prefs.remove(_lockedPrefKey);
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.user != null) {
        await prefs.setString(_userPrefKey, jsonEncode(state.user!.toJson()));
        await prefs.setBool(_lockedPrefKey, false);
      } else if (state.lockedUser != null) {
        await prefs.setString(_userPrefKey, jsonEncode(state.lockedUser!.toJson()));
        await prefs.setBool(_lockedPrefKey, true);
      } else {
        await prefs.remove(_userPrefKey);
        await prefs.remove(_lockedPrefKey);
      }
    } catch (e) {
      // Ignore storage failures
    }
  }

  void _logToShift({
    required ShiftTransactionType type,
    required String title,
    required String subtitle,
    required String performedBy,
  }) {
    try {
      final shift = _ref.read(shiftProvider.notifier);
      // Append audit logs to the active shift session
      final now = DateTime.now();
      final newActivity = ShiftActivity(
        id: 'tx-${now.millisecondsSinceEpoch}',
        type: type,
        timestamp: now,
        amount: 0.0,
        title: title,
        subtitle: subtitle,
        performedBy: performedBy,
      );
      shift.state = shift.state.copyWith(
        activities: [newActivity, ...shift.state.activities],
      );
      // Trigger local save of shift session
      // Since ShiftNotifier has a private saveSession, we let it update
      // by setting shift.state to trigger notifications
    } catch (e) {
      // Silence if shift provider is not fully active
    }
  }
}

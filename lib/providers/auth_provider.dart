import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_config.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/device_fingerprint_service.dart';
import '../core/services/dio_client.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/auth_service.dart';
import '../core/repositories/auth_repository.dart';
import '../models/models.dart';
import 'shift_provider.dart';

/// State representation of the active POS session.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLocked = false,
    this.lockedUser,
    this.errorMessage,
  });

  final PosUser? user;
  final bool isLoading;
  final bool isLocked;
  final PosUser? lockedUser;
  final String? errorMessage;

  AuthState copyWith({
    PosUser? Function()? user,
    bool? isLoading,
    bool? isLocked,
    PosUser? Function()? lockedUser,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
      isLocked: isLocked ?? this.isLocked,
      lockedUser: lockedUser != null ? lockedUser() : this.lockedUser,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

// ─── Riverpod Providers ───────────────────────────────────────

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final fingerprintServiceProvider = Provider<DeviceFingerprintService>((ref) {
  return DeviceFingerprintService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final fingerprint = ref.watch(fingerprintServiceProvider);
  return DioClient(secureStorage, fingerprint);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthService(dioClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final fingerprint = ref.watch(fingerprintServiceProvider);
  return AuthRepository(
    authService,
    secureStorage,
    fingerprint,
  );
});

/// Provider for managing terminal authentication and active user session.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);
  notifier.loadSession();
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    // Listen to session expiration events from the HTTP client
    _ref.read(dioClientProvider).onSessionExpired.listen((_) {
      _handleSessionExpired();
    });
  }

  final Ref _ref;
  static const _userPrefKey = 'active_pos_user';
  static const _lockedPrefKey = 'is_terminal_locked';

  void _handleSessionExpired() {
    final activeUser = state.user;
    if (activeUser != null) {
      state = AuthState(
        user: null,
        isLocked: true,
        lockedUser: activeUser,
        errorMessage: 'Session expired. Please enter your PIN to log back in.',
      );
    } else {
      state = const AuthState(
        errorMessage: 'Session expired. Please log in again.',
      );
    }
  }

  /// Loads persisted user and locked state from storage on app start.
  Future<void> loadSession() async {
    try {
      // 1. Try to restore active session from secure storage (production flow)
      final repository = _ref.read(authRepositoryProvider);
      final restoredUser = await repository.restoreSession();

      if (restoredUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final isLocked = prefs.getBool(_lockedPrefKey) ?? false;
        
        if (isLocked) {
          state = AuthState(
            user: null,
            isLocked: true,
            lockedUser: restoredUser,
          );
        } else {
          state = AuthState(user: restoredUser);
        }
        return;
      }

      // 2. Fallback to shared_preferences for dev mock fallback
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
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    final isReachable = await _ref.read(connectivityServiceProvider).isBackendReachable(
      AppConfig.baseUrl,
      AppConfig.healthEndpoint,
    );

    if (!isReachable) {
      // If server is offline and mock fallback is allowed in debug mode, use local validation
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (user.pin == pin) {
          state = AuthState(
            user: user,
            isLoading: false,
            isLocked: false,
            lockedUser: null,
          );
          await _saveSessionLocally();
          _logToShift(
            type: ShiftTransactionType.cashIn,
            title: 'User Authenticated (Mock)',
            subtitle: '${user.name} logged into ${user.terminalId}',
            performedBy: user.name,
          );
          return true;
        } else {
          state = state.copyWith(isLoading: false, errorMessage: () => 'Invalid PIN');
          return false;
        }
      } else {
        // Production offline warning
        state = state.copyWith(
          isLoading: false,
          errorMessage: () => 'Backend Offline. Please check your network connection.',
        );
        return false;
      }
    }

    try {
      final repository = _ref.read(authRepositoryProvider);
      
      // Use email corresponding to selected user. If not set, fallback to user id email format.
      final email = user.email ?? '${user.id}@orderlyy.com';

      // Login using exact, raw PIN as the password
      final authenticatedUser = await repository.login(email, pin);

      state = AuthState(
        user: authenticatedUser,
        isLoading: false,
        isLocked: false,
        lockedUser: null,
      );
      await _saveSessionLocally();

      _logToShift(
        type: ShiftTransactionType.cashIn,
        title: 'User Authenticated',
        subtitle: '${authenticatedUser.name} logged into ${authenticatedUser.terminalId}',
        performedBy: authenticatedUser.name,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Invalid PIN or credentials',
      );
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
    _saveSessionLocally();

    _logToShift(
      type: ShiftTransactionType.xReport,
      title: 'Terminal Locked',
      subtitle: '${activeUser.name} locked ${activeUser.terminalId} (Inactivity/Manual)',
      performedBy: activeUser.name,
    );
  }

  /// Unlock screen for currently locked terminal user.
  Future<bool> unlock(String pin, {PosUser? managerOverride}) async {
    final targetUser = managerOverride ?? state.lockedUser;
    if (targetUser == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    final isReachable = await _ref.read(connectivityServiceProvider).isBackendReachable(
      AppConfig.baseUrl,
      AppConfig.healthEndpoint,
    );

    if (!isReachable) {
      if (kDebugMode && AppConfig.allowMockFallbackInDebug) {
        await Future.delayed(const Duration(milliseconds: 800));
        
        final localMatched = targetUser.pin == pin;
        final managerMatched = managerOverride != null &&
            managerOverride.role == UserRole.manager &&
            managerOverride.pin == pin;

        if (localMatched || managerMatched) {
          final userToRestore = state.lockedUser ?? targetUser;
          state = AuthState(
            user: userToRestore,
            isLoading: false,
            isLocked: false,
            lockedUser: null,
          );
          await _saveSessionLocally();
          _logToShift(
            type: ShiftTransactionType.cashIn,
            title: 'Terminal Unlocked (Mock)',
            subtitle: managerOverride != null
                ? '${userToRestore.name} unlocked via Manager Override (${managerOverride.name})'
                : '${userToRestore.name} unlocked ${userToRestore.terminalId}',
            performedBy: userToRestore.name,
          );
          return true;
        } else {
          state = state.copyWith(isLoading: false, errorMessage: () => 'Invalid PIN');
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () => 'Backend Offline. Please check your network connection.',
        );
        return false;
      }
    }

    try {
      final repository = _ref.read(authRepositoryProvider);
      
      // Use email corresponding to the target unlocking user
      final email = targetUser.email ?? '${targetUser.id}@orderlyy.com';

      // Login using exact PIN
      final authenticatedUser = await repository.login(email, pin);

      final userToRestore = state.lockedUser ?? authenticatedUser;

      state = AuthState(
        user: userToRestore,
        isLoading: false,
        isLocked: false,
        lockedUser: null,
      );
      await _saveSessionLocally();

      _logToShift(
        type: ShiftTransactionType.cashIn,
        title: 'Terminal Unlocked',
        subtitle: managerOverride != null
            ? '${userToRestore.name} unlocked via Manager Override (${authenticatedUser.name})'
            : '${userToRestore.name} unlocked ${userToRestore.terminalId}',
        performedBy: userToRestore.name,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Invalid PIN or credentials',
      );
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
    
    // Clear secure credentials and local storage persistence
    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.logout();
    } catch (_) {
      // Ignored since repository.logout() clears local storage anyway
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPrefKey);
    await prefs.remove(_lockedPrefKey);
  }

  Future<void> _saveSessionLocally() async {
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
    } catch (e) {
      // Silence if shift provider is not fully active
    }
  }
}

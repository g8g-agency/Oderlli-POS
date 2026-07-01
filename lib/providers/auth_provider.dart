import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/device_fingerprint_service.dart';
import '../core/services/dio_client.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/realtime_sync_service.dart';
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
    this.tenantId,
    this.branchId,
    this.branchName,
    this.availableBranches = const [],
    this.isOrgAuthenticated = false,
  });

  final PosUser? user;
  final bool isLoading;
  final bool isLocked;
  final PosUser? lockedUser;
  final String? errorMessage;
  final String? tenantId;
  final String? branchId;
  final String? branchName;
  final List<BranchInfo> availableBranches;
  final bool isOrgAuthenticated;

  String? get gstin {
    if (branchId == null) return null;
    for (final b in availableBranches) {
      if (b.id == branchId) return b.gstin;
    }
    return null;
  }

  String? get fssai {
    if (branchId == null) return null;
    for (final b in availableBranches) {
      if (b.id == branchId) return b.fssai;
    }
    return null;
  }

  AuthState copyWith({
    PosUser? Function()? user,
    bool? isLoading,
    bool? isLocked,
    PosUser? Function()? lockedUser,
    String? Function()? errorMessage,
    String? Function()? tenantId,
    String? Function()? branchId,
    String? Function()? branchName,
    List<BranchInfo>? availableBranches,
    bool? isOrgAuthenticated,
  }) {
    return AuthState(
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
      isLocked: isLocked ?? this.isLocked,
      lockedUser: lockedUser != null ? lockedUser() : this.lockedUser,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      tenantId: tenantId != null ? tenantId() : this.tenantId,
      branchId: branchId != null ? branchId() : this.branchId,
      branchName: branchName != null ? branchName() : this.branchName,
      availableBranches: availableBranches ?? this.availableBranches,
      isOrgAuthenticated: isOrgAuthenticated ?? this.isOrgAuthenticated,
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
  return DioClient(secureStorage, fingerprint, ref);
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
  static const _tenantIdKey = 'active_tenant_id';
  static const _branchIdKey = 'active_branch_id';
  static const _branchNameKey = 'active_branch_name';
  static const _isOrgAuthKey = 'is_org_authenticated';

  void _handleSessionExpired() {
    // Don't wipe org/branch context — only clear the active user session
    // so the router lands on employee login, not org login
    state = state.copyWith(
      user: () => null,
      isLocked: false,
      lockedUser: () => null,
      errorMessage: () => 'Session expired. Please sign in again.',
    );
    // Clear staff token from secure storage but keep org token
    try {
      _ref.read(authRepositoryProvider).clearStaffSession();
    } catch (_) {}
  }

  Future<void> logoutLocally() async {
    final oldUser = state.user ?? state.lockedUser;
    if (oldUser != null) {
      _logToShift(
        type: ShiftTransactionType.shiftClosed,
        title: 'User Signed Out',
        subtitle: '${oldUser.name} closed session',
        performedBy: oldUser.name,
      );
    }

    state = const AuthState();

    try {
      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.clearSession();
    } catch (_) {}

    _ref.read(realtimeSyncServiceProvider).dispose();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPrefKey);
    await prefs.remove(_lockedPrefKey);
    await prefs.remove(_tenantIdKey);
    await prefs.remove(_branchIdKey);
    await prefs.remove(_branchNameKey);
    await prefs.setBool(_isOrgAuthKey, false);
  }

  /// Loads persisted user and locked state from storage on app start.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tenantId = prefs.getString(_tenantIdKey);
      final branchId = prefs.getString(_branchIdKey);
      final branchName = prefs.getString(_branchNameKey);
      final isOrgAuthenticated = prefs.getBool(_isOrgAuthKey) ?? false;

      // Restore active session from secure storage (production flow)
      final repository = _ref.read(authRepositoryProvider);
      final restoredUser = await repository.restoreSession();
      final isLocked = prefs.getBool(_lockedPrefKey) ?? false;

      if (restoredUser != null) {
        state = AuthState(
          user: isLocked ? null : restoredUser,
          isLocked: isLocked,
          lockedUser: isLocked ? restoredUser : null,
          tenantId: tenantId,
          branchId: branchId,
          branchName: branchName,
          isOrgAuthenticated: isOrgAuthenticated,
        );
        if (isOrgAuthenticated && tenantId != null) {
          // Fetch branches in the background to keep list fresh
          fetchBranches().catchError((_) {});
        }
        if (branchId != null) {
          _ref.read(realtimeSyncServiceProvider).subscribe(branchId, _ref);
        }
        return;
      }

      // restoreSession returned null → verify the access token actually exists
      // before trusting stale SharedPreferences data.
      final secureStorage = _ref.read(secureStorageProvider);
      final credentials = await secureStorage.getCredentials();
      final hasValidToken = credentials['accessToken'] != null &&
          credentials['accessToken']!.isNotEmpty;

      if (!hasValidToken && isOrgAuthenticated) {
        // Stale session: prefs say authenticated but token is gone.
        // Clear stale prefs and return a clean unauthenticated state
        // so the router redirects to the login screen instead of
        // firing API calls without a token (which causes 401 cascades).
        await prefs.remove(_userPrefKey);
        await prefs.remove(_lockedPrefKey);
        await prefs.remove(_tenantIdKey);
        await prefs.remove(_branchIdKey);
        await prefs.remove(_branchNameKey);
        await prefs.setBool(_isOrgAuthKey, false);
        state = const AuthState();
        return;
      }

      // Fallback to shared_preferences for dev mock fallback
      final userJson = prefs.getString(_userPrefKey);

      if (userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        final user = PosUser.fromJson(decoded);
        state = AuthState(
          user: isLocked ? null : user,
          isLocked: isLocked,
          lockedUser: isLocked ? user : null,
          tenantId: tenantId,
          branchId: branchId,
          branchName: branchName,
          isOrgAuthenticated: isOrgAuthenticated,
        );
        if (isOrgAuthenticated && tenantId != null) {
          fetchBranches().catchError((_) {});
        }
        if (branchId != null) {
          _ref.read(realtimeSyncServiceProvider).subscribe(branchId, _ref);
        }
      } else {
        state = AuthState(
          tenantId: tenantId,
          branchId: branchId,
          branchName: branchName,
          isOrgAuthenticated: isOrgAuthenticated,
        );
      }
    } catch (e) {
      // Fallback silently if storage fails
    }
  }

  /// STEP 1: Organization Login
  Future<bool> loginOrganization(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.login(email, password);

      // Retrieve tenantId from the stored user JSON
      final secureStorage = _ref.read(secureStorageProvider);
      final credentials = await secureStorage.getCredentials();
      final userJson = credentials['userJson'];
      String? tenantId;
      if (userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        tenantId = decoded['tenantId'] ?? decoded['tenant_id'];
      }

      state = state.copyWith(
        tenantId: () => tenantId,
        isOrgAuthenticated: true,
        isLoading: false,
      );

      // Now fetch available branches for the tenant
      await fetchBranches();
      await _saveSessionLocally();
      return true;
    } catch (e) {
      String message = 'Invalid organization credentials';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.message != null) {
          message = e.message!;
        }
      } else {
        message = e.toString();
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => message,
      );
      return false;
    }
  }

  /// Fetch Available Branches
  Future<void> fetchBranches() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final repository = _ref.read(authRepositoryProvider);
      final branches = await repository.fetchBranches();
      
      // Filter branches strictly by: branch.tenantId == session.tenantId
      final filtered = branches.where((b) => b.tenantId == state.tenantId).toList();
      state = state.copyWith(
        availableBranches: filtered,
        isLoading: false,
      );
    } catch (e) {
      String message = 'Failed to load branches';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.message != null) {
          message = e.message!;
        }
      } else {
        message = e.toString();
      }
      state = state.copyWith(
        availableBranches: [],
        isLoading: false,
        errorMessage: () => message,
      );
    }
  }

  /// STEP 2: Select Branch
  Future<void> selectBranch(String branchId, String branchName) async {
    state = state.copyWith(
      branchId: () => branchId,
      branchName: () => branchName,
    );
    await _saveSessionLocally();
  }

  /// STEP 3: Employee Verification (PIN Login)
  Future<bool> loginEmployee(PosUser staffProfile, String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final repository = _ref.read(authRepositoryProvider);
      final employee = await repository.loginStaff(
        tenantId: state.tenantId ?? '',
        branchId: state.branchId ?? '',
        staffProfile: staffProfile,
        pin: pin,
      );

      state = state.copyWith(
        user: () => employee,
        isLoading: false,
        isLocked: false,
        lockedUser: () => null,
      );

      if (state.branchId != null) {
        _ref.read(realtimeSyncServiceProvider).subscribe(state.branchId!, _ref);
      }

      await _saveSessionLocally();

      _logToShift(
        type: ShiftTransactionType.cashIn,
        title: 'Employee Authenticated',
        subtitle: '${employee.name} logged into ${state.branchName}',
        performedBy: employee.name,
      );

      return true;
    } catch (e) {
      // Only update loading + error — preserve ALL org/branch context
      // so the router does not redirect away from the employee login screen
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Invalid PIN. Please try again.',
      );
      return false;
    }
  }

  /// Validates a manager's PIN against the backend without altering the active session.
  Future<bool> validateManagerPin(String pin, PosUser manager) async {
    try {
      final tenantId = state.tenantId;
      final branchId = state.branchId;
      if (tenantId == null || branchId == null) {
        return false;
      }

      final employeeId = (manager.employeeId != null && manager.employeeId!.isNotEmpty)
          ? manager.employeeId!
          : manager.id;

      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.post(
        '/auth/staff/login',
        data: {
          'tenantId': tenantId,
          'branchId': branchId,
          'employeeId': employeeId,
          'pin': pin,
          'email': manager.email,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        if (body != null && body['success'] == true) {
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Try again.');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// For backwards compatibility with login keypad code
  Future<bool> authenticate(PosUser user, String pin) async {
    // Translate PIN '1234' to seeded password 'Test@123456' for test accounts
    // if organization login is bypassed, or if it is local keypad login
    if (!state.isOrgAuthenticated) {
      final ok = await loginOrganization(user.email ?? '', pin == '1234' ? 'Test@123456' : pin);
      if (!ok) return false;
      await selectBranch('br-royal-1', 'Royal Tandoor - Main Branch');
      final success = await loginEmployee(user, '1234');
      if (success && state.branchId != null) {
        _ref.read(realtimeSyncServiceProvider).subscribe(state.branchId!, _ref);
      }
      return success;
    }
    final success = await loginEmployee(user, pin);
    if (success && state.branchId != null) {
      _ref.read(realtimeSyncServiceProvider).subscribe(state.branchId!, _ref);
    }
    return success;
  }

  /// Lock screen - preserves session info but redirects to PIN entry.
  void lock() {
    final activeUser = state.user;
    if (activeUser == null) return;

    state = state.copyWith(
      user: () => null,
      isLocked: true,
      lockedUser: () => activeUser,
    );
    _ref.read(authRepositoryProvider).clearStaffSession();
    _saveSessionLocally();

    _logToShift(
      type: ShiftTransactionType.xReport,
      title: 'Terminal Locked',
      subtitle: '${activeUser.name} locked terminal',
      performedBy: activeUser.name,
    );
  }

  /// Unlock terminal session.
  Future<bool> unlock(String pin, {PosUser? managerOverride}) async {
    final targetUser = managerOverride ?? state.lockedUser;
    if (targetUser == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final repository = _ref.read(authRepositoryProvider);
      final employee = await repository.loginStaff(
        tenantId: state.tenantId ?? '',
        branchId: state.branchId ?? '',
        staffProfile: targetUser,
        pin: pin,
      );

      state = state.copyWith(
        user: () => employee,
        isLocked: false,
        lockedUser: () => null,
        isLoading: false,
      );
      if (state.branchId != null) {
        _ref.read(realtimeSyncServiceProvider).subscribe(state.branchId!, _ref);
      }
      await _saveSessionLocally();

      _logToShift(
        type: ShiftTransactionType.cashIn,
        title: 'Terminal Unlocked',
        subtitle: '${employee.name} unlocked session',
        performedBy: employee.name,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Invalid PIN. Please try again.',
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
        subtitle: '${oldUser.name} closed session',
        performedBy: oldUser.name,
      );
    }

    state = const AuthState();

    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.logout();
    } catch (_) {}

    _ref.read(realtimeSyncServiceProvider).dispose();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPrefKey);
    await prefs.remove(_lockedPrefKey);
    await prefs.remove(_tenantIdKey);
    await prefs.remove(_branchIdKey);
    await prefs.remove(_branchNameKey);
    await prefs.setBool(_isOrgAuthKey, false);
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

      if (state.tenantId != null) {
        await prefs.setString(_tenantIdKey, state.tenantId!);
      } else {
        await prefs.remove(_tenantIdKey);
      }

      if (state.branchId != null) {
        await prefs.setString(_branchIdKey, state.branchId!);
      } else {
        await prefs.remove(_branchIdKey);
      }

      if (state.branchName != null) {
        await prefs.setString(_branchNameKey, state.branchName!);
      } else {
        await prefs.remove(_branchNameKey);
      }

      await prefs.setBool(_isOrgAuthKey, state.isOrgAuthenticated);
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

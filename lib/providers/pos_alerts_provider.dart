import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Alert types ──────────────────────────────────────────────────────────────
enum POSAlertType {
  /// Full-screen blocking overlay — app lost connection to backend/printer.
  reconnecting,

  /// Slim top-banner — data sync in progress (non-blocking).
  syncing,

  /// Dismissible floating card — a payment transaction failed.
  paymentFailure,

  /// Floating side card — a kitchen order has breached its SLA.
  delayedOrder,

  /// Top warning banner — local state is stale / out-of-sync.
  staleState,
}

// ─── Alert data model ─────────────────────────────────────────────────────────
class POSAlert {
  POSAlert({
    required this.id,
    required this.type,
    this.message,
    this.tableLabel,
    this.actionLabel,
    this.onAction,
    this.autoDismissAfter,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final POSAlertType type;
  final String? message;
  final String? tableLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration? autoDismissAfter;
  final DateTime createdAt;

  bool get isBlocking => type == POSAlertType.reconnecting;
  bool get isDismissible => !isBlocking;
}

// ─── Alert notifier ───────────────────────────────────────────────────────────
class POSAlertsNotifier extends StateNotifier<List<POSAlert>> {
  POSAlertsNotifier() : super([]);

  final Map<String, Timer> _autoDismissTimers = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Show a blocking "Reconnecting…" overlay. Cleared via [clearReconnecting].
  void showReconnecting({String? message}) {
    _addAlert(POSAlert(
      id: 'reconnecting',
      type: POSAlertType.reconnecting,
      message: message ?? 'Connection lost. Reconnecting to server…',
    ));
  }

  void clearReconnecting() => _removeAlert('reconnecting');

  /// Show a non-blocking syncing top banner.
  void showSyncing({String? message, Duration autoDismissAfter = const Duration(seconds: 4)}) {
    _addAlert(POSAlert(
      id: 'syncing',
      type: POSAlertType.syncing,
      message: message ?? 'Syncing orders and table states…',
      autoDismissAfter: autoDismissAfter,
    ));
  }

  /// Show a payment failure floating card.
  void showPaymentFailure({
    required String message,
    VoidCallback? onRetry,
    Duration autoDismissAfter = const Duration(seconds: 8),
  }) {
    final id = 'pay-fail-${DateTime.now().millisecondsSinceEpoch}';
    _addAlert(POSAlert(
      id: id,
      type: POSAlertType.paymentFailure,
      message: message,
      actionLabel: onRetry != null ? 'RETRY' : null,
      onAction: onRetry,
      autoDismissAfter: autoDismissAfter,
    ));
  }

  /// Show a delayed order floating side card.
  void showDelayedOrder({
    required String tableLabel,
    required int delayMinutes,
    VoidCallback? onViewOrder,
    Duration autoDismissAfter = const Duration(seconds: 12),
  }) {
    final id = 'delay-$tableLabel-${DateTime.now().millisecondsSinceEpoch}';
    _addAlert(POSAlert(
      id: id,
      type: POSAlertType.delayedOrder,
      message: '${delayMinutes}m delayed — SLA breached',
      tableLabel: tableLabel,
      actionLabel: 'VIEW',
      onAction: onViewOrder,
      autoDismissAfter: autoDismissAfter,
    ));
  }

  /// Show a stale state top warning banner.
  void showStaleState({
    String? message,
    VoidCallback? onRefresh,
    Duration autoDismissAfter = const Duration(seconds: 10),
  }) {
    _addAlert(POSAlert(
      id: 'stale',
      type: POSAlertType.staleState,
      message: message ?? 'Table data may be out of sync. Last update: over 5 minutes ago.',
      actionLabel: 'REFRESH',
      onAction: onRefresh,
      autoDismissAfter: autoDismissAfter,
    ));
  }

  /// Manually dismiss a specific alert by id.
  void dismiss(String id) => _removeAlert(id);

  /// Dismiss all non-blocking alerts.
  void dismissAll() {
    final blockingIds = state
        .where((a) => a.isBlocking)
        .map((a) => a.id)
        .toSet();
    state = state.where((a) => blockingIds.contains(a.id)).toList();
    _autoDismissTimers
      ..forEach((id, timer) {
        if (!blockingIds.contains(id)) timer.cancel();
      })
      ..removeWhere((id, _) => !blockingIds.contains(id));
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _addAlert(POSAlert alert) {
    // Replace existing alert with same id (dedup)
    _removeAlert(alert.id, cancelTimer: true);
    state = [...state, alert];

    if (alert.autoDismissAfter != null) {
      _autoDismissTimers[alert.id] = Timer(alert.autoDismissAfter!, () {
        _removeAlert(alert.id);
      });
    }
  }

  void _removeAlert(String id, {bool cancelTimer = false}) {
    final timer = _autoDismissTimers.remove(id);
    if (cancelTimer) timer?.cancel();
    state = state.where((a) => a.id != id).toList();
  }

  @override
  void dispose() {
    for (final t in _autoDismissTimers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final posAlertsProvider =
    StateNotifierProvider<POSAlertsNotifier, List<POSAlert>>(
  (ref) => POSAlertsNotifier(),
);

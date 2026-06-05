import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// ─── Orderlyy POS · Operational Status ──────────────────────────────────────
///
/// Comprehensive state enum covering physical table states, kitchen order states,
/// checkout/financial states, and local network syncing states.
enum OperationalStatus {
  available,
  occupied,
  preparing,
  ready,
  delayed,
  paymentPending,
  paid,
  partialPaid,
  refunded,
  failed,
  syncing,
  reconnecting,
}

extension OperationalStatusX on OperationalStatus {
  /// User-friendly label for display on the POS screens.
  String get label => switch (this) {
        OperationalStatus.available => 'Available',
        OperationalStatus.occupied => 'Occupied',
        OperationalStatus.preparing => 'Preparing',
        OperationalStatus.ready => 'Ready',
        OperationalStatus.delayed => 'Delayed',
        OperationalStatus.paymentPending => 'Payment Pending',
        OperationalStatus.paid => 'Paid',
        OperationalStatus.partialPaid => 'Partial Paid',
        OperationalStatus.refunded => 'Refunded',
        OperationalStatus.failed => 'Failed',
        OperationalStatus.syncing => 'Syncing',
        OperationalStatus.reconnecting => 'Reconnecting',
      };

  /// The color-code assigned to this operational state from [AppColors].
  Color get color => switch (this) {
        OperationalStatus.available => AppColors.available,
        OperationalStatus.occupied => AppColors.occupied,
        OperationalStatus.preparing => AppColors.preparing,
        OperationalStatus.ready => AppColors.ready,
        OperationalStatus.delayed => AppColors.delayed,
        OperationalStatus.paymentPending => AppColors.partialPaid,
        OperationalStatus.paid => AppColors.paid,
        OperationalStatus.partialPaid => AppColors.partialPaid,
        OperationalStatus.refunded => AppColors.refunded,
        OperationalStatus.failed => AppColors.error,
        OperationalStatus.syncing => AppColors.syncing,
        OperationalStatus.reconnecting => AppColors.reconnecting,
      };

  /// Standard IconData representing the state.
  IconData get icon => switch (this) {
        OperationalStatus.available => Icons.check_circle_outline,
        OperationalStatus.occupied => Icons.table_bar,
        OperationalStatus.preparing => Icons.restaurant,
        OperationalStatus.ready => Icons.room_service,
        OperationalStatus.delayed => Icons.warning_amber_rounded,
        OperationalStatus.paymentPending => Icons.pending_actions,
        OperationalStatus.paid => Icons.verified,
        OperationalStatus.partialPaid => Icons.account_balance_wallet,
        OperationalStatus.refunded => Icons.assignment_return_outlined,
        OperationalStatus.failed => Icons.error_outline,
        OperationalStatus.syncing => Icons.sync,
        OperationalStatus.reconnecting => Icons.wifi_off,
      };

  /// Determines if the status requires an active attention-seeking visual animation.
  bool get hasPulseEffect => switch (this) {
        OperationalStatus.delayed ||
        OperationalStatus.failed ||
        OperationalStatus.reconnecting =>
          true,
        _ => false,
      };

  /// Determines if the icon should rotate continuously (e.g. during a sync).
  bool get hasSpinEffect => this == OperationalStatus.syncing;
}

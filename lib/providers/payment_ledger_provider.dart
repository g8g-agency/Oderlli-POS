import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/repositories/payment_ledger_repository.dart';
import 'auth_provider.dart';

/// Repository provider for PaymentLedgerRepository.
final paymentLedgerRepositoryProvider = Provider<PaymentLedgerRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PaymentLedgerRepository(dioClient);
});

/// Represents a custom date range parameter for FutureProvider.family.
class DateRange {
  final DateTime from;
  final DateTime to;

  const DateRange({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && from == other.from && to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}

/// FutureProvider to fetch the payment ledger for the current session's branch and date range.
final paymentLedgerProvider = FutureProvider.family<PaymentLedger, DateRange>((ref, range) async {
  final branchId = ref.watch(authProvider).branchId;
  if (branchId == null) {
    throw Exception('No branchId context configured. Please verify your login session.');
  }
  final repository = ref.watch(paymentLedgerRepositoryProvider);
  return repository.fetchLedger(branchId, range.from, range.to);
});

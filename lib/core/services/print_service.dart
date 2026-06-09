import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';

/// Print service interface for POS shift audit summaries and receipts.
abstract class PrintService {
  Future<void> printXReport(ShiftSession session);
  Future<void> exportPdf(ShiftSession session);
  Future<void> printReceipt(ReceiptRequest request);
}

final printServiceProvider = Provider<PrintService>((ref) {
  return const MockPrintService();
});

/// Mock print service simulating hardware communication delay.
class MockPrintService implements PrintService {
  const MockPrintService();

  @override
  Future<void> printXReport(ShiftSession session) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> exportPdf(ShiftSession session) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> printReceipt(ReceiptRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    assert(() {
      // ignore: avoid_print
      print(request.toReceiptText());
      return true;
    }());
  }
}

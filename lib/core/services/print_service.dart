import '../../models/models.dart';

/// Print service interface for POS shift audit summaries and receipts.
abstract class PrintService {
  Future<void> printXReport(ShiftSession session);
  Future<void> exportPdf(ShiftSession session);
}

/// Mock print service simulating hardware communication delay.
class MockPrintService implements PrintService {
  const MockPrintService();

  @override
  Future<void> printXReport(ShiftSession session) async {
    // Simulate printer spooling delay
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> exportPdf(ShiftSession session) async {
    // Simulate PDF generation/storage delay
    await Future.delayed(const Duration(seconds: 1));
  }
}

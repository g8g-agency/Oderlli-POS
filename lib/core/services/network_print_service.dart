import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import '../../models/models.dart';
import 'print_service.dart';

/// Print service implementation for ESC/POS receipt printers over TCP/IP network.
class NetworkPrintService implements PrintService {
  final String printerIp;
  final int printerPort;

  NetworkPrintService({
    required this.printerIp,
    this.printerPort = 9100,
  });

  @override
  Future<void> printXReport(ShiftSession session) async {
    // Audit reports are simulated for mock/pdf but not yet printed over network.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> exportPdf(ShiftSession session) async {
    // PDF export simulated.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> printReceipt(ReceiptRequest request) async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final result = await printer.connect(
      printerIp,
      port: printerPort,
      timeout: const Duration(seconds: 5),
    );

    if (result != PosPrintResult.success) {
      throw PrinterException('Printer offline: $printerIp:$printerPort');
    }

    try {
      // Bold, centered restaurant name
      printer.text(
        request.restaurantName,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      if (request.branchName.isNotEmpty) {
        printer.text(
          request.branchName,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      printer.text('------------------------------------------------');

      // Print line items
      for (final item in request.order.items) {
        final name = item.itemNameSnapshot;
        final qty = item.quantity.toString();
        final amount = '₹${item.subtotal.toStringAsFixed(2)}';

        printer.row([
          PosColumn(
            text: name,
            width: 8,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: qty,
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: amount,
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        for (final mod in item.modifiers) {
          printer.text('  + $mod', styles: const PosStyles(align: PosAlign.left));
        }

        if (item.notes != null && item.notes!.isNotEmpty) {
          printer.text('  Note: ${item.notes}', styles: const PosStyles(align: PosAlign.left));
        }
      }

      printer.text('------------------------------------------------');

      // Print total
      printer.row([
        PosColumn(
          text: 'TOTAL:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: '₹${request.order.total.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      printer.text('------------------------------------------------');

      // Print footer
      printer.text('Thank you for dining with us!', styles: const PosStyles(align: PosAlign.center));
      printer.text('Powered by Orderlyy', styles: const PosStyles(align: PosAlign.center));

      printer.feed(2);
      printer.cut();
    } finally {
      printer.disconnect();
    }
  }
}

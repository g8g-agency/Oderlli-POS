import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Settings State model ───────────────────────────────────────────────────
class POSSettingsState {
  final bool offlineStandalone;
  final bool autoPrintReceipt;
  final bool enableGuestScreen;
  final String kitchenPrinterIp;
  final String counterPrinterIp;
  final String billingPrinterIp;
  final String cardTerminalIp;
  final String cardTerminalPort;
  final bool enableCardReader;
  final bool enableUpiQr;
  final String upiMerchantVpa;
  final String syncApiUrl;
  final bool autoSyncOrders;
  final int autoRefreshInterval; // in seconds
  final int inactivityTimeout; // in minutes
  final bool requirePinForRefunds;
  final bool requirePinForVoids;

  const POSSettingsState({
    this.offlineStandalone = true,
    this.autoPrintReceipt = false,
    this.enableGuestScreen = true,
    this.kitchenPrinterIp = '192.168.1.185',
    this.counterPrinterIp = '192.168.1.186',
    this.billingPrinterIp = 'USB EPSON TM-T88VI',
    this.cardTerminalIp = '192.168.1.190',
    this.cardTerminalPort = '9100',
    this.enableCardReader = true,
    this.enableUpiQr = true,
    this.upiMerchantVpa = 'orderlyy@upi',
    this.syncApiUrl = 'http://localhost:3001/api/v1',
    this.autoSyncOrders = true,
    this.autoRefreshInterval = 30,
    this.inactivityTimeout = 5,
    this.requirePinForRefunds = true,
    this.requirePinForVoids = true,
  });

  POSSettingsState copyWith({
    bool? offlineStandalone,
    bool? autoPrintReceipt,
    bool? enableGuestScreen,
    String? kitchenPrinterIp,
    String? counterPrinterIp,
    String? billingPrinterIp,
    String? cardTerminalIp,
    String? cardTerminalPort,
    bool? enableCardReader,
    bool? enableUpiQr,
    String? upiMerchantVpa,
    String? syncApiUrl,
    bool? autoSyncOrders,
    int? autoRefreshInterval,
    int? inactivityTimeout,
    bool? requirePinForRefunds,
    bool? requirePinForVoids,
  }) {
    return POSSettingsState(
      offlineStandalone: offlineStandalone ?? this.offlineStandalone,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      enableGuestScreen: enableGuestScreen ?? this.enableGuestScreen,
      kitchenPrinterIp: kitchenPrinterIp ?? this.kitchenPrinterIp,
      counterPrinterIp: counterPrinterIp ?? this.counterPrinterIp,
      billingPrinterIp: billingPrinterIp ?? this.billingPrinterIp,
      cardTerminalIp: cardTerminalIp ?? this.cardTerminalIp,
      cardTerminalPort: cardTerminalPort ?? this.cardTerminalPort,
      enableCardReader: enableCardReader ?? this.enableCardReader,
      enableUpiQr: enableUpiQr ?? this.enableUpiQr,
      upiMerchantVpa: upiMerchantVpa ?? this.upiMerchantVpa,
      syncApiUrl: syncApiUrl ?? this.syncApiUrl,
      autoSyncOrders: autoSyncOrders ?? this.autoSyncOrders,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
      inactivityTimeout: inactivityTimeout ?? this.inactivityTimeout,
      requirePinForRefunds: requirePinForRefunds ?? this.requirePinForRefunds,
      requirePinForVoids: requirePinForVoids ?? this.requirePinForVoids,
    );
  }
}

class POSSettingsNotifier extends StateNotifier<POSSettingsState> {
  POSSettingsNotifier() : super(const POSSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = POSSettingsState(
        offlineStandalone: prefs.getBool('offline_standalone') ?? true,
        autoPrintReceipt: prefs.getBool('auto_print_receipt') ?? false,
        enableGuestScreen: prefs.getBool('enable_guest_screen') ?? true,
        kitchenPrinterIp: prefs.getString('kitchen_printer_ip') ?? '192.168.1.185',
        counterPrinterIp: prefs.getString('counter_printer_ip') ?? '192.168.1.186',
        billingPrinterIp: prefs.getString('billing_printer_ip') ?? 'USB EPSON TM-T88VI',
        cardTerminalIp: prefs.getString('card_terminal_ip') ?? '192.168.1.190',
        cardTerminalPort: prefs.getString('card_terminal_port') ?? '9100',
        enableCardReader: prefs.getBool('enable_card_reader') ?? true,
        enableUpiQr: prefs.getBool('enable_upi_qr') ?? true,
        upiMerchantVpa: prefs.getString('upi_merchant_vpa') ?? 'orderlyy@upi',
        syncApiUrl: prefs.getString('sync_api_url') ?? 'http://localhost:3001/api/v1',
        autoSyncOrders: prefs.getBool('auto_sync_orders') ?? true,
        autoRefreshInterval: prefs.getInt('auto_refresh_interval') ?? 30,
        inactivityTimeout: prefs.getInt('inactivity_timeout') ?? 5,
        requirePinForRefunds: prefs.getBool('require_pin_for_refunds') ?? true,
        requirePinForVoids: prefs.getBool('require_pin_for_voids') ?? true,
      );
    } catch (_) {}
  }

  Future<void> saveSettings(POSSettingsState newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_standalone', newSettings.offlineStandalone);
      await prefs.setBool('auto_print_receipt', newSettings.autoPrintReceipt);
      await prefs.setBool('enable_guest_screen', newSettings.enableGuestScreen);
      await prefs.setString('kitchen_printer_ip', newSettings.kitchenPrinterIp);
      await prefs.setString('counter_printer_ip', newSettings.counterPrinterIp);
      await prefs.setString('billing_printer_ip', newSettings.billingPrinterIp);
      await prefs.setString('card_terminal_ip', newSettings.cardTerminalIp);
      await prefs.setString('card_terminal_port', newSettings.cardTerminalPort);
      await prefs.setBool('enable_card_reader', newSettings.enableCardReader);
      await prefs.setBool('enable_upi_qr', newSettings.enableUpiQr);
      await prefs.setString('upi_merchant_vpa', newSettings.upiMerchantVpa);
      await prefs.setString('sync_api_url', newSettings.syncApiUrl);
      await prefs.setBool('auto_sync_orders', newSettings.autoSyncOrders);
      await prefs.setInt('auto_refresh_interval', newSettings.autoRefreshInterval);
      await prefs.setInt('inactivity_timeout', newSettings.inactivityTimeout);
      await prefs.setBool('require_pin_for_refunds', newSettings.requirePinForRefunds);
      await prefs.setBool('require_pin_for_voids', newSettings.requirePinForVoids);
      state = newSettings;
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_standalone');
      await prefs.remove('auto_print_receipt');
      await prefs.remove('enable_guest_screen');
      await prefs.remove('kitchen_printer_ip');
      await prefs.remove('counter_printer_ip');
      await prefs.remove('billing_printer_ip');
      await prefs.remove('card_terminal_ip');
      await prefs.remove('card_terminal_port');
      await prefs.remove('enable_card_reader');
      await prefs.remove('enable_upi_qr');
      await prefs.remove('upi_merchant_vpa');
      await prefs.remove('sync_api_url');
      await prefs.remove('auto_refresh_interval');
      await prefs.remove('inactivity_timeout');
      await prefs.remove('require_pin_for_refunds');
      await prefs.remove('require_pin_for_voids');
      state = const POSSettingsState();
    } catch (_) {}
  }
}

final posSettingsProvider = StateNotifierProvider<POSSettingsNotifier, POSSettingsState>((ref) {
  return POSSettingsNotifier();
});

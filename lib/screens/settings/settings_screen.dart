import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';
import '../../providers/providers.dart';

// ─── Settings Screen ────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedIndex = 0;
  String _appVersion = '1.0.0';
  String _buildNumber = '1';

  final List<Map<String, dynamic>> _settingsSections = [
    {'title': 'Terminal Settings', 'icon': Icons.tablet_android},
    {'title': 'Receipt Printers', 'icon': Icons.print_outlined},
    if (kDebugMode) ...[
      {'title': 'Payment Integrations', 'icon': Icons.credit_card_outlined},
      {'title': 'Database & Cloud Sync', 'icon': Icons.sync},
      {'title': 'Staff Permissions', 'icon': Icons.lock_open_outlined},
    ],
  ];

  late TextEditingController _kitchenPrinterIpCtrl;
  late TextEditingController _counterPrinterIpCtrl;
  late TextEditingController _billingPrinterIpCtrl;
  late TextEditingController _cardTerminalIpCtrl;
  late TextEditingController _cardTerminalPortCtrl;
  late TextEditingController _upiMerchantVpaCtrl;
  late TextEditingController _syncApiUrlCtrl;

  bool _offlineStandalone = true;
  bool _autoPrintReceipt = false;
  bool _enableGuestScreen = true;
  bool _enableCardReader = true;
  bool _enableUpiQr = true;
  bool _autoSyncOrders = true;
  int _autoRefreshInterval = 30;
  int _inactivityTimeout = 5;
  bool _requirePinForRefunds = true;
  bool _requirePinForVoids = true;

  @override
  void initState() {
    super.initState();
    _kitchenPrinterIpCtrl = TextEditingController();
    _counterPrinterIpCtrl = TextEditingController();
    _billingPrinterIpCtrl = TextEditingController();
    _cardTerminalIpCtrl = TextEditingController();
    _cardTerminalPortCtrl = TextEditingController();
    _upiMerchantVpaCtrl = TextEditingController();
    _syncApiUrlCtrl = TextEditingController();
    _loadAppVersion();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = ref.read(posSettingsProvider);
      _updateControllers(initial);
    });
  }

  void _updateControllers(POSSettingsState state) {
    setState(() {
      _offlineStandalone = state.offlineStandalone;
      _autoPrintReceipt = state.autoPrintReceipt;
      _enableGuestScreen = state.enableGuestScreen;
      _kitchenPrinterIpCtrl.text = state.kitchenPrinterIp;
      _counterPrinterIpCtrl.text = state.counterPrinterIp;
      _billingPrinterIpCtrl.text = state.billingPrinterIp;
      _cardTerminalIpCtrl.text = state.cardTerminalIp;
      _cardTerminalPortCtrl.text = state.cardTerminalPort;
      _upiMerchantVpaCtrl.text = state.upiMerchantVpa;
      _syncApiUrlCtrl.text = state.syncApiUrl;
      _enableCardReader = state.enableCardReader;
      _enableUpiQr = state.enableUpiQr;
      _autoSyncOrders = state.autoSyncOrders;
      _autoRefreshInterval = state.autoRefreshInterval;
      _inactivityTimeout = state.inactivityTimeout;
      _requirePinForRefunds = state.requirePinForRefunds;
      _requirePinForVoids = state.requirePinForVoids;
    });
  }

  @override
  void dispose() {
    _kitchenPrinterIpCtrl.dispose();
    _counterPrinterIpCtrl.dispose();
    _billingPrinterIpCtrl.dispose();
    _cardTerminalIpCtrl.dispose();
    _cardTerminalPortCtrl.dispose();
    _upiMerchantVpaCtrl.dispose();
    _syncApiUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;

    ref.listen<POSSettingsState>(posSettingsProvider, (previous, next) {
      _updateControllers(next);
    });

    final settingsState = ref.watch(posSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top bar
          Container(
            height: isVertical ? null : 72.h,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: isVertical ? 12.h : 0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: isVertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('POS Terminal Settings', style: AppTextStyles.titleLarge),
                      Gap(4.h),
                      const StatusChip(label: 'OFFLINE MODE COMPATIBLE', color: AppColors.success),
                    ],
                  )
                : Row(
                    children: [
                      Text('POS Terminal Settings', style: AppTextStyles.headlineMedium),
                      const Spacer(),
                      const StatusChip(label: 'OFFLINE MODE COMPATIBLE', color: AppColors.success),
                    ],
                  ),
          ),
          // Settings Layout
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isVertical ? 16.r : 24.r),
              child: isVertical
                  ? Column(
                      children: [
                        // Left sidebar categories
                        Expanded(
                          flex: 40,
                          child: _buildSidebar(isVertical),
                        ),
                        Gap(16.h),
                        // Right details panel
                        Expanded(
                          flex: 60,
                          child: _buildDetailsPanel(isVertical, settingsState),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left sidebar categories
                        Expanded(
                          flex: 4,
                          child: _buildSidebar(isVertical),
                        ),
                        Gap(24.w),
                        // Right details panel
                        Expanded(
                          flex: 6,
                          child: _buildDetailsPanel(isVertical, settingsState),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isVertical) {
    return POSCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isVertical ? 12.r : 16.r),
            child: Text('Configurations', style: AppTextStyles.titleLarge),
          ),
          Container(height: 1.h, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              itemCount: _settingsSections.length,
              separatorBuilder: (_, _) => Divider(color: AppColors.borderSubtle, height: 1),
              itemBuilder: (context, index) {
                final section = _settingsSections[index];
                final isSelected = _selectedIndex == index;
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    onTap: () => setState(() => _selectedIndex = index),
                    selected: isSelected,
                    selectedTileColor: AppColors.surfaceVariant,
                    leading: Icon(
                      section['icon'] as IconData,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      section['title'] as String,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18.sp,
                      color: isSelected ? AppColors.primary : AppColors.textDisabled,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(bool isVertical, POSSettingsState settingsState) {
    return POSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _settingsSections[_selectedIndex]['title'] as String,
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          Gap(16.h),
          Expanded(
            child: _buildDetailsContent(_selectedIndex),
          ),
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(
                onPressed: () async {
                  final confirm = await showPOSConfirmationDialog(
                    context: context,
                    title: 'Reset Settings?',
                    description: 'Are you sure you want to discard all changes and restore default terminal profiles?',
                    confirmText: 'RESET TO DEFAULTS',
                    isDanger: true,
                    icon: Icons.refresh,
                  );
                  if (confirm == true) {
                    await ref.read(posSettingsProvider.notifier).resetToDefaults();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings restored to factory defaults.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                text: 'RESET',
                fullWidth: false,
              ),
              Gap(16.w),
              PrimaryButton(
                onPressed: () async {
                  final newSettings = settingsState.copyWith(
                    offlineStandalone: _offlineStandalone,
                    autoPrintReceipt: _autoPrintReceipt,
                    enableGuestScreen: _enableGuestScreen,
                    kitchenPrinterIp: _kitchenPrinterIpCtrl.text,
                    counterPrinterIp: _counterPrinterIpCtrl.text,
                    billingPrinterIp: _billingPrinterIpCtrl.text,
                    cardTerminalIp: _cardTerminalIpCtrl.text,
                    cardTerminalPort: _cardTerminalPortCtrl.text,
                    enableCardReader: _enableCardReader,
                    enableUpiQr: _enableUpiQr,
                    upiMerchantVpa: _upiMerchantVpaCtrl.text,
                    syncApiUrl: _syncApiUrlCtrl.text,
                    autoSyncOrders: _autoSyncOrders,
                    autoRefreshInterval: _autoRefreshInterval,
                    inactivityTimeout: _inactivityTimeout,
                    requirePinForRefunds: _requirePinForRefunds,
                    requirePinForVoids: _requirePinForVoids,
                  );
                  await ref.read(posSettingsProvider.notifier).saveSettings(newSettings);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                text: 'SAVE SETTINGS',
                fullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(int index) {
    switch (index) {
      case 0:
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: [
            _buildSettingSwitch(
              title: 'Offline Standalone Mode',
              subtitle: 'Allow printing receipts and kitchen tickets when internet goes down.',
              value: _offlineStandalone,
              onChanged: (val) => setState(() => _offlineStandalone = val),
            ),
            _buildSettingSwitch(
              title: 'Auto Print Receipt',
              subtitle: 'Automatically print receipt immediately on successful payment.',
              value: _autoPrintReceipt,
              onChanged: (val) => setState(() => _autoPrintReceipt = val),
            ),
            _buildSettingSwitch(
              title: 'Enable Guest Screen',
              subtitle: 'Activate the guest display screen showing order summary and QR.',
              value: _enableGuestScreen,
              onChanged: (val) => setState(() => _enableGuestScreen = val),
            ),
          ],
        );
      case 1:
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: [
            _buildSettingTextField(
              title: 'Kitchen Printer (Receipt-KDS)',
              subtitle: 'Network IP Address or Hostname',
              controller: _kitchenPrinterIpCtrl,
            ),
            _buildSettingTextField(
              title: 'Counter Bar Printer',
              subtitle: 'Network IP Address or Hostname',
              controller: _counterPrinterIpCtrl,
            ),
            _buildSettingTextField(
              title: 'Billing Receipt Printer',
              subtitle: 'Network IP Address / USB Printer Name',
              controller: _billingPrinterIpCtrl,
            ),
          ],
        );
      case 2:
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: [
            _buildSettingSwitch(
              title: 'Enable Card Reader',
              subtitle: 'Integrate physical card swipe/tap terminal for payments.',
              value: _enableCardReader,
              onChanged: (val) => setState(() => _enableCardReader = val),
            ),
            if (_enableCardReader) ...[
              _buildSettingTextField(
                title: 'Card Reader IP Address',
                subtitle: 'Network IP Address of the PX-400 device',
                controller: _cardTerminalIpCtrl,
              ),
              _buildSettingTextField(
                title: 'Card Reader Port',
                subtitle: 'Connection port (default: 9100)',
                controller: _cardTerminalPortCtrl,
              ),
            ],
            Gap(16.h),
            _buildSettingSwitch(
              title: 'Enable UPI / QR Code Scanner',
              subtitle: 'Display dynamic UPI payment QR codes to guests.',
              value: _enableUpiQr,
              onChanged: (val) => setState(() => _enableUpiQr = val),
            ),
            if (_enableUpiQr)
              _buildSettingTextField(
                title: 'UPI Merchant VPA',
                subtitle: 'Virtual Payment Address (e.g. restaurant@upi)',
                controller: _upiMerchantVpaCtrl,
              ),
          ],
        );
      case 3:
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: [
            _buildSettingTextField(
              title: 'Sync API Base URL',
              subtitle: 'Orderlyy Cloud Backend Service URL',
              controller: _syncApiUrlCtrl,
            ),
            _buildSettingSwitch(
              title: 'Auto-sync Active Orders',
              subtitle: 'Keep kitchen tickets and payments synced in real time.',
              value: _autoSyncOrders,
              onChanged: (val) => setState(() => _autoSyncOrders = val),
            ),
            _buildSettingDropdown<int>(
              title: 'Floor Refresh Interval',
              subtitle: 'Time between automatic grid status fetches',
              value: _autoRefreshInterval,
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 Seconds')),
                DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                DropdownMenuItem(value: 60, child: Text('60 Seconds')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _autoRefreshInterval = val);
              },
            ),
          ],
        );
      case 4:
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: [
            _buildSettingSwitch(
              title: 'Require Manager PIN for Voids',
              subtitle: 'Server/Cashier cannot void active orders without manager override.',
              value: _requirePinForVoids,
              onChanged: (val) => setState(() => _requirePinForVoids = val),
            ),
            _buildSettingSwitch(
              title: 'Require Manager PIN for Refunds',
              subtitle: 'Prompt for manager PIN code to process billing refunds.',
              value: _requirePinForRefunds,
              onChanged: (val) => setState(() => _requirePinForRefunds = val),
            ),
            _buildSettingDropdown<int>(
              title: 'Inactivity Lock Timeout',
              subtitle: 'Auto-lock screen and prompt for PIN after idle period',
              value: _inactivityTimeout,
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 Minutes')),
                DropdownMenuItem(value: 5, child: Text('5 Minutes')),
                DropdownMenuItem(value: 10, child: Text('10 Minutes')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _inactivityTimeout = val);
              },
            ),
            Gap(24.h),
            const Divider(color: AppColors.border),
            Gap(16.h),
            Text('About Orderlyy POS', style: AppTextStyles.titleMedium),
            Gap(8.h),
            _buildInfoRow('App Version', '$_appVersion (Build $_buildNumber)'),
            _buildInfoRow('Platform', kIsWeb ? 'Web / Browser' : defaultTargetPlatform.name),
            _buildInfoRow('Terminal Build Mode', kDebugMode ? 'Debug / Development' : 'Release'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Gap(4.h),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTextField({
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          Gap(4.h),
          Text(subtitle, style: AppTextStyles.bodySmall),
          Gap(8.h),
          SizedBox(
            height: 48.h,
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingDropdown<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Gap(4.h),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          SizedBox(
            height: 48.h,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

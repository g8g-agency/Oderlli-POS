import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _settingsSections = [
    {'title': 'Terminal Settings', 'icon': Icons.tablet_android},
    {'title': 'Receipt Printers', 'icon': Icons.print_outlined},
    {'title': 'Payment Integrations', 'icon': Icons.credit_card_outlined},
    {'title': 'Database & Cloud Sync', 'icon': Icons.sync},
    {'title': 'Staff Permissions', 'icon': Icons.lock_open_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;

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
                          child: _buildDetailsPanel(isVertical),
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
                          child: _buildDetailsPanel(isVertical),
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
                return ListTile(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(bool isVertical) {
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
                onPressed: () {},
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
          children: [
            _buildSettingSwitch(
              title: 'Offline Standalone Mode',
              subtitle: 'Allow printing receipts and kitchen tickets when internet goes down.',
              value: true,
            ),
            _buildSettingSwitch(
              title: 'Auto Print Receipt',
              subtitle: 'Automatically print receipt immediately on successful payment.',
              value: false,
            ),
            _buildSettingSwitch(
              title: 'Enable Guest Screen',
              subtitle: 'Activate the guest display screen showing order summary and QR.',
              value: true,
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            _buildSettingItem(
              title: 'Kitchen Printer (Receipt-KDS)',
              value: '192.168.1.185 (Connected)',
            ),
            _buildSettingItem(
              title: 'Counter Bar Printer',
              value: '192.168.1.186 (Connected)',
            ),
            _buildSettingItem(
              title: 'Billing Receipt Printer',
              value: 'USB EPSON TM-T88VI',
            ),
          ],
        );
      default:
        return Center(
          child: EmptyStateWidget(
            icon: Icons.settings,
            title: 'Under Construction',
            description: 'This setting section is mock and currently under development.',
          ),
        );
    }
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
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
            onChanged: (val) {},
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String value,
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
                Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_note, color: AppColors.textSecondary),
            style: IconButton.styleFrom(
              minimumSize: Size(48.r, 48.r),
            ),
          ),
        ],
      ),
    );
  }
}

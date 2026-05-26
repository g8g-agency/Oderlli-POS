import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';

class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Shift & Cash Drawer',
                              style: AppTextStyles.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const StatusChip(label: 'SHIFT ACTIVE', color: AppColors.success),
                        ],
                      ),
                      Gap(4.h),
                      Text(
                        'Cashier: Alexander',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text('Shift & Cash Drawer', style: AppTextStyles.headlineMedium),
                      Gap(16.w),
                      const StatusChip(label: 'SHIFT ACTIVE', color: AppColors.success),
                      const Spacer(),
                      Text(
                        'Cashier: Alexander',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
          // Shift Manager Layout
          Expanded(
            child: isVertical
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeftContent(context, isVertical),
                        Gap(20.h),
                        _buildRightContent(isVertical),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left panel: Stats and Actions (flex 6)
                        Expanded(
                          flex: 6,
                          child: SingleChildScrollView(
                            child: _buildLeftContent(context, isVertical),
                          ),
                        ),
                        Gap(24.w),
                        // Right panel: Activity Log (flex 4)
                        Expanded(
                          flex: 4,
                          child: _buildRightContent(isVertical),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftContent(BuildContext context, bool isVertical) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Active Drawer Summary'),
        Gap(16.h),
        // Stats Grid
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Opening Cash',
                value: '£150.00',
                icon: Icons.vpn_key_outlined,
                color: AppColors.neutral,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: MetricTile(
                label: 'Net Cash Sales',
                value: '£435.50',
                icon: Icons.add_chart_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Payouts / Payout',
                value: '-£45.00',
                icon: Icons.outbox_outlined,
                color: AppColors.loss,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: MetricTile(
                label: 'Expected Cash',
                value: '£540.50',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.cash,
              ),
            ),
          ],
        ),
        Gap(32.h),
        SectionHeader(title: 'Shift Actions'),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: () {},
                text: 'PAYOUT / EXPENSE',
                icon: Icons.remove_circle_outline,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: SecondaryButton(
                onPressed: () {},
                text: 'CASH DROP / IN',
                icon: Icons.add_circle_outline,
              ),
            ),
          ],
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: () {},
                text: 'PRINT X REPORT',
                icon: Icons.print,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: DangerButton(
                onPressed: () async {
                  final confirm = await showPOSConfirmationDialog(
                    context: context,
                    title: 'Close Active Shift?',
                    description: 'Are you sure you want to close and lock the active shift? This will print the final Z-Report, log out the cashier, and open the cash drawer for terminal audit.',
                    confirmText: 'CLOSE SHIFT',
                    isDanger: true,
                    icon: Icons.lock,
                  );
                  if (confirm == true) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shift closed successfully. Cash drawer opened.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                text: 'CLOSE SHIFT & LOCK',
                icon: Icons.lock,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightContent(bool isVertical) {
    final listContent = [
      const _ActivityLogItem(
        time: '08:30 PM',
        type: 'Cash Out / Payout',
        desc: 'Supplier pay (Fresh veg)',
        amount: '-£45.00',
        color: AppColors.loss,
      ),
      const _ActivityLogItem(
        time: '06:12 PM',
        type: 'Cash Sale',
        desc: 'Bill #23048',
        amount: '+£84.20',
        color: AppColors.success,
      ),
      const _ActivityLogItem(
        time: '04:00 PM',
        type: 'Shift Opened',
        desc: 'Opening drawer verify',
        amount: '£150.00',
        color: AppColors.neutral,
      ),
    ];

    return POSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Drawer Activity Log', style: AppTextStyles.titleLarge),
          Gap(16.h),
          isVertical
              ? Column(
                  children: listContent,
                )
              : Expanded(
                  child: ListView(
                    children: listContent,
                  ),
                ),
        ],
      ),
    );
  }
}

class _ActivityLogItem extends StatelessWidget {
  const _ActivityLogItem({
    required this.time,
    required this.type,
    required this.desc,
    required this.amount,
    required this.color,
  });

  final String time;
  final String type;
  final String desc;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: AppTextStyles.titleMedium),
              Gap(2.h),
              Text('$time · $desc', style: AppTextStyles.bodySmall),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

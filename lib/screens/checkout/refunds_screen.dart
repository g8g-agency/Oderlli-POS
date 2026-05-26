import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/utils/currency_formatter.dart';

class RefundsScreen extends StatefulWidget {
  const RefundsScreen({super.key});

  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  String _receiptId = '';
  bool _searched = false;

  void _onSearch() {
    if (_receiptId.isNotEmpty) {
      setState(() {
        _searched = true;
      });
    }
  }

  void _onRefund() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refund Successful! Cash drawer opened.'), backgroundColor: AppColors.success),
    );
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Issue Billing Refund', style: AppTypography.headlineMedium),
          Gap(AppSpacing.lg.h),
          // Receipt search input
          POSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locate Original Bill Receipt', style: AppTypography.titleLarge),
                Gap(AppSpacing.md.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _receiptId = val),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.receipt),
                          hintText: 'Enter Receipt ID (e.g. #23048)...',
                        ),
                      ),
                    ),
                    Gap(AppSpacing.md.w),
                    SizedBox(
                      height: 52.h,
                      child: OutlinedButton(
                        onPressed: _receiptId.isEmpty ? null : _onSearch,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                          ),
                        ),
                        child: Text('SEARCH', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Gap(AppSpacing.lg.h),
          // Search results
          Expanded(
            child: _searched
                ? POSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Bill #$_receiptId Details',
                                        style: AppTypography.titleLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const StatusChip(label: 'PAID - VISA', color: AppColors.success),
                                  ],
                                ),
                                Gap(AppSpacing.md.h),
                                Text('Paid: ${CurrencyFormatter.format(4230.0)} · Date: Today 12:45 PM · Server: Sarah', style: AppTypography.bodySmall),
                                Gap(AppSpacing.lg.h),
                                Container(height: 1.h, color: AppColors.border),
                                Gap(AppSpacing.md.h),
                                Text('Refund Reason Selection', style: AppTypography.titleMedium),
                                Gap(AppSpacing.sm.h),
                                Wrap(
                                  spacing: AppSpacing.xs.w,
                                  runSpacing: AppSpacing.xs.h,
                                  children: const [
                                    _ReasonChip(label: 'Order mistake'),
                                    _ReasonChip(label: 'Food quality'),
                                    _ReasonChip(label: 'Customer changed mind'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Gap(AppSpacing.md.h),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go('/checkout'),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: Size(48.r, 48.r),
                              ),
                            ),
                            Gap(AppSpacing.md.w),
                            Expanded(
                              child: DangerButton(
                                onPressed: _onRefund,
                                text: 'APPROVE & ISSUE VISA REFUND',
                                icon: Icons.assignment_return,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: EmptyStateWidget(
                      icon: Icons.find_in_page_outlined,
                      title: 'Search Transaction',
                      description: 'Enter a valid receipt identifier above to review transaction details and process payouts.',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
      backgroundColor: AppColors.surfaceVariant,
      onPressed: () {},
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
      ),
      side: const BorderSide(color: AppColors.border),
      visualDensity: VisualDensity.standard,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w, vertical: AppSpacing.sm.h),
    );
  }
}

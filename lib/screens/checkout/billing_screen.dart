import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../core/services/print_service.dart';
import '../../core/extensions/extensions.dart';
import '../../providers/inactivity_provider.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billState = ref.watch(activeBillProvider);

    if (billState == null || !billState.paymentsHydrated) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final totalAmount = billState.total;
    final totalPaid = billState.amountPaid;
    final remainingAmount = billState.amountRemaining;
    final percentPaid = totalAmount > 0 ? (totalPaid / totalAmount).clamp(0.0, 1.0) : 0.0;

    final statusColor = billState.isPaid
        ? AppColors.success
        : billState.isPartiallyPaid
            ? AppColors.info
            : AppColors.statusPending;

    final isVertical = context.isVerticalLayout;

    final billingBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Screen title bar ────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg.r, AppSpacing.radiusXL.r, AppSpacing.lg.r, 0),
          child: Text('Active Bill Overview', style: AppTypography.headlineMedium),
        ),
        Gap(AppSpacing.md.h),

        // ── 1. Settlement Status Banner ──────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.r),
          child: POSCard(
            borderColor: statusColor.withValues(alpha: 0.3),
            backgroundColor: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settlement Status', style: AppTypography.titleSmall),
                        Gap(AppSpacing.xxs.h),
                        Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.h,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Gap(AppSpacing.xs.w),
                            Text(
                              billState.settlementStatus.toUpperCase(),
                              style: AppTypography.titleLarge.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Remaining', style: AppTypography.titleSmall),
                        Gap(AppSpacing.xxs.h),
                        Text(
                          remainingAmount.asCurrency,
                          style: AppTypography.priceTag.copyWith(
                            color: remainingAmount <= 0.01 ? AppColors.success : AppColors.primary,
                            fontSize: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Gap(AppSpacing.md.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull.r),
                  child: LinearProgressIndicator(
                    value: percentPaid,
                    minHeight: AppSpacing.xs.h,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                Gap(AppSpacing.sm.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid: ${totalPaid.asCurrency}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      'Total Bill: ${totalAmount.asCurrency}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Gap(AppSpacing.md.h),

        // ── 2. Service Charge & Discount Adjusters ───────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.r),
          child: POSCard(
            child: isVertical
                ? Column(
                    children: [
                      _buildServiceChargeSection(ref, billState),
                      Gap(AppSpacing.lg.h),
                      _buildDiscountSection(ref, billState, context),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildServiceChargeSection(ref, billState),
                      ),
                      Gap(AppSpacing.lg.w),
                      Expanded(
                        child: _buildDiscountSection(ref, billState, context),
                      ),
                    ],
                  ),
          ),
        ),
        Gap(AppSpacing.md.h),

        // ── 3. Payment History Log ────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.r),
          child: SizedBox(
            height: isVertical ? 220.h : 280.h,
            child: _buildPaymentHistoryLogCard(billState),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(child: billingBody),
        ),
        Gap(AppSpacing.md.h),

        // ── 4. Bottom Action Row ──────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg.r, 0, AppSpacing.lg.r, AppSpacing.lg.r),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: billState.isPaid
                      ? null
                      : () => context.go('/checkout/split-billing'),
                  text: 'SPLIT BILL',
                  icon: Icons.call_split,
                ),
              ),
              Gap(AppSpacing.md.w),
              Expanded(
                child: PrimaryButton(
                  onPressed: billState.isPaid
                      ? () async {
                          const storage = FlutterSecureStorage();
                          final cashierName = await storage.read(key: 'staff_name') ??
                              ref.read(authProvider).user?.name ??
                              'Cashier';

                          final branchConfig = ref.read(branchConfigProvider);
                          final receiptOrder = billState.order.copyWith(
                            discountPercent: billState.discountPercent,
                          );

                          final request = ReceiptRequest(
                            order: receiptOrder,
                            restaurantName: branchConfig.restaurantName,
                            branchName: branchConfig.branchName,
                            cashierName: cashierName,
                            paymentMethod: billState.lastPaymentMethod,
                            amountPaid: billState.amountPaid,
                            gstin: branchConfig.gstin,
                            fssai: branchConfig.fssai,
                          );

                          try {
                            await ref.read(printServiceProvider).printReceipt(request);
                            ref.read(inactivityServiceProvider).resetTimer();
                            ref.read(activeTableIdProvider.notifier).state = null;
                            if (!context.mounted) return;
                            context.showSuccessSnack('Session settled! Receipt printed.');
                            context.go('/floor');
                          } on PrinterException catch (e) {
                            ref.read(activeTableIdProvider.notifier).state = null;
                            if (!context.mounted) return;
                            context.showErrorSnack('Session settled! Print failed: ${e.message}');
                            context.go('/floor');
                          } catch (e) {
                            ref.read(activeTableIdProvider.notifier).state = null;
                            if (!context.mounted) return;
                            context.showErrorSnack('Session settled! Printing failed: $e');
                            context.go('/floor');
                          }
                        }
                      : () => context.go('/checkout/payment'),
                  text: billState.isPaid ? 'COMPLETE SESSION' : 'PROCEED TO PAY',
                  icon: billState.isPaid ? Icons.check_circle_outline : Icons.payment,
                  backgroundColor: billState.isPaid ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildServiceChargeSection(WidgetRef ref, ActiveBillState billState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Charge (adjustable)', style: AppTypography.titleSmall),
        Gap(AppSpacing.xs.h),
        Row(
          children: [
            _buildPresetChip(
              ref,
              'No SC',
              0,
              billState.serviceChargePercent,
              (val) => ref.read(activeBillProvider.notifier).applyServiceCharge(val),
            ),
            Gap(AppSpacing.xs.w),
            _buildPresetChip(
              ref,
              '10%',
              10,
              billState.serviceChargePercent,
              (val) => ref.read(activeBillProvider.notifier).applyServiceCharge(val),
            ),
            Gap(AppSpacing.xs.w),
            _buildPresetChip(
              ref,
              '15%',
              15,
              billState.serviceChargePercent,
              (val) => ref.read(activeBillProvider.notifier).applyServiceCharge(val),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleDiscountTap(
    WidgetRef ref,
    ActiveBillState billState,
    double percent,
    BuildContext context,
  ) async {
    // Discounts <= 20% apply immediately — no approval needed
    if (percent <= 20.0) {
      ref.read(activeBillProvider.notifier).applyDiscount(percent);
      return;
    }

    // Discounts > 20% require manager PIN
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagerOverrideDialog(
        actionName: '${percent.toStringAsFixed(0)}% Discount on '
            'Order ${billState.order.orderNumber ?? billState.order.id}',
      ),
    );

    if (approved != true) return;

    ref.read(activeBillProvider.notifier).applyDiscount(percent);

    final authState = ref.read(authProvider);
    ref.read(activeBillProvider.notifier).auditManagerOverride(
          discountPercent: percent,
          approvedByPin: '****',
          cashierName: authState.user?.name ?? 'Unknown',
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Manager approved ${percent.toStringAsFixed(0)}% discount.',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDiscountSection(
    WidgetRef ref,
    ActiveBillState billState,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apply Discount', style: AppTypography.titleSmall),
        Gap(AppSpacing.xs.h),
        Row(
          children: [
            _buildPresetChip(
              ref,
              '0%',
              0,
              billState.discountPercent,
              (val) => _handleDiscountTap(ref, billState, val, context),
            ),
            Gap(AppSpacing.xs.w),
            _buildPresetChip(
              ref,
              '10%',
              10,
              billState.discountPercent,
              (val) => _handleDiscountTap(ref, billState, val, context),
            ),
            Gap(AppSpacing.xs.w),
            _buildPresetChip(
              ref,
              '20%',
              20,
              billState.discountPercent,
              (val) => _handleDiscountTap(ref, billState, val, context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryLogCard(ActiveBillState billState) {
    return POSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Log / History', style: AppTypography.titleMedium),
          Gap(AppSpacing.sm.h),
          Expanded(
            child: billState.payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 36.sp, color: AppColors.textDisabled),
                        Gap(AppSpacing.xs.h),
                        Text(
                          'No payments recorded yet.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: billState.payments.length,
                    separatorBuilder: (context, index) => Divider(color: AppColors.borderSubtle, height: AppSpacing.sm.h),
                    itemBuilder: (context, i) {
                      final p = billState.payments[i];
                      final isCash = p.method.toLowerCase() == 'cash';
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.surfaceVariant,
                            radius: AppSpacing.md.r,
                            child: Icon(
                              isCash ? Icons.money : Icons.credit_card,
                              size: 16.sp,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Gap(AppSpacing.sm.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.method} Payment',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'By ${p.waiterName} • ${p.timestamp.timeLabel}',
                                style: AppTypography.labelSmall,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            p.amount.asCurrency,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    WidgetRef ref,
    String label,
    double value,
    double currentValue,
    ValueChanged<double> onChanged,
  ) {
    final isSelected = value == currentValue;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 48.h),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';

/// ─── Orderlli POS · Checkout Shell ──────────────────────────────────────────
///
/// Nested Shell layout for the Checkout/Payment flow.
/// Persistently displays the receipt summary on the left (40% width)
/// while rendering the active step (Billing, Payments, Split, Refunds) on the right.
class CheckoutShell extends ConsumerWidget {
  const CheckoutShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billState = ref.watch(activeBillProvider);

    if (billState == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final order = billState.order;
    final subtotal = billState.subtotal;
    final discount = billState.discountAmount;
    final tax = billState.taxAmount;
    final serviceCharge = billState.serviceChargeAmount;
    final total = billState.total;
    final billItems = order.items;

    final shortOrderId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final isVertical = context.isVerticalLayout;

    if (isVertical) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              color: AppColors.sidebarBg,
              child: ExpansionTile(
                iconColor: AppColors.textPrimary,
                collapsedIconColor: AppColors.textPrimary,
                title: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(activeTableIdProvider.notifier).state = null;
                        context.go('/floor');
                      },
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${order.tableNumber} Receipt',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Total: ${total.asCurrency} · Order #$shortOrderId',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    height: 280.h,
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: POSCard(
                      child: _buildReceiptContent(
                        billItems,
                        subtotal,
                        discount,
                        tax,
                        serviceCharge,
                        total,
                        billState,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Left Side: Persistent Bill Receipt Summary (Fixed width with safety limits) ────────────────────
          Container(
            constraints: BoxConstraints(
              minWidth: 280.w,
              maxWidth: 360.w,
            ),
            color: AppColors.sidebarBg,
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Back Button
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(activeTableIdProvider.notifier).state = null;
                        context.go('/floor');
                      },
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    Gap(16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Table ${order.tableNumber} Receipt', style: AppTextStyles.titleLarge),
                        Text('Order #$shortOrderId', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
                Gap(16.h),
                // Bill Items List
                Expanded(
                  child: POSCard(
                    child: _buildReceiptContent(
                      billItems,
                      subtotal,
                      discount,
                      tax,
                      serviceCharge,
                      total,
                      billState,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider line
          Container(width: 1.w, color: AppColors.border),
          // ── Right Side: Sub-views (Billing, Payments, Split, etc.) ────────
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent(
    List<dynamic> billItems,
    double subtotal,
    double discount,
    double tax,
    double serviceCharge,
    double total,
    dynamic billState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ordered Items', style: AppTextStyles.titleMedium),
        Gap(12.h),
        Expanded(
          child: ListView.separated(
            itemCount: billItems.length,
            separatorBuilder: (_, _) => Divider(color: AppColors.borderSubtle, height: 12.h),
            itemBuilder: (context, i) {
              final item = billItems[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menuItem.name,
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (item.modifiers.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              (item.modifiers as List<dynamic>).join(', '),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    (item.subtotal as double).asCurrency,
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              );
            },
          ),
        ),
        // Financial Totals Summary
        Container(height: 1.h, color: AppColors.border),
        Gap(12.h),
        _buildReceiptRow('Subtotal', subtotal.asCurrency),
        Gap(6.h),
        if (discount > 0) ...[
          _buildReceiptRow(
            billState.discountPercent > 0
                ? 'Discount (${billState.discountPercent.toInt()}%)'
                : 'Discount',
            '-${discount.asCurrency}',
            isPromo: true,
          ),
          Gap(6.h),
        ],
        _buildReceiptRow(
          'Sales Tax (${billState.order.taxPercent.toInt()}%)',
          tax.asCurrency,
        ),
        Gap(6.h),
        _buildReceiptRow(
          'Service Charge (${billState.serviceChargePercent.toInt()}%)',
          serviceCharge.asCurrency,
        ),
        Gap(12.h),
        Row(
          children: [
            Text(
              'Total Amount',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              total.asCurrency,
              style: AppTextStyles.priceLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isPromo = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isPromo ? AppColors.profit : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isPromo ? AppColors.profit : AppColors.textPrimary,
            fontWeight: isPromo ? FontWeight.w600 : AppTextStyles.bodyMedium.fontWeight,
          ),
        ),
      ],
    );
  }
}


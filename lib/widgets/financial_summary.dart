import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// ─── Orderlli POS · Financial Summary Widget ────────────────────────────────
///
/// A premium reusable widget to render subtotals, tax rates, promotions/discounts,
/// and total bill amounts consistently across checkout, billing, and cart screens.
class FinancialSummary extends StatelessWidget {
  const FinancialSummary({
    super.key,
    required this.subtotal,
    required this.taxPercent,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.showDetails = true,
  });

  final double subtotal;
  final double taxPercent;
  final double discountPercent;
  final double discountAmount;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final computedDiscount = discountAmount > 0.0
        ? discountAmount
        : (subtotal * (discountPercent / 100.0));
    final taxableAmount = subtotal - computedDiscount;
    final computedTax = taxableAmount * (taxPercent / 100.0);
    final total = taxableAmount + computedTax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDetails) ...[
          _buildRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          Gap(8.h),
          if (computedDiscount > 0) ...[
            _buildRow(
              discountPercent > 0
                  ? 'Discount (${discountPercent.toInt()}%)'
                  : 'Discount',
              '-\$${computedDiscount.toStringAsFixed(2)}',
              isPromo: true,
            ),
            Gap(8.h),
          ],
          _buildRow(
            'Sales Tax (${taxPercent.toInt()}%)',
            '\$${computedTax.toStringAsFixed(2)}',
          ),
          Gap(12.h),
          Container(height: 1.h, color: AppColors.border),
          Gap(12.h),
        ],
        Row(
          children: [
            Text(
              'Total Bill',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            ),
            const Spacer(),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: AppTextStyles.priceLarge.copyWith(
                color: AppColors.primary,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isPromo = false}) {
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
            fontWeight: isPromo ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

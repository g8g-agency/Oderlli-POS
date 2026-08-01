import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import '../core/utils/currency_formatter.dart';

/// ─── Orderlyy POS · Financial Summary Widget ────────────────────────────────
///
/// A premium reusable widget to render subtotals, tax rates, promotions/discounts,
/// and total bill amounts consistently across checkout, billing, and cart screens.
///
/// Currency is formatted via [CurrencyFormatter] — never hardcode symbols here.
class FinancialSummary extends StatelessWidget {
  const FinancialSummary({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    this.showDetails = true,
  });

  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDetails) ...[
          _buildRow('Subtotal', CurrencyFormatter.format(subtotal)),
          Gap(8.h),
          if (discountAmount > 0) ...[
            _buildRow(
              'Discount',
              CurrencyFormatter.formatNegative(discountAmount),
              isPromo: true,
            ),
            Gap(8.h),
          ],
          _buildRow(
            'Sales Tax',
            CurrencyFormatter.format(taxAmount),
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
              ),
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(total),
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


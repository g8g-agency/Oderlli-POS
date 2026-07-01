import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';
import '../../core/utils/currency_formatter.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  int _activeTab = 0; // 0: Cash, 1: Card, 2: UPI, 3: Mixed Payment
  String? _loadingMessage;
  
  // Cash mode states
  String _cashTendered = '';
  
  // Mixed mode states
  final TextEditingController _mixedCashController = TextEditingController(text: '0.00');
  final TextEditingController _mixedCardController = TextEditingController(text: '0.00');
  final TextEditingController _mixedUpiController = TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final amountParam = GoRouterState.of(context).uri.queryParameters['amount'];
      if (amountParam != null) {
        setState(() {
          _cashTendered = amountParam;
        });
      }
    });
  }

  @override
  void dispose() {
    _mixedCashController.dispose();
    _mixedCardController.dispose();
    _mixedUpiController.dispose();
    super.dispose();
  }

  // Cash Keypad Actions
  void _onKeyPress(String val) {
    setState(() {
      if (val == '.' && _cashTendered.contains('.')) return;
      _cashTendered += val;
    });
  }

  void _onBackspace() {
    if (_cashTendered.isNotEmpty) {
      setState(() {
        _cashTendered = _cashTendered.substring(0, _cashTendered.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _cashTendered = '';
    });
  }

  // Helper to calculate totals based on active mode
  int _getCurrentTenderedAmountPaise(int remainingPaise) {
    if (_activeTab == 0) {
      final raw = double.tryParse(_cashTendered) ?? 0.0;
      return (raw * 100).round();
    } else if (_activeTab == 1 || _activeTab == 2) {
      return remainingPaise;
    } else {
      final c = ((double.tryParse(_mixedCashController.text) ?? 0.0) * 100).round();
      final d = ((double.tryParse(_mixedCardController.text) ?? 0.0) * 100).round();
      final u = ((double.tryParse(_mixedUpiController.text) ?? 0.0) * 100).round();
      return c + d + u;
    }
  }

  void _distributeMixedEvenly(double remainingVal) {
    final splitVal = (remainingVal / 3).toStringAsFixed(2);
    setState(() {
      _mixedCashController.text = splitVal;
      _mixedCardController.text = splitVal;
      _mixedUpiController.text = splitVal;
    });
  }

  Future<void> _onCompletePayment(double remainingVal) async {
    // Clear any prior payment error before starting
    ref.read(activeBillProvider.notifier).clearPaymentError();

    setState(() {
      if (_activeTab == 0) {
        _loadingMessage = 'Recording Cash Payment...';
      } else if (_activeTab == 1) {
        _loadingMessage = 'Connecting to Card Reader...';
      } else if (_activeTab == 2) {
        _loadingMessage = 'Verifying UPI / QR Code scan...';
      } else {
        _loadingMessage = 'Processing Multi-Tender Allocations...';
      }
    });

    if (_activeTab == 1) {
      // Simulate multi-step card terminal response
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _loadingMessage = 'Authorizing card txn with bank...';
        });
      }
      await Future.delayed(const Duration(milliseconds: 600));
    } else {
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (!mounted) return;

    final billNotifier = ref.read(activeBillProvider.notifier);
    final billState = ref.read(activeBillProvider);
    if (billState == null) return;
    
    final remainingPaise = billState.amountRemainingPaise;
    try {
      if (_activeTab == 0) {
        // Cash payment
        final amountPaise = _getCurrentTenderedAmountPaise(remainingPaise);
        if (amountPaise <= 0) {
          return;
        }
        final appliedAmountPaise = amountPaise > remainingPaise ? remainingPaise : amountPaise;
        final appliedAmount = appliedAmountPaise / 100.0;
        await billNotifier.addPayment('Cash', appliedAmount);
        if (!mounted) return;
        
        final changePaise = amountPaise - remainingPaise;
        final change = changePaise / 100.0;
        if (change > 0) {
          context.showSuccessSnack('Payment successful! Return change: ${change.asCurrency}');
        } else {
          context.showSuccessSnack('Cash payment of ${appliedAmount.asCurrency} recorded.');
        }
      } else if (_activeTab == 1) {
        // Card payment
        await billNotifier.addPayment('Card', remainingVal);
        if (!mounted) return;
        context.showSuccessSnack('Card payment of ${remainingVal.asCurrency} completed via PX terminal.');
      } else if (_activeTab == 2) {
        // UPI payment
        await billNotifier.addPayment('UPI', remainingVal);
        if (!mounted) return;
        context.showSuccessSnack('UPI payment of ${remainingVal.asCurrency} scanned & approved.');
      } else {
        // Mixed Payment mode
        final cashVal = double.tryParse(_mixedCashController.text) ?? 0.0;
        final cardVal = double.tryParse(_mixedCardController.text) ?? 0.0;
        final upiVal = double.tryParse(_mixedUpiController.text) ?? 0.0;
        
        int transactionCount = 0;
        if (cashVal > 0) {
          await billNotifier.addPayment('Cash', cashVal);
          if (!mounted) return;
          transactionCount++;
        }
        if (cardVal > 0) {
          await billNotifier.addPayment('Card', cardVal);
          if (!mounted) return;
          transactionCount++;
        }
        if (upiVal > 0) {
          await billNotifier.addPayment('UPI', upiVal);
          if (!mounted) return;
          transactionCount++;
        }
        
        if (transactionCount > 0) {
          context.showSuccessSnack('Multi-tender payment recorded ($transactionCount transactions).');
        }
      }

      if (!mounted) return;

      // Only navigate away if no error was set by the provider
      final postPaymentState = ref.read(activeBillProvider);
      if (postPaymentState?.paymentError != null) {
        throw Exception(postPaymentState!.paymentError);
      }
      context.go('/checkout');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _onCompletePayment(remainingVal);
            },
            child: const Text('Payment could not be saved — tap to retry'),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _onCompletePayment(remainingVal);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(activeBillProvider);

    if (billState == null || !billState.paymentsHydrated) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final isProcessing = billState.isSubmittingPayment;
    final paymentError = billState.paymentError;

    final totalBill = billState.total;
    final amountPaid = billState.amountPaid;
    
    final remainingPaise = billState.amountRemainingPaise;
    final remainingVal = remainingPaise / 100.0;
    
    final currentTenderedPaise = _getCurrentTenderedAmountPaise(remainingPaise);
    final currentTendered = currentTenderedPaise / 100.0;
    
    // Settlement calculations
    final newRemainingPaise = (remainingPaise - currentTenderedPaise).clamp(0, 999999999);
    final changeDuePaise = (currentTenderedPaise - remainingPaise).clamp(0, 999999999);
    
    final newRemaining = newRemainingPaise / 100.0;
    final changeDue = changeDuePaise / 100.0;
    
    // Settlement preview message & color
    String settlementText;
    Color settlementColor;
    if (currentTenderedPaise <= 0) {
      settlementText = 'No payment entered';
      settlementColor = AppColors.textSecondary;
    } else if (currentTenderedPaise >= remainingPaise) {
      if (changeDuePaise > 0) {
        settlementText = 'Sufficient - Change Due: ${changeDue.asCurrency}';
        settlementColor = AppColors.cash;
      } else {
        settlementText = 'Fully Settled';
        settlementColor = AppColors.success;
      }
    } else {
      settlementText = 'Insufficient - Unpaid: ${newRemaining.asCurrency}';
      settlementColor = AppColors.warning;
    }

    return LoadingOverlay(
      isLoading: isProcessing,
      message: _loadingMessage,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Payment Method', style: AppTextStyles.headlineMedium),
            Gap(16.h),

            // ── 0. Payment Error Banner ──────────────────────────────────────
            if (paymentError != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 22.sp),
                      Gap(12.w),
                      Expanded(
                        child: Text(
                          paymentError,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Gap(8.w),
                      IconButton(
                        onPressed: () => ref
                            .read(activeBillProvider.notifier)
                            .clearPaymentError(),
                        icon: Icon(Icons.close,
                            color: AppColors.error, size: 18.sp),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
              ),

            // ── 1. Tab headers (Cash, Card, UPI, Mixed) ──────────────────────
            Row(
              children: [
                _buildTabCard('CASH', Icons.money, 0),
                Gap(12.w),
                _buildTabCard('CARD', Icons.credit_card, 1),
                Gap(12.w),
                _buildTabCard('UPI / QR', Icons.qr_code_scanner, 2),
                Gap(12.w),
                _buildTabCard('MIXED', Icons.account_balance_wallet_outlined, 3),
              ],
            ),
            Gap(16.h),

            // ── 2. Interactive Body and Right-side Summary Layout ─────────────
            Expanded(
              child: context.isVerticalLayout
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Active Tab Content
                          POSCard(
                            child: Container(
                              constraints: BoxConstraints(minHeight: 260.h),
                              child: _buildActiveTabContent(remainingPaise),
                            ),
                          ),
                          Gap(12.h),
                          // Payment Summary Panel
                          _buildSummaryPanel(
                            totalBill,
                            amountPaid,
                            remainingVal,
                            currentTendered,
                            settlementColor,
                            settlementText,
                            isScrollable: true,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel: Active tab layout content (expanded)
                        Expanded(
                          child: POSCard(
                            child: _buildActiveTabContent(remainingPaise),
                          ),
                        ),
                        Gap(16.w),
                        // Right Panel: Payment Summary & Settlement Preview (Fixed width)
                        SizedBox(
                          width: 360,
                          child: _buildSummaryPanel(
                            totalBill,
                            amountPaid,
                            remainingVal,
                            currentTendered,
                            settlementColor,
                            settlementText,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(
    double totalBill,
    double amountPaid,
    double remainingVal,
    double currentTendered,
    Color settlementColor,
    String settlementText, {
    bool isScrollable = false,
  }) {
    final billState = ref.read(activeBillProvider);
    final remainingPaise = billState?.amountRemainingPaise ?? 0;
    final currentTenderedPaise = _getCurrentTenderedAmountPaise(remainingPaise);
    final totalTenderedPaise = (billState?.amountPaidPaise ?? 0) + currentTenderedPaise;
    final grandTotalPaise = billState?.grandTotalPaise ?? 0;
    final canComplete = totalTenderedPaise >= grandTotalPaise;

    return POSCard(
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: AppTextStyles.titleMedium),
          Gap(12.h),
          
          _buildSummaryRow('Total Bill', totalBill.asCurrency),
          Gap(8.h),
          _buildSummaryRow('Amount Paid', amountPaid.asCurrency),
          Gap(8.h),
          _buildSummaryRow('Remaining Balance', remainingVal.asCurrency, isHighlight: true),
          Gap(12.h),
          
          Container(height: 1.h, color: AppColors.borderSubtle),
          Gap(12.h),
          
          _buildSummaryRow('Tendered / Input', currentTendered.asCurrency, color: AppColors.primary),
          Gap(16.h),

          // Settlement Preview Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: settlementColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: settlementColor.withValues(alpha: 0.2)),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SETTLEMENT PREVIEW',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: settlementColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Gap(4.h),
                Text(
                  settlementText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: settlementColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          isScrollable ? Gap(24.h) : const Spacer(),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  onPressed: !canComplete
                      ? null
                      : () => _onCompletePayment(remainingVal),
                  text: 'COMPLETE PAYMENT',
                  icon: Icons.check,
                ),
              ),
            ],
          ),
          Gap(10.h),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () => context.go('/checkout'),
                  text: 'CANCEL',
                  icon: Icons.close,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabCard(String label, IconData icon, int tabIndex) {
    final isSelected = _activeTab == tabIndex;
    return Expanded(
      child: POSCard(
        onTap: () => setState(() {
          _activeTab = tabIndex;
        }),
        isSelected: isSelected,
        backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
        borderColor: isSelected ? AppColors.primary : AppColors.border,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22.sp,
            ),
            Gap(10.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(int remainingPaise) {
    switch (_activeTab) {
      case 0:
        return _buildCashContent(remainingPaise);
      case 1:
        return _buildCardContent();
      case 2:
        return _buildUpiContent();
      case 3:
        return _buildMixedContent(remainingPaise);
      default:
        return Container();
    }
  }

  // CASH MODE LAYOUT
  Widget _buildCashContent(int remainingPaise) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tender summary display & presets (left)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cash Tender Input', style: AppTextStyles.titleLarge),
              Gap(16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.centerRight,
                child: Text(
                  _cashTendered.isEmpty
                      ? '${CurrencyFormatter.symbol}0.00'
                      : '${CurrencyFormatter.symbol}$_cashTendered',
                  style: AppTextStyles.priceLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Gap(20.h),
              Text('Quick Cash Helpers', style: AppTextStyles.titleSmall),
              Gap(10.h),
              Row(
                children: [
                  _buildQuickCashButton(
                    'Exact Cash',
                    () => setState(() => _cashTendered = (remainingPaise / 100.0).toStringAsFixed(2)),
                  ),
                  Gap(8.w),
                  _buildQuickCashButton(
                    '${CurrencyFormatter.symbol}200',
                    () => setState(() => _cashTendered = '200.00'),
                  ),
                  Gap(8.w),
                  _buildQuickCashButton(
                    '${CurrencyFormatter.symbol}500',
                    () => setState(() => _cashTendered = '500.00'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(16.w),
        // Numerical Keypad (right)
        Expanded(
          flex: 5,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              if (i == 9) return _buildKeypadButton('C', _onClear);
              if (i == 10) return _buildKeypadButton('0', () => _onKeyPress('0'));
              if (i == 11) return _buildKeypadButton('.', () => _onKeyPress('.'));
              
              final number = i + 1;
              if (number == 10) {
                return _buildKeypadButton('', _onBackspace, icon: Icons.backspace_outlined);
              }
              return _buildKeypadButton('$number', () => _onKeyPress('$number'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCashButton(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback onTap, {IconData? icon}) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: AppColors.textPrimary, size: 20.sp)
              : Text(
                  label,
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  // CARD MODE LAYOUT
  Widget _buildCardContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          Gap(24.h),
          Text('Waiting for swipe / tap on terminal...', style: AppTextStyles.titleLarge),
          Gap(8.h),
          Text('Terminal ID: PX-400-BAR', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // UPI MODE LAYOUT
  Widget _buildUpiContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: 140.sp, color: AppColors.textPrimary),
          Gap(16.h),
          Text('Scan QR Code on Guest Screen', style: AppTextStyles.titleLarge),
          Gap(12.h),
          // UPI Branding logs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBrandBadge('GPAY'),
              Gap(8.w),
              _buildBrandBadge('PHONEPE'),
              Gap(8.w),
              _buildBrandBadge('PAYTM'),
              Gap(8.w),
              _buildBrandBadge('UPI'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // MIXED PAYMENT MODE LAYOUT
  Widget _buildMixedContent(int remainingPaise) {
    final remainingVal = remainingPaise / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Mixed Tender Allocations',
                style: AppTextStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Gap(8.w),
            TextButton.icon(
              onPressed: () => _distributeMixedEvenly(remainingVal),
              icon: const Icon(Icons.splitscreen_outlined, size: 16),
              label: const Text('SPLIT EQUALLY'),
            ),
          ],
        ),
        Gap(20.h),
        
        context.isVerticalLayout
            ? Column(
                children: [
                  _buildMixedInputSlot(
                    'CASH TENDER',
                    Icons.money,
                    _mixedCashController,
                  ),
                  Gap(12.h),
                  _buildMixedInputSlot(
                    'CARD CHARGE',
                    Icons.credit_card,
                    _mixedCardController,
                  ),
                  Gap(12.h),
                  _buildMixedInputSlot(
                    'UPI / QR SCAN',
                    Icons.qr_code_scanner,
                    _mixedUpiController,
                  ),
                ],
              )
            : Row(
                children: [
                  // Cash Allocation
                  Expanded(
                    child: _buildMixedInputSlot(
                      'CASH TENDER',
                      Icons.money,
                      _mixedCashController,
                    ),
                  ),
                  Gap(16.w),
                  // Card Allocation
                  Expanded(
                    child: _buildMixedInputSlot(
                      'CARD CHARGE',
                      Icons.credit_card,
                      _mixedCardController,
                    ),
                  ),
                  Gap(16.w),
                  // UPI Allocation
                  Expanded(
                    child: _buildMixedInputSlot(
                      'UPI / QR SCAN',
                      Icons.qr_code_scanner,
                      _mixedUpiController,
                    ),
                  ),
                ],
              ),
        Gap(24.h),
        Text(
          'Allocate portions of the remaining balance to different methods. The COMPLETE button on the right will become active once allocations are specified.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMixedInputSlot(String label, IconData icon, TextEditingController controller) {
    return POSCard(
      backgroundColor: AppColors.surfaceVariant,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: AppColors.primary),
              Gap(8.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap(12.h),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              // Trigger build update to recalculate tendered totals
              setState(() {});
            },
            decoration: InputDecoration(
              prefixText: CurrencyFormatter.symbol,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Gap(8.w),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: color ?? AppColors.textPrimary,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

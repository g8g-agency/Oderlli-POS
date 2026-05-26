import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  int _activeTab = 0; // 0: Cash, 1: Card, 2: UPI, 3: Mixed Payment
  bool _isProcessing = false;
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
  double _getCurrentTenderedAmount(double remainingVal) {
    if (_activeTab == 0) {
      return double.tryParse(_cashTendered) ?? 0.0;
    } else if (_activeTab == 1 || _activeTab == 2) {
      // Card or UPI defaults to exact remaining balance if not customized
      return remainingVal;
    } else {
      // Mixed Payment mode
      final c = double.tryParse(_mixedCashController.text) ?? 0.0;
      final d = double.tryParse(_mixedCardController.text) ?? 0.0;
      final u = double.tryParse(_mixedUpiController.text) ?? 0.0;
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
    setState(() {
      _isProcessing = true;
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
    
    if (_activeTab == 0) {
      // Cash payment
      final amount = _getCurrentTenderedAmount(remainingVal);
      if (amount <= 0) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }
      final appliedAmount = amount > remainingVal ? remainingVal : amount;
      billNotifier.addPayment('Cash', appliedAmount);
      
      final change = amount - remainingVal;
      if (change > 0) {
        context.showSuccessSnack('Payment successful! Return change: ${change.asCurrency}');
      } else {
        context.showSuccessSnack('Cash payment of ${appliedAmount.asCurrency} recorded.');
      }
    } else if (_activeTab == 1) {
      // Card payment
      billNotifier.addPayment('Card', remainingVal);
      context.showSuccessSnack('Card payment of ${remainingVal.asCurrency} completed via PX terminal.');
    } else if (_activeTab == 2) {
      // UPI payment
      billNotifier.addPayment('UPI', remainingVal);
      context.showSuccessSnack('UPI payment of ${remainingVal.asCurrency} scanned & approved.');
    } else {
      // Mixed Payment mode
      final cashVal = double.tryParse(_mixedCashController.text) ?? 0.0;
      final cardVal = double.tryParse(_mixedCardController.text) ?? 0.0;
      final upiVal = double.tryParse(_mixedUpiController.text) ?? 0.0;
      
      int transactionCount = 0;
      if (cashVal > 0) {
        billNotifier.addPayment('Cash', cashVal);
        transactionCount++;
      }
      if (cardVal > 0) {
        billNotifier.addPayment('Card', cardVal);
        transactionCount++;
      }
      if (upiVal > 0) {
        billNotifier.addPayment('UPI', upiVal);
        transactionCount++;
      }
      
      if (transactionCount > 0) {
        context.showSuccessSnack('Multi-tender payment recorded ($transactionCount transactions).');
      }
    }

    setState(() {
      _isProcessing = false;
    });

    context.go('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(activeBillProvider);

    if (billState == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final totalBill = billState.total;
    final amountPaid = billState.amountPaid;
    final remainingVal = billState.amountRemaining;
    
    final currentTendered = _getCurrentTenderedAmount(remainingVal);
    
    // Settlement calculations
    final newRemaining = (remainingVal - currentTendered).clamp(0.0, double.infinity);
    final changeDue = (currentTendered - remainingVal).clamp(0.0, double.infinity);
    
    // Settlement preview message & color
    String settlementText;
    Color settlementColor;
    if (currentTendered <= 0.01) {
      settlementText = 'No payment entered';
      settlementColor = AppColors.textSecondary;
    } else if (currentTendered >= remainingVal - 0.01) {
      if (changeDue > 0.01) {
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
      isLoading: _isProcessing,
      message: _loadingMessage,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Payment Method', style: AppTextStyles.headlineMedium),
            Gap(16.h),

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
                              child: _buildActiveTabContent(remainingVal),
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
                            child: _buildActiveTabContent(remainingVal),
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
                  onPressed: currentTendered <= 0.01
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

  Widget _buildActiveTabContent(double remainingVal) {
    switch (_activeTab) {
      case 0:
        return _buildCashContent(remainingVal);
      case 1:
        return _buildCardContent();
      case 2:
        return _buildUpiContent();
      case 3:
        return _buildMixedContent(remainingVal);
      default:
        return Container();
    }
  }

  // CASH MODE LAYOUT
  Widget _buildCashContent(double remainingVal) {
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
                  _cashTendered.isEmpty ? '£0.00' : '£$_cashTendered',
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
                    () => setState(() => _cashTendered = remainingVal.toStringAsFixed(2)),
                  ),
                  Gap(8.w),
                  _buildQuickCashButton(
                    '£20.00',
                    () => setState(() => _cashTendered = '20.00'),
                  ),
                  Gap(8.w),
                  _buildQuickCashButton(
                    '£50.00',
                    () => setState(() => _cashTendered = '50.00'),
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
  Widget _buildMixedContent(double remainingVal) {
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
            decoration: const InputDecoration(
              prefixText: '£',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/print_service.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(shiftProvider);
    final allOrders = ref.watch(ordersProvider);
    final pendingOrdersCount = ref.watch(activeOrdersProvider).length;
    final isVertical = context.isVerticalLayout;

    if (!session.isShiftActive) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520.w),
              child: POSCard(
                padding: EdgeInsets.all(32.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 64.sp, color: AppColors.error),
                    Gap(16.h),
                    Text('Shift is Currently Closed', style: AppTextStyles.headlineMedium),
                    Gap(8.h),
                    Text(
                      'Terminal: ${session.terminalId} · Last Cashier: ${session.cashierName}',
                      style: AppTextStyles.bodySmall,
                    ),
                    Gap(24.h),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildClosedSummaryRow('Opening Float', CurrencyFormatter.format(session.openingCash)),
                          Gap(8.h),
                          _buildClosedSummaryRow('Net Cash Sales', CurrencyFormatter.format(session.netCashSales)),
                          Gap(8.h),
                          _buildClosedSummaryRow('Total Disbursements', CurrencyFormatter.format(session.payouts)),
                          Gap(8.h),
                          _buildClosedSummaryRow('Cash In Additions', CurrencyFormatter.format(session.cashInTotal)),
                          Gap(8.h),
                          _buildClosedSummaryRow('Cash Drop Deposits', CurrencyFormatter.format(session.cashDropTotal)),
                          const Divider(height: 16),
                          _buildClosedSummaryRow('Final Expected Drawer', CurrencyFormatter.format(session.expectedCash), isHighlight: true),
                        ],
                      ),
                    ),
                    Gap(32.h),
                    PrimaryButton(
                      onPressed: () {
                        ref.read(shiftProvider.notifier).startNewShift();
                        context.showSuccessSnack('New shift session initialized.');
                      },
                      text: 'START NEW SHIFT',
                      icon: Icons.vpn_key,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
                        'Cashier: ${session.cashierName}',
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
                        'Cashier: ${session.cashierName}',
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
                        _buildLeftContent(context, ref, session, allOrders.length, pendingOrdersCount),
                        Gap(20.h),
                        _buildRightContent(session, isVertical),
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
                            child: _buildLeftContent(context, ref, session, allOrders.length, pendingOrdersCount),
                          ),
                        ),
                        Gap(24.w),
                        // Right panel: Activity Log (flex 4)
                        Expanded(
                          flex: 4,
                          child: _buildRightContent(session, isVertical),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight ? AppColors.error : AppColors.textPrimary,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLeftContent(BuildContext context, WidgetRef ref, ShiftSession session, int allOrdersCount, int pendingCount) {
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
                value: CurrencyFormatter.format(session.openingCash),
                icon: Icons.vpn_key_outlined,
                color: AppColors.neutral,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: MetricTile(
                label: 'Net Cash Sales',
                value: CurrencyFormatter.format(session.netCashSales),
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
                value: CurrencyFormatter.formatNegative(session.payouts),
                icon: Icons.outbox_outlined,
                color: AppColors.loss,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: MetricTile(
                label: 'Expected Cash',
                value: CurrencyFormatter.format(session.expectedCash),
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
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const _PayoutExpenseDialog(),
                  );
                  if (result == true) {
                    if (context.mounted) {
                      context.showSuccessSnack('Payout expense recorded successfully.');
                    }
                  }
                },
                text: 'PAYOUT / EXPENSE',
                icon: Icons.remove_circle_outline,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: SecondaryButton(
                onPressed: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => _CashDropInDialog(expectedCash: session.expectedCash),
                  );
                  if (result == 'drop') {
                    if (context.mounted) {
                      context.showSuccessSnack('Cash drop safe deposit logged.');
                    }
                  } else if (result == 'in') {
                    if (context.mounted) {
                      context.showSuccessSnack('Cash float addition completed.');
                    }
                  }
                },
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
                onPressed: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => _PrintXReportDialog(session: session, orderCount: allOrdersCount),
                  );
                  if (result == 'print') {
                    ref.read(shiftProvider.notifier).logXReport(false);
                    if (context.mounted) {
                      context.showSuccessSnack('X-Report queued to terminal printer.');
                    }
                  } else if (result == 'pdf') {
                    ref.read(shiftProvider.notifier).logXReport(true);
                    if (context.mounted) {
                      context.showSuccessSnack('X-Report PDF exported to downloads.');
                    }
                  }
                },
                text: 'PRINT X REPORT',
                icon: Icons.print,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: DangerButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => _CloseShiftDialog(
                      session: session,
                      pendingOrdersCount: pendingCount,
                    ),
                  );
                  if (confirm == true) {
                    if (context.mounted) {
                      context.go('/login');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shift session finalized successfully. Terminal locked.'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
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

  Widget _buildRightContent(ShiftSession session, bool isVertical) {
    final listContent = session.activities.map((a) {
      final isNegative = a.amount < 0 ||
          a.type == ShiftTransactionType.payout ||
          a.type == ShiftTransactionType.cashDrop;
      final amountSign = a.amount == 0 ? '' : (isNegative ? '-' : '+');
      final amountText = a.amount == 0
          ? '—'
          : '$amountSign${CurrencyFormatter.format(a.amount.abs())}';

      return _ActivityLogItem(
        time: a.timestamp.timeLabel,
        type: a.title,
        desc: a.subtitle,
        amount: amountText,
        color: a.amount == 0
            ? AppColors.textSecondary
            : (isNegative ? AppColors.loss : AppColors.success),
      );
    }).toList();

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: AppTextStyles.titleMedium),
                Gap(2.h),
                Text('$time · $desc', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Gap(12.w),
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

// ─── Dialog Widgets ─────────────────────────────────────────────────────────

class _PayoutExpenseDialog extends ConsumerStatefulWidget {
  const _PayoutExpenseDialog();

  @override
  ConsumerState<_PayoutExpenseDialog> createState() => _PayoutExpenseDialogState();
}

class _PayoutExpenseDialogState extends ConsumerState<_PayoutExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _pinController = TextEditingController();
  String _selectedCategory = 'Supplies';
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Beverage',
    'Supplies',
    'Utilities',
    'Maintenance',
    'Marketing',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    ref.read(shiftProvider.notifier).addPayout(
          amount,
          _selectedCategory,
          _reasonController.text.trim(),
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: IgnorePointer(
        ignoring: _isLoading,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
            side: const BorderSide(color: AppColors.border),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 520.w,
            padding: EdgeInsets.all(24.r),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: AppColors.loss.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.outbox_outlined,
                            color: AppColors.loss,
                            size: 22.sp,
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: Text(
                            'Record Payout / Expense',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(20.h),
                    // Amount Field
                    Text('Amount *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '${CurrencyFormatter.symbol} ',
                        hintText: '0.00',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0 || amount.isNaN) {
                          return 'Please enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    Gap(16.h),
                    // Category Dropdown
                    Text('Expense Category *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      dropdownColor: AppColors.surfaceElevated,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c, style: AppTextStyles.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    Gap(16.h),
                    // Reason Field
                    Text('Reason / Vendor *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                        hintText: 'e.g. Fresh vegetables delivery',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a reason or vendor';
                        }
                        return null;
                      },
                    ),
                    Gap(16.h),
                    // Notes Field
                    Text('Optional Notes', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        hintText: 'Additional details or invoice reference...',
                      ),
                    ),
                    Gap(20.h),
                    const Divider(color: AppColors.border),
                    Gap(16.h),
                    // PIN Authorization
                    Text('Supervisor PIN Authorization *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: 'Enter Supervisor PIN',
                        helperText: 'Required for audit compliance on drawer payout.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Supervisor PIN is required';
                        }
                        if (value.trim() != '1111') {
                          return 'Invalid Supervisor PIN';
                        }
                        return null;
                      },
                    ),
                    Gap(24.h),
                    // Actions row
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                            text: 'CANCEL',
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                              : PrimaryButton(
                                  onPressed: _submit,
                                  text: 'CONFIRM DISBURSEMENT',
                                  icon: Icons.check,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CashDropInDialog extends ConsumerStatefulWidget {
  const _CashDropInDialog({required this.expectedCash});
  final double expectedCash;

  @override
  ConsumerState<_CashDropInDialog> createState() => _CashDropInDialogState();
}

class _CashDropInDialogState extends ConsumerState<_CashDropInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isDrop = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (_isDrop) {
      ref.read(shiftProvider.notifier).addCashDrop(
            amount,
            _reasonController.text.trim(),
            _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
    } else {
      ref.read(shiftProvider.notifier).addCashIn(
            amount,
            _reasonController.text.trim(),
            _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
    }

    Navigator.of(context).pop(_isDrop ? 'drop' : 'in');
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: IgnorePointer(
        ignoring: _isLoading,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
            side: const BorderSide(color: AppColors.border),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 520.w,
            padding: EdgeInsets.all(24.r),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: (_isDrop ? AppColors.loss : AppColors.success).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isDrop ? Icons.arrow_downward : Icons.arrow_upward,
                            color: _isDrop ? AppColors.loss : AppColors.success,
                            size: 22.sp,
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: Text(
                            'Drawer Cash Movement',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(20.h),
                    // Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.all(4.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isDrop = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isDrop ? AppColors.lossContainer : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                alignment: Alignment.center,
                                child: Text(
                                  'CASH DROP',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: _isDrop ? AppColors.loss : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isDrop = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isDrop ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                alignment: Alignment.center,
                                child: Text(
                                  'CASH IN',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: !_isDrop ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(20.h),
                    // Expected cash helper warning for Cash Drop
                    if (_isDrop) ...[
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.cash.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.cash.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.cash),
                            Gap(12.w),
                            Expanded(
                              child: Text(
                                'Expected cash in drawer: ${CurrencyFormatter.format(widget.expectedCash)}. Drop amount cannot exceed this.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(16.h),
                    ],
                    // Amount Field
                    Text('Amount *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '${CurrencyFormatter.symbol} ',
                        hintText: '0.00',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0 || amount.isNaN) {
                          return 'Please enter a valid positive amount';
                        }
                        if (_isDrop && amount > widget.expectedCash) {
                          return 'Amount exceeds expected cash in drawer (${CurrencyFormatter.format(widget.expectedCash)})';
                        }
                        return null;
                      },
                    ),
                    Gap(16.h),
                    // Reason Field
                    Text('Reason / Description *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(_isDrop ? Icons.account_balance_outlined : Icons.input_rounded),
                        hintText: _isDrop ? 'e.g. Mid-day safe drop' : 'e.g. Additional change float',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                    ),
                    Gap(16.h),
                    // Notes Field
                    Text('Optional Notes', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        hintText: 'Enter internal notes...',
                      ),
                    ),
                    Gap(20.h),
                    const Divider(color: AppColors.border),
                    Gap(16.h),
                    // PIN Authorization
                    Text('Supervisor PIN Authorization *', style: AppTextStyles.titleMedium),
                    Gap(8.h),
                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: 'Enter Supervisor PIN',
                        helperText: 'Manager override validation for cash drops.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Supervisor PIN is required';
                        }
                        if (value.trim() != '1111') {
                          return 'Invalid Supervisor PIN';
                        }
                        return null;
                      },
                    ),
                    Gap(24.h),
                    // Actions row
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
                            text: 'CANCEL',
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                              : PrimaryButton(
                                  onPressed: _submit,
                                  text: _isDrop ? 'CONFIRM DROP' : 'CONFIRM CASH IN',
                                  icon: Icons.check,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrintXReportDialog extends StatefulWidget {
  const _PrintXReportDialog({required this.session, required this.orderCount});
  final ShiftSession session;
  final int orderCount;

  @override
  State<_PrintXReportDialog> createState() => _PrintXReportDialogState();
}

class _PrintXReportDialogState extends State<_PrintXReportDialog> {
  bool _isPrinting = false;
  bool _isExporting = false;

  void _print() async {
    setState(() => _isPrinting = true);

    const PrintService printService = MockPrintService();
    await printService.printXReport(widget.session);

    if (!mounted) return;
    setState(() => _isPrinting = false);

    Navigator.of(context).pop('print');
  }

  void _exportPdf() async {
    setState(() => _isExporting = true);

    const PrintService printService = MockPrintService();
    await printService.exportPdf(widget.session);

    if (!mounted) return;
    setState(() => _isExporting = false);

    Navigator.of(context).pop('pdf');
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isWorking = _isPrinting || _isExporting;

    // Calculation constants
    final cardSalesMock = 18500.0;
    final upiSalesMock = 12400.0;
    final grossSales = session.netCashSales + cardSalesMock + upiSalesMock;
    final refundsMock = 1250.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: IgnorePointer(
        ignoring: isWorking,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
            side: const BorderSide(color: AppColors.border),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 520.w,
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.print_outlined,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                    ),
                    Gap(16.w),
                    Expanded(
                      child: Text(
                        'Shift Audit X-Report',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(16.h),
                // Report Scroll container
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 380.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        children: [
                          Text(
                            'ORDERLLI POS AUDIT',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Courier',
                            ),
                          ),
                          Text(
                            '*** SHIFT X-REPORT ***',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black,
                              fontFamily: 'Courier',
                            ),
                          ),
                          Gap(10.h),
                          const Divider(color: Colors.black),
                          _buildReceiptRow('Shift ID', session.shiftId.substring(0, 12)),
                          _buildReceiptRow('Terminal', session.terminalId),
                          _buildReceiptRow('Cashier', session.cashierName),
                          _buildReceiptRow('Start Time', '${session.shiftStart.shortDate} ${session.shiftStart.timeLabel}'),
                          _buildReceiptRow('Print Time', '${DateTime.now().shortDate} ${DateTime.now().timeLabel}'),
                          _buildReceiptRow('Shift Duration', '4 hours 30 mins'),
                          _buildReceiptRow('Total Orders', '${widget.orderCount}'),
                          const Divider(color: Colors.black),

                          // Sales summary
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'SALES REVENUE SUMMARY',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                          Gap(4.h),
                          _buildReceiptRow('Cash Sales', CurrencyFormatter.format(session.netCashSales)),
                          _buildReceiptRow('Card Sales (Mock)', CurrencyFormatter.format(cardSalesMock)),
                          _buildReceiptRow('UPI Sales (Mock)', CurrencyFormatter.format(upiSalesMock)),
                          _buildReceiptRow('Refunds (Mock)', '-${CurrencyFormatter.format(refundsMock)}'),
                          _buildReceiptRow('Gross Sales', CurrencyFormatter.format(grossSales)),
                          const Divider(color: Colors.black),

                          // Drawer Summary
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'DRAWER CASH AUDIT',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                          Gap(4.h),
                          _buildReceiptRow('Opening Float', CurrencyFormatter.format(session.openingCash)),
                          _buildReceiptRow('Cash In Additions', CurrencyFormatter.format(session.cashInTotal)),
                          _buildReceiptRow('Cash Drop Deposits', '-${CurrencyFormatter.format(session.cashDropTotal)}'),
                          _buildReceiptRow('Payout Expenses', '-${CurrencyFormatter.format(session.payouts)}'),
                          _buildReceiptRow('Expected Cash', CurrencyFormatter.format(session.expectedCash)),
                          const Divider(color: Colors.black),
                          Gap(10.h),
                          Text(
                            '* SIGNATURE REQUIRED *',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                            ),
                          ),
                          Gap(20.h),
                          Container(
                            height: 1.h,
                            width: 150.w,
                            color: Colors.black54,
                          ),
                          Gap(4.h),
                          Text(
                            'Auditor Signature',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.black54,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Gap(24.h),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        onPressed: isWorking ? null : () => Navigator.of(context).pop(),
                        text: 'CLOSE',
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: _isExporting
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : SecondaryButton(
                              onPressed: isWorking ? null : () => _exportPdf(),
                              text: 'EXPORT PDF',
                              icon: Icons.picture_as_pdf_outlined,
                            ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: _isPrinting
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : PrimaryButton(
                              onPressed: isWorking ? null : () => _print(),
                              text: 'PRINT REPORT',
                              icon: Icons.print,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.black,
              fontFamily: 'Courier',
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseShiftDialog extends ConsumerStatefulWidget {
  const _CloseShiftDialog({
    required this.session,
    required this.pendingOrdersCount,
  });

  final ShiftSession session;
  final int pendingOrdersCount;

  @override
  ConsumerState<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<_CloseShiftDialog> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Call state update
    ref.read(shiftProvider.notifier).closeShift();

    // Log out of the active auth session
    await ref.read(authProvider.notifier).logout();

    // Operational close sequence delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final pendingCount = widget.pendingOrdersCount;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Finalizing Shift Audit & Locking Terminal...',
        child: IgnorePointer(
          ignoring: _isLoading,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
              side: const BorderSide(color: AppColors.border),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 520.w,
              padding: EdgeInsets.all(24.r),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_reset_outlined,
                              color: AppColors.error,
                              size: 22.sp,
                            ),
                          ),
                          Gap(16.w),
                          Expanded(
                            child: Text(
                              'Close Shift & Lock Terminal',
                              style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                      Gap(20.h),

                      // Safety Warnings (Active orders check)
                      if (pendingCount > 0) ...[
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                              Gap(12.w),
                              Expanded(
                                child: Text(
                                  'WARNING: There are still $pendingCount active/pending orders on the floor. Closing the shift will archive these tickets as unsettled.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap(16.h),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.success),
                              Gap(12.w),
                              Expanded(
                                child: Text(
                                  'All clear. There are zero pending orders on the floor.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap(16.h),
                      ],

                      Text(
                        'Closing the active shift will print the final Z-Report, lock the cashier console, and open the cash drawer for terminal audit.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
                      ),
                      Gap(20.h),

                      // Shift Totals Summary
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildClosedSummaryRow('Opening Float', CurrencyFormatter.format(session.openingCash)),
                            Gap(8.h),
                            _buildClosedSummaryRow('Net Cash Sales', CurrencyFormatter.format(session.netCashSales)),
                            Gap(8.h),
                            _buildClosedSummaryRow('Total Disbursements', CurrencyFormatter.format(session.payouts)),
                            const Divider(height: 16),
                            _buildClosedSummaryRow('Expected Cash In Drawer', CurrencyFormatter.format(session.expectedCash), isHighlight: true),
                          ],
                        ),
                      ),
                      Gap(20.h),

                      // Supervisor authorization PIN
                      Text('Supervisor PIN Authorization *', style: AppTextStyles.titleMedium),
                      Gap(8.h),
                      TextFormField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: 'Enter Supervisor PIN',
                          helperText: 'Manager override validation for cash drops.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Supervisor PIN is required';
                          }
                          if (value.trim() != '1111') {
                            return 'Invalid Supervisor PIN';
                          }
                          return null;
                        },
                      ),
                      Gap(24.h),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              text: 'CANCEL',
                            ),
                          ),
                          Gap(16.w),
                          Expanded(
                            child: DangerButton(
                              onPressed: _submit,
                              text: 'CLOSE SHIFT',
                              icon: Icons.lock,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight ? AppColors.error : AppColors.textPrimary,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

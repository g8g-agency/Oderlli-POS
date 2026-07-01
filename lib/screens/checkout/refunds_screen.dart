import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:dio/dio.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/extensions/extensions.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class RefundsScreen extends ConsumerStatefulWidget {
  const RefundsScreen({super.key});

  @override
  ConsumerState<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends ConsumerState<RefundsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _receiptId = '';
  bool _searched = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _refunded = false;
  String _refundConfirmationNumber = '';
  String? _errorMessage;

  OrderDetail? _orderDetail;
  String _selectedReason = 'Order mistake';
  double _refundAmountInput = 0.0;

  void _onSearch() async {
    if (_receiptId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searched = false;
      _orderDetail = null;
    });

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final detail = await orderRepo.getOrderDetail(_receiptId.trim());

      setState(() {
        _orderDetail = detail;
        _refundAmountInput = detail.total;
        _searched = true;
      });
    } on DioException catch (e) {
      String message = 'Order not found. Check the receipt number.';
      if (e.response?.statusCode == 404) {
        message = 'Order not found. Check the receipt number.';
      } else if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response?.data['message'].toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      setState(() {
        _errorMessage = message;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefund() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final user = auth.user;

    if (user == null || _orderDetail == null) return;

    bool authorized = false;
    String authorizedBy = user.name;

    if (user.role == UserRole.manager) {
      authorized = true;
    } else {
      // Cashier requires Manager override PIN
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => const ManagerOverrideDialog(
          actionName: 'Approve Billing Refund',
        ),
      );
      if (confirm == true) {
        authorized = true;
        authorizedBy = 'Manager Override';
      }
    }

    if (!authorized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission denied. Manager authorization required.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final dioClient = ref.read(dioClientProvider);
      final secureStorage = ref.read(secureStorageProvider);
      final staffToken = await secureStorage.getRuntimeToken();
      final staffId = user.id;

      final amountMinor = (_refundAmountInput * 100).toInt();

      final response = await dioClient.dio.post(
        '/api/v1/billing/refunds',
        data: {
          'order_id': _orderDetail!.id,
          'amount_minor': amountMinor,
          'reason': _selectedReason,
          'refunded_by_staff_id': staffId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $staffToken',
          },
        ),
      );

      final refundId = response.data['data']?['refund']?['id']?.toString() ?? 'REF-OK';

      // Log to shift log ONLY after successful API response
      final shift = ref.read(shiftProvider.notifier);
      shift.addPayout(
        _refundAmountInput,
        'Refund',
        'Bill #$_receiptId (Authorized by $authorizedBy)',
        null,
      );

      setState(() {
        _refundConfirmationNumber = refundId;
        _refunded = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund Successful! Cash drawer opened.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      String message = 'Refund failed.';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response?.data['message'].toString() ?? message;
      } else if (e.response?.data is Map && e.response?.data['error']?['message'] != null) {
        message = e.response?.data['error']['message'].toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      setState(() {
        _errorMessage = message;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildReasonChip(String label) {
    final isSelected = _selectedReason == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedReason = label;
          });
        }
      },
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
      ),
      side: isSelected ? const BorderSide(color: AppColors.primary) : BorderSide.none,
    );
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
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                    Gap(AppSpacing.md.w),
                    SizedBox(
                      height: 52.h,
                      child: OutlinedButton(
                        onPressed: _receiptId.isEmpty || _isLoading ? null : _onSearch,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Text('SEARCH', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
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
            child: _refunded
                ? POSCard(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
                          Gap(AppSpacing.md.h),
                          Text('Refund Processed Successfully', style: AppTypography.titleLarge),
                          Gap(AppSpacing.sm.h),
                          Text('Confirmation #: $_refundConfirmationNumber', style: AppTypography.bodyMedium),
                          Gap(AppSpacing.lg.h),
                          SizedBox(
                            width: 200.w,
                            child: PrimaryButton(
                              onPressed: () {
                                setState(() {
                                  _refunded = false;
                                  _searched = false;
                                  _receiptId = '';
                                  _orderDetail = null;
                                });
                              },
                              text: 'DONE',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _searched && _orderDetail != null
                    ? POSCard(
                        child: Form(
                          key: _formKey,
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
                                              'Bill #${_orderDetail!.orderNumber} Details',
                                              style: AppTypography.titleLarge,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          StatusChip(
                                            label: 'PAID - ${_orderDetail!.status.name.toUpperCase()}',
                                            color: AppColors.success,
                                          ),
                                        ],
                                      ),
                                      Gap(AppSpacing.md.h),
                                      Text(
                                        'Paid: ${CurrencyFormatter.format(_orderDetail!.total)} · Date: ${_orderDetail!.createdAt.shortDate} ${_orderDetail!.createdAt.timeLabel} · Server: ${_orderDetail!.createdBy ?? 'Staff'}',
                                        style: AppTypography.bodySmall,
                                      ),
                                      Gap(AppSpacing.lg.h),
                                      Text('Items List:', style: AppTypography.titleMedium),
                                      Gap(AppSpacing.xs.h),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _orderDetail!.items.length,
                                        separatorBuilder: (_, index) => const Divider(height: 8),
                                        itemBuilder: (context, idx) {
                                          final item = _orderDetail!.items[idx];
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${item.itemNameSnapshot} x ${item.quantity}', style: AppTypography.bodyMedium),
                                              Text(CurrencyFormatter.format(item.subtotal), style: AppTypography.bodyMedium),
                                            ],
                                          );
                                        },
                                      ),
                                      Gap(AppSpacing.lg.h),
                                      Container(height: 1.h, color: AppColors.border),
                                      Gap(AppSpacing.md.h),
                                      Text('Refund Reason Selection', style: AppTypography.titleMedium),
                                      Gap(AppSpacing.sm.h),
                                      Wrap(
                                        spacing: AppSpacing.xs.w,
                                        runSpacing: AppSpacing.xs.h,
                                        children: [
                                          _buildReasonChip('Order mistake'),
                                          _buildReasonChip('Food quality'),
                                          _buildReasonChip('Customer changed mind'),
                                        ],
                                      ),
                                      Gap(AppSpacing.lg.h),
                                      Text('Refund Amount (adjustable)', style: AppTypography.titleMedium),
                                      Gap(AppSpacing.sm.h),
                                      TextFormField(
                                        initialValue: _orderDetail!.total.toStringAsFixed(2),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          prefixText: '${CurrencyFormatter.symbol} ',
                                          hintText: 'Enter amount...',
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _refundAmountInput = double.tryParse(val) ?? 0.0;
                                          });
                                        },
                                        validator: (val) {
                                          final amt = double.tryParse(val ?? '') ?? 0.0;
                                          if (amt <= 0) return 'Amount must be greater than zero';
                                          if (amt > _orderDetail!.total) return 'Amount cannot exceed order total';
                                          return null;
                                        },
                                      ),
                                      if (_errorMessage != null) ...[
                                        Gap(AppSpacing.md.h),
                                        Text(
                                          _errorMessage!,
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Gap(AppSpacing.md.h),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _searched = false;
                                        _receiptId = '';
                                        _orderDetail = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.surface,
                                      side: const BorderSide(color: AppColors.border),
                                      minimumSize: Size(48.r, 48.r),
                                    ),
                                  ),
                                  Gap(AppSpacing.md.w),
                                  Expanded(
                                    child: _isSubmitting
                                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                        : DangerButton(
                                            onPressed: _onRefund,
                                            text: 'APPROVE & ISSUE REFUND',
                                            icon: Icons.assignment_return,
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

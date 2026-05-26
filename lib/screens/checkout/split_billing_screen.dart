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

class SplitBillingScreen extends ConsumerStatefulWidget {
  const SplitBillingScreen({super.key});

  @override
  ConsumerState<SplitBillingScreen> createState() => _SplitBillingScreenState();
}

class _SplitBillingScreenState extends ConsumerState<SplitBillingScreen> {
  int _guestCount = 2;
  int _splitType = 0; // 0: Equal, 1: By Items, 2: Custom Split
  
  // Item-level assignments: maps item.id to guestIndex (0, 1, 2...)
  final Map<String, int> _itemAssignments = {};
  
  // Custom split amounts per guest
  final List<TextEditingController> _customAmountControllers = [];

  @override
  void initState() {
    super.initState();
    _syncCustomControllers();
  }

  @override
  void dispose() {
    for (final controller in _customAmountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncCustomControllers() {
    while (_customAmountControllers.length < _guestCount) {
      _customAmountControllers.add(TextEditingController(text: '0.00'));
    }
    while (_customAmountControllers.length > _guestCount) {
      final last = _customAmountControllers.removeLast();
      last.dispose();
    }
  }

  // Returns list of assigned items subtotal for a specific guest index
  double _getGuestItemSubtotal(int guestIndex, List<dynamic> items) {
    double total = 0.0;
    for (final item in items) {
      if (item != null) {
        final assignedGuest = _itemAssignments[item.id] ?? 0;
        if (assignedGuest == guestIndex) {
          total += (item.subtotal as double);
        }
      }
    }
    return total;
  }

  // Calculate dynamic tax & service share for guest in Item Mode
  double _getGuestItemTotal(int guestIndex, List<dynamic> items, double taxPercent, double servicePercent) {
    final subtotal = _getGuestItemSubtotal(guestIndex, items);
    if (subtotal <= 0) return 0.0;
    
    final billState = ref.read(activeBillProvider);
    final discountPercent = billState?.discountPercent ?? 0.0;
    
    final discount = subtotal * (discountPercent / 100);
    final taxable = subtotal - discount;
    final tax = taxable * (taxPercent / 100);
    final service = taxable * (servicePercent / 100);
    return taxable + tax + service;
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
    final items = billState.order.items;

    _syncCustomControllers();

    double totalAllocatedCustom = 0.0;
    for (final c in _customAmountControllers) {
      totalAllocatedCustom += double.tryParse(c.text) ?? 0.0;
    }
    final unallocatedCustom = (totalBill - totalAllocatedCustom).clamp(0.0, double.infinity);

    final isVertical = context.isVerticalLayout;

    return Padding(
      padding: EdgeInsets.all(isVertical ? AppSpacing.md.r : AppSpacing.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Split Bill Calculator', style: AppTypography.headlineMedium),
          Gap(isVertical ? AppSpacing.sm.h : AppSpacing.lg.h),
          
          // ── 1. Split Type selector tabs ──────────────────────────────────
          Row(
            children: [
              _buildTypeCard(context, 'EQUAL SPLIT', Icons.people_outline, 0),
              Gap(isVertical ? AppSpacing.xs.w : AppSpacing.sm.w),
              _buildTypeCard(context, 'BY ITEMS', Icons.restaurant_menu_outlined, 1),
              Gap(isVertical ? AppSpacing.xs.w : AppSpacing.sm.w),
              _buildTypeCard(context, 'CUSTOM SPLIT', Icons.edit_note, 2),
            ],
          ),
          Gap(isVertical ? AppSpacing.md.h : AppSpacing.lg.h),

          // ── 2. Active Tab Screen & Summary split layout ────────────────────
          Expanded(
            child: isVertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Panel: Split input controls
                      Expanded(
                        flex: 6,
                        child: _buildLeftPanel(billState, items, unallocatedCustom),
                      ),
                      Gap(AppSpacing.md.h),
                      // Bottom Panel: Participant summary & remaining balances
                      Expanded(
                        flex: 4,
                        child: _buildRightPanel(context, billState, items, totalAllocatedCustom, unallocatedCustom),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Panel: Split input controls (65% width)
                      Expanded(
                        flex: 65,
                        child: _buildLeftPanel(billState, items, unallocatedCustom),
                      ),
                      Gap(AppSpacing.lg.w),
                      // Right Panel: Participant summary & remaining balances (35% width)
                      Expanded(
                        flex: 35,
                        child: _buildRightPanel(context, billState, items, totalAllocatedCustom, unallocatedCustom),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(ActiveBillState billState, List<dynamic> items, double unallocatedCustom) {
    return POSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _splitType == 0 
                      ? 'Equal Split Controls' 
                      : _splitType == 1 
                          ? 'Allocate Items to Guests' 
                          : 'Custom Split Setup',
                  style: AppTypography.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text('Guests: ', style: AppTypography.bodyMedium),
                  Gap(AppSpacing.xs.w),
                  IconButton(
                    onPressed: _guestCount > 1 
                        ? () => setState(() {
                              _guestCount--;
                              _syncCustomControllers();
                            }) 
                        : null,
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      disabledBackgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.2),
                      minimumSize: Size(48.w, 48.h),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                    child: Text('$_guestCount', style: AppTypography.headlineSmall),
                  ),
                  IconButton(
                    onPressed: _guestCount < 10 
                        ? () => setState(() {
                              _guestCount++;
                              _syncCustomControllers();
                            }) 
                        : null,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      minimumSize: Size(48.w, 48.h),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Gap(AppSpacing.md.h),
          Container(height: 1.h, color: AppColors.border),
          Gap(AppSpacing.md.h),

          // Render active content
          Expanded(
            child: _buildSplitTabContent(billState, items, unallocatedCustom),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    ActiveBillState billState,
    List<dynamic> items,
    double totalAllocatedCustom,
    double unallocatedCustom,
  ) {
    final totalBill = billState.total;
    return POSCard(
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Participant Summary', style: AppTypography.titleMedium),
          Text('Owed shares breakdown', style: AppTypography.bodySmall),
          Gap(AppSpacing.sm.h),
          
          Expanded(
            child: _buildSummaryList(billState, items, totalAllocatedCustom, unallocatedCustom),
          ),
          
          Container(height: 1.h, color: AppColors.borderSubtle),
          Gap(AppSpacing.sm.h),
          
          // Remaining balance visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unallocated Balance',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                _getUnallocatedBalance(totalBill, items, totalAllocatedCustom).asCurrency,
                style: AppTypography.titleMedium.copyWith(
                  color: _getUnallocatedBalance(totalBill, items, totalAllocatedCustom) > 0.01 
                      ? AppColors.warning 
                      : AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.sm.h),
          
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () => context.go('/checkout'),
                  text: 'BACK TO BILL',
                  icon: Icons.arrow_back,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, String label, IconData icon, int type) {
    final isSelected = _splitType == type;
    final isVertical = context.isVerticalLayout;
    return Expanded(
      child: POSCard(
        onTap: () => setState(() => _splitType = type),
        isSelected: isSelected,
        backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
        borderColor: isSelected ? AppColors.primary : AppColors.border,
        padding: EdgeInsets.symmetric(vertical: isVertical ? AppSpacing.xs.h : AppSpacing.sm.h, horizontal: AppSpacing.xxs.w),
        child: isVertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 18.sp),
                  Gap(AppSpacing.xxs.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20.sp),
                  Gap(AppSpacing.xs.w),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTypography.titleSmall.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSplitTabContent(ActiveBillState billState, List<dynamic> items, double unallocatedCustom) {
    if (_splitType == 0) {
      final perGuestAmount = billState.total / _guestCount;
      return ListView.separated(
        itemCount: _guestCount,
        separatorBuilder: (context, index) => Divider(color: AppColors.borderSubtle, height: AppSpacing.md.h),
        itemBuilder: (context, i) {
          return Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                radius: AppSpacing.md.r,
                child: Text('${i + 1}', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
              ),
              Gap(AppSpacing.md.w),
              Expanded(
                child: Text(
                  'Guest ${i + 1}',
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(12.w),
              Text(
                perGuestAmount.asCurrency,
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(AppSpacing.md.w),
              IconButton(
                onPressed: () {
                  context.go('/checkout/payment?amount=${perGuestAmount.toStringAsFixed(2)}');
                },
                icon: const Icon(Icons.payment, color: AppColors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  minimumSize: Size(48.r, 48.r),
                ),
              ),
            ],
          );
        },
      );
    } else if (_splitType == 1) {
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(color: AppColors.borderSubtle, height: AppSpacing.md.h),
        itemBuilder: (context, i) {
          final item = items[i];
          final assignedGuest = _itemAssignments[item.id] ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.menuItem.name as String,
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Gap(12.w),
                  Text(
                    (item.subtotal as double).asCurrency,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Gap(AppSpacing.xs.h),
              Row(
                children: [
                  Text('Assign to: ', style: AppTypography.labelSmall),
                  Gap(AppSpacing.xs.w),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_guestCount, (guestIdx) {
                          final isAssigned = assignedGuest == guestIdx;
                          return Padding(
                            padding: EdgeInsets.only(right: AppSpacing.xs.w),
                            child: ChoiceChip(
                              label: Text('G${guestIdx + 1}'),
                              selected: isAssigned,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _itemAssignments[item.id] = guestIdx;
                                  });
                                }
                              },
                              labelStyle: AppTypography.labelSmall.copyWith(
                                color: isAssigned ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceVariant,
                              side: BorderSide(
                                color: isAssigned ? AppColors.primary : AppColors.border,
                              ),
                              visualDensity: VisualDensity.standard,
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w, vertical: AppSpacing.sm.h),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    } else {
      return ListView.separated(
        itemCount: _guestCount,
        separatorBuilder: (context, index) => Divider(color: AppColors.borderSubtle, height: AppSpacing.md.h),
        itemBuilder: (context, i) {
          final controller = _customAmountControllers[i];
          return Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                radius: AppSpacing.md.r,
                child: Text('${i + 1}', style: AppTypography.labelSmall),
              ),
              Gap(AppSpacing.md.w),
              Expanded(
                child: Text(
                  'Guest ${i + 1} Share',
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(12.w),
              SizedBox(
                width: 140.w,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    prefixText: CurrencyFormatter.symbol,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildSummaryList(ActiveBillState billState, List<dynamic> items, double totalCustom, double unallocatedCustom) {
    return ListView.separated(
      itemCount: _guestCount,
      separatorBuilder: (context, index) => Divider(color: AppColors.borderSubtle, height: AppSpacing.sm.h),
      itemBuilder: (context, index) {
        double guestTotal = 0.0;
        
        if (_splitType == 0) {
          guestTotal = billState.total / _guestCount;
        } else if (_splitType == 1) {
          guestTotal = _getGuestItemTotal(index, items, billState.order.taxPercent, billState.serviceChargePercent);
        } else {
          guestTotal = double.tryParse(_customAmountControllers[index].text) ?? 0.0;
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Guest ${index + 1}',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _splitType == 1 
                          ? 'Assigned items split' 
                          : _splitType == 0 
                              ? 'Equal share' 
                              : 'Custom share',
                      style: AppTypography.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              Text(
                guestTotal.asCurrency,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(AppSpacing.sm.w),
              IconButton(
                onPressed: guestTotal <= 0.01
                    ? null
                    : () {
                        context.go('/checkout/payment?amount=${guestTotal.toStringAsFixed(2)}');
                      },
                icon: Icon(Icons.payment, size: 18.sp),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  minimumSize: Size(48.r, 48.r),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getUnallocatedBalance(double totalBill, List<dynamic> items, double totalCustom) {
    if (_splitType == 0) {
      return 0.0;
    } else if (_splitType == 2) {
      return (totalBill - totalCustom).clamp(0.0, double.infinity);
    } else {
      double assignedTotal = 0.0;
      for (final item in items) {
        if (item != null && _itemAssignments.containsKey(item.id)) {
          assignedTotal += (item.subtotal as double);
        }
      }
      
      final billState = ref.read(activeBillProvider);
      final taxPercent = billState?.order.taxPercent ?? 5.0;
      final servicePercent = billState?.serviceChargePercent ?? 10.0;
      final discountPercent = billState?.discountPercent ?? 0.0;
      
      final discount = assignedTotal * (discountPercent / 100);
      final taxable = assignedTotal - discount;
      final tax = taxable * (taxPercent / 100);
      final service = taxable * (servicePercent / 100);
      final allocatedTotal = taxable + tax + service;
      
      return (totalBill - allocatedTotal).clamp(0.0, double.infinity);
    }
  }
}

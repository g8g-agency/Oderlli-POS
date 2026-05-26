import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';

/// State provider for selected table in the cart screen.
final cartSelectedTableProvider = StateProvider<String?>((ref) => null);

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  static const List<String> _availableModifiers = [
    'No Onion',
    'Extra Cheese',
    'Spicy',
    'Gluten Free',
    'Extra Sauce',
    'Double Meat',
    'No Dairy',
    'Vegetarian',
  ];

  static const List<String> _quickNotes = [
    'Allergy Alert',
    'To Go',
    'Well Done',
    'Extra Hot',
    'Dressing on Side',
  ];

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(posCartProvider);
    final selectedTableId = ref.watch(cartSelectedTableProvider);
    final tables = ref.watch(posTablesProvider);

    // If activeTableIdProvider from Floor Plan is set, pre-fill selectedTableId
    final floorSelectedTableId = ref.watch(activeTableIdProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (floorSelectedTableId != null && selectedTableId == null) {
        ref.read(cartSelectedTableProvider.notifier).state = floorSelectedTableId;
      }
    });

    final currentSelectedTable = selectedTableId != null
        ? tables.firstWhere((t) => t.id == selectedTableId, orElse: () => tables.first)
        : tables.firstWhere((t) => t.status == POSTableStatus.occupied || t.status == POSTableStatus.preparing, orElse: () => tables.first);

    final isVertical = context.isVerticalLayout;

    final headerWidget = Container(
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/menu'),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          Gap(16.w),
          Text('Cart Customization', style: AppTextStyles.headlineMedium),
          Gap(12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '${cartState.totalQty} Items',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    final itemsListWidget = cartState.items.isEmpty
        ? const Center(
            child: EmptyStateWidget(
              icon: Icons.shopping_basket_outlined,
              title: 'Cart is empty',
              description: 'Go back to the Menu Book to add dishes to the cart.',
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(isVertical ? 16.r : 24.r),
            itemCount: cartState.items.length,
            separatorBuilder: (context, index) => Gap(16.h),
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              return _buildCartItemCard(context, ref, item);
            },
          );

    final dispatchWidget = Container(
      color: AppColors.sidebarBg,
      padding: EdgeInsets.all(isVertical ? 16.r : 24.r),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Dispatch Info', style: AppTextStyles.titleLarge),
            Text('Assign table context and finalize checkout', style: AppTextStyles.bodySmall),
            Gap(24.h),

            // Table Context Selector
            POSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table Mapping', style: AppTextStyles.titleMedium),
                  Gap(12.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTableId ?? currentSelectedTable.id,
                    dropdownColor: AppColors.surfaceElevated,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.table_restaurant_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                    items: tables.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(
                          'Table ${t.number} (${t.status.label})',
                          style: AppTextStyles.bodyMedium,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      ref.read(cartSelectedTableProvider.notifier).state = val;
                    },
                  ),
                  if (currentSelectedTable.waiterName != null) ...[
                    Gap(10.h),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14.sp, color: AppColors.textSecondary),
                        Gap(6.w),
                        Text(
                          'Assigned Waiter: ${currentSelectedTable.waiterName}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Gap(24.h),

            // Apply Discount Options
            POSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Applied Discount', style: AppTextStyles.titleMedium),
                  Gap(12.h),
                  Row(
                    children: [
                      _buildDiscountButton(ref, '0%', 0, cartState.discountPercent),
                      Gap(8.w),
                      _buildDiscountButton(ref, '10%', 10, cartState.discountPercent),
                      Gap(8.w),
                      _buildDiscountButton(ref, '15%', 15, cartState.discountPercent),
                      Gap(8.w),
                      _buildDiscountButton(ref, '20%', 20, cartState.discountPercent),
                    ],
                  ),
                ],
              ),
            ),
            Gap(24.h),

            // Financial summary calculations
            if (cartState.items.isNotEmpty) ...[
              FinancialSummary(
                subtotal: cartState.subtotal,
                taxPercent: cartState.taxPercent,
                discountPercent: cartState.discountPercent,
              ),
              Gap(24.h),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    onPressed: () => context.go('/menu'),
                    text: 'ADD MORE ITEMS',
                    icon: Icons.add_shopping_cart,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: PrimaryButton(
                    onPressed: cartState.items.isEmpty
                        ? null
                        : () async {
                            setState(() {
                              _isSending = true;
                            });

                            // Simulate kitchen ticket dispatch
                            await Future.delayed(const Duration(seconds: 1));

                            if (!mounted) return;

                            // Dispatch Order to Kitchen
                            final selectedTable = currentSelectedTable;

                            final newOrder = Order(
                              id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
                              tableId: selectedTable.id,
                              tableNumber: selectedTable.number,
                              status: OrderStatus.preparing,
                              createdAt: DateTime.now(),
                              discountPercent: cartState.discountPercent,
                              taxPercent: cartState.taxPercent,
                              servedBy: selectedTable.waiterName ?? 'Sarah',
                              items: cartState.items.map((c) {
                                return OrderItem(
                                  id: 'oi-${DateTime.now().millisecondsSinceEpoch}-${c.menuItem.id}',
                                  menuItem: c.menuItem,
                                  quantity: c.qty,
                                  notes: c.notes,
                                  modifiers: c.selectedModifiers,
                                );
                              }).toList(),
                            );

                            // Add order
                            ref.read(ordersProvider.notifier).addOrder(newOrder);

                            // Update table to occupied/preparing
                            ref.read(posTablesProvider.notifier).seatTable(
                                  selectedTable.id,
                                  selectedTable.guestCount > 0 ? selectedTable.guestCount : 2,
                                  selectedTable.waiterName ?? 'Sarah',
                                );
                            ref.read(posTablesProvider.notifier).updateStatus(selectedTable.id, POSTableStatus.preparing);
                            ref.read(posTablesProvider.notifier).updateBill(selectedTable.id, cartState.total);

                            // Reset selected table contexts
                            ref.read(cartSelectedTableProvider.notifier).state = null;
                            ref.read(activeTableIdProvider.notifier).state = null;

                            // Clear active cart
                            ref.read(posCartProvider.notifier).clear();

                            setState(() {
                              _isSending = false;
                            });

                            if (!mounted) return;
                            // Success visual confirmation
                            this.context.showSuccessSnack('Order dispatched to KDS successfully!');

                            // Route back to floorplan
                            this.context.go('/floor');
                          },
                    text: 'SEND TO KITCHEN',
                    icon: Icons.soup_kitchen_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final Widget mainContent;
    if (isVertical) {
      mainContent = Column(
        children: [
          headerWidget,
          Expanded(
            flex: 6,
            child: itemsListWidget,
          ),
          Container(height: 1.h, color: AppColors.border),
          Expanded(
            flex: 4,
            child: dispatchWidget,
          ),
        ],
      );
    } else {
      mainContent = Row(
        children: [
          Expanded(
            child: Column(
              children: [
                headerWidget,
                Expanded(child: itemsListWidget),
              ],
            ),
          ),
          // Vertical divider line
          Container(width: 1.w, color: AppColors.border),
          SizedBox(
            width: 360,
            child: dispatchWidget,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isSending,
        message: 'Dispatching ticket to KDS...',
        child: mainContent,
      ),
    );
  }

  Widget _buildDiscountButton(WidgetRef ref, String label, double percent, double currentPercent) {
    final isSelected = percent == currentPercent;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          ref.read(posCartProvider.notifier).applyDiscount(percent);
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, POSCartItem item) {
    return POSCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Info & Qty adjust row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.menuItem.name, style: AppTextStyles.titleLarge),
                    Gap(4.h),
                    Row(
                      children: [
                        Text(item.menuItem.price.asCurrency, style: AppTextStyles.bodySmall),
                        Gap(12.w),
                        if (item.menuItem.isVegetarian)
                          const StatusChip(label: 'VEG', color: AppColors.success)
                        else if (item.menuItem.isVegan)
                          const StatusChip(label: 'VEGAN', color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
              // Item Subtotal tag
              Text(
                item.subtotal.asCurrency,
                style: AppTextStyles.priceTag.copyWith(fontSize: 18.sp),
              ),
              Gap(24.w),
              // Quantity controls (Touch target >= 48px)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => ref.read(posCartProvider.notifier).removeItem(item.menuItem),
                      icon: Icon(Icons.remove, size: 18.sp, color: AppColors.textPrimary),
                      style: IconButton.styleFrom(
                        minimumSize: Size(48.w, 48.h),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(9.r))),
                      ),
                    ),
                    Container(
                      width: 40.w,
                      alignment: Alignment.center,
                      child: Text(
                        '${item.qty}',
                        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(posCartProvider.notifier).addItem(item.menuItem),
                      icon: Icon(Icons.add, size: 18.sp, color: AppColors.textPrimary),
                      style: IconButton.styleFrom(
                        minimumSize: Size(48.w, 48.h),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(9.r))),
                      ),
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              // Remove completely button
              IconButton(
                onPressed: () {
                  // Simulate deleting items by subtracting qty
                  for (int i = 0; i < item.qty; i++) {
                    ref.read(posCartProvider.notifier).removeItem(item.menuItem);
                  }
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.loss),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lossContainer,
                  minimumSize: Size(48.w, 48.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
          Gap(12.h),
          Container(height: 1.h, color: AppColors.borderSubtle),
          Gap(12.h),

          // Modifiers Wrap
          Text('Modifiers / Customizations', style: AppTextStyles.titleSmall),
          Gap(8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: CartScreen._availableModifiers.map((mod) {
              final isSelected = item.selectedModifiers.contains(mod);
              return FilterChip(
                label: Text(mod),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(posCartProvider.notifier).toggleModifier(item.menuItem.id, mod);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                backgroundColor: AppColors.surfaceVariant,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              );
            }).toList(),
          ),
          Gap(16.h),

          // Notes Section
          Text('Kitchen Preparation Notes', style: AppTextStyles.titleSmall),
          Gap(8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: item.notes)..selection = TextSelection.collapsed(offset: item.notes?.length ?? 0),
                  onChanged: (val) {
                    ref.read(posCartProvider.notifier).updateNotes(item.menuItem.id, val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Enter instructions (e.g. no pepper, extra well-done)...',
                    prefixIcon: Icon(Icons.edit_note, color: AppColors.textSecondary),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          Gap(8.h),
          // Quick preset notes
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: CartScreen._quickNotes.map((qNote) {
              return ActionChip(
                label: Text(qNote),
                onPressed: () {
                  final currentNotes = item.notes ?? '';
                  final newNotes = currentNotes.trim().isEmpty ? qNote : '$currentNotes, $qNote';
                  ref.read(posCartProvider.notifier).updateNotes(item.menuItem.id, newNotes);
                },
                backgroundColor: AppColors.surfaceVariant,
                side: const BorderSide(color: AppColors.border),
                labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

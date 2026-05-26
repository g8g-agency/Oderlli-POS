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

class FloorScreen extends ConsumerStatefulWidget {
  const FloorScreen({super.key});

  @override
  ConsumerState<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends ConsumerState<FloorScreen> {
  TableModel? _selectedTable;

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(posFilteredTablesProvider);
    final allTables = ref.watch(posTablesProvider);
    final sections = ref.watch(posTableSectionsProvider);
    final selectedSection = ref.watch(posSelectedSectionProvider);

    // Calculate operational summary stats dynamically
    final occupiedCount = allTables.where((t) => t.status == POSTableStatus.occupied).length;
    final preparingCount = allTables.where((t) => t.status == POSTableStatus.preparing).length;
    final readyCount = allTables.where((t) => t.status == POSTableStatus.ready).length;
    final activeOrdersCount = occupiedCount + preparingCount + readyCount;

    final paymentPendingCount = allTables.where((t) => t.status == POSTableStatus.paymentPending).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 1. Top Bar & Section Filter ────────────────────────────────────
          Container(
            height: 72.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text('Floor Overview', style: AppTextStyles.headlineMedium),
                Gap(32.w),
                // Section segmented chips wrapped in horizontal scroll view to prevent overflow
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SectionSegmentChip(
                          label: 'ALL SECTIONS',
                          isSelected: selectedSection == null,
                          onTap: () => ref.read(posSelectedSectionProvider.notifier).state = null,
                        ),
                        Gap(12.w),
                        ...sections.map((s) => Padding(
                              padding: EdgeInsets.only(right: 12.w),
                              child: _SectionSegmentChip(
                                label: s.toUpperCase(),
                                isSelected: selectedSection == s,
                                onTap: () => ref.read(posSelectedSectionProvider.notifier).state = s,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                Gap(16.w),
                const StatusChip(label: 'LIVE FLOORS', color: AppColors.success),
              ],
            ),
          ),

          // ── 2. Top Operational Summary Bar ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.isVerticalLayout ? 12.w : 16.w,
              vertical: 12.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryIndicator(
                    label: 'Occupied Tables',
                    value: '$occupiedCount',
                    icon: Icons.table_bar,
                    color: AppColors.primary,
                  ),
                ),
                Gap(context.isVerticalLayout ? 8.w : 16.w),
                Expanded(
                  child: _SummaryIndicator(
                    label: 'Payment Pending',
                    value: '$paymentPendingCount',
                    icon: Icons.pending_actions,
                    color: AppColors.cash,
                  ),
                ),
                Gap(context.isVerticalLayout ? 8.w : 16.w),
                Expanded(
                  child: _SummaryIndicator(
                    label: 'Active Kitchen Orders',
                    value: '$activeOrdersCount',
                    icon: Icons.restaurant,
                    color: AppColors.statusPreparing,
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Main Dining Floor Plan Grid & Quick Actions ────────────────
          Expanded(
            child: context.isVerticalLayout
                ? Column(
                    children: [
                      // Dining Room Grid (top panel)
                      Expanded(
                        flex: 6,
                        child: _buildGrid(tables),
                      ),
                      // Horizontal Divider
                      Container(height: 1.h, color: AppColors.border),
                      // Quick Actions (bottom panel)
                      Expanded(
                        flex: 4,
                        child: _buildQuickActionsPanel(ref),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dining Room Grid (left panel)
                      Expanded(
                        flex: 7,
                        child: _buildGrid(tables),
                      ),
                      // Divider line
                      Container(width: 1.w, color: AppColors.border),
                      // Quick Actions (right panel)
                      Expanded(
                        flex: 3,
                        child: _buildQuickActionsPanel(ref),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<dynamic> tables) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1600
            ? 5
            : (width > 1200
                ? 4
                : (width > 900
                    ? 3
                    : 2));
        final childAspectRatio = context.isVerticalLayout
            ? (width > 600 ? 1.42 : 1.50)
            : (width > 1200 ? 1.32 : 1.38);

        return GridView.builder(
          padding: EdgeInsets.all(16.r),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: tables.length,
          itemBuilder: (context, i) {
            final table = tables[i];
            final isSelected = _selectedTable?.id == table.id;
            return POSTableCard(
              table: table,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedTable = isSelected ? null : table;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionsPanel(WidgetRef ref) {
    return Container(
      color: AppColors.sidebarBg,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.titleLarge),
          Gap(16.h),
          if (_selectedTable != null) ...[
            _buildSelectedTablePanel(ref),
          ] else ...[
            const Expanded(
              child: Center(
                child: EmptyStateWidget(
                  icon: Icons.ads_click,
                  title: 'No Table Selected',
                  description: 'Select a physical dining table from the floor grid to trigger order actions, billing checkout, or status updates.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedTablePanel(WidgetRef ref) {
    final table = _selectedTable!;
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Brief table status card
          POSCard(
            backgroundColor: AppColors.surface,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: table.status.color.withValues(alpha: 0.15),
                  child: Text('${table.number}', style: AppTextStyles.labelLarge.copyWith(color: table.status.color)),
                ),
                Gap(16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Table ${table.number}', style: AppTextStyles.titleMedium),
                    Text(table.status.label.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: table.status.color)),
                  ],
                ),
              ],
            ),
          ),
          Gap(24.h),
          SectionHeader(title: 'Available Operations'),
          Gap(16.h),
          // Actions depending on table state
          if (table.status == POSTableStatus.available) ...[
            PrimaryButton(
              onPressed: () {
                // Seat table (mock Sarah waiter, 2 guests)
                ref.read(posTablesProvider.notifier).seatTable(table.id, 2, 'Sarah');
                ref.read(activeTableIdProvider.notifier).state = table.id;
                setState(() => _selectedTable = null);
              },
              text: 'SEAT GUESTS',
              icon: Icons.person_add_alt,
            ),
            Gap(12.h),
            SecondaryButton(
              onPressed: () {
                ref.read(activeTableIdProvider.notifier).state = table.id;
                context.go('/menu');
              },
              text: 'OPEN MENU BOOK',
              icon: Icons.menu_book,
            ),
          ] else ...[
            PrimaryButton(
              onPressed: () {
                // Open menu / add items for this table
                ref.read(activeTableIdProvider.notifier).state = table.id;
                context.go('/menu');
              },
              text: 'MANAGE ORDER ITEMS',
              icon: Icons.restaurant_menu,
            ),
            Gap(12.h),
            if (table.status == POSTableStatus.paymentPending) ...[
              PrimaryButton(
                onPressed: () {
                  // Direct route to checkout payments
                  ref.read(activeTableIdProvider.notifier).state = table.id;
                  context.go('/checkout');
                },
                text: 'PROCEED TO CHECKOUT',
                icon: Icons.payment,
              ),
              Gap(12.h),
            ] else ...[
              SecondaryButton(
                onPressed: () {
                  // Set billing checkout state
                  ref.read(posTablesProvider.notifier).updateStatus(table.id, POSTableStatus.paymentPending);
                  setState(() => _selectedTable = null);
                },
                text: 'REQUEST BILL / CHECKOUT',
                icon: Icons.receipt,
              ),
              Gap(12.h),
            ],
            DangerButton(
              onPressed: () async {
                final confirm = await showPOSConfirmationDialog(
                  context: context,
                  title: 'Vacate Table ${table.number}?',
                  description: 'Are you sure you want to clear this table? This will vacate all seated guests and clear all active order items.',
                  confirmText: 'VACATE TABLE',
                  isDanger: true,
                  icon: Icons.cleaning_services,
                );
                if (confirm == true) {
                  ref.read(posTablesProvider.notifier).clearTable(table.id);
                  setState(() => _selectedTable = null);
                }
              },
              text: 'CLEAR TABLE / VACATE',
              icon: Icons.cleaning_services,
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _SectionSegmentChip extends StatelessWidget {
  const _SectionSegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1,
      ),
    );
  }
}

class _SummaryIndicator extends StatelessWidget {
  const _SummaryIndicator({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            radius: 18.r,
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

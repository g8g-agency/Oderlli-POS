import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../constants/pos_constants.dart';
import '../../core/extensions/extensions.dart';

class FloorScreen extends ConsumerStatefulWidget {
  const FloorScreen({super.key});

  @override
  ConsumerState<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends ConsumerState<FloorScreen> {
  TableModel? _selectedTable;
  Timer? _refreshTimer;

  void _startRefreshTimer(int seconds) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (mounted) {
        final repo = ref.read(tableRepositoryProvider);
        if (repo.lastFetchFailedWith401) {
          debugPrint('[FloorScreen] Skipping refresh poll cycle because the last attempt failed with 401.');
          return;
        }
        ref.read(posTablesProvider.notifier).refreshTables();
        ref.read(ordersProvider.notifier).fetchOrders();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final initialSeconds = ref.read(posSettingsProvider).autoRefreshInterval;
    _startRefreshTimer(initialSeconds);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _selectTableForOrdering(String tableId) {
    ref.read(activeTableIdProvider.notifier).state = tableId;
    ref.read(cartSelectedTableProvider.notifier).state = tableId;
  }

  void _startCounterOrder() {
    final branchId = ref.read(authProvider).branchId;
    if (branchId == null) return;

    final counterTableId = PosConstants.counterTableId;
    _selectTableForOrdering(counterTableId);
    setState(() => _selectedTable = null);
    context.go('/menu');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      posSettingsProvider.select((s) => s.autoRefreshInterval),
      (previous, next) {
        if (next != previous) {
          _startRefreshTimer(next);
        }
      },
    );

    final tables = ref.watch(liveTableStatusProvider);
    // Filter by selected section (mirrors posFilteredTablesProvider logic but on enriched tables)
    final selectedSection = ref.watch(posSelectedSectionProvider);
    final filteredTables = selectedSection == null
        ? tables
        : tables.where((t) => t.sectionName == selectedSection).toList();

    final sections = ref.watch(posTableSectionsProvider);
    // Calculate operational summary stats dynamically
    final allTables = tables; // liveTableStatusProvider already returns all tables enriched
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
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  tooltip: 'Refresh Floor Plan',
                  onPressed: () {
                    ref.read(posTablesProvider.notifier).refreshTables();
                  },
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

          // ── 3. Counter / Walk-in shortcut ─────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: _startCounterOrder,
                icon: const Icon(Icons.storefront),
                label: const Text('COUNTER / WALK-IN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cash,
                  foregroundColor: Colors.white,
                  textStyle: AppTextStyles.labelLarge,
                ),
              ),
            ),
          ),

          // ── 4. Main Dining Floor Plan Grid & Quick Actions ────────────────
          Expanded(
            child: context.isVerticalLayout
                ? Column(
                    children: [
                      // Dining Room Grid (top panel)
                      Expanded(
                        flex: 6,
                        child: _buildGrid(filteredTables),
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
                        child: _buildGrid(filteredTables),
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

  Widget _buildGrid(List<TableModel> tables) {
    final allTablesAsync = ref.watch(posTablesProvider);

    if (allTablesAsync.isLoading && (allTablesAsync.valueOrNull ?? []).isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (allTablesAsync.hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: EmptyStateWidget(
            icon: Icons.wifi_off_outlined,
            title: 'Connection Error',
            description: 'Failed to fetch tables from the server. Please check your connection.\n${allTablesAsync.error}',
          ),
        ),
      );
    }

    if (tables.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          icon: Icons.table_restaurant_outlined,
          title: 'No Tables Configured',
          description: 'No tables found for this branch in the selected section.',
        ),
      );
    }

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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startCounterOrder,
              icon: const Icon(Icons.storefront),
              label: const Text('COUNTER / WALK-IN'),
            ),
          ),
          Gap(16.h),
          if (_selectedTable != null) ...[
            _buildSelectedTablePanel(ref),
          ] else ...[
            const Expanded(
              child: Center(
                child: EmptyStateWidget(
                  icon: Icons.ads_click,
                  title: 'No Table Selected',
                  description: 'Select a dining table from the floor grid, or use Counter / Walk-in for takeout orders.',
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
                final currentUserName = ref.read(authProvider).user?.name ?? 'Staff';
                ref.read(posTablesProvider.notifier).seatTable(table.id, 2, currentUserName);
                _selectTableForOrdering(table.id);
                setState(() => _selectedTable = null);
              },
              text: 'SEAT GUESTS',
              icon: Icons.person_add_alt,
            ),
            Gap(12.h),
            SecondaryButton(
              onPressed: () {
                final currentUserName = ref.read(authProvider).user?.name ?? 'Staff';
                ref.read(posTablesProvider.notifier).seatTable(table.id, 2, currentUserName);
                _selectTableForOrdering(table.id);
                context.go('/menu');
              },
              text: 'OPEN MENU BOOK',
              icon: Icons.menu_book,
            ),
          ] else ...[
            PrimaryButton(
              onPressed: () {
                // Open menu / add items for this table
                _selectTableForOrdering(table.id);
                context.go('/menu');
              },
              text: 'MANAGE ORDER ITEMS',
              icon: Icons.restaurant_menu,
            ),
            Gap(12.h),
            if (ref.read(authProvider).user?.role != UserRole.server) ...[
              if (table.status == POSTableStatus.paymentPending) ...[
                PrimaryButton(
                  onPressed: () {
                    // Direct route to checkout payments
                    _selectTableForOrdering(table.id);
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

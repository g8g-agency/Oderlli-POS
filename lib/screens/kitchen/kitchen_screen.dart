import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/extensions/extensions.dart';
import '../../mock/mock_data.dart';
import '../../models/order.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

// ─── SLA thresholds (minutes) ─────────────────────────────────────────────────
const int _slaWarning = 20;  // amber  — approaching breach
const int _slaCritical = 25; // red    — SLA breached

// ─── View filter ─────────────────────────────────────────────────────────────
enum _KdsView { all, preparing, delayed, ready }

// ─── Kitchen screen ───────────────────────────────────────────────────────────
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  late List<_KdsTicket> _tickets;
  Timer? _ticker;
  _KdsView _currentView = _KdsView.all;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tickets = _buildTickets();
    // Tick every second so elapsed times update live
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Build mock tickets from mock orders ────────────────────────────────────
  List<_KdsTicket> _buildTickets() {
    final orders = MockData.orders;
    final kitchenOrders = orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready)
        .toList();

    // Also add a couple of extra hard-coded delayed tickets for demo richness
    return [
      ...kitchenOrders.map((o) => _KdsTicket.fromOrder(o)),
      _KdsTicket(
        id: 'ord-demo-1',
        tableNumber: 6,
        section: 'Terrace',
        status: OrderStatus.preparing,
        createdAt: DateTime.now().subtract(const Duration(minutes: 27)),
        servedBy: 'Marco',
        items: [
          _KdsItem(name: 'BBQ Ribs Half-Rack', qty: 2, notes: 'Extra sauce'),
          _KdsItem(name: 'Garlic Bread', qty: 2),
          _KdsItem(name: 'House Red Wine (Glass)', qty: 2),
        ],
        priority: _TicketPriority.critical,
      ),
      _KdsTicket(
        id: 'ord-demo-2',
        tableNumber: 11,
        section: 'Terrace',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        servedBy: 'Sara',
        items: [
          _KdsItem(name: 'Tiramisu', qty: 2),
          _KdsItem(name: 'Espresso', qty: 2, notes: 'Double shot'),
        ],
        priority: _TicketPriority.normal,
      ),
      _KdsTicket(
        id: 'ord-demo-3',
        tableNumber: 5,
        section: 'Indoor',
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 22)),
        servedBy: 'Lena',
        items: [
          _KdsItem(name: 'Mushroom Risotto', qty: 1),
          _KdsItem(name: 'Margherita Pizza', qty: 1),
          _KdsItem(name: 'Sparkling Water (500ml)', qty: 2),
        ],
        priority: _TicketPriority.warning,
      ),
    ];
  }

  // ── Derived lists ─────────────────────────────────────────────────────────
  List<_KdsTicket> get _preparing =>
      _tickets.where((t) => t.status == OrderStatus.preparing).toList();

  List<_KdsTicket> get _pending =>
      _tickets.where((t) => t.status == OrderStatus.pending).toList();

  List<_KdsTicket> get _ready =>
      _tickets.where((t) => t.status == OrderStatus.ready).toList();

  List<_KdsTicket> get _delayed => _tickets
      .where((t) =>
          t.status != OrderStatus.ready &&
          _elapsedMinutes(t) >= _slaWarning)
      .toList();

  int _elapsedMinutes(_KdsTicket t) =>
      _now.difference(t.createdAt).inMinutes;

  List<_KdsTicket> get _filtered {
    switch (_currentView) {
      case _KdsView.all:
        return _tickets;
      case _KdsView.preparing:
        return _preparing;
      case _KdsView.delayed:
        return _delayed;
      case _KdsView.ready:
        return _ready;
    }
  }

  // ── Bump ticket to next status ─────────────────────────────────────────────
  void _bumpTicket(_KdsTicket ticket) {
    setState(() {
      final idx = _tickets.indexWhere((t) => t.id == ticket.id);
      if (idx < 0) return;
      final next = switch (ticket.status) {
        OrderStatus.pending => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.served,
        _ => ticket.status,
      };
      if (next == OrderStatus.served) {
        _tickets.removeAt(idx);
      } else {
        _tickets[idx] = ticket.copyWith(status: next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final preparingCount = _preparing.length;
    final pendingCount = _pending.length;
    final readyCount = _ready.length;
    final delayedCount = _delayed.length;
    final totalActive = _tickets.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────────
          _KdsTopBar(
            preparingCount: preparingCount,
            pendingCount: pendingCount,
            readyCount: readyCount,
            delayedCount: delayedCount,
            totalActive: totalActive,
            currentView: _currentView,
            onViewChanged: (v) => setState(() => _currentView = v),
            now: _now,
          ),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : _buildTicketGrid(_filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.soup_kitchen_outlined, size: 64.sp, color: AppColors.textTertiary),
          Gap(AppSpacing.md.h),
          Text(
            'No tickets in this view',
            style: AppTypography.titleLarge.copyWith(color: AppColors.textSecondary),
          ),
          Gap(AppSpacing.xs.h),
          Text(
            'All caught up! The kitchen is clear.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketGrid(List<_KdsTicket> tickets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1600
            ? 5
            : (width > 1200
                ? 4
                : (width > 900 ? 3 : 2));
        final ratio = columns == 1
            ? 1.7
            : (columns == 2
                ? 1.05
                : (columns == 3 ? 0.85 : 0.80));

        return GridView.builder(
          padding: EdgeInsets.all(16.r),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: ratio,
          ),
          itemCount: tickets.length,
          itemBuilder: (_, i) => _KdsTicketCard(
            ticket: tickets[i],
            elapsed: _elapsedMinutes(tickets[i]),
            onBump: () => _bumpTicket(tickets[i]),
          ),
        );
      },
    );
  }
}

// ─── Top operational bar ──────────────────────────────────────────────────────
class _KdsTopBar extends StatelessWidget {
  const _KdsTopBar({
    required this.preparingCount,
    required this.pendingCount,
    required this.readyCount,
    required this.delayedCount,
    required this.totalActive,
    required this.currentView,
    required this.onViewChanged,
    required this.now,
  });

  final int preparingCount;
  final int pendingCount;
  final int readyCount;
  final int delayedCount;
  final int totalActive;
  final _KdsView currentView;
  final ValueChanged<_KdsView> onViewChanged;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isVertical = context.isVerticalLayout;
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Padding(
            padding: EdgeInsets.fromLTRB(
              isVertical ? AppSpacing.sm.w : AppSpacing.lg.w,
              isVertical ? AppSpacing.xs.h : AppSpacing.sm.h,
              isVertical ? AppSpacing.sm.w : AppSpacing.lg.w,
              isVertical ? AppSpacing.xs.h : AppSpacing.xs.h,
            ),
            child: Row(
              children: [
                if (!isVertical) ...[
                  // KDS icon
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                    ),
                    child: Icon(Icons.soup_kitchen, color: AppColors.primary, size: 22.sp),
                  ),
                  Gap(AppSpacing.sm.w),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVertical ? 'Kitchen Queue' : 'Kitchen Display System',
                      style: AppTypography.headlineSmall,
                    ),
                    if (!isVertical)
                      Text(
                        'Live Order Queue · $totalActive active tickets',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const Spacer(),
                // Live clock
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVertical ? AppSpacing.sm.w : AppSpacing.md.w,
                    vertical: AppSpacing.xs.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      if (!isVertical) ...[
                        Icon(Icons.access_time, size: 14.sp, color: AppColors.primary),
                        Gap(AppSpacing.xs.w),
                      ],
                      Text(
                        timeStr,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(isVertical ? AppSpacing.xs.w : AppSpacing.sm.w),
                // Connection status
                const StatusChip(label: 'LIVE', color: AppColors.success),
              ],
            ),
          ),

          // Summary metrics row
          Container(
            height: 52.h,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(
                top: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                _SummaryTile(
                  icon: Icons.pending_actions,
                  label: 'Pending',
                  count: pendingCount,
                  color: AppColors.statusPending,
                  isActive: currentView == _KdsView.all,
                  onTap: () => onViewChanged(_KdsView.all),
                ),
                _SummaryTile(
                  icon: Icons.local_fire_department,
                  label: 'Preparing',
                  count: preparingCount,
                  color: AppColors.statusPreparing,
                  isActive: currentView == _KdsView.preparing,
                  onTap: () => onViewChanged(_KdsView.preparing),
                ),
                _SummaryTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Delayed',
                  count: delayedCount,
                  color: AppColors.error,
                  isActive: currentView == _KdsView.delayed,
                  onTap: () => onViewChanged(_KdsView.delayed),
                  isPulsing: delayedCount > 0,
                ),
                _SummaryTile(
                  icon: Icons.check_circle_outline,
                  label: 'Ready',
                  count: readyCount,
                  color: AppColors.statusReady,
                  isActive: currentView == _KdsView.ready,
                  onTap: () => onViewChanged(_KdsView.ready),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary tile in top bar ──────────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.isPulsing = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final bool isPulsing;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18.sp),
              Gap(AppSpacing.xs.w),
              Text(
                '$count',
                style: AppTypography.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Gap(AppSpacing.xs.w),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isActive ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ticket card ──────────────────────────────────────────────────────────────
class _KdsTicketCard extends StatelessWidget {
  const _KdsTicketCard({
    required this.ticket,
    required this.elapsed,
    required this.onBump,
  });

  final _KdsTicket ticket;
  final int elapsed;
  final VoidCallback onBump;

  Color get _slaColor {
    if (ticket.status == OrderStatus.ready) return AppColors.statusReady;
    if (elapsed >= _slaCritical) return AppColors.error;
    if (elapsed >= _slaWarning) return AppColors.warning;
    return AppColors.statusPreparing;
  }

  Color get _headerBg {
    if (ticket.status == OrderStatus.ready) return AppColors.statusReadyContainer;
    if (elapsed >= _slaCritical) return AppColors.errorContainer;
    if (elapsed >= _slaWarning) return AppColors.warningContainer;
    if (ticket.status == OrderStatus.preparing) return AppColors.statusPreparingContainer;
    return AppColors.statusPendingContainer;
  }

  String get _statusLabel {
    if (ticket.status == OrderStatus.ready) return 'READY';
    if (elapsed >= _slaCritical) return 'OVERDUE';
    if (elapsed >= _slaWarning) return 'DELAYED';
    if (ticket.status == OrderStatus.preparing) return 'PREPARING';
    return 'PENDING';
  }

  String get _bumpLabel {
    return switch (ticket.status) {
      OrderStatus.pending => 'START PREPARING',
      OrderStatus.preparing => 'MARK READY',
      OrderStatus.ready => 'SERVE & CLEAR',
      _ => 'DONE',
    };
  }

  IconData get _bumpIcon {
    return switch (ticket.status) {
      OrderStatus.pending => Icons.play_arrow_rounded,
      OrderStatus.preparing => Icons.done_all_rounded,
      OrderStatus.ready => Icons.delivery_dining_rounded,
      _ => Icons.check_rounded,
    };
  }

  Color get _bumpColor {
    return switch (ticket.status) {
      OrderStatus.pending => AppColors.primary,
      OrderStatus.preparing => AppColors.statusPreparing,
      OrderStatus.ready => AppColors.statusReady,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = elapsed >= _slaCritical && ticket.status != OrderStatus.ready;
    final elapsedStr = elapsed >= 60
        ? '${elapsed ~/ 60}h ${elapsed % 60}m'
        : '${elapsed}m';

    return POSCard(
      borderColor: _slaColor.withValues(alpha: 0.6),
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 220.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card header ────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.sm.h,
              ),
              decoration: BoxDecoration(
                color: _headerBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLG.r),
                  topRight: Radius.circular(AppSpacing.radiusLG.r),
                ),
              ),
              child: Row(
                children: [
                  // Table badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs.w,
                      vertical: AppSpacing.xxs.h,
                    ),
                    decoration: BoxDecoration(
                      color: _slaColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
                      border: Border.all(color: _slaColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'T${ticket.tableNumber}',
                      style: AppTypography.titleMedium.copyWith(
                        color: _slaColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Gap(AppSpacing.xs.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.section,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (ticket.servedBy != null)
                          Text(
                            ticket.servedBy!,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Status chip
                  StatusChip(label: _statusLabel, color: _slaColor),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────────────────
            Container(height: 1, color: AppColors.border),

            // ── SLA timer bar ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md.w, AppSpacing.xs.h, AppSpacing.md.w, AppSpacing.xxs.h),
              child: _SlaTimerRow(
                elapsed: elapsed,
                elapsedStr: elapsedStr,
                slaColor: _slaColor,
                isCritical: isCritical,
              ),
            ),

            Container(height: 1, color: AppColors.borderSubtle),

            // ── Items list ─────────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(AppSpacing.sm.r),
                itemCount: ticket.items.length,
                separatorBuilder: (context, index) =>
                    Divider(color: AppColors.borderSubtle, height: AppSpacing.sm.h),
                itemBuilder: (_, i) {
                  final item = ticket.items[i];
                  return _KdsItemRow(item: item, slaColor: _slaColor);
                },
              ),
            ),

            Container(height: 1, color: AppColors.border),

            // ── Action button ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm.r),
              child: PrimaryButton(
                onPressed: onBump,
                text: _bumpLabel,
                icon: _bumpIcon,
                backgroundColor: _bumpColor,
                height: 44.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SLA timer row ────────────────────────────────────────────────────────────
class _SlaTimerRow extends StatelessWidget {
  const _SlaTimerRow({
    required this.elapsed,
    required this.elapsedStr,
    required this.slaColor,
    required this.isCritical,
  });

  final int elapsed;
  final String elapsedStr;
  final Color slaColor;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final progress = (elapsed / _slaCritical).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 13.sp, color: slaColor),
            Gap(AppSpacing.xxs.w),
            Text(
              elapsedStr,
              style: AppTypography.labelMedium.copyWith(
                color: slaColor,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            if (isCritical)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded, size: 12.sp, color: AppColors.error),
                  Gap(AppSpacing.xxs.w),
                  Text(
                    'SLA BREACH',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
        Gap(AppSpacing.xxs.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: AppSpacing.xxs.h,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(slaColor),
          ),
        ),
      ],
    );
  }
}

// ─── Item row inside ticket ───────────────────────────────────────────────────
class _KdsItemRow extends StatelessWidget {
  const _KdsItemRow({required this.item, required this.slaColor});

  final _KdsItem item;
  final Color slaColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Qty badge
            Container(
              width: 28.w,
              height: 22.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXS.r),
              ),
              child: Text(
                '${item.qty}×',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Gap(AppSpacing.xs.w),
            Expanded(
              child: Text(
                item.name,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        if (item.notes != null && item.notes!.isNotEmpty) ...[
          Gap(AppSpacing.xxs.h),
          Padding(
            padding: EdgeInsets.only(left: 38.w),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 10.sp, color: AppColors.warning),
                Gap(AppSpacing.xxs.w),
                Expanded(
                  child: Text(
                    item.notes!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}



// ─── Data models ──────────────────────────────────────────────────────────────
enum _TicketPriority { normal, warning, critical }

class _KdsItem {
  const _KdsItem({required this.name, required this.qty, this.notes});
  final String name;
  final int qty;
  final String? notes;
}

class _KdsTicket {
  const _KdsTicket({
    required this.id,
    required this.tableNumber,
    required this.section,
    required this.status,
    required this.createdAt,
    required this.items,
    this.servedBy,
    this.priority = _TicketPriority.normal,
  });

  final String id;
  final int tableNumber;
  final String section;
  final OrderStatus status;
  final DateTime createdAt;
  final List<_KdsItem> items;
  final String? servedBy;
  final _TicketPriority priority;

  factory _KdsTicket.fromOrder(Order order) {
    return _KdsTicket(
      id: order.id,
      tableNumber: order.tableNumber,
      section: 'Indoor',
      status: order.status,
      createdAt: order.createdAt,
      servedBy: order.servedBy,
      items: order.items
          .map((oi) => _KdsItem(
                name: oi.menuItem.name,
                qty: oi.quantity,
                notes: oi.notes,
              ))
          .toList(),
    );
  }

  _KdsTicket copyWith({OrderStatus? status}) => _KdsTicket(
        id: id,
        tableNumber: tableNumber,
        section: section,
        status: status ?? this.status,
        createdAt: createdAt,
        items: items,
        servedBy: servedBy,
        priority: priority,
      );
}

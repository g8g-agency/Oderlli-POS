import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/extensions/extensions.dart';
import '../../features/kitchen/models/kitchen_item.dart';
import '../../features/kitchen/models/kitchen_item_status.dart';
import '../../features/kitchen/models/kitchen_ticket.dart';
import '../../features/kitchen/models/kitchen_ticket_status.dart';
import '../../features/kitchen/providers/kitchen_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

// ─── SLA thresholds (minutes) ─────────────────────────────────────────────────
const int _slaWarning = 10;  // amber  — approaching breach
const int _slaCritical = 20; // red    — SLA breached

// ─── View filter ─────────────────────────────────────────────────────────────
enum _KdsView { all, preparing, delayed, ready }

// ─── Kitchen screen ───────────────────────────────────────────────────────────
class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  Timer? _clockTicker;
  Timer? _refreshTimer;
  _KdsView _currentView = _KdsView.all;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Tick every second so elapsed times update live
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // Auto-refresh from backend every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(kitchenProvider.notifier).refreshTickets();
      }
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Derived filter from view ───────────────────────────────────────────────
  int _elapsedMinutes(KitchenTicket t) {
    // Prefer server-reported elapsedSeconds; fall back to local clock diff
    if (t.elapsedSeconds > 0) return t.elapsedSeconds ~/ 60;
    return _now.difference(t.createdAt).inMinutes;
  }

  List<KitchenTicket> _applyViewFilter(List<KitchenTicket> tickets) {
    return switch (_currentView) {
      _KdsView.all => tickets,
      _KdsView.preparing =>
        tickets.where((t) => t.status == KitchenTicketStatus.preparing).toList(),
      _KdsView.delayed => tickets
          .where((t) =>
              t.status != KitchenTicketStatus.ready && _elapsedMinutes(t) >= _slaWarning)
          .toList(),
      _KdsView.ready =>
        tickets.where((t) => t.status == KitchenTicketStatus.ready).toList(),
    };
  }

  // ── Bump ticket to next FSM status ────────────────────────────────────────
  void _bumpTicket(KitchenTicket ticket) {
    final nextStatus = kNextTicketStatus[ticket.status];
    if (nextStatus == null) return;
    ref.read(kitchenProvider.notifier).bumpTicket(ticket.ticketId, nextStatus);
  }

  @override
  Widget build(BuildContext context) {
    final kitchenState = ref.watch(kitchenProvider);
    final allActive = kitchenState.activeTickets;
    final filtered = _applyViewFilter(allActive);

    final preparingCount = allActive.where((t) => t.status == KitchenTicketStatus.preparing).length;
    final pendingCount = allActive.where((t) => t.status == KitchenTicketStatus.pending).length;
    final readyCount = allActive.where((t) => t.status == KitchenTicketStatus.ready).length;
    final delayedCount = allActive.where((t) => _elapsedMinutes(t) >= _slaWarning).length;
    final totalActive = allActive.length;

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
            isRefreshing: kitchenState.isLoading,
            onRefresh: () => ref.read(kitchenProvider.notifier).refreshTickets(),
          ),

          // ── Error banner ───────────────────────────────────────────────────
          if (kitchenState.error != null && allActive.isEmpty)
            _buildErrorBanner(kitchenState.error!),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: kitchenState.isLoading && allActive.isEmpty
                ? _buildLoadingState()
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildTicketGrid(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      color: AppColors.errorContainer,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16.sp, color: AppColors.error),
          Gap(AppSpacing.xs.w),
          Expanded(
            child: Text(
              'Unable to reach server — showing cached data',
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(kitchenProvider.notifier).loadTickets(),
            child: Text('Retry', style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          Gap(AppSpacing.md.h),
          Text(
            'Loading kitchen queue…',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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

  Widget _buildTicketGrid(List<KitchenTicket> tickets) {
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
    required this.isRefreshing,
    required this.onRefresh,
  });

  final int preparingCount;
  final int pendingCount;
  final int readyCount;
  final int delayedCount;
  final int totalActive;
  final _KdsView currentView;
  final ValueChanged<_KdsView> onViewChanged;
  final DateTime now;
  final bool isRefreshing;
  final VoidCallback onRefresh;

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
                // Refresh button
                IconButton(
                  icon: isRefreshing
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(Icons.refresh_rounded, size: 20.sp, color: AppColors.textSecondary),
                  onPressed: isRefreshing ? null : onRefresh,
                  tooltip: 'Refresh queue',
                ),
                Gap(AppSpacing.xs.w),
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

  final KitchenTicket ticket;
  final int elapsed;
  final VoidCallback onBump;

  Color get _slaColor {
    if (ticket.status == KitchenTicketStatus.ready) return AppColors.statusReady;
    if (elapsed >= _slaCritical) return AppColors.error;
    if (elapsed >= _slaWarning) return AppColors.warning;
    return AppColors.statusPreparing;
  }

  Color get _headerBg {
    if (ticket.status == KitchenTicketStatus.ready) return AppColors.statusReadyContainer;
    if (elapsed >= _slaCritical) return AppColors.errorContainer;
    if (elapsed >= _slaWarning) return AppColors.warningContainer;
    if (ticket.status == KitchenTicketStatus.preparing) return AppColors.statusPreparingContainer;
    return AppColors.statusPendingContainer;
  }

  String get _statusLabel {
    if (ticket.status == KitchenTicketStatus.ready) return 'READY';
    if (ticket.isOverdue || elapsed >= _slaCritical) return 'OVERDUE';
    if (elapsed >= _slaWarning) return 'DELAYED';
    if (ticket.status == KitchenTicketStatus.preparing) return 'PREPARING';
    if (ticket.status == KitchenTicketStatus.accepted) return 'ACCEPTED';
    return 'PENDING';
  }

  String get _bumpLabel {
    return switch (ticket.status) {
      KitchenTicketStatus.pending => 'START PREPARING',
      KitchenTicketStatus.accepted => 'START PREPARING',
      KitchenTicketStatus.preparing => 'MARK READY',
      KitchenTicketStatus.ready => 'SERVE & CLEAR',
      KitchenTicketStatus.delivered => 'DONE',
    };
  }

  IconData get _bumpIcon {
    return switch (ticket.status) {
      KitchenTicketStatus.pending || KitchenTicketStatus.accepted =>
        Icons.play_arrow_rounded,
      KitchenTicketStatus.preparing => Icons.done_all_rounded,
      KitchenTicketStatus.ready => Icons.delivery_dining_rounded,
      KitchenTicketStatus.delivered => Icons.check_rounded,
    };
  }

  Color get _bumpColor {
    return switch (ticket.status) {
      KitchenTicketStatus.pending || KitchenTicketStatus.accepted =>
        AppColors.primary,
      KitchenTicketStatus.preparing => AppColors.statusPreparing,
      KitchenTicketStatus.ready => AppColors.statusReady,
      KitchenTicketStatus.delivered => AppColors.primary,
    };
  }

  bool get _canBump => ticket.status != KitchenTicketStatus.delivered;

  @override
  Widget build(BuildContext context) {
    final isCritical = (elapsed >= _slaCritical || ticket.isOverdue) &&
        ticket.status != KitchenTicketStatus.ready;
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
            // ── Card header ──────────────────────────────────────────────────
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
                          ticket.orderNumber,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  StatusChip(label: _statusLabel, color: _slaColor),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            Container(height: 1, color: AppColors.border),

            // ── SLA timer bar ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md.w,
                AppSpacing.xs.h,
                AppSpacing.md.w,
                AppSpacing.xxs.h,
              ),
              child: _SlaTimerRow(
                elapsed: elapsed,
                elapsedStr: elapsedStr,
                slaColor: _slaColor,
                isCritical: isCritical,
              ),
            ),

            Container(height: 1, color: AppColors.borderSubtle),

            // ── Items list ────────────────────────────────────────────────
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

            // ── Action button ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm.r),
              child: PrimaryButton(
                onPressed: _canBump ? onBump : null,
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

  final KitchenItem item;
  final Color slaColor;

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == KitchenItemStatus.completed ||
        item.status == KitchenItemStatus.cancelled;

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
                color: isDone
                    ? AppColors.surfaceVariant
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXS.r),
              ),
              child: Text(
                '${item.quantity}×',
                style: AppTypography.labelMedium.copyWith(
                  color: isDone ? AppColors.textTertiary : AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Gap(AppSpacing.xs.w),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDone ? AppColors.textTertiary : null,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (item.stationName != null) ...[
                    Gap(AppSpacing.xs.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXS.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        item.stationName!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ],
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

import 'package:flutter/material.dart';

/// ─── Orderlli POS · Colour System ───────────────────────────────────────────
///
/// Light operational palette designed for:
///  • High-contrast light surfaces for modern restaurant environments
///  • Financial clarity (unambiguous positive / negative / neutral signals)
///  • 24-hour operational readability with Action Orange and white surfaces
///
/// Usage: AppColors.surface, AppColors.profit, AppColors.ready …
abstract final class AppColors {
  // ── Base backgrounds ────────────────────────────────────────────────────────
  /// Deepest app background — behind every panel (Stitch background: #f8f9ff)
  static const Color background = Color(0xFFF8F9FF);

  /// Primary surface — cards, panels, dialogs (Stitch surface: #ffffff)
  static const Color surface = Color(0xFFFFFFFF);

  /// Elevated surface — modals, dropdowns, popovers (Stitch surface-container: #e7eefb)
  static const Color surfaceElevated = Color(0xFFE7EEFB);

  /// Subtle variant — input fields, chip backgrounds (Stitch surface-variant: #dce3f0)
  static const Color surfaceVariant = Color(0xFFDCE3F0);

  /// Overlay tint — hover, pressed states
  static const Color surfaceOverlay = Color(0x0C151C25);

  // ── Sidebar ─────────────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarSurface = Color(0xFFF8F9FF);
  static const Color sidebarActive = Color(0xFFE31E24);
  static const Color sidebarActiveBg = Color(0xFFFEE8E9); // Stitch primary-fixed
  static const Color sidebarText = Color(0xFF1A1C1E); // Stitch on-surface-variant
  static const Color sidebarTextActive = Color(0xFF5C2800); // Stitch on-primary-container
  static const Color sidebarDivider = Color(0xFFE0C0AF); // Stitch outline-variant

  // ── Brand / Primary ─────────────────────────────────────────────────────────
  /// Deep Brand Orange/Brown (Stitch primary: #994700)
  static const Color primary = Color(0xFFE31E24);
  static const Color primaryLight = Color(0xFFE31E24); // Stitch primary-container
  static const Color primaryDark = Color(0xFFB0121A); // Stitch on-primary-fixed-variant
  static const Color primaryContainer = Color(0xFFE31E24);

  // ── Financial colours ────────────────────────────────────────────────────────
  /// Revenue, positive delta, successful payment
  static const Color profit = Color(0xFF22C55E);
  static const Color profitDim = Color(0xFF16A34A);
  static const Color profitContainer = Color(0xFFDCFCE7);

  /// Refund, negative delta, loss, discount warning
  static const Color loss = Color(0xFFEF4444);
  static const Color lossDim = Color(0xFFDC2626);
  static const Color lossContainer = Color(0xFFFEE2E2);

  /// Neutral amount, pending payment, tax line
  static const Color neutral = Color(0xFF3B82F6);
  static const Color neutralDim = Color(0xFF2563EB);
  static const Color neutralContainer = Color(0xFFDBEAFE);

  /// Cash tender
  static const Color cash = Color(0xFFFFD166);
  static const Color cashContainer = Color(0xFFFEF3C7);

  // ── Operational status colours ────────────────────────────────────────────────
  /// Table / order: awaiting action
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingContainer = Color(0xFFFEF3C7);

  /// Kitchen actively working on order
  static const Color statusPreparing = Color(0xFF3B82F6);
  static const Color statusPreparingContainer = Color(0xFFDBEAFE);

  /// Order ready, waiting to be picked up / served
  static const Color statusReady = Color(0xFF22C55E);
  static const Color statusReadyContainer = Color(0xFFDCFCE7);

  /// Order delivered to table
  static const Color statusServed = Color(0xFF6C757D);
  static const Color statusServedContainer = Color(0xFFF3F4F6);

  /// Void / cancelled
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCancelledContainer = Color(0xFFFEE2E2);

  // ── Table status colours ──────────────────────────────────────────────────────
  static const Color tableAvailable = Color(0xFF10B981);
  static const Color tableOccupied = Color(0xFF8B5CF6);
  static const Color tableReserved = Color(0xFFFFD166);
  static const Color tableCleaning = Color(0xFF3B82F6);
  static const Color tableBlocked = Color(0xFF9CA3AF);

  // ── Semantic system colours ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFBA1A1A); // Stitch error: #ba1a1a
  static const Color errorContainer = Color(0xFFFEDAD6); // Stitch error-container: #ffdad6
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ── Operational States (Stitch request) ───────────────────────────────────────
  static const Color preparing = Color(0xFF3B82F6);
  static const Color ready = Color(0xFF22C55E);
  static const Color pending = Color(0xFFF59E0B);
  static const Color delayed = Color(0xFFEF4444);
  static const Color occupied = Color(0xFF8B5CF6);
  static const Color available = Color(0xFF10B981);

  // ── Financial States (Stitch request) ──────────────────────────────────────────
  static const Color paid = Color(0xFF22C55E);
  static const Color unpaid = Color(0xFFEF4444);
  static const Color partialPaid = Color(0xFFF59E0B);
  static const Color refunded = Color(0xFF6366F1);

  // ── Sync States (Stitch request) ───────────────────────────────────────────────
  static const Color syncing = Color(0xFF0EA5E9);
  static const Color reconnecting = Color(0xFFF97316);
  static const Color offline = Color(0xFF6C757D);

  // ── Text ─────────────────────────────────────────────────────────────────────
  /// Primary readable text (Stitch on-surface: #151c25)
  static const Color textPrimary = Color(0xFF1A1C1E);

  /// Secondary / supporting text (Stitch on-surface-variant: #584235)
  static const Color textSecondary = Color(0xFF1A1C1E);

  /// Tertiary / captions, placeholders
  static const Color textTertiary = Color(0xFF6C757D);

  /// Disabled state text
  static const Color textDisabled = Color(0xFF9CA3AF);

  /// Text on coloured containers (primary buttons, badges)
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnSuccess = Color(0xFF064E3B);
  static const Color textOnWarning = Color(0xFF78350F);

  // ── Borders & dividers ───────────────────────────────────────────────────────
  static const Color border = Color(0xFF8C7263); // Stitch outline: #8c7263
  static const Color borderSubtle = Color(0xFFE0C0AF); // Stitch outline-variant: #e0c0af
  static const Color borderFocus = Color(0xFFE31E24);
  static const Color divider = Color(0xFFDEE0E2); // Stitch secondary-container: #dee0e2

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static const Color shadowDeep = Color(0x0C000000);    // 4% black
  static const Color shadowMedium = Color(0x08000000);  // 3% black
  static const Color shadowLight = Color(0x04000000);   // 1.5% black
  static const Color glowPrimary = Color(0x1AFF7A00);   // orange glow
  static const Color glowSuccess = Color(0x1A22C55E);   // green glow
}

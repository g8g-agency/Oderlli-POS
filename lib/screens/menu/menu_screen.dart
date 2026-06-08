import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';
import '../../routes/app_routes.dart';

/// ─── Light POS Design Palette Colors ─────────────────────────────────────────
abstract final class LightPOSColors {
  static const Color primary = Color(0xFFFF7A00);
  static const Color primaryLight = Color(0xFFFFA352);
  static const Color background = Color(0xFFF6F7F9);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  
  static const Color shadowColor = Color(0x0A000000);

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x04000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x04000000),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}

/// ─── Light POS Typography System ─────────────────────────────────────────────
abstract final class LightPOSTypography {
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 26.sp,
        fontWeight: FontWeight.w800,
        color: LightPOSColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: LightPOSColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: LightPOSColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: LightPOSColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: LightPOSColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: LightPOSColors.textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: LightPOSColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: LightPOSColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
        color: LightPOSColors.textSecondary,
        letterSpacing: 0.5,
      );
}

/// ─── New Order Screen ────────────────────────────────────────────────────────
///
/// A premium, tablet-first POS menu selector screen. Styled with a clean
/// light operational palette, custom left sidebar, responsive central item grid,
/// and an interactive draft checkout cart panel.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);
    
    final categories = categoriesAsync.valueOrNull ?? [];
    final selectedCat = ref.watch(selectedCategoryProvider);
    final items = ref.watch(searchedMenuItemsProvider);
    final cartState = ref.watch(posCartProvider);
    
    // Watch active table metadata
    final tableId = ref.watch(activeTableIdProvider);
    final tables = ref.watch(posTablesProvider).valueOrNull ?? [];
    final activeTable = tableId != null
        ? (tables.isEmpty
            ? null
            : tables.firstWhere((t) => t.id == tableId, orElse: () => tables.first))
        : null;

    final isVertical = context.isVerticalLayout;

    // Center grid contents
    final menuGridContent = Container(
      color: LightPOSColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Search Row ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 0),
            child: POSHeader(activeTable: activeTable),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
            child: POSSearchBar(
              onChanged: (q) => ref.read(menuSearchQueryProvider.notifier).state = q,
            ),
          ),

          // ── Categories Bar ────────────────────────────────────────────────
          Container(
            height: 46.h,
            margin: EdgeInsets.only(bottom: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final isSelected = isAll ? selectedCat == null : selectedCat == categories[index - 1].id;
                final label = isAll ? 'All Dishes' : categories[index - 1].name;
                final icon = isAll ? '🍽️' : categories[index - 1].icon;
                final catId = isAll ? null : categories[index - 1].id;

                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs.w),
                  child: CategoryChip(
                    label: label,
                    icon: icon,
                    isSelected: isSelected,
                    onSelected: () => ref.read(selectedCategoryProvider.notifier).state = catId,
                  ),
                );
              },
            ),
          ),

          // ── Menu Items Grid ───────────────────────────────────────────────
          Expanded(
            child: menuItemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: LightPOSColors.primary,
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: EmptyStateWidget(
                    icon: Icons.wifi_off_outlined,
                    title: 'Connection Error',
                    description: 'Failed to fetch menu items from the server. Please check your connection.\n$err',
                  ),
                ),
              ),
              data: (_) {
                if (items.isEmpty) {
                  return const Center(
                    child: EmptyStateWidget(
                      icon: Icons.search_off_outlined,
                      title: 'No Items Found',
                      description: 'No menu products match your search query or selected category filter.',
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
                            : (width > 900 ? 3 : 2));
                    // Dynamically calculate aspect ratio so card details never overflow
                    final cardWidth = (width - 32.r - (crossAxisCount - 1) * 12.w) / crossAxisCount;
                    // Ensure card height is at least 195.h to prevent vertical layout overflows in the details container
                    final cardHeight = (cardWidth * 1.15).clamp(195.h, 240.h);
                    final childAspectRatio = cardWidth / cardHeight;

                    return GridView.builder(
                      padding: EdgeInsets.all(16.r),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final cartIndex = cartState.items.indexWhere((c) => c.menuItem.id == item.id);
                        final qtyInCart = cartIndex >= 0 ? cartState.items[cartIndex].qty : 0;

                        return MenuItemCard(
                          item: item,
                          qtyInCart: qtyInCart,
                          onAdd: () => ref.read(posCartProvider.notifier).addItem(item),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    // If Portrait view or Narrow screen, wrap in simple vertical column
    if (isVertical) {
      return Scaffold(
        backgroundColor: LightPOSColors.background,
        appBar: AppBar(
          backgroundColor: LightPOSColors.sidebarBg,
          title: Text('Orderlyy POS', style: LightPOSTypography.headlineMedium),
          iconTheme: const IconThemeData(color: LightPOSColors.textPrimary),
          elevation: 0,
        ),
        drawer: const Drawer(
          child: POSSidebar(activeRoute: AppRoutes.menu),
        ),
        body: SafeArea(child: menuGridContent),
        floatingActionButton: Badge(
          label: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Text(
              '${cartState.totalQty}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          isLabelVisible: cartState.items.isNotEmpty,
          backgroundColor: LightPOSColors.primary,
          child: FloatingActionButton(
            onPressed: () => context.go('/cart'),
            backgroundColor: LightPOSColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        ),
      );
    }

    // Tablet-First Landscape Layout
    return Scaffold(
      backgroundColor: LightPOSColors.background,
      body: Row(
        children: [
          // ── 1. Widescreen Left Sidebar ─────────────────────────────────────
          const POSSidebar(activeRoute: AppRoutes.menu),
          
          // ── 2. Menu Catalog Workspace (Center) ─────────────────────────────
          Expanded(
            child: menuGridContent,
          ),

          // Divider
          Container(width: 1.w, color: LightPOSColors.border),

          // ── 3. Active Checkout Cart Panel (Right) — fixed width for robust landscape proportions
          SizedBox(
            width: AppLayoutConstants.orderPanelWidth.w,
            child: OrderCartPanel(
              cartState: cartState,
              activeTable: activeTable,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Component: POSSidebar ──────────────────────────────────────────────────
class POSSidebar extends StatelessWidget {
  const POSSidebar({super.key, required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayoutConstants.sidebarWidth.w,
      height: double.infinity,
      color: LightPOSColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo header
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg.r),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: LightPOSColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                ),
                Gap(AppSpacing.sm.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orderlyy',
                      style: LightPOSTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const StatusIndicator(),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: LightPOSColors.border),
          Gap(AppSpacing.md.h),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
              children: [
                _buildNavItem(context, 'Dashboard', Icons.dashboard_outlined, AppRoutes.dashboard),
                _buildNavItem(context, 'Floor Plan', Icons.table_restaurant_outlined, AppRoutes.floor),
                _buildNavItem(context, 'New Order', Icons.shopping_bag_outlined, AppRoutes.menu),
                _buildNavItem(context, 'Shifts', Icons.vpn_key_outlined, AppRoutes.shifts),
                _buildNavItem(context, 'Settings', Icons.settings_outlined, AppRoutes.settings),
                
                Gap(AppSpacing.lg.h),
                const Divider(color: LightPOSColors.border),
                Gap(AppSpacing.md.h),

                // Metrics Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                  child: Text(
                    'LIVE PERFORMANCE',
                    style: LightPOSTypography.labelSmall.copyWith(
                      color: LightPOSColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Gap(AppSpacing.xs.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(Icons.table_restaurant, '4/12', 'Tables'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cashier Profile footer
          const Divider(height: 1, color: LightPOSColors.border),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg.r),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: LightPOSColors.background,
                  radius: 20.r,
                  child: Text(
                    'SJ',
                    style: LightPOSTypography.titleMedium.copyWith(color: LightPOSColors.primary),
                  ),
                ),
                Gap(AppSpacing.sm.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarah Jenkins',
                        style: LightPOSTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Cashier • Terminal 1',
                        style: LightPOSTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData icon, String route) {
    final isActive = activeRoute == route;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xxs.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
          onTap: () {
            context.go(route);
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w, vertical: AppSpacing.sm.h),
            decoration: BoxDecoration(
              color: isActive ? LightPOSColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
            ),
            child: Row(
              children: [
                // Left indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 3.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: isActive ? LightPOSColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Gap(isActive ? AppSpacing.xs.w : AppSpacing.xs.w + 3.w),
                Icon(
                  icon,
                  color: isActive ? LightPOSColors.primary : LightPOSColors.textSecondary,
                  size: 20.sp,
                ),
                Gap(AppSpacing.sm.w),
                Expanded(
                  child: Text(
                    label,
                    style: LightPOSTypography.bodyMedium.copyWith(
                      color: isActive ? LightPOSColors.primary : LightPOSColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xs.r),
      decoration: BoxDecoration(
        color: LightPOSColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
        border: Border.all(color: LightPOSColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LightPOSColors.primary, size: 14.sp),
          Gap(AppSpacing.xxs.h),
          Text(
            value,
            style: LightPOSTypography.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: LightPOSTypography.bodySmall.copyWith(fontSize: 9.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// ─── Component: POSHeader ───────────────────────────────────────────────────
class POSHeader extends StatelessWidget {
  const POSHeader({super.key, this.activeTable});

  final dynamic activeTable;

  @override
  Widget build(BuildContext context) {
    final hasTable = activeTable != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('New Order', style: LightPOSTypography.headlineLarge),
        Gap(AppSpacing.xxs.h),
        Wrap(
          spacing: 4.w,
          runSpacing: 4.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildMetadataItem(Icons.devices_other, 'Terminal 1'),
            _buildDotSeparator(),
            _buildMetadataItem(Icons.person_outline, 'Sarah Jenkins'),
            _buildDotSeparator(),
            _buildMetadataItem(
              Icons.table_bar_outlined,
              hasTable ? 'Table ${activeTable.number}' : 'Quick Order',
            ),
            if (hasTable) ...[
              _buildDotSeparator(),
              _buildMetadataItem(Icons.people_outline, '${activeTable.guestCount} Guests'),
            ],
            _buildDotSeparator(),
            _buildMetadataItem(Icons.delivery_dining_outlined, 'Dine-In'),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: LightPOSColors.textSecondary, size: 13.sp),
        Gap(4.w),
        Text(text, style: LightPOSTypography.bodySmall),
      ],
    );
  }

  Widget _buildDotSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
      child: Text(
        '•',
        style: TextStyle(color: LightPOSColors.textSecondary, fontSize: 12.sp),
      ),
    );
  }
}

/// ─── Component: POSSearchBar ────────────────────────────────────────────────
class POSSearchBar extends StatelessWidget {
  const POSSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        boxShadow: LightPOSColors.softShadow,
      ),
      child: TextField(
        onChanged: onChanged,
        style: LightPOSTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search menu dishes, beverages, toppings...',
          hintStyle: LightPOSTypography.bodySmall,
          prefixIcon: const Icon(Icons.search, color: LightPOSColors.textSecondary),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: AppSpacing.md.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
            borderSide: const BorderSide(color: LightPOSColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
            borderSide: const BorderSide(color: LightPOSColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
            borderSide: const BorderSide(color: LightPOSColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// ─── Component: CategoryChip ────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [LightPOSColors.primary, LightPOSColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        border: isSelected ? null : Border.all(color: LightPOSColors.border),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: LightPOSColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : LightPOSColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 44.h),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.xs.h),
            alignment: Alignment.center,
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: 16.sp)),
                Gap(AppSpacing.xs.w),
                Text(
                  label,
                  style: LightPOSTypography.titleMedium.copyWith(
                    color: isSelected ? Colors.white : LightPOSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── Component: MenuItemCard ────────────────────────────────────────────────
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.qtyInCart,
    required this.onAdd,
  });

  final MenuItem item;
  final int qtyInCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final hasInCart = qtyInCart > 0;

    return Container(
      constraints: BoxConstraints(minHeight: 180.h),
      decoration: BoxDecoration(
        color: LightPOSColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasInCart ? LightPOSColors.primary : LightPOSColors.border,
          width: hasInCart ? 1.5 : 1,
        ),
        boxShadow: hasInCart
            ? [
                BoxShadow(
                  color: LightPOSColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : LightPOSColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onAdd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / Emoji Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: LightPOSColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Emoji Container
                      Container(
                        width: 58.r,
                        height: 58.r,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getCategoryEmoji(item.categoryId),
                          style: TextStyle(fontSize: 28.sp),
                        ),
                      ),
                      
                      // Cart item quantity indicator (top-right badge)
                      if (hasInCart)
                        Positioned(
                          top: AppSpacing.sm.h,
                          right: AppSpacing.sm.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w, vertical: AppSpacing.xxs.h),
                            decoration: BoxDecoration(
                              color: LightPOSColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
                              boxShadow: [
                                BoxShadow(
                                  color: LightPOSColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Text(
                              '${qtyInCart}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: LightPOSTypography.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.price.asCurrency,
                            style: LightPOSTypography.headlineMedium.copyWith(
                              color: LightPOSColors.primary,
                              fontSize: 15.sp,
                            ),
                          ),
                          // Floating Add Button
                          IconButton(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: LightPOSColors.primary,
                              minimumSize: Size(36.w, 36.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String categoryId) {
    return switch (categoryId) {
      'cat-1' => '🥗',
      'cat-2' => '🥩',
      'cat-3' => '🍗',
      'cat-4' => '🍝',
      'cat-5' => '🍕',
      'cat-6' => '🍮',
      'cat-7' => '🥤',
      'cat-8' => '🍟',
      _ => '🍔',
    };
  }
}

/// ─── Component: OrderCartPanel ──────────────────────────────────────────────
class OrderCartPanel extends ConsumerStatefulWidget {
  const OrderCartPanel({
    super.key,
    required this.cartState,
    this.activeTable,
  });

  final POSCartState cartState;
  final dynamic activeTable;

  @override
  ConsumerState<OrderCartPanel> createState() => _OrderCartPanelState();
}

class _OrderCartPanelState extends ConsumerState<OrderCartPanel> {
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cartState.items;

    return Container(
      color: LightPOSColors.sidebarBg,
      padding: EdgeInsets.all(AppSpacing.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Title Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Order', style: LightPOSTypography.titleLarge),
                  Text(
                    widget.activeTable != null
                        ? 'Table ${widget.activeTable.number} Checkout'
                        : 'Quick Walk-In Checkout',
                    style: LightPOSTypography.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              if (cartItems.isNotEmpty)
                IconButton(
                  onPressed: () {
                    ref.read(posCartProvider.notifier).clear();
                    _notesController.clear();
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, color: LightPOSColors.danger),
                  tooltip: 'Clear Cart',
                ),
            ],
          ),
          
          Gap(AppSpacing.md.h),
          const Divider(height: 1, color: LightPOSColors.border),
          Gap(AppSpacing.md.h),

          // Scrollable Cart Items
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Order Cart is Empty',
                      description: 'Tap the floating add button (+) on any menu dish to compile the ticket.',
                    ),
                  )
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) => Divider(color: LightPOSColors.border, height: AppSpacing.md.h),
                    itemBuilder: (context, i) {
                      final item = cartItems[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item main row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.menuItem.name, style: LightPOSTypography.titleMedium),
                                    Text(item.menuItem.price.asCurrency, style: LightPOSTypography.bodySmall),
                                  ],
                                ),
                              ),
                              // Qty Adjustment Buttons
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => ref.read(posCartProvider.notifier).removeItem(item.menuItem),
                                    icon: const Icon(Icons.remove, size: 14),
                                    style: IconButton.styleFrom(
                                      backgroundColor: LightPOSColors.background,
                                      minimumSize: Size(44.w, 44.h),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                                    child: Text('${item.qty}', style: LightPOSTypography.titleMedium),
                                  ),
                                  IconButton(
                                    onPressed: () => ref.read(posCartProvider.notifier).addItem(item.menuItem),
                                    icon: const Icon(Icons.add, size: 14),
                                    style: IconButton.styleFrom(
                                      backgroundColor: LightPOSColors.background,
                                      minimumSize: Size(44.w, 44.h),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Gap(AppSpacing.xs.h),

                          // Modifiers selection section
                          _buildModifiersRow(item),
                        ],
                      );
                    },
                  ),
          ),
          
          const Divider(height: 1, color: LightPOSColors.border),
          Gap(AppSpacing.md.h),

          // Order Notes Section
          if (cartItems.isNotEmpty) ...[
            Text('KITCHEN NOTES', style: LightPOSTypography.labelSmall.copyWith(color: LightPOSColors.textSecondary, letterSpacing: 0.5)),
            Gap(AppSpacing.xs.h),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: LightPOSTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter preparation instructions...',
                hintStyle: LightPOSTypography.bodySmall,
                fillColor: LightPOSColors.background,
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w, vertical: AppSpacing.xs.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Gap(AppSpacing.xs.h),
            // Quick note tags
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickNoteChip('Allergy Alert'),
                  _buildQuickNoteChip('Spicy'),
                  _buildQuickNoteChip('To Go'),
                  _buildQuickNoteChip('Well Done'),
                ],
              ),
            ),
            Gap(AppSpacing.md.h),

            // Financial Summary Card
            FinancialSummaryCard(cartState: widget.cartState),
            Gap(AppSpacing.md.h),

            // Checkout CTA buttons
            Row(
              children: [
                Expanded(
                  child: POSActionButton(
                    onPressed: () {
                      ref.read(posCartProvider.notifier).clear();
                      _notesController.clear();
                      context.showSuccessSnack('Ticket dispatched to Kitchen KDS!');
                      context.go('/floor');
                    },
                    text: 'SEND KITCHEN',
                    icon: Icons.soup_kitchen_outlined,
                    backgroundColor: Colors.white,
                    foregroundColor: LightPOSColors.primary,
                    borderColor: LightPOSColors.primary,
                  ),
                ),
                Gap(AppSpacing.sm.w),
                Expanded(
                  child: POSActionButton(
                    onPressed: () {
                      // Set notes before navigating
                      if (_notesController.text.isNotEmpty) {
                        for (final item in widget.cartState.items) {
                          ref.read(posCartProvider.notifier).updateNotes(item.menuItem.id, _notesController.text);
                        }
                      }
                      context.go('/cart');
                    },
                    text: 'CHECKOUT',
                    icon: Icons.shopping_cart_checkout_outlined,
                    backgroundColor: LightPOSColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModifiersRow(POSCartItem item) {
    const listModifiers = ['No Garlic', 'Extra Spicy', 'To Go', 'Less Oil'];

    return Wrap(
      spacing: AppSpacing.xxs.w,
      children: listModifiers.map((mod) {
        final isSelected = item.selectedModifiers.contains(mod);
        return ChoiceChip(
          label: Text(mod, style: TextStyle(fontSize: 10.sp)),
          selected: isSelected,
          onSelected: (_) {
            ref.read(posCartProvider.notifier).toggleModifier(item.menuItem.id, mod);
          },
          labelStyle: LightPOSTypography.labelSmall.copyWith(
            color: isSelected ? LightPOSColors.primary : LightPOSColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          selectedColor: LightPOSColors.primary.withValues(alpha: 0.15),
          backgroundColor: LightPOSColors.background,
          side: BorderSide(
            color: isSelected ? LightPOSColors.primary : Colors.transparent,
            width: 1,
          ),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildQuickNoteChip(String noteText) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: ActionChip(
        label: Text(noteText, style: TextStyle(fontSize: 10.sp)),
        labelStyle: LightPOSTypography.labelSmall.copyWith(color: LightPOSColors.textSecondary),
        backgroundColor: LightPOSColors.background,
        onPressed: () {
          if (_notesController.text.isEmpty) {
            _notesController.text = noteText;
          } else {
            _notesController.text = '${_notesController.text}, $noteText';
          }
        },
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM.r),
        ),
      ),
    );
  }
}

/// ─── Component: StatusIndicator ────────────────────────────────────────────
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing Green dot decoration
        Container(
          width: 8.w,
          height: 8.h,
          decoration: const BoxDecoration(
            color: LightPOSColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LightPOSColors.success,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Gap(6.w),
        Text('Cloud Synced', style: LightPOSTypography.bodySmall),
      ],
    );
  }
}

/// ─── Component: FinancialSummaryCard ────────────────────────────────────────
class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({super.key, required this.cartState});

  final POSCartState cartState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r),
        border: Border.all(color: LightPOSColors.border),
        boxShadow: LightPOSColors.softShadow,
      ),
      child: Column(
        children: [
          _buildSummaryLine('Subtotal', cartState.subtotal.asCurrency),
          Gap(AppSpacing.xxs.h),
          _buildSummaryLine('Tax (5%)', cartState.taxAmount.asCurrency),
          if (cartState.discountPercent > 0) ...[
            Gap(AppSpacing.xxs.h),
            _buildSummaryLine(
              'Discount (${cartState.discountPercent.toStringAsFixed(0)}%)',
              '-${cartState.discountAmount.asCurrency}',
              isNegative: true,
            ),
          ],
          Gap(AppSpacing.md.h),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.r),
            decoration: BoxDecoration(
              color: LightPOSColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
              border: Border.all(color: LightPOSColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: LightPOSTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  cartState.total.asCurrency,
                  style: LightPOSTypography.headlineMedium.copyWith(
                    color: LightPOSColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String title, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: LightPOSTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Gap(8.w),
        Text(
          value,
          style: LightPOSTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isNegative ? LightPOSColors.danger : LightPOSColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// ─── Component: POSActionButton ─────────────────────────────────────────────
class POSActionButton extends StatelessWidget {
  const POSActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
    this.backgroundColor = LightPOSColors.primary,
    this.foregroundColor = Colors.white,
    this.borderColor,
  });

  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isPrimary = backgroundColor == LightPOSColors.primary;

    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: isPrimary
            ? const LinearGradient(
                colors: [LightPOSColors.primary, LightPOSColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : backgroundColor,
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: LightPOSColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18.sp, color: foregroundColor),
                Gap(AppSpacing.xs.w),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

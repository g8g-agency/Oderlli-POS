import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../theme/theme.dart';
import '../models/models.dart';
import '../providers/pos_cart_provider.dart';
import '../core/extensions/extensions.dart';

class ModifierSelectionDialog extends ConsumerStatefulWidget {
  final MenuItem item;

  const ModifierSelectionDialog({super.key, required this.item});

  @override
  ConsumerState<ModifierSelectionDialog> createState() => _ModifierSelectionDialogState();
}

class _ModifierSelectionDialogState extends ConsumerState<ModifierSelectionDialog> {
  final Set<String> _selectedModifiers = {};
  String? _errorMessage;

  void _toggleModifier(ModifierGroup group, ModifierOption option) {
    setState(() {
      _errorMessage = null;
      if (_selectedModifiers.contains(option.name)) {
        _selectedModifiers.remove(option.name);
      } else {
        // Enforce maxSelect
        final selectedInGroup = group.options.where((o) => _selectedModifiers.contains(o.name)).length;
        if (group.maxSelect != null && selectedInGroup >= group.maxSelect!) {
          _errorMessage = '${group.name} allows a maximum of ${group.maxSelect} selection(s).';
          return;
        }
        _selectedModifiers.add(option.name);
      }
    });
  }

  void _validateAndSubmit() {
    setState(() {
      _errorMessage = null;
    });

    for (final group in widget.item.modifierGroups) {
      final selectedInGroup = group.options.where((o) => _selectedModifiers.contains(o.name)).length;
      if (group.isRequired && selectedInGroup < group.minSelect) {
        setState(() {
          _errorMessage = '${group.name} requires at least ${group.minSelect} selection(s).';
        });
        return;
      }
    }

    // Try adding through provider to catch any backend validation mirrored in provider
    ref.read(posCartProvider.notifier).addItem(
      widget.item, 
      selectedModifiers: _selectedModifiers.toList(),
    ).then((_) {
      final error = ref.read(posCartProvider).errorMessage;
      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: AppColors.surface,
      child: Container(
        width: 600.w,
        constraints: BoxConstraints(maxHeight: 800.h),
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Customize ${widget.item.name}',
                    style: AppTextStyles.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Gap(16.h),
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12.r),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.lossContainer.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.loss),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 20.sp),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.loss),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: widget.item.modifierGroups.length,
                separatorBuilder: (_, __) => Gap(24.h),
                itemBuilder: (context, index) {
                  final group = widget.item.modifierGroups[index];
                  final isRequired = group.isRequired;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            group.name,
                            style: AppTextStyles.titleMedium,
                          ),
                          Gap(8.w),
                          if (isRequired)
                            Text(
                              'Required (Min: ${group.minSelect}${group.maxSelect != null ? ', Max: ${group.maxSelect}' : ''})',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.loss),
                            )
                          else
                            Text(
                              group.maxSelect != null ? 'Optional (Max: ${group.maxSelect})' : 'Optional',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      Gap(12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: group.options.map((option) {
                          final isSelected = _selectedModifiers.contains(option.name);
                          return FilterChip(
                            label: Text('${option.name} (+${option.priceDelta.asCurrency})'),
                            selected: isSelected,
                            onSelected: (_) => _toggleModifier(group, option),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            labelStyle: AppTextStyles.labelMedium.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            backgroundColor: AppColors.surfaceVariant,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
            Gap(24.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('Add to Cart', style: AppTextStyles.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

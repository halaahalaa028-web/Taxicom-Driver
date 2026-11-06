/// شريط تبويبات فلترة الرحلات لتطبيق السائق
/// 
/// يتيح تصفية سجل الرحلات حسب الحالة (الكل، المكتملة، الملغاة) مع عرض العدادات
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// خيارات فلترة الرحلات
enum TripFilter {
  all,
  completed,
  cancelled,
}

/// شريط تبويبات فلترة الرحلات بتصميم مونوكرومي موحد
class TripFilterTabs extends StatelessWidget {
  final TripFilter selectedFilter;
  final ValueChanged<TripFilter> onFilterSelected;
  final int allCount;
  final int completedCount;
  final int cancelledCount;

  const TripFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.allCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab(
              filter: TripFilter.all,
              title: l10n.allTripsTab,
              count: allCount,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab(
              filter: TripFilter.completed,
              title: l10n.completedTripsTab,
              count: completedCount,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab(
              filter: TripFilter.cancelled,
              title: l10n.cancelledTripsTab,
              count: cancelledCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required TripFilter filter,
    required String title,
    required int count,
  }) {
    final isSelected = selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterSelected(filter),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.border.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

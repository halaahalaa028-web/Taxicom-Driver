/// ويدجت الحالة الفارغة للرحلات في تطبيق السائق
/// 
/// تعرض واجهة مونوكرومية أنيقة عند عدم وجود رحلات بحسب الفلتر المحدد
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import 'trip_filter_tabs.dart';

/// ويدجت الحالة الفارغة
class TripsEmptyState extends StatelessWidget {
  final TripFilter filter;
  final VoidCallback? onAction;
  final String? actionLabel;

  const TripsEmptyState({
    super.key,
    this.filter = TripFilter.all,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // أيقونة الحالة الفارغة داخل دائرة مونوكرومية
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getIcon(),
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // عنوان الحالة الفارغة
            Text(
              _getTitle(l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // وصف توضيحي
            Text(
              _getSubtitle(l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            // زر الإجراء إذا وُجد
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  actionLabel ?? 'تحديث',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (filter) {
      case TripFilter.all:
        return Icons.local_taxi_rounded;
      case TripFilter.completed:
        return Icons.check_circle_outline_rounded;
      case TripFilter.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getTitle(AppLocalizations l10n) {
    switch (filter) {
      case TripFilter.all:
        return l10n.noPastTrips;
      case TripFilter.completed:
        return l10n.noCompletedTrips;
      case TripFilter.cancelled:
        return l10n.noCancelledTrips;
    }
  }

  String _getSubtitle(AppLocalizations l10n) {
    switch (filter) {
      case TripFilter.all:
        return l10n.pastTripsEmptySubtitle;
      case TripFilter.completed:
        return l10n.noCompletedTrips;
      case TripFilter.cancelled:
        return l10n.noCancelledTrips;
    }
  }
}

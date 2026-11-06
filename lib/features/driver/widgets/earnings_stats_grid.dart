import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/trip_calculation_helper.dart';

/// شبكة بطاقات تفاصيل الإحصائيات (صافي أرباح الأسبوع والشهر وإجمالي الرحلات)
class EarningsStatsGrid extends StatelessWidget {
  /// صافي أرباح الأسبوع
  final double weekEarnings;

  /// صافي أرباح الشهر
  final double monthEarnings;

  /// إجمالي عدد الرحلات المكتملة
  final int completedTripsCount;

  /// إجمالي ما دفعه الركاب هذا الأسبوع
  final double weekGrossFare;

  /// إجمالي ما دفعه الركاب هذا الشهر
  final double monthGrossFare;

  /// إجمالي عمولة المنصة هذا الأسبوع
  final double weekCommission;

  /// إجمالي عمولة المنصة هذا الشهر
  final double monthCommission;

  /// رمز العملة
  final String? currency;

  /// رمز الدولة
  final String? countryCode;

  const EarningsStatsGrid({
    super.key,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.completedTripsCount,
    this.weekGrossFare = 0.0,
    this.monthGrossFare = 0.0,
    this.weekCommission = 0.0,
    this.monthCommission = 0.0,
    this.currency,
    this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // صافي أرباح هذا الأسبوع
        Expanded(
          child: _buildItem(
            title: 'صافي الأسبوع',
            value: TripCalculationHelper.formatPrice(
              weekEarnings,
              currency: currency,
              countryCode: countryCode,
            ),
            icon: Icons.date_range_rounded,
          ),
        ),
        const SizedBox(width: 10),
        // صافي أرباح هذا الشهر
        Expanded(
          child: _buildItem(
            title: 'صافي الشهر',
            value: TripCalculationHelper.formatPrice(
              monthEarnings,
              currency: currency,
              countryCode: countryCode,
            ),
            icon: Icons.calendar_month_rounded,
          ),
        ),
        const SizedBox(width: 10),
        // إجمالي الرحلات المكتملة
        Expanded(
          child: _buildItem(
            title: 'الرحلات المنجزة',
            value: '$completedTripsCount',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// بطاقة إحصائية تفصيلية لتوزيع دخل اليوم بين الكاش المستلم باليد وأرباح المحفظة
///
/// توضح للسائق بدقة إجمالي النقد المحصل باليد ومقداره،
/// مقابل الأرباح الإلكترونية المودعة في محفظة التطبيق والجاهزة للسحب
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/trip_calculation_helper.dart';

class TodayEarningsBreakdownCard extends StatelessWidget {
  /// إجمالي الكاش المستلم باليد من الركاب لليوم
  final double cashCollected;

  /// صافي أرباح السائق من الرحلات النقدية
  final double cashNet;

  /// عدد الرحلات النقدية لليوم
  final int cashTripsCount;

  /// صافي الأرباح الإلكترونية المودعة بالمحفظة لليوم
  final double electronicNet;

  /// إجمالي قيمة الرحلات الإلكترونية
  final double electronicGross;

  /// عدد الرحلات الإلكترونية لليوم
  final int electronicTripsCount;

  /// رمز العملة
  final String? currency;

  /// رمز الدولة
  final String? countryCode;

  const TodayEarningsBreakdownCard({
    super.key,
    required this.cashCollected,
    this.cashNet = 0.0,
    required this.cashTripsCount,
    required this.electronicNet,
    this.electronicGross = 0.0,
    required this.electronicTripsCount,
    this.currency,
    this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.todayEarningsBreakdownTitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'نشاط اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // توزيع الكاش مقابل المحفظة (بطاقتان متجاورتان)
          Row(
            children: [
              // 1. بطاقة الكاش المستلم باليد
              Expanded(
                child: _buildBreakdownItem(
                  icon: Icons.payments_outlined,
                  title: loc.todayCashInHand,
                  amount: TripCalculationHelper.formatPrice(
                    cashCollected,
                    currency: currency,
                    countryCode: countryCode,
                  ),
                  subtitle: loc.todayCashTripsCountText(cashTripsCount),
                ),
              ),

              const SizedBox(width: 10),

              // 2. بطاقة الأرباح بالمحفظة
              Expanded(
                child: _buildBreakdownItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: loc.todayWalletEarnings,
                  amount: TripCalculationHelper.formatPrice(
                    electronicNet,
                    currency: currency,
                    countryCode: countryCode,
                  ),
                  subtitle: loc.todayElectronicTripsCountText(electronicTripsCount),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // شريط التوضيح والإرشاد
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.todayEarningsBreakdownNote,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String title,
    required String amount,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textPrimary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

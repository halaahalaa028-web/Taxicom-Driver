import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/trip_calculation_helper.dart';

/// بطاقة ملخص صافي أرباح المشاوير ونشاط اليوم للسائق
class EarningsBalanceCard extends StatelessWidget {
  /// صافي دخل السائق الإجمالي (المبلغ المستحق بعد خصم عمولات المنصة)
  final double netEarnings;

  /// إجمالي ما دفعه الركاب قبل استقطاع العمولة
  final double grossFare;

  /// إجمالي عمولات المنصة المستقطعة
  final double commissionAmount;

  /// صافي أرباح اليوم
  final double todayEarnings;

  /// إجمالي ما دفعه الركاب اليوم
  final double todayGrossFare;

  /// إجمالي عمولة المنصة لليوم
  final double todayCommission;

  /// عدد مشاوير اليوم المنجزة
  final int todayTripsCount;

  /// رمز العملة
  final String? currency;

  /// رمز الدولة
  final String? countryCode;

  const EarningsBalanceCard({
    super.key,
    required this.netEarnings,
    this.grossFare = 0.0,
    this.commissionAmount = 0.0,
    required this.todayEarnings,
    this.todayGrossFare = 0.0,
    this.todayCommission = 0.0,
    required this.todayTripsCount,
    this.currency,
    this.countryCode,
  });

  /// باني للتوافقية السابقة
  factory EarningsBalanceCard.legacy({
    Key? key,
    required double totalEarnings,
    double grossFare = 0.0,
    double commissionAmount = 0.0,
    required double todayEarnings,
    required int todayTripsCount,
    String? currency,
    String? countryCode,
  }) {
    return EarningsBalanceCard(
      key: key,
      netEarnings: totalEarnings,
      grossFare: grossFare,
      commissionAmount: commissionAmount,
      todayEarnings: todayEarnings,
      todayTripsCount: todayTripsCount,
      currency: currency,
      countryCode: countryCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شارة إحصائيات النشاط التشغيلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'صافي أرباحك من المشاوير',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'صافي الأرباح',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // الرقم الرئيسي البارز: صافي دخل السائق
          Text(
            TripCalculationHelper.formatPrice(
              netEarnings,
              currency: currency,
              countryCode: countryCode,
            ),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'المبلغ الصافي الفعلي بعد اقتطاع عمولات المنصة لكل رحلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          // تفصيل فرعي شفاف: إجمالي ما دفعه الركاب وعمولة المنصة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                // إجمالي ما دفعه الركاب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'ما دفعه الركاب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TripCalculationHelper.formatPrice(
                          grossFare,
                          currency: currency,
                          countryCode: countryCode,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // فاصل رأسي
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // عمولة المنصة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'عمولة المنصة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '- ${TripCalculationHelper.formatPrice(
                          commissionAmount,
                          currency: currency,
                          countryCode: countryCode,
                        )}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // بطاقة إحصائيات مشاوير اليوم
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'صافي دخل اليوم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TripCalculationHelper.formatPrice(
                          todayEarnings,
                          currency: currency,
                          countryCode: countryCode,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مشاوير اليوم المنجزة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$todayTripsCount مشوار',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
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
}

/// رأس بطاقة رصيد محفظة السائق
///
/// يعرض الرصيد المالي الحالي (أخضر للأرباح، وأحمر/تنبيه للمديونية)
/// مع إحصائيات سريعة وأزرار تسديد المديونية وسحب الأرباح
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../../data/models/driver_wallet_model.dart';

class DriverBalanceHeader extends StatelessWidget {
  final DriverWalletModel? wallet;
  final String currency;
  final String countryCode;
  final VoidCallback onPayDebtPressed;
  final VoidCallback onRequestPayoutPressed;
  final VoidCallback? onPayoutRequestsHistoryPressed;

  const DriverBalanceHeader({
    super.key,
    required this.wallet,
    required this.currency,
    required this.countryCode,
    required this.onPayDebtPressed,
    required this.onRequestPayoutPressed,
    this.onPayoutRequestsHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final balance = wallet?.balance ?? 0.0;
    final hasDebt = balance < 0;
    final isPositive = balance > 0;
    final displayAmount = balance.abs();

    final formattedAmount = TripCalculationHelper.formatPrice(
      displayAmount,
      currency: currency,
      countryCode: countryCode,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasDebt
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.8),
          width: hasDebt ? 1.5 : 1.0,
        ),
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
          // شارة الحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasDebt
                      ? AppColors.error.withValues(alpha: 0.1)
                      : (isPositive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.border.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasDebt
                          ? Icons.warning_rounded
                          : (isPositive ? Icons.account_balance_wallet_rounded : Icons.check_circle_outline),
                      color: hasDebt
                          ? AppColors.error
                          : (isPositive ? AppColors.success : AppColors.textSecondary),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasDebt
                          ? 'مديونية مستحقة للمنصة'
                          : (isPositive ? 'رصيد أرباح متاح' : 'لا توجد مديونية'),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasDebt
                            ? AppColors.error
                            : (isPositive ? AppColors.success : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              if (wallet?.pendingPayout != null && wallet!.pendingPayout > 0)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPayoutRequestsHistoryPressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 12, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'معلق: ${TripCalculationHelper.formatPrice(wallet!.pendingPayout, currency: currency, countryCode: countryCode)}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          if (onPayoutRequestsHistoryPressed != null) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.warning),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // رقم الرصيد الكبير
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (hasDebt)
                const Text(
                  '- ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              Text(
                formattedAmount,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: hasDebt
                      ? AppColors.error
                      : (isPositive ? AppColors.success : AppColors.textPrimary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            hasDebt
                ? 'مستحقات عمولة المنصة عن الرحلات النقدية'
                : (isPositive
                    ? 'صافي أرباحك المستحقة من الرحلات الإلكترونية القابلة للسحب'
                    : 'حسابك المالي متزن، ولا توجد أي مديونية عليك حالياً'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // أزرار الإجراءات الرئيسية
          Row(
            children: [
              if (hasDebt)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPayDebtPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.credit_card_rounded, size: 20),
                    label: const Text(
                      'تسديد المديونية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (isPositive)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRequestPayoutPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 20),
                    label: const Text(
                      'طلب سحب الأرباح',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (!hasDebt && !isPositive)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPayDebtPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_card_rounded, size: 18),
                    label: const Text(
                      'شحن رصيد مسبق للمحفظة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // شبكة الإحصائيات الإجمالية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildStatItem(
                  title: 'إجمالي المشاوير',
                  value: '${wallet?.totalTripsCompleted ?? 0}',
                  icon: Icons.directions_car_rounded,
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                _buildStatItem(
                  title: 'العمولة المسددة',
                  value: TripCalculationHelper.formatPrice(
                    wallet?.totalCommissionPaid ?? 0.0,
                    currency: currency,
                    countryCode: countryCode,
                  ),
                  icon: Icons.percent_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

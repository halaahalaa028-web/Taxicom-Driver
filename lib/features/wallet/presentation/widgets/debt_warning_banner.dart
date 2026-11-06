/// شريط تنبيه سقف المديونية للسائق
///
/// يظهر عند اقتراب أو تجاوز حد المديونية الأقصى
/// مع عرض نسبة الامتلاء وزر تسديد فوري
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/driver_commission_service.dart';
import '../../../../core/utils/trip_calculation_helper.dart';

class DebtWarningBanner extends StatelessWidget {
  final DriverDebtStatus debtStatus;
  final String currency;
  final String countryCode;
  final VoidCallback onPayPressed;

  const DebtWarningBanner({
    super.key,
    required this.debtStatus,
    required this.currency,
    required this.countryCode,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!debtStatus.isBlocked && !debtStatus.isWarning) {
      return const SizedBox.shrink();
    }

    final isBlocked = debtStatus.isBlocked;
    final bannerColor = isBlocked ? AppColors.error : AppColors.warning;
    final formattedDebt = TripCalculationHelper.formatPrice(
      debtStatus.currentDebt,
      currency: currency,
      countryCode: countryCode,
    );
    final formattedLimit = TripCalculationHelper.formatPrice(
      debtStatus.maxDebtLimit,
      currency: currency,
      countryCode: countryCode,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBlocked ? Icons.block_rounded : Icons.warning_amber_rounded,
                  color: bannerColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBlocked
                          ? 'تم إيقاف استقبال الطلبات (تجاوز سقف المديونية)'
                          : 'تنبيه: اقتربت من سقف المديونية الأقصى',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: bannerColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBlocked
                          ? 'تجاوزت مديونيتك الحد الأقصى ($formattedLimit). يرجى التسديد لاستئناف العمل.'
                          : 'مديونيتك الحالية $formattedDebt من أصل $formattedLimit.',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // شريط تقدم المديونية
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: debtStatus.debtRatio.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(bannerColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onPayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bannerColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: Text(
                isBlocked ? 'تسديد المديونية الآن واستئناف العمل' : 'تسديد دفعة فورية الآن',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

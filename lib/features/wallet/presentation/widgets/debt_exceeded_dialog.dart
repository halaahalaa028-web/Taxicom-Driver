/// نافذة تنبيه تجاوز سقف المديونية وحظر استقبال الطلبات
///
/// تظهر للسائق عند محاولة العمل وهو متجاوز لحد المديونية الأقصى
/// مع إمكانية الانتقال الفوري لشاشة المحفظة للتسديد
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/driver_commission_service.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../screens/driver_wallet_screen.dart';

class DebtExceededDialog extends StatelessWidget {
  final DriverDebtStatus debtStatus;
  final String currency;
  final String countryCode;

  const DebtExceededDialog({
    super.key,
    required this.debtStatus,
    required this.currency,
    required this.countryCode,
  });

  static Future<void> show(
    BuildContext context, {
    required DriverDebtStatus debtStatus,
    required String currency,
    required String countryCode,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DebtExceededDialog(
        debtStatus: debtStatus,
        currency: currency,
        countryCode: countryCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.block_rounded, color: AppColors.error, size: 26),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تجاوز سقف المديونية الأقصى',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'عذراً، تم إيقاف استقبال الطلبات مؤقتاً بسبب وصول مديونية عمولة المنصة إلى السقف الأقصى المسموح به.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مديونيتك الحالية:',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    Text(
                      formattedDebt,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الحد الأقصى المسموح:',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    Text(
                      formattedLimit,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'يرجى تسديد المديونية المستحقة عبر بطاقة الدفع لاستئناف استقبال طلبات الركاب فوراً.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const DriverWalletScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
          label: const Text(
            'فتح المحفظة والتسديد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

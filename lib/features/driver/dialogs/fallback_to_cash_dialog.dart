import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../../trips/models/trip_request_model.dart';

/// مربع حوار تنبيهي عند تعذر الخصم الإلكتروني وتحويل الدفع للنقد (Cash Fallback)
class FallbackToCashDialog extends StatelessWidget {
  final TripRequestModel trip;
  final String? reasonMessage;

  const FallbackToCashDialog({
    super.key,
    required this.trip,
    this.reasonMessage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TripRequestModel trip,
    String? reasonMessage,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FallbackToCashDialog(
        trip: trip,
        reasonMessage: reasonMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fare = trip.effectiveOriginalPrice;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تعذر الخصم الإلكتروني',
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(
              reasonMessage ?? 'تعذر خصم الأجرة من رصيد محفظة أو بطاقة الراكب.',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '⚠️ خطة الطوارئ (تحصيل كاش):',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يرجى استلام الأجرة كاملة نقداً من الراكب بمبلغ:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                TripCalculationHelper.formatPrice(
                  fare,
                  currency: trip.currency,
                  countryCode: trip.countryCode,
                ),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (trip.effectiveCommissionRate <= 0.0001)
                ? 'الرحلة معفاة من عمولة المنصة (0%)، لن يتم خصم أي عمولة من محفظتك.'
                : 'سيتم استقطاع عمولة المنصة ${(trip.effectiveCommissionRate * 100).toStringAsFixed((trip.effectiveCommissionRate * 100 % 1 == 0) ? 0 : 1)}% من محفظتك كرحلة نقدية بعد تأكيدك استلام المبلغ.',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'إلغاء / إعادة المحاولة',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            'استلمت الكاش وأنهِ الرحلة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

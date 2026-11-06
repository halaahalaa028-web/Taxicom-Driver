import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../../trips/models/trip_request_model.dart';

/// بطاقة عرض السعر وطريقة الدفع لطلب الرحلة الوارد للسائق
class DriverTripRequestPriceBadge extends StatelessWidget {
  final TripRequestModel request;

  const DriverTripRequestPriceBadge({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    if (request.hasDiscount) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إجمالي أرباحك من الرحلة:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  TripCalculationHelper.formatPrice(
                    request.effectiveOriginalPrice,
                    currency: request.currency,
                    countryCode: request.countryCode,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      PaymentHelper.getPaymentMethodIcon(request.paymentMethod),
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      PaymentHelper.isCashPayment(request.paymentMethod)
                          ? 'المطلوب تحصيله نقداً من الراكب:'
                          : 'المدفوع إلكترونياً (${PaymentHelper.getPaymentMethodTitle(context, request.paymentMethod)}):',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  TripCalculationHelper.formatPrice(
                    request.price,
                    currency: request.currency,
                    countryCode: request.countryCode,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'خصم الكوبون (مدعوم من التطبيق):',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${TripCalculationHelper.formatPrice(
                    request.discountAmount!,
                    currency: request.currency,
                    countryCode: request.countryCode,
                  )}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              TripCalculationHelper.formatPrice(
                request.price,
                currency: request.currency,
                countryCode: request.countryCode,
              ),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PaymentHelper.isCashPayment(request.paymentMethod)
                  ? AppColors.surfaceVariant
                  : AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PaymentHelper.isCashPayment(request.paymentMethod)
                    ? AppColors.border
                    : AppColors.primary,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PaymentHelper.getPaymentMethodIcon(request.paymentMethod),
                  size: 16,
                  color: PaymentHelper.isCashPayment(request.paymentMethod)
                      ? AppColors.textPrimary
                      : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  PaymentHelper.getPaymentMethodTitle(context, request.paymentMethod),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: PaymentHelper.isCashPayment(request.paymentMethod)
                        ? AppColors.textPrimary
                        : AppColors.primary,
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

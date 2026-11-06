/// بطاقة تفاصيل السعر والخصم للرحلة السابقة في تطبيق السائق
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../models/trip_request_model.dart';

/// ويدجت تفاصيل تسعيرة الرحلة والخصومات المدعومة لسجل الرحلات
class TripHistoryPriceBreakdown extends StatelessWidget {
  final TripRequestModel trip;

  const TripHistoryPriceBreakdown({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    if (!trip.hasDiscount) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final currency = trip.currency;
    final countryCode = trip.countryCode;

    final earningsFormatted = TripCalculationHelper.formatPrice(
      trip.effectiveOriginalPrice,
      currency: currency,
      countryCode: countryCode,
    );
    final cashFormatted = TripCalculationHelper.formatPrice(
      trip.price,
      currency: currency,
      countryCode: countryCode,
    );
    final discountFormatted = TripCalculationHelper.formatPrice(
      trip.discountAmount ?? 0,
      currency: currency,
      countryCode: countryCode,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. إجمالي أرباح الرحلة الكاملة للسائق
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.driverTotalEarnings,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                earningsFormatted,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // 2. المبلغ المحصل من الراكب حسب وسيلة الدفع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    PaymentHelper.getPaymentMethodIcon(trip.paymentMethod),
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    PaymentHelper.isCashPayment(trip.paymentMethod)
                        ? loc.cashFromPassenger
                        : loc.electronicPaymentFromPassenger,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                cashFormatted,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 3. خصم الكوبون المدعوم من منصة التطبيق مع Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.platformDiscountSubsidy,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  '+$discountFormatted',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

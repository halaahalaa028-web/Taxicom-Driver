/// بطاقة عرض تفاصيل المشوار المكتمل وصافي دخل السائق
///
/// توضح للسائق تفصيل الأجرة، عمولة المنصة الديناميكية الفعلية، وصافي ربح السائق
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/payment_helper.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../../../trips/models/trip_request_model.dart';

class EarningsTripCard extends StatelessWidget {
  final TripRequestModel trip;

  const EarningsTripCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final fare = trip.effectiveOriginalPrice;
    final commissionRate = trip.effectiveCommissionRate;
    final commission = trip.effectiveCommissionAmount;
    final netDriverEarning = trip.effectiveNetDriverEarnings;
    final isZeroCommission = commissionRate <= 0.0001 || commission <= 0.0001;

    // حساب نسبة العمولة ونسبة السائق بتنسيق نظيف
    final commissionRatePercent = (commissionRate * 100).toStringAsFixed(
      (commissionRate * 100 % 1 == 0) ? 0 : 1,
    );
    final driverSharePercent = ((1.0 - commissionRate) * 100).toStringAsFixed(
      ((1.0 - commissionRate) * 100 % 1 == 0) ? 0 : 1,
    );

    final String commissionLabel = isZeroCommission
        ? 'عمولة المنصة (0% - عرض)'
        : 'عمولة المنصة ($commissionRatePercent%)';
    final String driverShareLabel = isZeroCommission
        ? 'صافي ربحك (100%)'
        : 'صافي ربحك ($driverSharePercent%)';

    final isCash = PaymentHelper.isCashPayment(trip.paymentMethod);
    final paymentTitle = PaymentHelper.getPaymentMethodTitle(context, trip.paymentMethod);
    final paymentIcon = PaymentHelper.getPaymentMethodIcon(trip.paymentMethod);
    final formattedDate = DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(trip.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف العلوي: بيانات الراكب وطريقة الدفع
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(paymentIcon, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trip.passengerName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trip.passengerPhone.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            PhoneFormatter.format(trip.passengerPhone),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // شارة وسيلة الدفع
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCash
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paymentTitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCash ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // الوجهة
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip.destinationAddress,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // تفصيل التسعيرة والعمولة وصافي ربح السائق
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // أجرة المشوار
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أجرة المشوار',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      TripCalculationHelper.formatPrice(
                        fare,
                        currency: trip.currency,
                        countryCode: trip.countryCode,
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

                // عمولة المنصة
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      commissionLabel,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      isZeroCommission
                          ? TripCalculationHelper.formatPrice(
                              0.0,
                              currency: trip.currency,
                              countryCode: trip.countryCode,
                            )
                          : '- ${TripCalculationHelper.formatPrice(
                              commission,
                              currency: trip.currency,
                              countryCode: trip.countryCode,
                            )}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isZeroCommission ? AppColors.textSecondary : AppColors.error,
                      ),
                    ),
                  ],
                ),

                // صافي ربح السائق
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      driverShareLabel,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      '+ ${TripCalculationHelper.formatPrice(
                        netDriverEarning,
                        currency: trip.currency,
                        countryCode: trip.countryCode,
                      )}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

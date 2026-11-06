import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../../trips/models/trip_request_model.dart';
import 'trip_preview_addresses_card.dart';

/// لوحة تفاصيل الرحلة السفلية في شاشة المعاينة
class TripPreviewBottomPanel extends StatelessWidget {
  final TripRequestModel trip;
  final double driverDistanceKm;
  final int driverEtaMinutes;

  const TripPreviewBottomPanel({
    super.key,
    required this.trip,
    required this.driverDistanceKm,
    required this.driverEtaMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripEstimatedTime = (trip.distance * 2).ceil();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // مقبض السحب
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شارة نوع الطلب
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: trip.tripType == TripType.delivery 
                          ? Colors.orange.withValues(alpha: 0.1) 
                          : AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          trip.tripType == TripType.delivery 
                              ? Icons.delivery_dining_rounded 
                              : Icons.local_taxi_rounded,
                          color: trip.tripType == TripType.delivery 
                              ? Colors.orange 
                              : AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trip.tripType == TripType.delivery 
                              ? l10n.deliveryRequest
                              : l10n.rideRequest,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: trip.tripType == TripType.delivery 
                                ? Colors.orange 
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات الراكب والسعر
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.passengerName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              PhoneFormatter.format(trip.passengerPhone),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // السعر المنسق مع وسيلة الدفع
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  TripCalculationHelper.formatPrice(
                                    trip.effectiveOriginalPrice,
                                    currency: trip.currency,
                                    countryCode: trip.countryCode,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PaymentHelper.isCashPayment(trip.paymentMethod)
                                      ? AppColors.surfaceVariant
                                      : AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: PaymentHelper.isCashPayment(trip.paymentMethod)
                                        ? AppColors.border
                                        : AppColors.primary,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PaymentHelper.getPaymentMethodIcon(trip.paymentMethod),
                                      size: 14,
                                      color: PaymentHelper.isCashPayment(trip.paymentMethod)
                                          ? AppColors.textPrimary
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      PaymentHelper.getPaymentMethodTitle(context, trip.paymentMethod),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: PaymentHelper.isCashPayment(trip.paymentMethod)
                                            ? AppColors.textPrimary
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (trip.hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${PaymentHelper.getPaymentMethodTitle(context, trip.paymentMethod)}: ${TripCalculationHelper.formatPrice(trip.price, currency: trip.currency, countryCode: trip.countryCode)}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // العناوين
                  TripPreviewAddressesCard(trip: trip),
                  
                  const SizedBox(height: 16),
                  
                  // إحصائيات الرحلة
                  Row(
                    children: [
                      // مسافة الرحلة
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.route_rounded,
                          label: l10n.tripDistance,
                          value: '${trip.distance.toStringAsFixed(1)} كم',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // وقت الرحلة
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.access_time_rounded,
                          label: l10n.tripTime,
                          value: '$tripEstimatedTime دقيقة',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // المسافة إليك
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.navigation_rounded,
                          label: l10n.distanceToYou,
                          value: '${driverDistanceKm.toStringAsFixed(1)} كم',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // وقت الوصول للراكب
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.schedule_rounded,
                          label: l10n.timeToPassenger,
                          value: '$driverEtaMinutes دقيقة',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

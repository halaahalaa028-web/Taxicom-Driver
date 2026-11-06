import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../../trips/models/trip_request_model.dart';
import 'active_trip_passenger_header.dart';
import 'active_trip_addresses_card.dart';
import 'active_trip_action_buttons.dart';
import 'driver_delivery_details_card.dart';

/// اللوحة السفلية الخاصة بالرحلة النشطة الحالية
class DriverActiveTripPanel extends StatelessWidget {
  final ScrollController scrollController;
  final TripRequestModel trip;
  final bool isPassengerPickedUp;
  final bool isProcessingTripAction;
  final int Function(double distanceKm) getEstimatedTimeToPassenger;
  final double Function(TripRequestModel request) getDistanceToPassenger;
  final VoidCallback onOpenChat;
  final Future<void> Function() onCallPassenger;
  final Future<void> Function() onOpenNavigationApp;
  final Future<void> Function() onArrivedAtPassenger;
  final Future<void> Function() onPassengerBoarded;
  final Future<void> Function() onCompleteTrip;
  final Future<void> Function() onCancelTrip;

  const DriverActiveTripPanel({
    super.key,
    required this.scrollController,
    required this.trip,
    required this.isPassengerPickedUp,
    this.isProcessingTripAction = false,
    required this.getEstimatedTimeToPassenger,
    required this.getDistanceToPassenger,
    required this.onOpenChat,
    required this.onCallPassenger,
    required this.onOpenNavigationApp,
    required this.onArrivedAtPassenger,
    required this.onPassengerBoarded,
    required this.onCompleteTrip,
    required this.onCancelTrip,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // المقبض
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // عنوان وشارة نوع الرحلة
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'رحلة نشطة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trip.tripType == TripType.delivery
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trip.tripType == TripType.delivery
                          ? Icons.local_shipping_rounded
                          : Icons.directions_car_rounded,
                      color: trip.tripType == TripType.delivery
                          ? AppColors.secondary
                          : AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trip.tripType == TripType.delivery ? 'توصيل طلب' : 'تكسي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trip.tripType == TripType.delivery
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // خيارات إضافية للرحلة النشطة (ذهاب وإياب، وقت انتظار)
        if (trip.isRoundTrip || trip.waitTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (trip.isRoundTrip)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.loop_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('ذهاب وإياب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                if (trip.waitTime != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(trip.waitTime!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // معلومات الراكب مع أزرار المحادثة والاتصال
        ActiveTripPassengerHeader(
          trip: trip,
          onOpenChat: onOpenChat,
          onCallPassenger: onCallPassenger,
        ),

        const SizedBox(height: 16),

        // بطاقة العناوين
        ActiveTripAddressesCard(trip: trip),

        // تفاصيل التوصيل (للطلبات من نوع delivery)
        if (trip.tripType == TripType.delivery) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DriverDeliveryDetailsCard(request: trip),
          ),
        ],

        const SizedBox(height: 16),

        // الوقت المتوقع والسعر بالعملة الديناميكية
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(
                        TripCalculationHelper.formatDuration(
                          getEstimatedTimeToPassenger(getDistanceToPassenger(trip)),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        isPassengerPickedUp ? 'للوصول للوجهة' : 'للوصول للزبون',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.attach_money_rounded, color: AppColors.success),
                      const SizedBox(height: 4),
                      Text(
                        TripCalculationHelper.formatPrice(
                          trip.effectiveOriginalPrice,
                          currency: trip.currency,
                          countryCode: trip.countryCode,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        trip.hasDiscount
                            ? 'نقداً: ${TripCalculationHelper.formatPrice(trip.price, currency: trip.currency, countryCode: trip.countryCode)}'
                            : 'السعر',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // أزرار الملاحة ومراحل الرحلة والإلغاء
        ActiveTripActionButtons(
          trip: trip,
          isPassengerPickedUp: isPassengerPickedUp,
          isProcessing: isProcessingTripAction,
          onOpenNavigationApp: onOpenNavigationApp,
          onArrivedAtPassenger: onArrivedAtPassenger,
          onPassengerBoarded: onPassengerBoarded,
          onCompleteTrip: onCompleteTrip,
          onCancelTrip: onCancelTrip,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

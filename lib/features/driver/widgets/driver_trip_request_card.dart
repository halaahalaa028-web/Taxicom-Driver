import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../trips/models/trip_request_model.dart';
import '../screens/trip_preview_screen.dart';
import 'hold_to_accept_button.dart';
import 'driver_delivery_details_card.dart';
import 'driver_request_route_info.dart';
import 'driver_trip_request_price_badge.dart';

/// بطاقة تفاصيل طلب الرحلة الوارد للسائق
class DriverTripRequestCard extends StatelessWidget {
  final TripRequestModel request;
  final double distanceToPassenger;
  final int estimatedTimeToPassenger;
  final VoidCallback onDismiss;
  final Future<void> Function(TripRequestModel request) onAccept;

  const DriverTripRequestCard({
    super.key,
    required this.request,
    required this.distanceToPassenger,
    required this.estimatedTimeToPassenger,
    required this.onDismiss,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الراكب ونوع الرحلة
          Row(
            children: [
              const Icon(Icons.person_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.passengerName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // مؤشر نوع الرحلة
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: request.tripType == TripType.delivery
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            request.tripType == TripType.delivery
                                ? Icons.local_shipping_rounded
                                : Icons.directions_car_rounded,
                            color: request.tripType == TripType.delivery
                                ? AppColors.secondary
                                : AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            request.tripType == TripType.delivery ? 'توصيل طلب' : 'تكسي',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: request.tripType == TripType.delivery
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // خيارات إضافية (ذهاب وإياب، وقت انتظار)
                    if (request.isRoundTrip || request.waitTime != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: [
                            if (request.isRoundTrip)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.loop_rounded, size: 12, color: AppColors.primary),
                                    SizedBox(width: 2),
                                    Text(
                                      'ذهاب وإياب',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (request.waitTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_rounded, size: 12, color: Colors.orange),
                                    const SizedBox(width: 2),
                                    Text(
                                      request.waitTime!,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
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
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                tooltip: 'إلغاء هذا الطلب',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // معلومات المسار والعناوين
          DriverRequestRouteInfo(
            request: request,
            distanceToPassenger: distanceToPassenger,
            estimatedTimeToPassenger: estimatedTimeToPassenger,
          ),

          // السعر المنسق مع تفاصيل الخصم إن وجد
          DriverTripRequestPriceBadge(request: request),

          // تفاصيل التوصيل (للطلبات من نوع delivery)
          if (request.tripType == TripType.delivery) ...[
            const SizedBox(height: 12),
            DriverDeliveryDetailsCard(request: request),
          ],

          const SizedBox(height: 12),

          // زر موقع الرحلة
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripPreviewScreen(
                      tripRequest: request,
                      driverDistanceKm: distanceToPassenger,
                      driverEtaMinutes: estimatedTimeToPassenger,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined, size: 20),
              label: const Text(
                'موقع الرحلة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // زر القبول مع الاستمرار
          HoldToAcceptButton(
            holdDuration: 1.0,
            onAccepted: () => onAccept(request),
            label: 'اضغط مع الاستمرار للقبول',
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

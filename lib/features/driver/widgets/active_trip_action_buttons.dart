import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../trips/models/trip_request_model.dart';
import '../screens/trip_preview_screen.dart';

/// أزرار التحكم بالملاحة ومراحل وإلغاء الرحلة النشطة
class ActiveTripActionButtons extends StatelessWidget {
  final TripRequestModel trip;
  final bool isPassengerPickedUp;
  final bool isProcessing;
  final Future<void> Function() onOpenNavigationApp;
  final Future<void> Function() onArrivedAtPassenger;
  final Future<void> Function() onPassengerBoarded;
  final Future<void> Function() onCompleteTrip;
  final Future<void> Function() onCancelTrip;

  const ActiveTripActionButtons({
    super.key,
    required this.trip,
    required this.isPassengerPickedUp,
    this.isProcessing = false,
    required this.onOpenNavigationApp,
    required this.onArrivedAtPassenger,
    required this.onPassengerBoarded,
    required this.onCompleteTrip,
    required this.onCancelTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // أزرار الملاحة ومعاينة الخريطة
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenNavigationApp,
                  icon: const Icon(Icons.navigation_rounded, size: 20),
                  label: Text(
                    isPassengerPickedUp ? 'المسار للوجهة' : 'المسار للزبون',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripPreviewScreen(
                          tripRequest: trip,
                          driverDistanceKm: 0,
                          driverEtaMinutes: 0,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: const Text(
                    'موقع الرحلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // زر المرحلة (وصلت للزبون / ركب الزبون / إكمال الرحلة)
          SizedBox(
            width: double.infinity,
            child: trip.status == TripStatus.accepted
                ? ElevatedButton.icon(
                    onPressed: isProcessing ? null : onArrivedAtPassenger,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.location_on_rounded),
                    label: Text(
                      isProcessing ? 'جارٍ المعالجة...' : 'وصلت للزبون',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : trip.status == TripStatus.arrivedAtPickup
                    ? ElevatedButton.icon(
                        onPressed: isProcessing ? null : onPassengerBoarded,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_rounded),
                        label: Text(
                          isProcessing ? 'جارٍ المعالجة...' : 'ركب الزبون',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: isProcessing ? null : onCompleteTrip,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          isProcessing ? 'جارٍ المعالجة...' : 'إكمال الرحلة',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
          ),

          const SizedBox(height: 12),

          // زر إلغاء الرحلة
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isProcessing ? null : onCancelTrip,
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

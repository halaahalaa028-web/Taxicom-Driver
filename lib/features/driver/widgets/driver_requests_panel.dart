import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../trips/models/trip_request_model.dart';
import 'driver_availability_toggle.dart';
import 'driver_stats_card.dart';
import 'driver_trip_request_card.dart';

/// اللوحة السفلية القابلة للسحب لعرض قائمة الطلبات أو حالة التوفر
class DriverRequestsPanel extends StatelessWidget {
  final ScrollController scrollController;
  final bool isStatusInitialized;
  final bool isAvailable;
  final bool isTogglingAvailability;
  final int todayTrips;
  final double todayEarnings;
  final List<TripRequestModel> incomingRequests;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleAvailability;
  final double Function(TripRequestModel request) getDistanceToPassenger;
  final int Function(double distanceKm) getEstimatedTimeToPassenger;
  final void Function(TripRequestModel request) onDismissRequest;
  final Future<void> Function(TripRequestModel request) onAcceptRequest;

  const DriverRequestsPanel({
    super.key,
    required this.scrollController,
    required this.isStatusInitialized,
    required this.isAvailable,
    required this.isTogglingAvailability,
    required this.todayTrips,
    required this.todayEarnings,
    required this.incomingRequests,
    required this.onRefresh,
    required this.onToggleAvailability,
    required this.getDistanceToPassenger,
    required this.getEstimatedTimeToPassenger,
    required this.onDismissRequest,
    required this.onAcceptRequest,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
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

          const SizedBox(height: 16),

          // زر التفعيل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DriverAvailabilityToggle(
              isStatusInitialized: isStatusInitialized,
              isAvailable: isAvailable,
              isTogglingAvailability: isTogglingAvailability,
              onToggle: onToggleAvailability,
            ),
          ),

          const SizedBox(height: 16),

          // إحصائيات اليوم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DriverStatsCard(
              todayTrips: todayTrips,
              todayEarnings: todayEarnings,
            ),
          ),

          const SizedBox(height: 16),

          // الطلبات الواردة
          if (incomingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'طلبات الرحلات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...incomingRequests.map((request) {
              final distance = getDistanceToPassenger(request);
              final eta = getEstimatedTimeToPassenger(distance);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DriverTripRequestCard(
                  request: request,
                  distanceToPassenger: distance,
                  estimatedTimeToPassenger: eta,
                  onDismiss: () => onDismissRequest(request),
                  onAccept: onAcceptRequest,
                ),
              );
            }),
          ],

          if (incomingRequests.isEmpty && isAvailable)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text(
                      'لا توجد طلبات حالياً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

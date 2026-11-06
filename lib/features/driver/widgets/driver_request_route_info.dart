import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../trips/models/trip_request_model.dart';

/// ويدجت عرض معلومات المسار والعناوين والمسافة للطلب
class DriverRequestRouteInfo extends StatelessWidget {
  final TripRequestModel request;
  final double distanceToPassenger;
  final int estimatedTimeToPassenger;

  const DriverRequestRouteInfo({
    super.key,
    required this.request,
    required this.distanceToPassenger,
    required this.estimatedTimeToPassenger,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final tripDistance = request.distance;
    final tripEstimatedTime = (tripDistance * 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // معلومات مسافة ووقت الرحلة الفعلية
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route_rounded, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'معلومات الرحلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.straighten_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${tripDistance.toStringAsFixed(1)} كم',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 20, color: AppColors.border),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$tripEstimatedTime دقيقة',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // المسافة بين موقع السائق وموقع الراكب
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                loc.distanceToYou,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${distanceToPassenger.toStringAsFixed(1)} كم',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppColors.border)),
              const SizedBox(width: 8),
              Text(
                '$estimatedTimeToPassenger د',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // العناوين (الانطلاق والوجهة)
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                request.pickupAddress,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.flag_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                request.destinationAddress,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        if (request.secondDestinationAddress != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.add_location_alt_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.secondDestinationAddress!,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

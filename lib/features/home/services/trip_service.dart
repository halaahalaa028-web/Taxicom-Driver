/// خدمة الرحلات لتطبيق السائق
/// 
/// توفر وظائف حساب السعر والمسار مع دعم التسعير والتقريب المالي الديناميكي
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/utils/trip_calculation_helper.dart';

/// فئة خدمة الرحلات
class TripService {
  TripService._();
  static final TripService _instance = TripService._();
  static TripService get instance => _instance;

  /// حساب السعر التقديري للرحلة
  double calculatePrice(
    double distanceKm, {
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    LatLng? secondDestinationLocation,
    String? countryCode,
  }) {
    double finalDistance = distanceKm;
    if (pickupLocation != null && destinationLocation != null) {
      finalDistance = getCappedDistance(
        googleDistance: distanceKm,
        pickupLat: pickupLocation.latitude,
        pickupLng: pickupLocation.longitude,
        destLat: destinationLocation.latitude,
        destLng: destinationLocation.longitude,
        secondDestLat: secondDestinationLocation?.latitude,
        secondDestLng: secondDestinationLocation?.longitude,
      );
    }

    return TripCalculationHelper.calculatePrice(
      finalDistance,
      countryCode: countryCode,
    );
  }

  /// الحصول على المسافة المحددة (Capped Distance) بناءً على صيغة Haversine
  double getCappedDistance({
    required double googleDistance,
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    double? secondDestLat,
    double? secondDestLng,
  }) {
    double straightDist = _calculateDistanceBetween(pickupLat, pickupLng, destLat, destLng);
    if (secondDestLat != null && secondDestLng != null) {
      straightDist += _calculateDistanceBetween(destLat, destLng, secondDestLat, secondDestLng);
    }
    final double capLimit = math.max(straightDist * 1.5, straightDist + 2.0);
    if (googleDistance > capLimit) {
      debugPrint('⚠️ [Fare Cap Warning] Google Distance ($googleDistance km) exceeded cap limit ($capLimit km). Straight line: $straightDist km. Capping to $capLimit km.');
      return capLimit;
    }
    return googleDistance;
  }

  double _calculateDistanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // كم
    
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLng = (lng2 - lng1) * (math.pi / 180);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// تنسيق السعر للعرض
  String formatPrice(double price, {String? currency, String? countryCode}) {
    return TripCalculationHelper.formatPrice(
      price,
      currency: currency,
      countryCode: countryCode,
    );
  }

  /// تقدير وقت الرحلة بالدقائق
  int estimateTripTime(double distanceKm) {
    const double averageSpeedKmPerHour = 30;
    double timeHours = distanceKm / averageSpeedKmPerHour;
    int timeMinutes = (timeHours * 60).round();
    return timeMinutes < 3 ? 3 : timeMinutes;
  }

  /// تنسيق المسافة للعرض
  String formatDistance(double distanceKm) {
    return TripCalculationHelper.formatDistance(distanceKm);
  }

  /// تنسيق الوقت للعرض
  String formatTime(int minutes) {
    return TripCalculationHelper.formatDuration(minutes);
  }
}

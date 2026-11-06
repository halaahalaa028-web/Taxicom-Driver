/// نماذج وقوائم أسباب إلغاء الرحلة للسائق
library;

import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../trips/models/trip_request_model.dart';

/// نموذج سبب الإلغاء للسائق
class DriverCancellationReason {
  final String key;
  final IconData icon;

  const DriverCancellationReason({
    required this.key,
    required this.icon,
  });

  /// الحصول على عنوان السبب المترجم
  String getLocalizedTitle(AppLocalizations loc) {
    switch (key) {
      case 'carMalfunction':
        return loc.cancelReasonCarMalfunction;
      case 'heavyTraffic':
        return loc.cancelReasonHeavyTraffic;
      case 'pickupTooFarOrInaccurate':
        return loc.cancelReasonPickupTooFarOrInaccurate;
      case 'passengerRequestedCancel':
        return loc.cancelReasonPassengerRequestedCancel;
      case 'personalEmergency':
        return loc.cancelReasonPersonalEmergency;
      case 'passengerNoShow':
        return loc.cancelReasonPassengerNoShow;
      case 'passengerUnreachable':
        return loc.cancelReasonPassengerUnreachable;
      case 'excessLoad':
        return loc.cancelReasonExcessLoad;
      case 'inaccurateOrUnsafeLocation':
      case 'inaccurateLocation':
        return loc.cancelReasonInaccurateOrUnsafeLocation;
      case 'passengerRefused':
        return loc.cancelReasonPassengerRefused;
      case 'otherReasons':
        return loc.cancelReasonOtherReasons;
      default:
        return key;
    }
  }

  /// الحصول على وصف السبب المترجم
  String getLocalizedDescription(AppLocalizations loc) {
    switch (key) {
      case 'carMalfunction':
        return loc.cancelReasonCarMalfunctionDesc;
      case 'heavyTraffic':
        return loc.cancelReasonHeavyTrafficDesc;
      case 'pickupTooFarOrInaccurate':
        return loc.cancelReasonPickupTooFarOrInaccurateDesc;
      case 'passengerRequestedCancel':
        return loc.cancelReasonPassengerRequestedCancelDesc;
      case 'personalEmergency':
        return loc.cancelReasonPersonalEmergencyDesc;
      case 'passengerNoShow':
        return loc.cancelReasonPassengerNoShowDesc;
      case 'passengerUnreachable':
        return loc.cancelReasonPassengerUnreachableDesc;
      case 'excessLoad':
        return loc.cancelReasonExcessLoadDesc;
      case 'inaccurateOrUnsafeLocation':
      case 'inaccurateLocation':
        return loc.cancelReasonInaccurateOrUnsafeLocationDesc;
      case 'passengerRefused':
        return loc.cancelReasonPassengerRefusedDesc;
      case 'otherReasons':
      default:
        return '';
    }
  }
}

/// أسباب إلغاء السائق وهو في الطريق لموقع الاستلام
final List<DriverCancellationReason> driverOnWayReasons = const [
  DriverCancellationReason(
    key: 'carMalfunction',
    icon: Icons.car_crash_outlined,
  ),
  DriverCancellationReason(
    key: 'heavyTraffic',
    icon: Icons.traffic_rounded,
  ),
  DriverCancellationReason(
    key: 'pickupTooFarOrInaccurate',
    icon: Icons.location_off_outlined,
  ),
  DriverCancellationReason(
    key: 'passengerRequestedCancel',
    icon: Icons.phone_disabled_outlined,
  ),
  DriverCancellationReason(
    key: 'personalEmergency',
    icon: Icons.warning_amber_rounded,
  ),
  DriverCancellationReason(
    key: 'otherReasons',
    icon: Icons.more_horiz_rounded,
  ),
];

/// أسباب إلغاء السائق بعد الوصول لموقع الاستلام والانتظار
final List<DriverCancellationReason> driverArrivedReasons = const [
  DriverCancellationReason(
    key: 'passengerNoShow',
    icon: Icons.person_off_outlined,
  ),
  DriverCancellationReason(
    key: 'passengerUnreachable',
    icon: Icons.phone_missed_outlined,
  ),
  DriverCancellationReason(
    key: 'excessLoad',
    icon: Icons.luggage_outlined,
  ),
  DriverCancellationReason(
    key: 'inaccurateOrUnsafeLocation',
    icon: Icons.wrong_location_outlined,
  ),
  DriverCancellationReason(
    key: 'passengerRefused',
    icon: Icons.do_not_disturb_on_outlined,
  ),
  DriverCancellationReason(
    key: 'otherReasons',
    icon: Icons.more_horiz_rounded,
  ),
];

/// جلب أسباب الإلغاء للسائق بناء على مرحلة الرحلة
List<DriverCancellationReason> getDriverCancellationReasonsForStatus(TripStatus status) {
  if (status == TripStatus.arrivedAtPickup) {
    return driverArrivedReasons;
  }
  return driverOnWayReasons;
}

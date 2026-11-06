import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/driver_tracking_service.dart';
import '../../permissions/screens/location_disclosure_screen.dart';
import '../../profile/services/user_service.dart';

/// معالج تتبع وتحديث الموقع لخدمة السائق مع التقييد الذكي للترميز الجغرافي
class DriverHomeLocationHandler {
  final LocationService _locationService = LocationService.instance;
  final DriverTrackingService _driverTrackingService = DriverTrackingService.instance;
  final UserService _userService = UserService.instance;

  StreamSubscription<Position>? positionSubscription;

  // ─────────────────────────────────────────────────────────────────────────
  // ثوابت ومتغيرات التقييد الذكي للترميز الجغرافي (Throttling & Caching)
  // ─────────────────────────────────────────────────────────────────────────
  static const double minDistanceForGeocodingMeters = 250.0;
  static const Duration minIntervalForGeocoding = Duration(seconds: 45);

  LatLng? _lastGeocodedLocation;
  DateTime? _lastGeocodedTime;
  String _lastKnownAddress = '';
  bool _isGeocodingInProgress = false;

  String get lastKnownAddress => _lastKnownAddress;

  Future<Position?> initLocation(BuildContext context) async {
    final disclosureShown = await _locationService.wasDisclosureShown();
    if (!disclosureShown && context.mounted) {
      final accepted = await showLocationDisclosureDialog(context);
      if (accepted) {
        await _locationService.setDisclosureShown();
      } else {
        return null;
      }
    }
    return await _locationService.getCurrentPosition();
  }

  void startTracking({
    required bool isHighAccuracy,
    required void Function(Position position, LatLng newLocation) onLocationUpdate,
    void Function(Position position)? onMockLocationDetected,
  }) {
    positionSubscription?.cancel();
    final stream = isHighAccuracy
        ? _locationService.getHighAccuracyPositionStream()
        : _locationService.getPositionStream();

    positionSubscription = stream.listen(
      (position) {
        if (position.isMocked) {
          debugPrint('🚨 [DriverHomeLocationHandler] تم رصد موقع وهمي (Mock Location) أثناء البث المباشر!');
          onMockLocationDetected?.call(position);
          return;
        }

        final newLocation = LatLng(position.latitude, position.longitude);
        onLocationUpdate(position, newLocation);
      },
      onError: (error) {
        debugPrint('⚠️ [DriverHomeLocationHandler] Location stream error handled: $error');
      },
      cancelOnError: false,
    );
  }

  void stopTracking() {
    positionSubscription?.cancel();
    positionSubscription = null;
  }

  /// التحقق الذكي من استيفاء شروط المسافة والوقت لطلب الترميز الجغرافي العكسي
  bool shouldUpdateAddress({
    required LatLng newLocation,
    required bool hasActiveTrip,
  }) {
    if (hasActiveTrip || _isGeocodingInProgress) return false;
    if (_lastGeocodedLocation == null || _lastGeocodedTime == null) return true;

    final distanceMoved = Geolocator.distanceBetween(
      _lastGeocodedLocation!.latitude,
      _lastGeocodedLocation!.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );
    final timeElapsed = DateTime.now().difference(_lastGeocodedTime!);

    return distanceMoved >= minDistanceForGeocodingMeters && timeElapsed >= minIntervalForGeocoding;
  }

  /// تحويل الإحداثيات إلى عنوان نصي مع التخزين المؤقت وحماية الأخطاء
  Future<String> getAddressFromCoordinates(
    LatLng location, {
    bool force = false,
    bool hasActiveTrip = false,
  }) async {
    if (hasActiveTrip && !force) return _lastKnownAddress;
    if (!force && !shouldUpdateAddress(newLocation: location, hasActiveTrip: hasActiveTrip)) {
      return _lastKnownAddress;
    }
    if (_isGeocodingInProgress) return _lastKnownAddress;

    _isGeocodingInProgress = true;
    try {
      final address = await _locationService
          .getAddressFromCoordinates(location.latitude, location.longitude)
          .timeout(const Duration(seconds: 4));

      if (address.isNotEmpty && address != 'موقع غير معروف') {
        _lastKnownAddress = address;
        _lastGeocodedLocation = location;
        _lastGeocodedTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('⚠️ [DriverHomeLocationHandler] Reverse geocoding failed (graceful fallback): $e');
    } finally {
      _isGeocodingInProgress = false;
    }

    return _lastKnownAddress.isNotEmpty ? _lastKnownAddress : 'موقع غير معروف';
  }

  Future<void> updateFirebaseLocation({
    required Position position,
    required bool isAvailable,
    required bool hasActiveTrip,
  }) async {
    if (position.isMocked) {
      debugPrint('🚨 [DriverHomeLocationHandler] تم حظر إرسال إحداثيات وهمية إلى Firebase!');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final cachedUser = _userService.cachedUser;

    if (hasActiveTrip || isAvailable) {
      await _driverTrackingService.updateDriverLocation(
        driverId: user.uid,
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: hasActiveTrip ? position.speed : 0.0,
        accuracy: hasActiveTrip ? position.accuracy : 0.0,
        fcmToken: cachedUser?.fcmToken,
        isMocked: position.isMocked,
      );
    }
  }

  Future<void> pushCurrentLocationToFirebase({
    required LatLng location,
    double heading = 0.0,
    bool hasActiveTrip = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final cachedUser = _userService.cachedUser;

    try {
      await _driverTrackingService.updateDriverLocation(
        driverId: user.uid,
        lat: location.latitude,
        lng: location.longitude,
        heading: heading,
        speed: 0.0,
        accuracy: 0.0,
        fcmToken: cachedUser?.fcmToken,
        isMocked: false,
      );
    } catch (e) {
      debugPrint('⚠️ [DriverHomeLocationHandler] pushCurrentLocationToFirebase failed: $e');
    }
  }

  void handleSignificantMovement({
    required LatLng newLocation,
    required LatLng? lastStreamLocation,
    required bool isAvailable,
    required void Function(LatLng loc) onMoved,
  }) {
    if (!isAvailable || lastStreamLocation == null) return;
    final moved = Geolocator.distanceBetween(
      lastStreamLocation.latitude,
      lastStreamLocation.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );
    if (moved > 100) {
      onMoved(newLocation);
    }
  }

  void dispose() {
    stopTracking();
  }
}

/// خدمة الموقع وتحديد الإحداثيات
/// 
/// توفر وظائف الحصول على الموقع الحالي، كشف المواقع الوهمية (Mock Location)،
/// وإدارة الصلاحيات والبث المباشر للإحداثيات
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'reverse_geocoding_service.dart';

/// فئة خدمة الموقع
class LocationService {
  LocationService._();
  
  static final LocationService _instance = LocationService._();
  
  /// الحصول على instance وحيد
  static LocationService get instance => _instance;
  
  /// هل وضع المطور مفعل
  static bool isDeveloperModeEnabled = false;
  
  /// تحميل حالة وضع المطور
  static Future<void> loadDeveloperMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDeveloperModeEnabled = prefs.getBool('developer_mode_enabled') ?? false;
    } catch (_) {}
  }

  /// مفتاح حفظ حالة عرض الإفصاح
  static const String _disclosureShownKey = 'location_disclosure_shown';

  /// التحقق من إذن الموقع وطلبه إذا لزم الأمر
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }
  
  /// التحقق مما إذا كان الإفصاح قد عُرض من قبل
  Future<bool> wasDisclosureShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disclosureShownKey) ?? false;
  }
  
  /// تعيين أن الإفصاح قد عُرض
  Future<void> setDisclosureShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclosureShownKey, true);
  }
  
  /// التحقق من حالة إذن الموقع الحالية
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
  
  /// طلب إذن الموقع
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }
  
  /// فتح إعدادات الموقع في الجهاز
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
  
  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// الحصول على الموقع الحالي مع فحص التزييف (Anti-Mock Location)
  Future<Position?> getCurrentPosition({bool allowMock = false}) async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (!allowMock && position.isMocked) {
        debugPrint('🚨 [LocationService] تم اكتشاف وحظر موقع وهمي (Mock Location)!');
        return null;
      }

      return position;
    } catch (_) {
      return null;
    }
  }

  /// التحقق الصريح مما إذا كان موقع الجهاز الحالي وهمياً ومزيفاً
  Future<bool> isLocationMocked() async {
    try {
      final position = await getCurrentPosition(allowMock: true);
      return position?.isMocked ?? false;
    } catch (_) {
      return false;
    }
  }

  /// التحقق من كون كائن الموقع Position وهمياً
  static bool isMockLocation(Position position) => position.isMocked;

  /// الحصول على الموقع الافتراضي (السماوة)
  Future<Position> getDefaultPosition() async {
    return Position(
      latitude: AppConstants.samawahLat,
      longitude: AppConstants.samawahLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// التحقق مما إذا كان الموقع داخل حدود العراق
  static bool isWithinServiceArea(double latitude, double longitude) {
    return latitude >= 29.0 && latitude <= 37.5 && 
           longitude >= 38.7 && longitude <= 48.6;
  }

  /// تحويل الإحداثيات إلى عنوان دقيق ومفصل عبر خدمة ReverseGeocodingService
  Future<String> getAddressFromCoordinates(double latitude, double longitude) =>
      ReverseGeocodingService.instance.getAddressFromCoordinates(latitude, longitude);

  /// حساب المسافة بين نقطتين بالكيلومتر
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000;
  }

  /// بث مستمر لتحديثات الموقع
  Stream<Position> getPositionStream() {
    if (Platform.isIOS) {
      return Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          activityType: ActivityType.automotiveNavigation,
        ),
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
  }

  /// بث مستمر لتحديثات الموقع بأعلى دقة (للتتبع أثناء الرحلات)
  Stream<Position> getHighAccuracyPositionStream() {
    if (Platform.isIOS) {
      return Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          activityType: ActivityType.automotiveNavigation,
        ),
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "تتبع الرحلة",
          notificationText: "يتم تتبع موقعك لعرضه للزبون",
          enableWakeLock: true,
        ),
      ),
    );
  }
}

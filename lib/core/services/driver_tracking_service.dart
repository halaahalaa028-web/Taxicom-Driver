/// خدمة تتبع موقع السائق
/// 
/// تستخدم Firebase Realtime Database للاستماع لموقع السائق لحظياً
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

/// نموذج موقع السائق
class DriverLocation {
  /// خط العرض
  final double lat;
  
  /// خط الطول
  final double lng;
  
  /// اتجاه السيارة (بالدرجات)
  final double heading;
  
  /// سرعة السائق (متر/ثانية)
  final double speed;
  
  /// دقة الموقع (بالمتر)
  final double accuracy;
  
  /// الموقع كـ LatLng
  LatLng get latLng => LatLng(lat, lng);

  DriverLocation({
    required this.lat,
    required this.lng,
    this.heading = 0.0,
    this.speed = 0.0,
    this.accuracy = 0.0,
  });

  /// إنشاء من Map
  factory DriverLocation.fromMap(Map<dynamic, dynamic> map) {
    double lat = 0.0;
    double lng = 0.0;

    if (map['lat'] != null && map['lng'] != null) {
      lat = (map['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (map['lng'] as num?)?.toDouble() ?? 0.0;
    } else if (map['l'] != null) {
      final lField = map['l'];
      if (lField is List && lField.length >= 2) {
        lat = (lField[0] as num?)?.toDouble() ?? 0.0;
        lng = (lField[1] as num?)?.toDouble() ?? 0.0;
      }
    }

    final headingVal = map['h'] ?? map['heading'] ?? 0.0;
    final speedVal = map['s'] ?? map['speed'] ?? 0.0;
    final accuracyVal = map['a'] ?? map['accuracy'] ?? 0.0;

    return DriverLocation(
      lat: lat,
      lng: lng,
      heading: (headingVal as num?)?.toDouble() ?? 0.0,
      speed: (speedVal as num?)?.toDouble() ?? 0.0,
      accuracy: (accuracyVal as num?)?.toDouble() ?? 0.0,
    );
  }
  
  @override
  String toString() => 'DriverLocation(lat: $lat, lng: $lng, heading: $heading, speed: $speed, accuracy: $accuracy)';
}

/// خدمة تتبع السائق
class DriverTrackingService {
  /// Singleton instance
  static final DriverTrackingService instance = DriverTrackingService._();
  
  DriverTrackingService._();
  
  /// رابط قاعدة البيانات (europe-west1)
  static const String _databaseUrl = AppConstants.realtimeDatabaseUrl;
  
  /// مرجع قاعدة البيانات
  late final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _databaseUrl,
  ).ref();
  
  /// الاستماع لموقع السائق
  /// 
  /// [driverId] معرف السائق
  /// يعيد Stream من مواقع السائق المحدثة
  Stream<DriverLocation?> watchDriverLocation(String driverId) {
    return _database
        .child('drivers_locations')
        .child(driverId)
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return null;
          
          if (data is Map) {
            return DriverLocation.fromMap(data);
          }
          return null;
        });
  }
  
  /// الحصول على موقع السائق مرة واحدة
  Future<DriverLocation?> getDriverLocation(String driverId) async {
    final snapshot = await _database
        .child('drivers_locations')
        .child(driverId)
        .get();
    
    if (!snapshot.exists || snapshot.value == null) return null;
    
    final data = snapshot.value;
    if (data is Map) {
      return DriverLocation.fromMap(data);
    }
    return null;
  }

  
  /// تحديث موقع السائق
  /// 
  /// [driverId] معرف السائق
  /// [lat] خط العرض
  /// [lng] خط الطول
  /// [heading] الاتجاه
  /// [speed] السرعة (متر/ثانية)
  /// [accuracy] دقة الموقع (بالمتر)
  /// [fcmToken] FCM Token للسائق (اختياري - لتسريع الإشعارات)
  Future<void> updateDriverLocation({
    required String driverId,
    required double lat,
    required double lng,
    required double heading,
    double speed = 0.0,
    double accuracy = 0.0,
    String? fcmToken,
    bool isMocked = false,
  }) async {
    if (isMocked) {
      debugPrint('⚠️ [RTDB Security] تم حظر إرسال الموقع بسبب اكتشاف موقع وهمي (Mock Location)!');
      return;
    }
    try {
      debugPrint('🔄 [RTDB] محاولة تحديث موقع السائق: $driverId');
      debugPrint('📍 [RTDB] الموقع: $lat, $lng');
      
      // حساب Geohash للموقع (دقة 9 للدقة العالية)
      final geohash = _encodeGeohash(lat, lng, precision: 9);
      debugPrint('🔍 [RTDB] Geohash: $geohash');
      
      final locationRef = _database.child('drivers_locations').child(driverId);
      
      // تحديث الموقع مع Geohash
      final data = {
        'g': geohash,           // Geohash للبحث السريع
        'l': [lat, lng],        // الموقع بصيغة GeoFire
        'h': heading,           // الاتجاه
        's': speed,             // السرعة
        'a': accuracy,          // الدقة
        'ts': ServerValue.timestamp, // الوقت
      };
      
      // إضافة FCM Token إذا كان متوفراً
      if (fcmToken != null && fcmToken.isNotEmpty) {
        data['t'] = fcmToken;
        debugPrint('📱 [RTDB] FCM Token متوفر');
      } else {
        debugPrint('⚠️ [RTDB] FCM Token غير متوفر');
      }
      
      debugPrint('💾 [RTDB] إرسال البيانات...');
      await locationRef.set(data);
      debugPrint('✅ [RTDB] تم التحديث بنجاح!');
    } catch (e, stackTrace) {
      debugPrint('❌ [RTDB] خطأ في تحديث الموقع: $e');
      debugPrint('📋 [RTDB] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// تشفير Geohash
  String _encodeGeohash(double lat, double lng, {int precision = 9}) {
    // استخدام Base32 alphabet للـ Geohash
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    
    double minLat = -90.0;
    double maxLat = 90.0;
    double minLng = -180.0;
    double maxLng = 180.0;
    
    String geohash = '';
    int bit = 0;
    int ch = 0;
    bool even = true;
    
    while (geohash.length < precision) {
      if (even) {
        // خط الطول
        final mid = (minLng + maxLng) / 2;
        if (lng > mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        // خط العرض
        final mid = (minLat + maxLat) / 2;
        if (lat > mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      
      even = !even;
      
      if (bit < 4) {
        bit++;
      } else {
        geohash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    
    return geohash;
  }
  
  /// حذف موقع السائق (عند Go Offline)
  Future<void> removeDriverLocation(String driverId) async {
    await _database.child('drivers_locations').child(driverId).remove();
  }
}

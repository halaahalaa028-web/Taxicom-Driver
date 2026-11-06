/// خدمة Geohashing
/// 
/// توفر وظائف تحويل الإحداثيات إلى Geohash وحساب حدود البحث
library;

import 'dart:math' as dart_math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/// خدمة Geohashing
class GeohashService {
  GeohashService._();
  
  static final GeohashService _instance = GeohashService._();
  
  /// الحصول على instance وحيد
  static GeohashService get instance => _instance;
  
  /// تحويل الإحداثيات إلى Geohash
  /// 
  /// [lat] خط العرض
  /// [lng] خط الطول
  /// [precision] دقة الـ Geohash (الافتراضي 9 للدقة العالية)
  /// 
  /// Returns: Geohash string
  String encodeGeohash(double lat, double lng, {int precision = 9}) {
    return GeoFirePoint(
      GeoPoint(lat, lng),
    ).geohash.substring(0, precision);
  }
  
  /// حساب حدود Geohash للبحث ضمن نطاق معين
  /// 
  /// [centerLat] خط عرض المركز
  /// [centerLng] خط طول المركز
  /// [radiusKm] نصف قطر البحث بالكيلومتر
  /// 
  /// Returns: List من الـ Geohash ranges للبحث
  List<String> getGeohashRange(
    double centerLat,
    double centerLng,
    double radiusKm,
  ) {
    // حساب الـ Geohash للمركز
    final center = GeoFirePoint(GeoPoint(centerLat, centerLng));
    
    // حساب الدقة المناسبة حسب نصف القطر
    // كلما كان النطاق أكبر، كلما قلت الدقة
    int precision;
    if (radiusKm <= 0.5) {
      precision = 9; // دقة عالية جداً (~5 أمتار)
    } else if (radiusKm <= 2) {
      precision = 7; // دقة عالية (~150 متر)
    } else if (radiusKm <= 5) {
      precision = 6; // دقة متوسطة (~1.2 كم)
    } else {
      precision = 5; // دقة منخفضة (~5 كم)
    }
    
    // إرجاع قائمة بالـ Geohash المحتملة في النطاق
    // في الممارسة، نستخدم prefix للبحث
    final baseHash = center.geohash.substring(0, precision);
    
    // نحتاج للبحث في 9 مربعات محيطة بالمركز
    // (المربع الأوسط والمربعات المحيطة به)
    return _getNeighbors(baseHash);
  }
  
  /// الحصول على الـ Geohashes المجاورة (8 اتجاهات + المركز = 9)
  List<String> _getNeighbors(String geohash) {
    // للتبسيط، نرجع المربع الحالي فقط
    // في الإنتاج، يمكن استخدام مكتبة للحصول على الجيران الفعليين
    return [geohash];
  }
  
  /// حساب المسافة بين نقطتين (Haversine)
  /// 
  /// [lat1] خط عرض النقطة الأولى
  /// [lng1] خط طول النقطة الأولى
  /// [lat2] خط عرض النقطة الثانية
  /// [lng2] خط طول النقطة الثانية
  /// 
  /// Returns: المسافة بالكيلومتر
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0; // نصف قطر الأرض بالكيلومتر
    
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = 
        (1 - dart_math.cos(dLat)) / 2 +
        dart_math.cos(_toRadians(lat1)) *
        dart_math.cos(_toRadians(lat2)) *
        (1 - dart_math.cos(dLng)) / 2;
    
    final c = 2 * dart_math.atan2(dart_math.sqrt(a), dart_math.sqrt(1 - a));
    
    return R * c;
  }
  
  /// تحويل من درجات إلى راديان
  double _toRadians(double degrees) {
    return degrees * dart_math.pi / 180;
  }
}


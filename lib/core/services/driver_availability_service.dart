/// خدمة إدارة توفر السائق
/// 
/// تتحقق من جاهزية GPS والصلاحيات وكشف المواقع الوهمية قبل تفعيل السائق
/// وتراقب حالة GPS أثناء العمل لفرض الإيقاف التلقائي
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_tracking_service.dart';
import 'location_service.dart';

/// نتيجة فحص جاهزية السائق للعمل
enum AvailabilityError {
  /// خدمة GPS مغلقة في الجهاز
  gpsDisabled,
  
  /// صلاحية الموقع مرفوضة (يمكن إعادة الطلب)
  permissionDenied,
  
  /// صلاحية الموقع مرفوضة نهائياً (يجب فتح الإعدادات)
  permissionDeniedForever,

  /// تم اكتشاف موقع وهمي أو برنامج Fake GPS
  mockLocationDetected,
}

/// نتيجة فحص الجاهزية
class AvailabilityCheckResult {
  /// هل يمكن المتابعة؟
  final bool canProceed;
  
  /// نوع الخطأ (إن وُجد)
  final AvailabilityError? error;

  const AvailabilityCheckResult._({
    required this.canProceed,
    this.error,
  });

  /// نجاح الفحص
  factory AvailabilityCheckResult.success() =>
      const AvailabilityCheckResult._(canProceed: true);

  /// فشل الفحص مع سبب
  factory AvailabilityCheckResult.failure(AvailabilityError error) =>
      AvailabilityCheckResult._(canProceed: false, error: error);
}

/// خدمة إدارة توفر السائق
class DriverAvailabilityService {
  /// Singleton instance
  static final DriverAvailabilityService instance = DriverAvailabilityService._();
  
  DriverAvailabilityService._();

  final DriverTrackingService _trackingService = DriverTrackingService.instance;
  
  Stream<ServiceStatus>? _gpsStatusStream;

  // ─────────────────────────────────────────
  // 1. جدار الحماية قبل التفعيل (Pre-condition Check)
  // ─────────────────────────────────────────

  /// التحقق من جاهزية السائق للعمل
  /// 
  /// يفحص:
  /// 1. هل خدمة GPS مُفعّلة في الجهاز؟
  /// 2. هل صلاحيات الموقع ممنوحة؟
  /// 3. هل الموقع الجغرافي حقيقي وغير مزيف (Anti-Mock Location)؟
  /// 
  /// يُرجع [AvailabilityCheckResult] يوضح إمكانية المتابعة أو سبب الفشل
  Future<AvailabilityCheckResult> checkCanGoOnline() async {
    try {
      // فحص 1: هل GPS مُفعّل في الجهاز (Hardware)
      final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        return AvailabilityCheckResult.failure(AvailabilityError.gpsDisabled);
      }

      // فحص 2: هل صلاحيات الموقع ممنوحة
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return AvailabilityCheckResult.failure(AvailabilityError.permissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return AvailabilityCheckResult.failure(AvailabilityError.permissionDeniedForever);
      }

      // فحص 3: كشف الموقع الوهمي وبرامج Fake GPS
      final isMocked = await LocationService.instance.isLocationMocked();
      if (isMocked) {
        debugPrint('🚨 [AvailabilityService] حظر تفعيل السائق بسبب اكتشاف موقع وهمي (Mock Location)!');
        return AvailabilityCheckResult.failure(AvailabilityError.mockLocationDetected);
      }

      // كل الفحوصات نجحت
      return AvailabilityCheckResult.success();
    } catch (e) {
      debugPrint('❌ [AvailabilityService] خطأ في فحص الجاهزية: $e');
      return AvailabilityCheckResult.failure(AvailabilityError.gpsDisabled);
    }
  }

  // ─────────────────────────────────────────
  // 2. المراقبة المستمرة (GPS Status Stream)
  // ─────────────────────────────────────────

  /// بث حالة خدمة GPS في الوقت الفعلي
  Stream<ServiceStatus> getGpsStatusStream() {
    _gpsStatusStream ??= Geolocator.getServiceStatusStream().asBroadcastStream();
    return _gpsStatusStream!;
  }

  // ─────────────────────────────────────────
  // 3. الإيقاف التلقائي الفوري (Force Offline)
  // ─────────────────────────────────────────

  /// إيقاف السائق إجبارياً
  Future<bool> forceOffline() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ [AvailabilityService] لا يوجد مستخدم مسجل');
        return false;
      }

      final driverId = user.uid;
      debugPrint('🔴 [AvailabilityService] بدء الإيقاف الإجباري للسائق: $driverId');

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(driverId)
            .update({
          'isOnline': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [AvailabilityService] Firestore: isOnline = false');
      } catch (e) {
        debugPrint('❌ [AvailabilityService] فشل تحديث Firestore: $e');
      }

      try {
        await _trackingService.removeDriverLocation(driverId);
        debugPrint('✅ [AvailabilityService] RTDB: تم حذف موقع السائق');
      } catch (e) {
        debugPrint('❌ [AvailabilityService] فشل حذف موقع RTDB: $e');
      }

      debugPrint('🔴 [AvailabilityService] اكتمل الإيقاف الإجباري');
      return true;
    } catch (e) {
      debugPrint('❌ [AvailabilityService] خطأ عام في forceOffline: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────
  // 4. أدوات مساعدة
  // ─────────────────────────────────────────

  /// فتح إعدادات الموقع في الجهاز
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('❌ [AvailabilityService] فشل فتح إعدادات الموقع: $e');
      return false;
    }
  }

  /// فتح إعدادات التطبيق (لمنح الصلاحيات يدوياً)
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('❌ [AvailabilityService] فشل فتح إعدادات التطبيق: $e');
      return false;
    }
  }
}

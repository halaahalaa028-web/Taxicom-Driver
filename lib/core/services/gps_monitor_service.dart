/// خدمة مراقبة GPS في الخلفية
///
/// تعمل كـ Foreground Service (Android) لمراقبة حالة GPS
/// حتى عندما يكون التطبيق مصغراً أو الشاشة مغلقة.
/// عند إيقاف GPS: تُوقف السائق تلقائياً في Firebase وتُبلّغ الـ UI.
library;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../../firebase_options.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ثوابت
// ─────────────────────────────────────────────────────────────────────────────

/// معرّف قناة الإشعارات — يجب إنشاؤها قبل تشغيل الخدمة
const _kChannelId = 'taxicom_gps_monitor';

/// حدث بدء المراقبة — يُرسل من الـ UI للخدمة مع driverId
const _kEventStart = 'start';

/// حدث إيقاف المراقبة — يُرسل من الـ UI للخدمة
const _kEventStop = 'stop';

/// حدث إطفاء الـ GPS — تُرسله الخدمة للـ UI عند اكتشاف الإيقاف
const kEventGpsDisabled = 'gps_disabled';

/// اسم مفتاح driverId في بيانات الحدث
const _kDriverId = 'driverId';

// ─────────────────────────────────────────────────────────────────────────────
// نقطة الدخول للـ Background Isolate
// ─────────────────────────────────────────────────────────────────────────────

/// نقطة دخول الـ Foreground Service — تعمل في Isolate منفصل تماماً
@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // تهيئة Firebase داخل الـ Isolate (لا يرث تهيئة الـ UI)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 [BgService] Firebase initialized in background isolate');
  } catch (e) {
    debugPrint('⚠️ [BgService] Firebase already initialized: $e');
  }

  // إعداد إشعار Foreground Service — القناة موجودة بالفعل من initialize()
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'تكسيكوم — متاح للعمل',
      content: 'جاري البحث عن رحلات...',
    );
  }

  String? driverId;
  StreamSubscription<ServiceStatus>? gpsSubscription;

  // ─────────────────────────────────
  // دالة Force Offline داخل الـ Isolate
  // ─────────────────────────────────
  Future<void> forceOffline(String uid) async {
    debugPrint('🔴 [BgService] GPS disabled! Force offline for: $uid');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'isOnline': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BgService] Firestore: isOnline = false');
    } catch (e) {
      debugPrint('❌ [BgService] Firestore update failed: $e');
    }

    try {
      await FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConstants.realtimeDatabaseUrl,
      )
          .ref('drivers_locations')
          .child(uid)
          .remove();
      debugPrint('✅ [BgService] RTDB: location removed');
    } catch (e) {
      debugPrint('❌ [BgService] RTDB remove failed: $e');
    }

    service.invoke(kEventGpsDisabled, {_kDriverId: uid});

    await gpsSubscription?.cancel();
    gpsSubscription = null;
    service.stopSelf();
    debugPrint('⏹️ [BgService] Service stopped');
  }

  // الاستماع لأمر البدء
  service.on(_kEventStart).listen((data) async {
    final newDriverId = data?[_kDriverId] as String?;
    if (newDriverId == null || newDriverId.isEmpty) return;

    driverId = newDriverId;
    debugPrint('▶️ [BgService] Monitoring started for driver: $driverId');

    await gpsSubscription?.cancel();

    gpsSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) async {
        debugPrint('📡 [BgService] GPS status: $status');
        if (status == ServiceStatus.disabled && driverId != null) {
          await forceOffline(driverId!);
        }
      },
      onError: (e) {
        debugPrint('❌ [BgService] GPS stream error: $e');
      },
    );
  });

  // الاستماع لأمر الإيقاف
  service.on(_kEventStop).listen((_) async {
    debugPrint('⏹️ [BgService] Stop command received');
    await gpsSubscription?.cancel();
    gpsSubscription = null;
    service.stopSelf();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// GpsMonitorService — Singleton للتحكم من الـ UI
// ─────────────────────────────────────────────────────────────────────────────

class GpsMonitorService {
  static final GpsMonitorService instance = GpsMonitorService._();
  GpsMonitorService._();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// تهيئة خدمة الخلفية — تُستدعى مرة واحدة في `main()`
  static Future<void> initialize() async {
    try {
      // الخطوة 1: إنشاء قناة الإشعار أولاً — مطلوب قبل startForeground() على Android 8+
      if (defaultTargetPlatform == TargetPlatform.android) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _kChannelId,
          'خدمة Taxicom Driver',
          description: 'إشعار مراقبة GPS للسائقين',
          importance: Importance.low,  // Low = لا صوت ولا اهتزاز
          playSound: false,
          enableVibration: false,
        );
        await FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        debugPrint('✅ [GpsMonitorService] Notification channel created: $_kChannelId');
      }

      // الخطوة 2: تهيئة الخدمة
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _kChannelId,
          initialNotificationTitle: 'Taxicom Driver',
          initialNotificationContent: 'جاري البحث عن رحلات...',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onStart,
          onBackground: _iosBackgroundHandler,
        ),
      );
      debugPrint('✅ [GpsMonitorService] Configured');
    } catch (e) {
      // لا نوقف التطبيق — الخدمة اختيارية
      debugPrint('⚠️ [GpsMonitorService] initialize() failed (non-fatal): $e');
    }
  }

  /// بدء مراقبة GPS عند تفعيل السائق
  Future<void> startMonitoring(String driverId) async {
    try {
      final isRunning = await _service.isRunning();
      if (!isRunning) {
        final started = await _service.startService();
        if (!started) {
          debugPrint('⚠️ [GpsMonitorService] startService() returned false — notification permission may be missing');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _service.invoke(_kEventStart, {_kDriverId: driverId});
      debugPrint('▶️ [GpsMonitorService] Monitoring started for: $driverId');
    } catch (e) {
      debugPrint('❌ [GpsMonitorService] Failed to start monitoring (non-fatal): $e');
    }
  }

  /// إيقاف المراقبة عند تحويل السائق لـ Offline
  Future<void> stopMonitoring() async {
    try {
      _service.invoke(_kEventStop, {});
      debugPrint('⏹️ [GpsMonitorService] Stop signal sent');
    } catch (e) {
      debugPrint('❌ [GpsMonitorService] Failed to stop monitoring: $e');
    }
  }

  StreamController? _gpsDisabledController;
  StreamSubscription? _gpsDisabledRawSubscription;

  void _initGpsDisabledStream() {
    if (_gpsDisabledController != null) return;
    _gpsDisabledController = StreamController.broadcast();
    _gpsDisabledRawSubscription = _service.on(kEventGpsDisabled).listen(
      (event) {
        _gpsDisabledController?.add(event);
      },
      onError: (e) {
        debugPrint('⚠️ [GpsMonitorService] Raw GPS event stream error: $e');
      },
      cancelOnError: false,
    );
  }

  /// الاستماع لحدث إيقاف GPS من الـ Background Isolate
  StreamSubscription? listenToGpsDisabled(Function() callback) {
    _initGpsDisabledStream();
    return _gpsDisabledController!.stream.listen(
      (_) {
        callback();
      },
      onError: (e) {
        debugPrint('⚠️ [GpsMonitorService] GPS disabled notification stream error: $e');
      },
      cancelOnError: false,
    );
  }

  /// تنظيف الموارد وتحرير الـ Streams
  void dispose() {
    _gpsDisabledRawSubscription?.cancel();
    _gpsDisabledRawSubscription = null;
    if (_gpsDisabledController != null && !_gpsDisabledController!.isClosed) {
      _gpsDisabledController!.close();
    }
    _gpsDisabledController = null;
    debugPrint('🗑️ [GpsMonitorService] Disposed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// معالج iOS
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<bool> _iosBackgroundHandler(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

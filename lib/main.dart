/// نقطة الدخول الرئيسية للتطبيق
/// 
/// يقوم بتهيئة Firebase وتشغيل التطبيق
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/language_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/gps_monitor_service.dart';
import 'core/services/location_service.dart';
import 'core/services/pricing_service.dart';
import 'core/services/country_service.dart';
import 'core/services/driver_commission_service.dart';

/// نقطة الدخول الرئيسية
void main() async {
  // التأكد من تهيئة Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // معالجة الأخطاء العالمية للـ Flutter Framework
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FlutterError: ${details.exception}');
    debugPrint('📋 StackTrace: ${details.stack}');
  };

  // معالجة الأخطاء العالمية للـ Platform/Asynchronous
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PlatformError: $error');
    debugPrint('📋 StackTrace: $stack');
    return true; // تعني أن الخطأ تم معالجته ولن يؤدي لإغلاق التطبيق قسراً
  };

  // ضبط اتجاه الشاشة للوضع العمودي فقط (لا تحتاج await)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ضبط ألوان شريط الحالة (لا تحتاج await)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // تهيئة Firebase (بأمان لتجنب خطأ duplicate-app)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initializeApp warning: $e');
  }

  // تشغيل التطبيق فوراً - باقي التهيئة تتم في الخلفية داخل AppInitializer
  runApp(const TaxicomDriverApp());

  // ─── التهيئة في الخلفية بعد runApp ───────────────────────────
  // هذه العمليات تعمل بشكل غير متزامن ولا تعيق عرض الواجهة
  _initializeServicesInBackground();
}

/// تهيئة الخدمات في الخلفية بعد تشغيل التطبيق
Future<void> _initializeServicesInBackground() async {
  try {
    // تهيئة App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint('⚠️ App Check init error: $e');
  }

  // تشغيل الخدمات الباقية بالتوازي لتوفير الوقت
  await Future.wait([
    _safeInit('LanguageService', () => LanguageService.instance.initialize()),
    _safeInit('PricingService', () async {
      await PricingService.instance.fetchPricing();
      PricingService.instance.startListening();
    }),
    _safeInit('CountryService', () async {
      await CountryService.instance.fetchCountries();
      CountryService.instance.startListening();
    }),
    _safeInit('DriverCommissionService', () async {
      await DriverCommissionService.instance.fetchDynamicCommission();
      DriverCommissionService.instance.startListening();
    }),
    _safeInit('GpsMonitor', () => GpsMonitorService.initialize()),
    _safeInit('DeveloperMode', () => LocationService.loadDeveloperMode()),
  ]);

  // تهيئة الإشعارات أخيراً (قد تعرض dialog صلاحيات على iOS)
  await _safeInit(
      'NotificationService', () => NotificationService.instance.initialize());
}

/// تهيئة آمنة مع معالجة الأخطاء
Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init();
  } catch (e) {
    debugPrint('⚠️ $name init error: $e');
  }
}




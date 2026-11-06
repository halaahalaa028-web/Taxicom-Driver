/// خدمة الإشعارات FCM
/// 
/// تتعامل مع Firebase Cloud Messaging لإرسال واستقبال الإشعارات
library;

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/wallet/presentation/screens/payout_requests_screen.dart';
import 'session_service.dart';

/// معالج الإشعارات في الخلفية (يجب أن يكون top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('📬 استلام إشعار في الخلفية: ${message.notification?.title ?? message.data['type']}');
}

/// خدمة الإشعارات
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  /// مفتاح التنقل العام لاستخدامه في فتح الشاشات من الإشعارات
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    // إعداد معالج الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // طلب صلاحيات الإشعارات (سريع على Android، قد يُظهر dialog على iOS)
    await _requestPermission();

    // تهيئة الإشعارات المحلية
    await _initializeLocalNotifications();

    // الاستماع للإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // الاستماع عند النقر على الإشعار (من الخلفية)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // التحقق من إشعار أولي (البدء البارد - التطبيق كان مغلقاً)
    await _handleInitialMessage();

    // الحصول على FCM Token في الخلفية بعد التهيئة الأساسية
    // لا ننتظره هنا لتجنب تأخير التطبيق على iOS
    _getFcmToken();

    // الاستماع لتحديث Token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveFcmTokenToFirestore(newToken);
    });
  }

  /// طلب صلاحيات الإشعارات
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: false,
      criticalAlert: false,
    );

    dev.log('🔔 حالة صلاحيات الإشعارات: ${settings.authorizationStatus}', name: 'FCM-Permission');
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    // إعدادات Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // إعدادات iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // إنشاء قنوات الإشعارات لـ Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      const channel = AndroidNotificationChannel(
        'driver_status_channel',
        'حالة السائق',
        description: 'إشعارات تغيير حالة السائق',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(channel);
      
      // قناة إشعارات الإدارة
      const adminChannel = AndroidNotificationChannel(
        'admin_notifications_channel',
        'إشعارات الإدارة',
        description: 'إشعارات من إدارة التطبيق',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(adminChannel);

      // قناة إشعارات طلبات الرحلات
      const tripRequestsChannel = AndroidNotificationChannel(
        'trip_requests_channel',
        'طلبات الرحلات',
        description: 'إشعارات عند وجود طلب رحلة جديد',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(tripRequestsChannel);
    }
  }

  /// الحصول على FCM Token - يعمل في الخلفية ولا يعيق التطبيق
  /// الحصول على FCM Token - يعمل في الخلفية ولا يعيق التطبيق
  Future<void> _getFcmToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        try {
          apnsToken = await _messaging.getAPNSToken();
        } catch (apnsErr) {
          dev.log('❌ خطأ APNs: $apnsErr', name: 'FCM-APNs');
        }

        int attempts = 0;
        while (apnsToken == null && attempts < 3) {
          await Future.delayed(const Duration(seconds: 3));
          try {
            apnsToken = await _messaging.getAPNSToken();
          } catch (_) {}
          attempts++;
        }

        if (apnsToken == null) return;
      }

      _fcmToken = await _messaging.getToken();
      if (_fcmToken == null) {
        await Future.delayed(const Duration(seconds: 2));
        _fcmToken = await _messaging.getToken();
      }

      if (_fcmToken != null) {
        await _saveFcmTokenToFirestore(_fcmToken!);
      }
    } catch (e, st) {
      dev.log('❌ خطأ في _getFcmToken: $e', name: 'FCM-Token', error: e, stackTrace: st);
    }
  }

  /// حفظ FCM Token في Firestore
  Future<void> _saveFcmTokenToFirestore(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        return;
      }
    }

    if (user != null) {
      final isActive = await SessionService.instance.isCurrentDevice(user.uid);
      if (!isActive) return;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        dev.log('🚀 تم حفظ FCM Token بنجاح للمستخدم: ${user.uid}', name: 'FCM-Firestore');
      } catch (e, st) {
        dev.log('❌ خطأ في رفع FCM Token: $e', name: 'FCM-Firestore', error: e, stackTrace: st);
      }
    }
  }

  /// تحديث FCM Token عند تسجيل الدخول
  Future<void> updateFcmTokenOnLogin() async {
    await _getFcmToken();
  }

  /// معالجة الإشعارات في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 استلام إشعار في المقدمة: ${message.notification?.title}');
    
    final notification = message.notification;
    final type = message.data['type'] ?? '';
    if (notification != null) {
      // تحديد القناة بناءً على نوع الإشعار
      final isRequest = type == 'new_trip_request';
      final channelId = isRequest
          ? 'trip_requests_channel'
          : 'driver_status_channel';
      final channelName = isRequest
          ? 'طلبات الرحلات'
          : 'حالة السائق';

      _showLocalNotification(
        title: notification.title ?? (isRequest ? 'طلب رحلة جديد 🚕' : 'إشعار جديد'),
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
        channelId: channelId,
        channelName: channelName,
      );
    } else if (type == 'new_trip_request') {
      final passengerName = message.data['passengerName'] ?? 'راكب';
      final pickupAddress = message.data['pickupAddress'] ?? 'طلب جديد بالقرب منك';
      _showLocalNotification(
        title: 'طلب رحلة جديد: $passengerName 🚕',
        body: pickupAddress,
        payload: jsonEncode(message.data),
        channelId: 'trip_requests_channel',
        channelName: 'طلبات الرحلات',
      );
    }
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'driver_status_channel',
    String channelName = 'حالة السائق',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'إشعارات $channelName',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// التحقق من إشعار أولي (عند فتح التطبيق من إشعار وهو مغلق)
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 التطبيق فُتح من إشعار (بدء بارد): ${initialMessage.data}');
      _navigateBasedOnData(initialMessage.data);
    }
  }

  /// معالجة النقر على الإشعار (من الخلفية)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 تم النقر على الإشعار: ${message.data}');
    _navigateBasedOnData(message.data);
  }

  /// استجابة النقر على الإشعار المحلي
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('👆 تم النقر على الإشعار المحلي: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateBasedOnData(data);
      } catch (e) {
        debugPrint('❌ خطأ في تحليل payload: $e');
      }
    }
  }

  /// التنقل بناءً على بيانات الإشعار
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    debugPrint('🧭 نوع الإشعار: $type');

    if (type == 'new_trip_request') {
      Future.delayed(const Duration(milliseconds: 500), () {
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          navigator.popUntil((route) => route.isFirst);
          debugPrint('✅ تم الذهاب لشاشة السائق الرئيسية لعرض الرحلات');
        }
      });
    } else if (type == 'payout_approved' || type == 'payout_rejected') {
      Future.delayed(const Duration(milliseconds: 500), () {
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) => PayoutRequestsScreen(driverId: user.uid),
              ),
            );
            debugPrint('✅ تم فتح شاشة سجل طلبات سحب الأرباح من الإشعار');
          }
        }
      });
    }
  }

  /// حذف FCM Token عند تسجيل الخروج
  Future<void> clearFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});
        debugPrint('✅ تم حذف FCM Token من Firestore');
      } catch (e) {
        debugPrint('❌ خطأ في حذف FCM Token: $e');
      }
    }
    _fcmToken = null;
  }
}

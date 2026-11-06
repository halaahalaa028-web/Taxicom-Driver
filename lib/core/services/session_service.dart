/// خدمة إدارة الجلسة الواحدة (Single Device Session Management)
///
/// تضمن أن كل مستخدم (سائق أو زبون) لا يمكنه فتح حسابه
/// على أكثر من جهاز في نفس الوقت.
///
/// الآلية:
///  1. عند تسجيل الدخول: تُولِّد معرفاً فريداً للجهاز وتكتبه في Firestore
///     (currentDeviceId) وتحفظه محلياً في SharedPreferences.
///  2. مستمع Firestore يراقب وثيقة المستخدم باستمرار.
///  3. إذا تغيّر currentDeviceId في السيرفر → طرد فوري بحسب نوع الحساب.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'driver_presence_service.dart';
import 'gps_monitor_service.dart';
import 'notification_service.dart';
import '../../features/auth/screens/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ثوابت SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

/// مفتاح حفظ deviceId محلياً
const String kPrefsSessionDeviceId = 'session_device_id';

/// مفتاح حفظ uid المستخدم الحالي
const String kPrefsSessionUid = 'session_uid';

/// مفتاح حفظ نوع المستخدم الحالي
const String kPrefsSessionUserType = 'session_user_type';

// ─────────────────────────────────────────────────────────────────────────────
// SessionService
// ─────────────────────────────────────────────────────────────────────────────

/// خدمة إدارة الجلسة الواحدة — Singleton
class SessionService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final SessionService instance = SessionService._();
  SessionService._();

  // ── المتغيرات الداخلية ───────────────────────────────────────────────────

  /// اشتراك مستمع وثيقة المستخدم في Firestore
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;

  /// هل المستمع نشط؟
  bool _isListening = false;

  bool get isListening => _isListening;

  // ─────────────────────────────────────────────────────────────────────────
  // 1. توليد / جلب معرف الجهاز
  // ─────────────────────────────────────────────────────────────────────────

  /// يُولِّد أو يجلب معرفاً فريداً مستقراً للجهاز الحالي.
  ///
  /// الاستراتيجية: أول تشغيل → UUID عشوائي يُحفظ في SharedPreferences.
  /// كل تشغيل لاحق → نفس UUID من SharedPreferences.
  ///
  /// لماذا UUID وليس Build.ID أو identifierForVendor؟
  /// - Build.ID = رقم إصدار البيلد، مشترك بين جميع الأجهزة من نفس الموديل/الإصدار.
  /// - identifierForVendor يتغير عند حذف التطبيق على iOS.
  /// - UUID عشوائي محفوظ محلياً = معرف فريد وثابت لكل جهاز.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // إذا كان المعرف محفوظاً مسبقاً فلا نعيد توليده
    final cached = prefs.getString(kPrefsSessionDeviceId);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // توليد UUID فريد لهذا الجهاز
    final deviceId = _generateUuid();

    await prefs.setString(kPrefsSessionDeviceId, deviceId);
    debugPrint('📱 [SessionService] DeviceId generated (new): $deviceId');
    return deviceId;
  }

  /// يُولِّد UUID v4 عشوائياً
  String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // UUID v4: أحرف 6 و7 ← 0100xxxx ، أحرف 8 و9 ← 10xxxxxx
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. تسجيل بصمة الجهاز عند الدخول
  // ─────────────────────────────────────────────────────────────────────────

  /// يكتب [currentDeviceId] في وثيقة المستخدم بـ Firestore،
  /// ويحفظ بيانات الجلسة محلياً.
  ///
  /// [uid]      — معرف المستخدم من Firebase Auth
  /// [userType] — 'driver' أو 'customer'
  Future<void> registerDevice(String uid, String userType) async {
    try {
      final deviceId = await getDeviceId();

      // الكتابة في Firestore — يُطلق لاحقاً مستمع الجهاز القديم
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'currentDeviceId': deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // حفظ بيانات الجلسة محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefsSessionDeviceId, deviceId);
      await prefs.setString(kPrefsSessionUid, uid);
      await prefs.setString(kPrefsSessionUserType, userType);

      debugPrint('✅ [SessionService] Device registered: uid=$uid deviceId=$deviceId userType=$userType');
    } catch (e) {
      // تسجيل الدخول لا يتوقف حتى لو فشل التسجيل — الأمان أهم إلا أننا لا نعيق UX
      debugPrint('❌ [SessionService] registerDevice failed (non-fatal): $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. تحديث معرف الجهاز عند كل تشغيل
  // ─────────────────────────────────────────────────────────────────────────

  /// يتحقق من [currentDeviceId] المخزون في Firestore مقارنةً بمعرف الجهاز الحالي.
  ///
  /// ثلاث حالات:
  ///  1. **المعرف موجود ومطابق** → لا تكتب شيئاً (توفير للموارد).
  ///  2. **المعرف موجود لكن مختلف** → هذا يعني أن جهازاً آخر سجّل الدخول.
  ///     لا نكتب شيئاً لأن هذا الجهاز مطرود (سيتولى مستمع الجلسة إجراء الطرد).
  ///  3. **المعرف غير موجود أصلاً** (مستخدمون قدامى) → ضعه لأول مرة.
  ///
  /// يُستدعى هذا الأسلوب عند كل تشغيل للتطبيق وكان المستخدم مسجلاً دخوله.
  ///
  /// [uid]      — معرف المستخدم من Firebase Auth
  /// [userType] — 'driver' أو 'customer'
  Future<void> refreshDeviceIdIfNeeded(String uid, String userType) async {
    try {
      final deviceId = await getDeviceId();

      // جلب وثيقة المستخدم من Firestore
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid);

      final snap = await docRef.get();
      if (!snap.exists) return;

      final serverDeviceId = snap.data()?['currentDeviceId'] as String?;

      // ── الحالة 1: المعرف نفسه → لا نكتب شيئاً ──────────────────────────
      if (serverDeviceId != null &&
          serverDeviceId.isNotEmpty &&
          serverDeviceId == deviceId) {
        debugPrint('✅ [SessionService] DeviceId unchanged, skipping update.');
        return;
      }

      // ── الحالة 2: المعرف مختلف → جهاز آخر سجّل الدخول، هذا الجهاز مطرود ──
      // لا نكتب أي شيء في Firestore لأن ذلك سيُفسد جلسة الجهاز الآخر.
      // سيتولى مستمع الجلسة (startSessionListener) طرد هذا الجهاز تلقائياً.
      if (serverDeviceId != null && serverDeviceId.isNotEmpty) {
        debugPrint(
          '🚫 [SessionService] DeviceId mismatch — another device is logged in. '
          'Skipping update to protect the active session. '
          'server=$serverDeviceId | local=$deviceId',
        );
        return;
      }

      // ── الحالة 3: المعرف غير موجود أصلاً (مستخدم قديم) → ضعه لأول مرة ──
      await docRef.update({
        'currentDeviceId': deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // تحديث SharedPreferences ليبقى متزامناً مع Firestore
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefsSessionDeviceId, deviceId);
      await prefs.setString(kPrefsSessionUid, uid);
      await prefs.setString(kPrefsSessionUserType, userType);

      debugPrint('🆕 [SessionService] DeviceId set for first time (legacy user): $deviceId');
    } catch (e) {
      debugPrint('❌ [SessionService] refreshDeviceIdIfNeeded failed (non-fatal): $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // دالة مساعدة: هل هذا الجهاز هو الجهاز النشط الحالي؟
  // ─────────────────────────────────────────────────────────────────────────

  /// يتحقق مما إذا كان هذا الجهاز هو الجهاز المسجّل حالياً في وثيقة [uid].
  ///
  /// يُستخدم قبل أي عملية كتابة في Firestore (مثل حفظ FCM Token)
  /// لضمان عدم الكتابة عندما يكون الجهاز مطروداً.
  ///
  /// يُعيد [true] إذا كان هذا الجهاز هو الجهاز النشط أو إذا لم يكن هناك
  /// [currentDeviceId] مسجّل أصلاً (مستخدم قديم).
  Future<bool> isCurrentDevice(String uid) async {
    try {
      final deviceId = await getDeviceId();
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!snap.exists) return true; // لا يوجد وثيقة → اسمح بالكتابة
      final serverDeviceId = snap.data()?['currentDeviceId'] as String?;
      // إذا لم يكن هناك deviceId مسجّل بعد → نعتبر الجهاز نشطاً
      if (serverDeviceId == null || serverDeviceId.isEmpty) return true;
      return serverDeviceId == deviceId;
    } catch (e) {
      debugPrint('❌ [SessionService] isCurrentDevice check failed: $e');
      return true; // في حالة الخطأ، اسمح بالكتابة لتجنب حظر UX
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. بدء مستمع الجلسة
  // ─────────────────────────────────────────────────────────────────────────

  /// يبدأ الاستماع لوثيقة المستخدم في Firestore.
  ///
  /// عند كل تغيير يقارن [currentDeviceId] من السيرفر
  /// مع المعرف المحفوظ محلياً.
  /// إذا اختلفا → تنفيذ [_executeForceLogout].
  ///
  /// [uid]      — معرف المستخدم
  /// [userType] — 'driver' أو 'customer'
  Future<void> startSessionListener(String uid, String userType) async {
    // إلغاء أي مستمع سابق
    await stopSessionListener();

    debugPrint('👂 [SessionService] Starting listener: uid=$uid userType=$userType');

    _sessionSubscription = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists) return;

        final data = snapshot.data();
        if (data == null) return;

        final serverDeviceId = data['currentDeviceId'] as String?;
        if (serverDeviceId == null || serverDeviceId.isEmpty) return;

        // جلب المعرف المحلي
        final prefs = await SharedPreferences.getInstance();
        final localDeviceId = prefs.getString(kPrefsSessionDeviceId);

        debugPrint('🔍 [SessionService] Compare — server: $serverDeviceId | local: $localDeviceId');

        // الطرد عند عدم التطابق
        if (localDeviceId != null &&
            localDeviceId.isNotEmpty &&
            serverDeviceId != localDeviceId) {
          debugPrint('🚨 [SessionService] Device mismatch! Executing force logout...');
          await _executeForceLogout(userType);
        }
      },
      onError: (e) {
        debugPrint('❌ [SessionService] Listener error: $e');
      },
    );

    _isListening = true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. إيقاف المستمع
  // ─────────────────────────────────────────────────────────────────────────

  /// يُلغي اشتراك الاستماع وينظّف الحالة.
  Future<void> stopSessionListener() async {
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _isListening = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. خوارزمية الطرد الكاملة
  // ─────────────────────────────────────────────────────────────────────────

  /// ينفّذ تسلسل الطرد:
  ///  1. [سائقون] إيقاف GPS Monitor + مسح presence من RTDB
  ///  2. إيقاف مستمع الجلسة
  ///  3. FirebaseAuth.signOut()
  ///  4. SharedPreferences.clear()
  ///  5. Navigate → LoginScreen + Dialog تحذيري
  Future<void> _executeForceLogout(String userType) async {
    // إيقاف المستمع فوراً لمنع التشغيل المكرر
    await stopSessionListener();

    // ── [سائقون فقط] إيقاف خدمات الموقع ──────────────────────────────────
    if (userType == 'driver') {
      try {
        debugPrint('🔴 [SessionService] Stopping driver services...');
        await GpsMonitorService.instance.stopMonitoring();
        await DriverPresenceService.instance.goOffline();
        debugPrint('✅ [SessionService] Driver services stopped');
      } catch (e) {
        debugPrint('⚠️ [SessionService] Driver cleanup error (non-fatal): $e');
      }
    }

    // ── تسجيل الخروج من Firebase ──────────────────────────────────────────
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ [SessionService] Signed out from FirebaseAuth');
    } catch (e) {
      debugPrint('⚠️ [SessionService] SignOut error: $e');
    }

    // ── مسح البيانات المحلية ──────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ [SessionService] SharedPreferences cleared');
    } catch (e) {
      debugPrint('⚠️ [SessionService] Prefs clear error: $e');
    }

    // ── التوجيه القسري ────────────────────────────────────────────────────
    final navigatorState = NotificationService.navigatorKey.currentState;
    if (navigatorState != null && navigatorState.mounted) {
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      // تأخير بسيط للسماح لـ Navigation بالاكتمال قبل عرض الـ Dialog
      Future.delayed(const Duration(milliseconds: 500), () {
        final ctx = NotificationService.navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          _showForcedLogoutDialog(ctx);
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Dialog الطرد
  // ─────────────────────────────────────────────────────────────────────────

  /// يعرض Dialog غير قابل للتجاوز يُبلّغ المستخدم بسبب تسجيل الخروج.
  void _showForcedLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.security_rounded,
            color: AppColors.error,
            size: 48,
          ),
          title: const Text(
            'تسجيل خروج تلقائي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'تم تسجيل الخروج.\n\n'
            'لقد قمت بتسجيل الدخول من جهاز آخر، '
            'يُسمح باستخدام حسابك على هاتف واحد فقط في نفس الوقت.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

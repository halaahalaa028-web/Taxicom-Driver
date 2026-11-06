/// خدمة إدارة تواجد السائق (Presence System)
///
/// تستخدم Firebase Realtime Database لمعرفة انقطاع اتصال السائق
/// بشكل موثوق حتى عند انقطاع الإنترنت المفاجئ أو إغلاق التطبيق قسراً.
///
/// الآلية:
///  1. عند الإتاحة (go online):
///     - تُسجَّل قاعدة onDisconnect().remove() على المسار status/{driverId}
///       في الـ Firebase Server مسبقاً — تُنفَّذ تلقائياً عند انقطاع اتصال WebSocket
///     - تُكتب القيمة true في نفس المسار لتأكيد الاتصال
///     - يُحدَّث حقل isOnline في Firestore إلى true
///
///  2. عند انقطاع الإنترنت:
///     - خوادم Firebase تُطبِّق onDisconnect().remove() تلقائياً
///     - Cloud Function تكتشف الحذف وتُحدِّث Firestore: isOnline = false
///
///  3. عند الإيقاف الطوعي (go offline):
///     - نُلغي قاعدة onDisconnect أولاً (cancel)
///     - نحذف العقدة يدوياً
///     - نُحدِّث Firestore: isOnline = false
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// خدمة إدارة التواجد للسائق
class DriverPresenceService {
  // ─────────────────────────
  // Singleton
  // ─────────────────────────
  static final DriverPresenceService instance = DriverPresenceService._();
  DriverPresenceService._();

  // ─────────────────────────
  // المتغيرات الداخلية
  // ─────────────────────────

  /// مرجع العقدة الحالية في RTDB
  DatabaseReference? _presenceRef;

  /// معرف السائق الحالي
  String? _currentDriverId;

  /// هل نظام التواجد نشط حالياً؟
  bool _isActive = false;

  bool get isActive => _isActive;

  // ─────────────────────────────────────────────────────────────────
  // 1. تفعيل وضع الإتاحة (Online) مع تسجيل onDisconnect
  // ─────────────────────────────────────────────────────────────────

  /// يُنشئ عقدة التواجد ويُسجِّل onDisconnect للكشف التلقائي عن الانقطاع.
  ///
  /// يجب استدعاؤه بعد التحقق من الاتصال بالإنترنت وصلاحيات السائق.
  ///
  /// [driverId] معرف السائق — إن تُرك فارغاً، يُستخدم معرف المستخدم الحالي.
  Future<void> goOnline({String? driverId}) async {
    final uid = driverId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ [PresenceService] لا يوجد مستخدم مسجّل');
      throw Exception('User not authenticated');
    }

    // إلغاء أي جلسة سابقة أولاً
    await _cleanup();

    _currentDriverId = uid;
    debugPrint('🟢 [PresenceService] تفعيل التواجد للسائق: $uid');

    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConstants.realtimeDatabaseUrl,
      );

      _presenceRef = rtdb.ref('status/$uid');
      final locationRef = rtdb.ref('drivers_locations/$uid');

      // ── الخطوة 1: كتابة حالة التواجد فوراً في RTDB ──
      await _presenceRef!.set(true);

      // ── الخطوة 2: تسجيل أمر الحذف عند انقطاع الاتصال (onDisconnect) ──
      _presenceRef!.onDisconnect().remove().catchError((e) {
        debugPrint('⚠️ [PresenceService] onDisconnect status error: $e');
      });
      locationRef.onDisconnect().remove().catchError((e) {
        debugPrint('⚠️ [PresenceService] onDisconnect location error: $e');
      });
      debugPrint('✅ [PresenceService] تم تسجيل onDisconnect و RTDB بنجاح');

      // ── الخطوة 3: تحديث Firestore إلى Online ──
      await _setFirestoreOnlineStatus(uid, true);

      _isActive = true;
    } catch (e) {
      debugPrint('❌ [PresenceService] فشل إعداد التواجد (RTDB/Firestore): $e');
      _isActive = false;

      // Rollback أمان: التأكد من إبقاء Firestore على Offline عند فشل RTDB
      try {
        await _setFirestoreOnlineStatus(uid, false);
      } catch (_) {}

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // 2. الإيقاف الطوعي (Offline بإرادة السائق)
  // ─────────────────────────────────────────────────────────────────

  /// يُوقف وضع الإتاحة ويُنظِّف العقدة.
  ///
  /// يُلغي قاعدة onDisconnect أولاً لمنع تكرار التشغيل غير المقصود،
  /// ثم يحذف العقدة ويُحدِّث Firestore.
  Future<void> goOffline() async {
    try {
      final uid = _currentDriverId ?? FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        debugPrint('⚠️ [PresenceService] لا يوجد مستخدم مسجّل لإيقافه');
        return;
      }

      debugPrint('🔴 [PresenceService] إيقاف التواجد للسائق: $uid');

      // 1. تحديث Firestore دائماً وأولاً لضمان سرعة الاستجابة
      try {
        await _setFirestoreOnlineStatus(uid, false).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ [PresenceService] فشل تحديث Firestore إلى Offline: $e');
      }

      // 2. تنظيف RTDB و onDisconnect
      try {
        final rtdb = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: AppConstants.realtimeDatabaseUrl,
        );
        final statusRef = _presenceRef ?? rtdb.ref('status/$uid');
        final locationRef = rtdb.ref('drivers_locations/$uid');

        await Future.wait([
          statusRef.onDisconnect().cancel().catchError((_) {}),
          statusRef.remove().catchError((_) {}),
          locationRef.onDisconnect().cancel().catchError((_) {}),
          locationRef.remove().catchError((_) {}),
        ]).timeout(const Duration(seconds: 10));
        debugPrint('🗑️ [PresenceService] تم تنظيف عقد RTDB وإلغاء onDisconnect');
      } catch (e) {
        debugPrint('⚠️ [PresenceService] تحذير في تنظيف RTDB عند goOffline: $e');
      }

      await _cleanup();
    } catch (e) {
      debugPrint('❌ [PresenceService] خطأ في goOffline: $e');
      await _cleanup();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. تنظيف الموارد الداخلية
  // ─────────────────────────────────────────────────────────────────

  Future<void> _cleanup() async {
    _presenceRef = null;
    _currentDriverId = null;
    _isActive = false;
  }

  // ─────────────────────────────────────────────────────────────────
  // 4. تحديث حالة isOnline في Firestore
  // ─────────────────────────────────────────────────────────────────

  /// يُحدِّث حقل [isOnline] في Firestore.
  ///
  /// يبحث أولاً في مجموعة [users] (المستخدمة في هذا المشروع).
  Future<void> _setFirestoreOnlineStatus(String uid, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '${isOnline ? "✅" : "🔴"} [PresenceService] Firestore: isOnline = $isOnline للسائق $uid',
      );
    } catch (e) {
      debugPrint('❌ [PresenceService] فشل تحديث Firestore: $e');
      // لا نُعيد الخطأ — تحديث RTDB أهم للـ Presence System
    }
  }
}

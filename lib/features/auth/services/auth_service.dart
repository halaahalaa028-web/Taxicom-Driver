/// خدمة المصادقة
/// 
/// توفر وظائف المصادقة عبر Firebase Phone Auth و OTP
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/driver_presence_service.dart';
import '../../../core/services/gps_monitor_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../profile/services/user_service.dart';

/// فئة خدمة المصادقة
class AuthService {
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  AuthService._();
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  /// الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;
  
  /// بث حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// تحويل رقم الهاتف إلى email وهمي (موجود للتوافق المؤقت إن لزم الأمر)
  String getEmailFromPhone(String phone) {
    String cleanPhone = phone.replaceAll('+', '').replaceAll(' ', '');
    return '$cleanPhone@taxicom.app';
  }

  /// استدعاء دوال Cloud Functions مع دعم النمط الاحتياطي المباشر (Direct HTTPS Fallback)
  Future<Map<String, dynamic>> _callCloudFunction(String name, Map<String, dynamic> data) async {
    // 1. المحاولة الأولى: عبر حزمة cloud_functions الرسمية
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      final result = await callable.call(data);
      if (result.data is Map) {
        return Map<String, dynamic>.from(result.data as Map);
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService-Driver] FirebaseFunctions SDK call to $name error: $e. Trying HTTP fallback...');
    }

    // 2. المحاولة الثانية: استدعاء مباشر عبر HTTPS REST API (Fallback)
    try {
      final url = Uri.parse('https://us-central1-taxicom-4c281.cloudfunctions.net/$name');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': data}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('result')) {
          return Map<String, dynamic>.from(decoded['result'] as Map);
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } else {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('error')) {
            final errorMap = decoded['error'];
            if (errorMap is Map && errorMap.containsKey('message')) {
              throw Exception(errorMap['message'].toString());
            }
          }
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
        }
      }
      debugPrint('❌ [AuthService-Driver] HTTP fallback failed ($name) status: ${response.statusCode}, body: ${response.body}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('تعذر الاتصال')) {
        rethrow;
      }
      debugPrint('❌ [AuthService-Driver] HTTP fallback exception ($name): $e');
    }

    throw Exception('تعذر الاتصال بخدمة التحقق السحابية. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
  }

  /// إرسال رمز التحقق الذكي عبر WhatsApp / SMS (Cloud Functions)
  Future<Map<String, dynamic>> sendCustomOtp({
    required String phoneNumber,
    String channel = 'auto',
  }) async {
    try {
      return await _callCloudFunction('sendCustomOtp', {
        'phoneNumber': phoneNumber,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('❌ [AuthService-Driver] sendCustomOtp error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// التحقق من رمز OTP المدخل وتسجيل الدخول بواسطة Firebase Custom Token
  Future<User?> verifyCustomOtpAndSignIn({
    required String phoneNumber,
    required String otpCode,
    String? verificationId,
  }) async {
    try {
      final data = await _callCloudFunction('verifyCustomOtp', {
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
        'verificationId': verificationId,
      });

      final customToken = data['customToken'] as String?;

      if (customToken == null || customToken.isEmpty) {
        throw Exception('فشل إنشاء رمز الدخول المخصص');
      }

      // تسجيل الدخول الرسمي إلى Firebase Auth باستخدام Custom Token
      final userCredential = await _auth.signInWithCustomToken(customToken);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService-Driver] FirebaseAuthException: ${e.code}');
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ [AuthService-Driver] verifyCustomOtp error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// إعادة إرسال رمز التحقق عبر قناة محددة (مثل SMS)
  Future<Map<String, dynamic>> resendCustomOtp({
    required String phoneNumber,
    String channel = 'sms',
  }) async {
    try {
      return await _callCloudFunction('resendCustomOtp', {
        'phoneNumber': phoneNumber,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('❌ [AuthService-Driver] resendCustomOtp error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// إرسال رمز التحقق SMS عبر Firebase Phone Auth (النمط الاحتياطي)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        forceResendingToken: resendToken,
      );
    } catch (e) {
      throw Exception('فشل في إرسال رمز التحقق: ${e.toString()}');
    }
  }

  /// تسجيل الدخول أو إكمال الحساب باستخدام PhoneAuthCredential
  Future<User?> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الدخول بالهاتف.');
    }
  }

  /// التحقق من كود الـ OTP المكتوب وتسجيل الدخول بـ Firebase Auth
  Future<User?> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await signInWithPhoneCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      throw Exception('رمز التحقق غير صحيح أو منتهي الصلاحية.');
    }
  }

  /// التحقق من وجود رقم الهاتف مسبقاً في Firestore
  Future<bool> checkPhoneExists(String phone) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('checkPhoneExists');
      final result = await callable.call({'phoneNumber': phone});
      return result.data['exists'] ?? false;
    } catch (e) {
      // البحث في كولكشن المستخدمين مباشرة كإجراء احتياطي
      try {
        final query = await _firestore
            .collection(AppConstants.usersCollection)
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();
        return query.docs.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// التحقق من وجود المستخدم في Firestore عبر uid
  Future<bool> checkUserExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    // 1. إيقاف خدمات السائق الفعالة (التواجد، نظام المراقبة)
    try {
      await DriverPresenceService.instance.goOffline().timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint('⚠️ [AuthService] goOffline timed out'),
      );
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error going offline: $e');
    }

    try {
      await GpsMonitorService.instance.stopMonitoring();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error stopping GPS monitor: $e');
    }

    // 2. مسح التوكن من Firestore مع مهلة تجنباً لتعليق العملية عند ضعف الشبكة
    try {
      await NotificationService.instance.clearFcmToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint('⚠️ [AuthService] FCM token clear timed out'),
      );
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error clearing FCM token: $e');
    }

    // 3. إيقاف مستمع الجلسة
    try {
      await SessionService.instance.stopSessionListener();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error stopping session listener: $e');
    }

    // 4. مسح كاش بيانات المستخدم
    try {
      await UserService.instance.clearCache();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error clearing user cache: $e');
    }

    // 5. تسجيل الخروج من Firebase Auth
    await _auth.signOut();
  }

  /// تحويل رموز أخطاء Firebase إلى رسائل عربية
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد';
      case 'session-expired':
        return 'انتهت جلسة التحقق. يرجى إعادة الإرسال';
      case 'quota-exceeded':
        return 'تم تجاوز حد رسائل التحقق اليومي. حاول لاحقاً';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'requires-recent-login':
        return 'يتطلب هذا الإجراء تسجيل الدخول مجدداً لأسباب أمنية. يرجى تسجيل الخروج والدخول مجدداً ثم المحاولة.';
      default:
        return 'حدث خطأ. يرجى المحاولة مرة أخرى ($code)';
    }
  }

  /// حذف الحساب نهائياً
  Future<void> deleteAccount([String? password]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      // 1. إيقاف خدمات السائق الفعالة ومسح الكاش
      try {
        await DriverPresenceService.instance.goOffline().timeout(
          const Duration(seconds: 2),
          onTimeout: () => debugPrint('⚠️ [AuthService] goOffline timed out'),
        );
      } catch (e) {
        debugPrint('⚠️ [AuthService] Error going offline: $e');
      }

      try {
        await GpsMonitorService.instance.stopMonitoring();
      } catch (e) {
        debugPrint('⚠️ [AuthService] Error stopping GPS monitor: $e');
      }

      try {
        await NotificationService.instance.clearFcmToken().timeout(
          const Duration(seconds: 2),
          onTimeout: () => debugPrint('⚠️ [AuthService] FCM token clear timed out'),
        );
      } catch (e) {
        debugPrint('⚠️ [AuthService] Error clearing FCM token: $e');
      }

      try {
        await SessionService.instance.stopSessionListener();
      } catch (e) {
        debugPrint('⚠️ [AuthService] Error stopping session listener: $e');
      }

      try {
        await UserService.instance.clearCache();
      } catch (e) {
        debugPrint('⚠️ [AuthService] Error clearing user cache: $e');
      }

      // 2. حذف بيانات المستخدم من Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .delete();

      // 3. حذف الحساب من Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      throw Exception('حدث خطأ أثناء حذف الحساب. يرجى المحاولة مرة أخرى.');
    }
  }
}

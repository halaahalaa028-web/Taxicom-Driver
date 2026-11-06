import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// مساعد مركزي لتحويل كافة أخطاء النظام وفايربيس والشبكة إلى رسائل عربية واضحة ومفهومة للسائق
class AppErrorHandler {
  AppErrorHandler._();

  /// رسالة مخصصة وواضحة عند محاولة قبول طلب رحلة ملغي أو غير متاح
  static String getTripAcceptanceErrorMessage(dynamic error) {
    if (error == null) return 'تعذر قبول الطلب، يرجى المحاولة ثانية';

    final errStr = error.toString().toLowerCase();

    // التحقق من حالة إلغاء الراكب أو انتهاء الصلاحية
    if (error is FirebaseException) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        return 'عذراً، هذا الطلب لم يعد متاحاً (قام الراكب بإلغائه أو تم قبوله من سائق آخر)';
      }
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        return 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت والمحاولة ثانية';
      }
    }

    if (errStr.contains('permission-denied') || errStr.contains('permission_denied')) {
      return 'عذراً، هذا الطلب لم يعد متاحاً (قام الراكب بإلغائه أو تم قبوله من سائق آخر)';
    }

    if (errStr.contains('إلغاء') || errStr.contains('ملغي') || errStr.contains('cancelled')) {
      return 'عذراً، قام الراكب بإلغاء هذا الطلب';
    }

    if (errStr.contains('سائق آخر') || errStr.contains('مقبول') || errStr.contains('already accepted')) {
      return 'عذراً، تم قبول هذا الطلب بالفعل من قبل سائق آخر';
    }

    if (errStr.contains('غير موجودة') || errStr.contains('غير موجود') || errStr.contains('not-found')) {
      return 'عذراً، هذا الطلب لم يعد متاحاً في النظام';
    }

    return getFriendlyErrorMessage(error, defaultMessage: 'عذراً، تعذر قبول الطلب في الوقت الحالي');
  }

  /// تحويل أي استثناء عام إلى رسالة عربية سهلة وواضحة خالية من الرموز التقنية والإنجليزية
  static String getFriendlyErrorMessage(dynamic error, {String? defaultMessage}) {
    if (error == null) return defaultMessage ?? 'حدث خطأ، يرجى المحاولة مرة أخرى';

    // 1. أخطاء فايربيس (Firestore / Auth / Functions)
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'عذراً، لا تملك الصلاحية لتنفيذ هذه العملية أو تم تغيير حالة الطلب';
        case 'not-found':
          return 'البيانات المطلوبة غير متوفرة أو تم حذفها';
        case 'unavailable':
        case 'network-request-failed':
        case 'deadline-exceeded':
          return 'تعذر الاتصال بالشبكة، يرجى التحقق من اتصال الإنترنت';
        case 'unauthenticated':
          return 'انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مجدداً';
        case 'already-exists':
          return 'هذه البيانات مسجلة مسبقاً في النظام';
        case 'resource-exhausted':
          return 'تم تجاوز الحد المسموح من الطلبات، يرجى الانتظار قليلاً';
        default:
          if (error.message != null && _containsArabic(error.message!)) {
            return _cleanRawMessage(error.message!);
          }
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'رقم الهاتف أو كلمة المرور غير صحيحة';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب، يرجى مراجعة إدارة التطبيق';
        case 'too-many-requests':
          return 'تم تجاوز عدد المحاولات المسموحة، يرجى الانتظار والمحاولة لاحقاً';
        case 'network-request-failed':
          return 'تحقق من اتصالك بالإنترنت';
        default:
          if (error.message != null && _containsArabic(error.message!)) {
            return _cleanRawMessage(error.message!);
          }
      }
    }

    // 2. أخطاء انقطاع الاتصال والشبكة
    if (error is SocketException || error is TimeoutException) {
      return 'تعذر الاتصال بالإنترنت، يرجى التأكد من تفعيل الشبكة';
    }

    if (error is PlatformException) {
      if (error.message != null && _containsArabic(error.message!)) {
        return _cleanRawMessage(error.message!);
      }
      return 'تعذر إتمام العملية على هذا الجهاز (${error.code})';
    }

    // 3. نصوص الاستثناء العادية
    final rawText = error.toString();
    final cleanText = _cleanRawMessage(rawText);

    // إذا كانت الرسالة تحتوي على نص عربي مفيد وواضح، نعرضه للمستخدم
    if (_containsArabic(cleanText) && !cleanText.contains('[cloud_firestore') && !cleanText.contains('firebase')) {
      return cleanText;
    }

    return defaultMessage ?? 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }

  /// تنظيف النصوص التقنية مثل "Exception: " أو الأقواس والرموز الإنجليزية
  static String _cleanRawMessage(String raw) {
    var text = raw
        .replaceAll(RegExp(r'^(Exception|FirebaseException|PlatformException):\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[[a-zA-Z0-9_\-\/]+\]'), '')
        .trim();
    return text;
  }

  /// فحص احتواء النص على أحرف عربية
  static bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

/// أداة تنسيق أرقام الهواتف الشاملة لجميع الدول المدعومة في تاكسيكوم
library;

class PhoneFormatter {
  PhoneFormatter._();

  /// تنظيف رقم الهاتف وإزالة المسافات والرموز غير المرغوبة
  static String clean(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// تنسيق رقم الهاتف للعرض الجميل لجميع البلدان
  /// يدعم تلقائياً: مصر (+20)، العراق (+964)، سوريا (+963)، إيران (+98)،
  /// تركيا (+90)، السعودية (+966)، الإمارات (+971)، الأردن (+962)، لبنان (+961)، الكويت (+965)
  static String format(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    String cleaned = clean(phone);

    // إذا كان الرقم بصيغة 00 في البداية نحوله إلى +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    } else if (!cleaned.startsWith('+') && !cleaned.startsWith('0')) {
      // إذا كان بدون + وبدون 0، نتأكد إذا كان يبدأ برمز دولة معروف
      if (cleaned.startsWith('964') ||
          cleaned.startsWith('963') ||
          cleaned.startsWith('966') ||
          cleaned.startsWith('971') ||
          cleaned.startsWith('962') ||
          cleaned.startsWith('961') ||
          cleaned.startsWith('965')) {
        cleaned = '+$cleaned';
      } else if (cleaned.startsWith('20') ||
          cleaned.startsWith('98') ||
          cleaned.startsWith('90')) {
        cleaned = '+$cleaned';
      }
    }

    // 1. مصر: +20 10 1234 5678 (رمز الدولة 2 خانات)
    if (cleaned.startsWith('+20')) {
      final rest = cleaned.substring(3);
      if (rest.length >= 10) {
        return '+20 ${rest.substring(0, 2)} ${rest.substring(2, 6)} ${rest.substring(6)}';
      }
      return '+20 $rest';
    }

    // 2. العراق: +964 770 123 4567 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+964')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 10) {
        return '+964 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
      }
      return '+964 $rest';
    }

    // 3. سوريا: +963 912 345 678 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+963')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 9) {
        return '+963 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
      }
      return '+963 $rest';
    }

    // 4. إيران: +98 912 345 6789 (رمز الدولة 2 خانات)
    if (cleaned.startsWith('+98')) {
      final rest = cleaned.substring(3);
      if (rest.length >= 10) {
        return '+98 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
      }
      return '+98 $rest';
    }

    // 5. تركيا: +90 532 123 4567 (رمز الدولة 2 خانات)
    if (cleaned.startsWith('+90')) {
      final rest = cleaned.substring(3);
      if (rest.length >= 10) {
        return '+90 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
      }
      return '+90 $rest';
    }

    // 6. السعودية: +966 50 123 4567 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+966')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 9) {
        return '+966 ${rest.substring(0, 2)} ${rest.substring(2, 5)} ${rest.substring(5)}';
      }
      return '+966 $rest';
    }

    // 7. الإمارات: +971 50 123 4567 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+971')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 9) {
        return '+971 ${rest.substring(0, 2)} ${rest.substring(2, 5)} ${rest.substring(5)}';
      }
      return '+971 $rest';
    }

    // 8. الأردن: +962 7 9123 4567 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+962')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 9) {
        return '+962 ${rest.substring(0, 1)} ${rest.substring(1, 5)} ${rest.substring(5)}';
      }
      return '+962 $rest';
    }

    // 9. لبنان: +961 70 123 456 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+961')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 8) {
        return '+961 ${rest.substring(0, 2)} ${rest.substring(2, 5)} ${rest.substring(5)}';
      }
      return '+961 $rest';
    }

    // 10. الكويت: +965 9123 4567 (رمز الدولة 3 خانات)
    if (cleaned.startsWith('+965')) {
      final rest = cleaned.substring(4);
      if (rest.length >= 8) {
        return '+965 ${rest.substring(0, 4)} ${rest.substring(4)}';
      }
      return '+965 $rest';
    }

    // أرقام محلية تبدأ بـ 0
    if (cleaned.startsWith('0') && cleaned.length >= 10) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }

    return cleaned;
  }
}

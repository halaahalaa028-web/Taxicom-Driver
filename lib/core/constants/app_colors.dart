/// ألوان تطبيق تاكسيكوم - السائق (Taxicom Driver Brand Color System)
/// 
/// تم استخراجها وتنسيقها بعناية فائقة لتتوافق 100% مع الهوية البصرية الرسمية للأيقونة:
/// - الأزرق الملكي الفاخر (Royal Sapphire Blue) كخلفية وأشرطة علوية وعناصر رئيسية
/// - الأصفر التاكسي والذهبي المعدني (Taxi Yellow & Metallic Gold) للأزرار التفاعلية ومسارات التاكسي وقبول الطلبات
/// - الفضي والكروم المعدني (Platinum & Chrome) للحدود والإطارات والرموز
/// - الأبيض والرمادي الفاتح (Clean Off-White) للخلفيات النظيفة وقراءة مريحة
/// - الكحلي المسود الفاحم (Deep Charcoal Slate) لنصوص واضحة وعالية التباين
library;

import 'package:flutter/material.dart';

/// فئة ألوان التطبيق الرسمية
class AppColors {
  AppColors._(); // منع إنشاء instance

  // ==========================================
  // 1. الألوان الأساسية - الأزرق الملكي الفاخر (Royal Sapphire Blue)
  // ==========================================
  /// اللون الأساسي - أزرق ملكي غني وراقي
  static const Color primary = Color(0xFF0B4EA2);
  
  /// اللون الأساسي الفاتح - أزرق مشرق للتدرجات والإضاءة العلوية
  static const Color primaryLight = Color(0xFF1A73E8);
  
  /// اللون الأساسي الداكن - كحلي ملكي عميق وفاخر
  static const Color primaryDark = Color(0xFF062152);

  // ==========================================
  // 2. الألوان الثانوية والتمييز - الأصفر التاكسي والذهبي المعدني
  // ==========================================
  /// اللون الثانوي / التمييز - أصفر تاكسي مشرق وحيوي
  static const Color secondary = Color(0xFFFFC700);
  
  /// أصفر ذهبي فاتح للتدرجات والوميض
  static const Color secondaryLight = Color(0xFFFFE066);
  
  /// ذهبي معدني كلاسيكي فاخر (مثل إطار الأيقونة وقوس الشعار)
  static const Color goldAccent = Color(0xFFE5B842);
  
  /// ذهبي داكن للظلال والعمق
  static const Color goldDark = Color(0xFFB38318);

  // ==========================================
  // 3. درجات الفضي والكروم المعدني (Chrome & Platinum)
  // ==========================================
  /// فضي بلاتيني فاتح
  static const Color chromeLight = Color(0xFFE1E8F0);
  
  /// فضي رمادي معدني متوسط
  static const Color chromeMedium = Color(0xFF94A3B8);
  
  /// فضي داكن / صلب
  static const Color chromeDark = Color(0xFF475569);

  // ==========================================
  // 4. ألوان الخلفيات والأسطح (Clean Modern Surfaces)
  // ==========================================
  /// لون خلفية التطبيق العامة - رمادي ناصع مائل للأبيض فائق الراحة للعين
  static const Color background = Color(0xFFF8FAFC);
  
  /// لون السطح والبطاقات - أبيض نقي
  static const Color surface = Color(0xFFFFFFFF);
  
  /// لون السطح المتغير - رمادي ناعم جداً لحقول الإدخال والبطاقات الثانوية
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ==========================================
  // 5. ألوان النصوص والخطوط (High-Contrast Typography)
  // ==========================================
  /// لون النص الأساسي - كحلي مسود داكن فائق الوضوح والأناقة
  static const Color textPrimary = Color(0xFF0F172A);
  
  /// لون النص الثانوي - رمادي متناسق ومقروء
  static const Color textSecondary = Color(0xFF64748B);
  
  /// لون النص على الألوان الداكنة (مثل الأزرار والأزرق الملكي) - أبيض ناصع
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// لون النص على الألوان الصفراء والذهبية - داكن لضمان التباين
  static const Color textOnAccent = Color(0xFF0F172A);

  // ==========================================
  // 6. ألوان الحالة وإشارات النظام (System Status Indicators)
  // ==========================================
  /// لون النجاح - أخضر زمردي فاخر
  static const Color success = Color(0xFF10B981);
  
  /// لون الخطأ - أحمر ناعم وواضح
  static const Color error = Color(0xFFEF4444);
  
  /// لون التحذير - برتقالي كهرماني
  static const Color warning = Color(0xFFF59E0B);
  
  /// لون المعلومات - أزرق ملكي
  static const Color info = Color(0xFF0B4EA2);

  // ==========================================
  // 7. ألوان الحدود والتعطيل
  // ==========================================
  /// لون الحدود والفواصل
  static const Color border = Color(0xFFE2E8F0);
  
  /// لون الحقول والأزرار المعطلة
  static const Color disabled = Color(0xFFCBD5E1);
  
  /// لون تعبئة حقول الإدخال
  static const Color inputFill = Color(0xFFF1F5F9);

  /// لون شفاف
  static const Color transparent = Colors.transparent;

  // ==========================================
  // 8. التدرجات اللونية الفاخرة (Luxury Gradients)
  // ==========================================
  /// التدرج الملكي الأزرق (مثل خلفية الأيقونة والبانرات)
  static const LinearGradient royalBlueGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// التدرج الأساسي للأزرار والبطاقات المميزة
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج الذهبي والأصفر التاكسي (للشارات والعناصر المميزة)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [secondaryLight, secondary, goldAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// محرك حساب عمولة المنصة وإدارة سقف المديونية للسائق
///
/// يدير نسبة استقطاع المنصة ديناميكياً من لوحة التحكم وصافي أرباح السائق
/// وحدود المديونية القصوى لكل دولة وحالة الحظر
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'country_service.dart';

/// فئة بيانات حالة مديونية السائق
class DriverDebtStatus {
  /// هل تم تجاوز سقف المديونية الأقصى (محظور من العمل)
  final bool isBlocked;

  /// هل وصل السائق إلى حد التحذير (70% من السقف)
  final bool isWarning;

  /// مقدار المديونية الحالية
  final double currentDebt;

  /// سقف المديونية الأقصى للدولة
  final double maxDebtLimit;

  /// النسبة المئوية للمديونية من السقف (0.0 إلى 1.0+)
  final double debtRatio;

  /// المبلغ المتبقي قبل الوصول للسقف
  final double remainingLimit;

  const DriverDebtStatus({
    required this.isBlocked,
    required this.isWarning,
    required this.currentDebt,
    required this.maxDebtLimit,
    required this.debtRatio,
    required this.remainingLimit,
  });
}

/// خدمة إدارة عمولة المنصة وسقف المديونية
class DriverCommissionService {
  DriverCommissionService._();

  /// الـ Singleton الموحد للخدمة
  static final DriverCommissionService instance = DriverCommissionService._();

  /// نسبة العمولة الافتراضية الاحتياطية (15%) في حال تعذر الاتصال
  static const double defaultCommissionRate = 0.15;

  /// نسبة العمولة الديناميكية الحالية المحفوظة محلياً
  double _dynamicCommissionRate = defaultCommissionRate;

  /// اشتراك الاستماع الحي لإعدادات الفايرستور
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  /// هل تم جلب الإعدادات لأول مرة
  bool _isLoaded = false;

  /// الحصول على نسبة عمولة المنصة الحالية (مثلاً 0.30 أو 0.15)
  double get currentCommissionRate => _dynamicCommissionRate;

  /// الحصول على نسبة صافي أرباح السائق الحالية (مثلاً 0.70 أو 0.85)
  double get currentDriverEarningsRate =>
      (1.0 - _dynamicCommissionRate).clamp(0.0, 1.0);

  /// للتوافقية العكسية مع المراجع السابقة
  double get platformCommissionRate => _dynamicCommissionRate;
  double get driverEarningsRate => currentDriverEarningsRate;
  bool get isLoaded => _isLoaded;

  /// نسبة عتبة التحذير قبل الحظر (70% من السقف الأقصى)
  static const double warningThresholdRatio = 0.70;

  /// سقوف المديونية القصوى الافتراضية لكل دولة حسب العملة المحلية
  static const Map<String, double> defaultMaxDebtLimits = {
    'IQ': 25000.0, // 25,000 دينار عراقي
    'EG': 250.0, // 250 جنيه مصري
    'SY': 60000.0, // 60,000 ليرة سورية
    'IR': 200000.0, // 200,000 تومان إيراني
    'TR': 350.0, // 350 ليرة تركية
    'SA': 80.0, // 80 ريال سعودي
    'AE': 80.0, // 80 درهم إماراتي
    'JO': 15.0, // 15 دينار أردني
    'LB': 1500000.0, // 1,500,000 ليرة لبنانية
    'KW': 8.0, // 8 دينار كويتي
  };

  /// جلب الإعدادات المالية ونسبة العمولة من Firestore
  Future<void> fetchDynamicCommission() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('financial')
          .get();

      if (doc.exists && doc.data() != null) {
        _applyFinancialSettings(doc.data()!);
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('⚠️ [DriverCommissionService] فشل جلب الإعدادات المالية: $e');
    }
  }

  /// بدء الاستماع الحي لتحديثات نسبة العمولة من لوحة التحكم
  void startListening() {
    _settingsSubscription?.cancel();
    _settingsSubscription = FirebaseFirestore.instance
        .collection('settings')
        .doc('financial')
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          _applyFinancialSettings(doc.data()!);
          _isLoaded = true;
        }
      },
      onError: (e) {
        debugPrint('⚠️ [DriverCommissionService] خطأ في استماع الإعدادات المالية: $e');
      },
    );
  }

  /// تطبيق وتطبيع نسبة العمولة من بيانات Firestore
  void _applyFinancialSettings(Map<String, dynamic> data) {
    final raw = (data['commissionRate'] as num?)?.toDouble() ??
        (data['platformCommissionRate'] as num?)?.toDouble() ??
        (defaultCommissionRate * 100);

    // تطبيع النسبة: إذا كانت 30 تصبح 0.30 وإذا كانت 0.30 تبقى 0.30
    final normalizedRate = raw > 1.0 ? raw / 100.0 : raw;
    _dynamicCommissionRate = normalizedRate.clamp(0.0, 1.0);
    debugPrint('📊 [DriverCommissionService] تم تحديث نسبة العمولة ديناميكياً: '
        '${(_dynamicCommissionRate * 100).toStringAsFixed(1)}% (صافي السائق: ${(currentDriverEarningsRate * 100).toStringAsFixed(1)}%)');
  }

  /// حساب عمولة المنصة من إجمالي الأجرة (مع دعم تمرير نسبة خاصة بالرحلة)
  double calculatePlatformCommission(double totalFare, [double? dynamicRate]) {
    if (totalFare <= 0) return 0.0;
    final rate = (dynamicRate != null)
        ? (dynamicRate > 1.0 ? dynamicRate / 100.0 : dynamicRate)
        : _dynamicCommissionRate;
    return totalFare * rate;
  }

  /// حساب صافي أرباح السائق من إجمالي الأجرة (مع دعم تمرير نسبة خاصة بالرحلة)
  double calculateDriverEarnings(double totalFare, [double? dynamicRate]) {
    if (totalFare <= 0) return 0.0;
    final commission = calculatePlatformCommission(totalFare, dynamicRate);
    return math.max(0.0, totalFare - commission);
  }

  /// إيقاف الاستماع للخدمة
  void dispose() {
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
  }

  /// الحصول على سقف المديونية الأقصى للدولة المحددة
  double getMaxDebtLimit([String? countryCode]) {
    final code = countryCode ?? CountryService.instance.selectedCountry.code;
    return defaultMaxDebtLimits[code] ?? 25000.0;
  }

  /// فحص حالة مديونية السائق بشكل تفصيلي
  DriverDebtStatus checkDebtStatus({
    required double currentDebt,
    String? countryCode,
  }) {
    final maxLimit = getMaxDebtLimit(countryCode);
    final debt = math.max(0.0, currentDebt);
    final ratio = maxLimit > 0 ? (debt / maxLimit) : 0.0;
    final isBlocked = debt >= maxLimit;
    final isWarning = !isBlocked && ratio >= warningThresholdRatio;
    final remaining = math.max(0.0, maxLimit - debt);

    return DriverDebtStatus(
      isBlocked: isBlocked,
      isWarning: isWarning,
      currentDebt: debt,
      maxDebtLimit: maxLimit,
      debtRatio: ratio.clamp(0.0, 1.5),
      remainingLimit: remaining,
    );
  }

  /// هل السائق محظور بسبب تجاوز سقف المديونية
  bool isDebtExceeded(double currentDebt, [String? countryCode]) {
    final maxLimit = getMaxDebtLimit(countryCode);
    return currentDebt >= maxLimit;
  }

  /// هل السائق في نطاق التحذير (اقترب من السقف)
  bool isWarningThresholdReached(double currentDebt, [String? countryCode]) {
    final maxLimit = getMaxDebtLimit(countryCode);
    final warningLimit = maxLimit * warningThresholdRatio;
    return currentDebt >= warningLimit && currentDebt < maxLimit;
  }

  /// حساب النسبة المئوية للمديونية (0 إلى 100%)
  int getDebtPercentageInt(double currentDebt, [String? countryCode]) {
    final maxLimit = getMaxDebtLimit(countryCode);
    if (maxLimit <= 0) return 0;
    final ratio = (currentDebt / maxLimit) * 100;
    return ratio.clamp(0, 100).toInt();
  }
}

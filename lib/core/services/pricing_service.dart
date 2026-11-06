/// خدمة جلب الأسعار الديناميكية الموحدة لتطبيق السائق
///
/// تجلب وتدير أسعار الرحلات والعملات لجميع البلدان المدعومة
/// متوافقة تماماً مع لوحة التحكم وتحدد الأسعار ديناميكياً بحسب دولة السائق
library;

import 'dart:math' as math;
import '../models/country_config.dart';
import 'country_service.dart';

/// خدمة الأسعار الديناميكية — Singleton
class PricingService {
  PricingService._();
  static final PricingService _instance = PricingService._();
  static PricingService get instance => _instance;

  // ─── Getters ديناميكية متصلة بدولة السائق الحالية ─────────────────────────
  CountryConfig get currentCountry => CountryService.instance.selectedCountry;

  double get baseFare => currentCountry.baseFare;
  double get pricePerKm => currentCountry.pricePerKm;
  double get minimumFare => currentCountry.minimumFare;
  double get roundingStep => currentCountry.roundingStep;
  String get currency => currentCountry.currencyAr;
  String get currencyEn => currentCountry.currencyEn;
  String get currencyCode => currentCountry.currencyCode;
  bool get isLoaded => CountryService.instance.isLoaded;

  /// جلب الأسعار من Firestore عبر CountryService
  Future<void> fetchPricing() async {
    await CountryService.instance.fetchCountries();
  }

  /// الاستماع لتحديثات الأسعار الحية
  void startListening() {
    CountryService.instance.startListening();
  }

  /// حساب تكلفة وقت الانتظار بناءً على سعر الكيلومتر للدولة
  double getWaitTimeCost(String waitTime) {
    final kmPrice = pricePerKm;
    switch (waitTime) {
      case '0-5 دقائق':
        return kmPrice * 1.0;
      case '5-10 دقائق':
        return kmPrice * 2.0;
      case '10-20 دقيقة':
        return kmPrice * 4.0;
      case '20-30 دقيقة':
        return kmPrice * 6.0;
      case '30-45 دقيقة':
        return kmPrice * 9.0;
      case '45-60 دقيقة':
        return kmPrice * 12.0;
      default:
        return 0.0;
    }
  }

  /// حساب السعر النهائي للرحلة مع تطبيق خطوة التقريب المالي الخاصة بالدولة
  double calculatePrice(
    double distanceKm, {
    String? waitTime,
    bool isRoundTrip = false,
  }) {
    double raw = baseFare + (distanceKm * pricePerKm);

    if (isRoundTrip) {
      raw *= 1.5;
    }

    if (waitTime != null) {
      raw += getWaitTimeCost(waitTime);
    }

    final effective = math.max(raw, minimumFare);
    final step = roundingStep;

    if (step >= 1) {
      return (effective / step).round() * step;
    } else if (step > 0) {
      final factor = (1 / step).round();
      return (effective * factor).round() / factor;
    }
    return effective;
  }

  /// إيقاف الاستماع
  void dispose() {
    // CountryService manages its own subscription
  }
}

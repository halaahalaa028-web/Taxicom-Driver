/// مساعد حسابات وتنسيق أسعار ومسافات الرحلات لتطبيق السائق
/// 
/// يوفر دوال مركزية لحساب الأسعار مع قواعد التقريب المالي لكل دولة
/// وتنسيق العملات الديناميكية والمسافات والوقت
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/pricing_service.dart';
import '../services/country_service.dart';

/// فئة المساعد المركزي لحساب وتنسيق الرحلات
class TripCalculationHelper {
  TripCalculationHelper._();

  /// حساب المسافة بين نقطتين بالكيلومتر بصيغة Haversine
  static double calculateDistanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // كم
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLng = (lng2 - lng1) * (math.pi / 180);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// الحصول على المسافة المحددة (Capped Distance) بناءً على صيغة Haversine
  static double getCappedDistance({
    required double googleDistance,
    required LatLng pickup,
    required LatLng destination,
    LatLng? secondDestination,
  }) {
    double straightDist = calculateDistanceBetween(
      pickup.latitude,
      pickup.longitude,
      destination.latitude,
      destination.longitude,
    );
    if (secondDestination != null) {
      straightDist += calculateDistanceBetween(
        destination.latitude,
        destination.longitude,
        secondDestination.latitude,
        secondDestination.longitude,
      );
    }
    final double capLimit = math.max(straightDist * 1.5, straightDist + 2.0);
    if (googleDistance > capLimit) {
      debugPrint('⚠️ [Fare Cap Warning] Google Distance ($googleDistance km) exceeded cap ($capLimit km). Straight: $straightDist km.');
      return capLimit;
    }
    return googleDistance;
  }

  /// تنسيق السعر مع العملة المناسبة
  /// 
  /// إذا تم تمرير [currency] (مثلاً من كائن الرحلة `trip.currency`)، يتم استخدامه
  /// وإلا يتم استنتاج عملة الدولة الحالية من [countryCode] أو [PricingService]
  static String formatPrice(
    double price, {
    String? currency,
    String? countryCode,
    bool includeCurrency = true,
  }) {
    String effectiveCurrency = '';
    if (includeCurrency) {
      if (currency != null && currency.isNotEmpty) {
        effectiveCurrency = currency;
      } else if (countryCode != null && countryCode.isNotEmpty) {
        effectiveCurrency = CountryService.instance.getCountryByCode(countryCode).currencyAr;
      } else {
        effectiveCurrency = PricingService.instance.currency;
      }
    }

    final rounded = price.round();
    final isInt = (price - rounded).abs() < 0.001;
    String formattedNum;
    if (isInt) {
      formattedNum = _formatWithSeparators(rounded.toString());
    } else {
      final parts = price.toStringAsFixed(2).split('.');
      formattedNum = '${_formatWithSeparators(parts[0])}.${parts[1]}';
    }

    if (!includeCurrency || effectiveCurrency.isEmpty) {
      return formattedNum;
    }

    return '$formattedNum $effectiveCurrency';
  }

  /// تقريب السعر وفقاً للخطوة المحددة لكل دولة
  /// 
  /// خطوة التقريب:
  /// - مصر (EG): 1
  /// - العراق (IQ): 250
  /// - سوريا (SY): 500
  /// - إيران (IR): 1000
  static double roundPrice(double price, {double? roundingStep, String? countryCode}) {
    double step = roundingStep ?? 
        (countryCode != null 
            ? CountryService.instance.getCountryByCode(countryCode).roundingStep 
            : PricingService.instance.roundingStep);

    if (step <= 0) return price;

    if (step >= 1) {
      return ((price / step).round() * step).toDouble();
    } else {
      final factor = (1 / step).round();
      return ((price * factor).round() / factor).toDouble();
    }
  }

  /// حساب تكلفة الانتظار بناءً على سعر الكيلومتر للدولة
  static double getWaitTimeCost(String waitTime, {double? pricePerKm}) {
    final kmPrice = pricePerKm ?? PricingService.instance.pricePerKm;
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

  /// حساب السعر الكامل للرحلة بناءً على دولة محددة أو الدولة النشطة
  static double calculatePrice(
    double distanceKm, {
    String? waitTime,
    bool isRoundTrip = false,
    String? countryCode,
  }) {
    final country = countryCode != null 
        ? CountryService.instance.getCountryByCode(countryCode)
        : PricingService.instance.currentCountry;

    double raw = country.baseFare + (distanceKm * country.pricePerKm);

    if (isRoundTrip) {
      raw *= 1.5;
    }

    if (waitTime != null) {
      raw += getWaitTimeCost(waitTime, pricePerKm: country.pricePerKm);
    }

    final effective = math.max(raw, country.minimumFare);
    return roundPrice(effective, roundingStep: country.roundingStep);
  }

  /// تنسيق المسافة بالكيلومتر أو المتر
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} م';
    }
    return '${distanceKm.toStringAsFixed(1)} كم';
  }

  /// تنسيق الوقت بالعربية
  static String formatDuration(int minutes) {
    if (minutes <= 1) return 'دقيقة واحدة';
    if (minutes == 2) return 'دقيقتان';
    if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
    if (minutes < 60) return '$minutes دقيقة';

    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;

    String hoursText = hours == 1 ? 'ساعة' : (hours == 2 ? 'ساعتان' : '$hours ساعات');
    if (remainingMinutes == 0) return hoursText;
    
    String minText = remainingMinutes == 1 
        ? 'دقيقة واحدة' 
        : (remainingMinutes == 2 
            ? 'دقيقتان' 
            : (remainingMinutes <= 10 ? '$remainingMinutes دقائق' : '$remainingMinutes دقيقة'));

    return '$hoursText و $minText';
  }

  static String _formatWithSeparators(String value) {
    String result = '';
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = ',$result';
      }
      result = value[i] + result;
      count++;
    }
    return result;
  }
}

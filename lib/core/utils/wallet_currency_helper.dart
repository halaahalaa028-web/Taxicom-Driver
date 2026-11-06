import '../services/country_service.dart';

/// مساعد إدارة مبالغ وقواعد العملات وسداد المديونية للمحفظة حسب الدولة
class WalletCurrencyHelper {
  WalletCurrencyHelper._();

  /// حل وتحديد كود الدولة بدقة من الكود أو العملة أو الدولة المحددة
  static String _resolveCountryCode(String? countryCode, String? currency) {
    if (countryCode != null && countryCode.isNotEmpty) {
      return countryCode.toUpperCase();
    }
    if (currency != null && currency.isNotEmpty) {
      final cur = currency.trim().toUpperCase();
      if (cur == 'ج.م' || cur == 'EGP') return 'EG';
      if (cur == 'د.ع' || cur == 'IQD') return 'IQ';
      if (cur == 'ر.س' || cur == 'SAR') return 'SA';
      if (cur == 'د.إ' || cur == 'AED') return 'AE';
      if (cur == 'د.ك' || cur == 'KWD') return 'KW';
      if (cur == 'د.أ' || cur == 'JOD') return 'JO';
      if (cur == 'TL' || cur == 'TRY') return 'TR';
      if (cur == 'ل.س' || cur == 'SYP') return 'SY';
      if (cur == 'ل.ل' || cur == 'LBP') return 'LB';
      if (cur == 'تومان' || cur == 'IRT') return 'IR';
    }
    return CountryService.instance.selectedCountry.code.toUpperCase();
  }

  /// جلب المبالغ السريعة المقترحة للسداد/الشحن حسب الدولة والعملة
  static List<double> getQuickAmounts([String? countryCode, String? currency]) {
    final code = _resolveCountryCode(countryCode, currency);
    switch (code) {
      case 'EG':
        return [50.0, 100.0, 200.0, 500.0];
      case 'SA':
      case 'AE':
        return [20.0, 50.0, 100.0, 200.0];
      case 'KW':
        return [2.0, 5.0, 10.0, 20.0];
      case 'JO':
        return [5.0, 10.0, 20.0, 50.0];
      case 'TR':
        return [100.0, 250.0, 500.0, 1000.0];
      case 'SY':
        return [25000.0, 50000.0, 100000.0, 250000.0];
      case 'LB':
        return [500000.0, 1000000.0, 2500000.0, 5000000.0];
      case 'IR':
        return [100000.0, 250000.0, 500000.0, 1000000.0];
      case 'IQ':
      default:
        return [5000.0, 10000.0, 25000.0, 50000.0];
    }
  }

  /// جلب أدنى حد مسموح للشحن / السداد عبر Stripe
  static double getMinAmount([String? countryCode, String? currency]) {
    final code = _resolveCountryCode(countryCode, currency);
    switch (code) {
      case 'EG':
        return 20.0;
      case 'SA':
      case 'AE':
        return 10.0;
      case 'KW':
        return 1.0;
      case 'JO':
        return 2.0;
      case 'TR':
        return 50.0;
      case 'SY':
        return 10000.0;
      case 'LB':
        return 100000.0;
      case 'IR':
        return 50000.0;
      case 'IQ':
      default:
        return 1000.0;
    }
  }

  /// هل تتطلب هذه العملة تحويلاً للدولار الأمريكي في Stripe (مثل الدينار العراقي)؟
  static bool requiresUsdConversion(String currency) {
    final cur = currency.trim().toLowerCase();
    return cur == 'د.ع' || cur == 'iqd' || cur == 'ل.س' || cur == 'syp' || cur == 'ل.ل' || cur == 'lbp' || cur == 'تومان' || cur == 'irt';
  }
}

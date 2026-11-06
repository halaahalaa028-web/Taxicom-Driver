/// نموذج إعدادات وتكوين الدولة في تطبيق سائق تاكسيكوم
///
/// يدعم جميع الدول الـ 10 المعرّفة في النظام مع التسعير والعملات ومفاتيح الاتصال
library;

class CountryConfig {
  final String code; // كود الدولة مثل EG, IQ, SY...
  final String nameAr; // اسم الدولة بالعربية
  final String nameEn; // اسم الدولة بالإنجليزية
  final String dialCode; // مفتاح الاتصال الدولي مثل +20, +964...
  final String flag; // إيموجي علم الدولة
  final String currencyAr; // رمز العملة بالعربية
  final String currencyEn; // رمز العملة بالإنجليزية
  final String currencyCode; // كود العملة القياسي
  final bool isEnabled; // هل الدولة مفعلة
  final bool isDefault; // هل هي الدولة الافتراضية
  final double baseFare; // أجرة البداية
  final double pricePerKm; // سعر الكيلومتر
  final double minimumFare; // الحد الأدنى للأجرة
  final double roundingStep; // خطوة تقريب السعر
  final int minPhoneLength; // أدنى طول لرقم الهاتف بدون المفتاح
  final int maxPhoneLength; // أقصى طول لرقم الهاتف بدون المفتاح
  final String phonePlaceholder; // نص توضيحي للرقم

  const CountryConfig({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.dialCode,
    required this.flag,
    required this.currencyAr,
    required this.currencyEn,
    required this.currencyCode,
    required this.isEnabled,
    this.isDefault = false,
    required this.baseFare,
    required this.pricePerKm,
    required this.minimumFare,
    required this.roundingStep,
    this.minPhoneLength = 9,
    this.maxPhoneLength = 11,
    this.phonePlaceholder = '10X XXX XXXX',
  });

  /// إنشاء نسخة معدلة
  CountryConfig copyWith({
    String? code,
    String? nameAr,
    String? nameEn,
    String? dialCode,
    String? flag,
    String? currencyAr,
    String? currencyEn,
    String? currencyCode,
    bool? isEnabled,
    bool? isDefault,
    double? baseFare,
    double? pricePerKm,
    double? minimumFare,
    double? roundingStep,
    int? minPhoneLength,
    int? maxPhoneLength,
    String? phonePlaceholder,
  }) {
    return CountryConfig(
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      dialCode: dialCode ?? this.dialCode,
      flag: flag ?? this.flag,
      currencyAr: currencyAr ?? this.currencyAr,
      currencyEn: currencyEn ?? this.currencyEn,
      currencyCode: currencyCode ?? this.currencyCode,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
      baseFare: baseFare ?? this.baseFare,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      minimumFare: minimumFare ?? this.minimumFare,
      roundingStep: roundingStep ?? this.roundingStep,
      minPhoneLength: minPhoneLength ?? this.minPhoneLength,
      maxPhoneLength: maxPhoneLength ?? this.maxPhoneLength,
      phonePlaceholder: phonePlaceholder ?? this.phonePlaceholder,
    );
  }

  static bool _parseBool(dynamic val, bool fallback) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    if (val is num) return val != 0;
    return fallback;
  }

  /// تحويل من خريطة بيانات Firestore
  factory CountryConfig.fromMap(String code, Map<String, dynamic> map, [CountryConfig? fallback]) {
    final base = fallback ?? defaultCountries[code] ?? defaultCountries['EG']!;
    final isEnabledValue = map.containsKey('isEnabled')
        ? _parseBool(map['isEnabled'], base.isEnabled)
        : base.isEnabled;
    final isDefaultValue = map.containsKey('isDefault')
        ? _parseBool(map['isDefault'], base.isDefault)
        : base.isDefault;

    return CountryConfig(
      code: code,
      nameAr: map['nameAr'] as String? ?? base.nameAr,
      nameEn: map['nameEn'] as String? ?? base.nameEn,
      dialCode: map['dialCode'] as String? ?? base.dialCode,
      flag: map['flag'] as String? ?? base.flag,
      currencyAr: map['currencyAr'] as String? ?? base.currencyAr,
      currencyEn: map['currencyEn'] as String? ?? base.currencyEn,
      currencyCode: map['currencyCode'] as String? ?? base.currencyCode,
      isEnabled: isEnabledValue,
      isDefault: isDefaultValue,
      baseFare: (map['baseFare'] as num?)?.toDouble() ?? base.baseFare,
      pricePerKm: (map['pricePerKm'] as num?)?.toDouble() ?? base.pricePerKm,
      minimumFare: (map['minimumFare'] as num?)?.toDouble() ?? base.minimumFare,
      roundingStep: (map['roundingStep'] as num?)?.toDouble() ?? base.roundingStep,
      minPhoneLength: (map['minPhoneLength'] as num?)?.toInt() ?? base.minPhoneLength,
      maxPhoneLength: (map['maxPhoneLength'] as num?)?.toInt() ?? base.maxPhoneLength,
      phonePlaceholder: map['phonePlaceholder'] as String? ?? base.phonePlaceholder,
    );
  }

  /// تحويل إلى خريطة بيانات Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'dialCode': dialCode,
      'flag': flag,
      'currencyAr': currencyAr,
      'currencyEn': currencyEn,
      'currencyCode': currencyCode,
      'isEnabled': isEnabled,
      'isDefault': isDefault,
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'minimumFare': minimumFare,
      'roundingStep': roundingStep,
      'minPhoneLength': minPhoneLength,
      'maxPhoneLength': maxPhoneLength,
      'phonePlaceholder': phonePlaceholder,
    };
  }

  /// الحصول على الاسم حسب كود اللغة
  String getName(String languageCode) {
    if (languageCode == 'en') return nameEn;
    return nameAr;
  }
}

/// ترتيب عرض البلدان الافتراضي
const List<String> countriesOrder = [
  'EG',
  'IQ',
  'SY',
  'IR',
  'TR',
  'SA',
  'AE',
  'JO',
  'LB',
  'KW',
];

/// البلدان العشرة المدعومة في نظام Taxicom بافتراضياتها
const Map<String, CountryConfig> defaultCountries = {
  'EG': CountryConfig(
    code: 'EG',
    nameAr: 'مصر',
    nameEn: 'Egypt',
    dialCode: '+20',
    flag: '🇪🇬',
    currencyAr: 'ج.م',
    currencyEn: 'EGP',
    currencyCode: 'EGP',
    isEnabled: true,
    isDefault: true,
    baseFare: 15.0,
    pricePerKm: 4.0,
    minimumFare: 20.0,
    roundingStep: 1.0,
    minPhoneLength: 10,
    maxPhoneLength: 11,
    phonePlaceholder: '10X XXX XXXX',
  ),
  'IQ': CountryConfig(
    code: 'IQ',
    nameAr: 'العراق',
    nameEn: 'Iraq',
    dialCode: '+964',
    flag: '🇮🇶',
    currencyAr: 'د.ع',
    currencyEn: 'IQD',
    currencyCode: 'IQD',
    isEnabled: true,
    isDefault: false,
    baseFare: 1000.0,
    pricePerKm: 500.0,
    minimumFare: 1500.0,
    roundingStep: 250.0,
    minPhoneLength: 10,
    maxPhoneLength: 11,
    phonePlaceholder: '7XX XXX XXXX',
  ),
  'SY': CountryConfig(
    code: 'SY',
    nameAr: 'سوريا',
    nameEn: 'Syria',
    dialCode: '+963',
    flag: '🇸🇾',
    currencyAr: 'ل.س',
    currencyEn: 'SYP',
    currencyCode: 'SYP',
    isEnabled: false,
    isDefault: false,
    baseFare: 6000.0,
    pricePerKm: 3000.0,
    minimumFare: 10000.0,
    roundingStep: 500.0,
    minPhoneLength: 9,
    maxPhoneLength: 10,
    phonePlaceholder: '9X XXX XXXX',
  ),
  'IR': CountryConfig(
    code: 'IR',
    nameAr: 'إيران',
    nameEn: 'Iran',
    dialCode: '+98',
    flag: '🇮🇷',
    currencyAr: 'تومان',
    currencyEn: 'IRT',
    currencyCode: 'IRT',
    isEnabled: false,
    isDefault: false,
    baseFare: 25000.0,
    pricePerKm: 8000.0,
    minimumFare: 35000.0,
    roundingStep: 1000.0,
    minPhoneLength: 10,
    maxPhoneLength: 11,
    phonePlaceholder: '9XX XXX XXXX',
  ),
  'TR': CountryConfig(
    code: 'TR',
    nameAr: 'تركيا',
    nameEn: 'Turkey',
    dialCode: '+90',
    flag: '🇹🇷',
    currencyAr: 'TL',
    currencyEn: 'TRY',
    currencyCode: 'TRY',
    isEnabled: false,
    isDefault: false,
    baseFare: 35.0,
    pricePerKm: 15.0,
    minimumFare: 60.0,
    roundingStep: 1.0,
    minPhoneLength: 10,
    maxPhoneLength: 10,
    phonePlaceholder: '5XX XXX XXXX',
  ),
  'SA': CountryConfig(
    code: 'SA',
    nameAr: 'المملكة العربية السعودية',
    nameEn: 'Saudi Arabia',
    dialCode: '+966',
    flag: '🇸🇦',
    currencyAr: 'ر.س',
    currencyEn: 'SAR',
    currencyCode: 'SAR',
    isEnabled: false,
    isDefault: false,
    baseFare: 8.0,
    pricePerKm: 2.5,
    minimumFare: 12.0,
    roundingStep: 0.5,
    minPhoneLength: 9,
    maxPhoneLength: 9,
    phonePlaceholder: '5X XXX XXXX',
  ),
  'AE': CountryConfig(
    code: 'AE',
    nameAr: 'الإمارات العربية المتحدة',
    nameEn: 'United Arab Emirates',
    dialCode: '+971',
    flag: '🇦🇪',
    currencyAr: 'د.إ',
    currencyEn: 'AED',
    currencyCode: 'AED',
    isEnabled: false,
    isDefault: false,
    baseFare: 10.0,
    pricePerKm: 2.8,
    minimumFare: 15.0,
    roundingStep: 0.5,
    minPhoneLength: 9,
    maxPhoneLength: 9,
    phonePlaceholder: '5X XXX XXXX',
  ),
  'JO': CountryConfig(
    code: 'JO',
    nameAr: 'الأردن',
    nameEn: 'Jordan',
    dialCode: '+962',
    flag: '🇯🇴',
    currencyAr: 'د.أ',
    currencyEn: 'JOD',
    currencyCode: 'JOD',
    isEnabled: false,
    isDefault: false,
    baseFare: 0.8,
    pricePerKm: 0.4,
    minimumFare: 1.5,
    roundingStep: 0.1,
    minPhoneLength: 9,
    maxPhoneLength: 9,
    phonePlaceholder: '7X XXX XXXX',
  ),
  'LB': CountryConfig(
    code: 'LB',
    nameAr: 'لبنان',
    nameEn: 'Lebanon',
    dialCode: '+961',
    flag: '🇱🇧',
    currencyAr: 'ل.ل',
    currencyEn: 'LBP',
    currencyCode: 'LBP',
    isEnabled: false,
    isDefault: false,
    baseFare: 150000.0,
    pricePerKm: 50000.0,
    minimumFare: 200000.0,
    roundingStep: 10000.0,
    minPhoneLength: 7,
    maxPhoneLength: 8,
    phonePlaceholder: '7X XXX XXX',
  ),
  'KW': CountryConfig(
    code: 'KW',
    nameAr: 'الكويت',
    nameEn: 'Kuwait',
    dialCode: '+965',
    flag: '🇰🇼',
    currencyAr: 'د.ك',
    currencyEn: 'KWD',
    currencyCode: 'KWD',
    isEnabled: false,
    isDefault: false,
    baseFare: 0.6,
    pricePerKm: 0.3,
    minimumFare: 1.25,
    roundingStep: 0.05,
    minPhoneLength: 8,
    maxPhoneLength: 8,
    phonePlaceholder: '9XX XXXXX',
  ),
};

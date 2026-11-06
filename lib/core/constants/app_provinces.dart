/// قائمة المحافظات المعتمدة للدول الأربع المدعومة في تاكسيكوم
///
/// مصر (27 محافظة)، العراق (19 محافظة)، سوريا (14 محافظة)، إيران (31 محافظة)
library;

class ProvinceItem {
  final String id;
  final String nameAr;
  final String nameEn;

  const ProvinceItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  String getName(String langCode) => langCode == 'en' ? nameEn : nameAr;
}

class AppProvinces {
  AppProvinces._();

  /// الدول الأربع المدعومة رسمياً للتسجيل
  static const Set<String> supportedCountryCodes = {'EG', 'IQ', 'SY', 'IR'};

  /// التحقق مما إذا كانت الدولة مدعومة للتسجيل حالياً
  static bool isCountrySupported(String countryCode) {
    return supportedCountryCodes.contains(countryCode.toUpperCase());
  }

  /// استنتاج كود الدولة من رقم الهاتف الدولي
  static String detectCountryCodeFromPhone(String phone) {
    final clean = phone.trim();
    if (clean.startsWith('+20')) return 'EG';
    if (clean.startsWith('+964')) return 'IQ';
    if (clean.startsWith('+963')) return 'SY';
    if (clean.startsWith('+98')) return 'IR';
    if (clean.startsWith('+90')) return 'TR';
    if (clean.startsWith('+966')) return 'SA';
    if (clean.startsWith('+971')) return 'AE';
    if (clean.startsWith('+962')) return 'JO';
    if (clean.startsWith('+961')) return 'LB';
    if (clean.startsWith('+965')) return 'KW';
    return 'EG'; // افتراضي
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. محافظات جمهورية مصر العربية (27 محافظة)
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ProvinceItem> egyptProvinces = [
    ProvinceItem(id: 'cairo', nameAr: 'القاهرة', nameEn: 'Cairo'),
    ProvinceItem(id: 'giza', nameAr: 'الجيزة', nameEn: 'Giza'),
    ProvinceItem(id: 'alexandria', nameAr: 'الإسكندرية', nameEn: 'Alexandria'),
    ProvinceItem(id: 'qalyubia', nameAr: 'القليوبية', nameEn: 'Qalyubia'),
    ProvinceItem(id: 'port_said', nameAr: 'بورسعيد', nameEn: 'Port Said'),
    ProvinceItem(id: 'suez', nameAr: 'السويس', nameEn: 'Suez'),
    ProvinceItem(id: 'ismailia', nameAr: 'الإسماعيلية', nameEn: 'Ismailia'),
    ProvinceItem(id: 'dakahlia', nameAr: 'الدقهلية', nameEn: 'Dakahlia'),
    ProvinceItem(id: 'sharqia', nameAr: 'الشرقية', nameEn: 'Sharqia'),
    ProvinceItem(id: 'gharbia', nameAr: 'الغربية', nameEn: 'Gharbia'),
    ProvinceItem(id: 'monufia', nameAr: 'المنوفية', nameEn: 'Monufia'),
    ProvinceItem(id: 'beheira', nameAr: 'البحيرة', nameEn: 'Beheira'),
    ProvinceItem(id: 'kafr_el_sheikh', nameAr: 'كفر الشيخ', nameEn: 'Kafr El Sheikh'),
    ProvinceItem(id: 'damietta', nameAr: 'دمياط', nameEn: 'Damietta'),
    ProvinceItem(id: 'matrouh', nameAr: 'مطروح', nameEn: 'Matrouh'),
    ProvinceItem(id: 'red_sea', nameAr: 'البحر الأحمر', nameEn: 'Red Sea'),
    ProvinceItem(id: 'new_valley', nameAr: 'الوادي الجديد', nameEn: 'New Valley'),
    ProvinceItem(id: 'faiyum', nameAr: 'الفيوم', nameEn: 'Faiyum'),
    ProvinceItem(id: 'beni_suef', nameAr: 'بني سويف', nameEn: 'Beni Suef'),
    ProvinceItem(id: 'minya', nameAr: 'المنيا', nameEn: 'Minya'),
    ProvinceItem(id: 'asyut', nameAr: 'أسيوط', nameEn: 'Asyut'),
    ProvinceItem(id: 'sohag', nameAr: 'سوهاج', nameEn: 'Sohag'),
    ProvinceItem(id: 'qena', nameAr: 'قنا', nameEn: 'Qena'),
    ProvinceItem(id: 'luxor', nameAr: 'الأقصر', nameEn: 'Luxor'),
    ProvinceItem(id: 'aswan', nameAr: 'أسوان', nameEn: 'Aswan'),
    ProvinceItem(id: 'north_sinai', nameAr: 'شمال سيناء', nameEn: 'North Sinai'),
    ProvinceItem(id: 'south_sinai', nameAr: 'جنوب سيناء', nameEn: 'South Sinai'),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 2. محافظات جمهورية العراق (19 محافظة)
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ProvinceItem> iraqProvinces = [
    ProvinceItem(id: 'baghdad', nameAr: 'بغداد', nameEn: 'Baghdad'),
    ProvinceItem(id: 'kirkuk', nameAr: 'كركوك', nameEn: 'Kirkuk'),
    ProvinceItem(id: 'erbil', nameAr: 'أربيل', nameEn: 'Erbil'),
    ProvinceItem(id: 'basra', nameAr: 'البصرة', nameEn: 'Basra'),
    ProvinceItem(id: 'nineveh', nameAr: 'نينوى', nameEn: 'Nineveh'),
    ProvinceItem(id: 'sulaymaniyah', nameAr: 'السليمانية', nameEn: 'Sulaymaniyah'),
    ProvinceItem(id: 'babil', nameAr: 'بابل', nameEn: 'Babil'),
    ProvinceItem(id: 'najaf', nameAr: 'النجف', nameEn: 'Najaf'),
    ProvinceItem(id: 'karbala', nameAr: 'كربلاء', nameEn: 'Karbala'),
    ProvinceItem(id: 'duhok', nameAr: 'دهوك', nameEn: 'Duhok'),
    ProvinceItem(id: 'anbar', nameAr: 'الأنبار', nameEn: 'Anbar'),
    ProvinceItem(id: 'salahuddin', nameAr: 'صلاح الدين', nameEn: 'Salahuddin'),
    ProvinceItem(id: 'diyala', nameAr: 'ديالى', nameEn: 'Diyala'),
    ProvinceItem(id: 'wasit', nameAr: 'واسط', nameEn: 'Wasit'),
    ProvinceItem(id: 'maysan', nameAr: 'ميسان', nameEn: 'Maysan'),
    ProvinceItem(id: 'dhi_qar', nameAr: 'ذي قار', nameEn: 'Dhi Qar'),
    ProvinceItem(id: 'muthanna', nameAr: 'المثنى', nameEn: 'Muthanna'),
    ProvinceItem(id: 'diwaniya', nameAr: 'الديوانية', nameEn: 'Diwaniya'),
    ProvinceItem(id: 'halabja', nameAr: 'حلبجة', nameEn: 'Halabja'),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 3. محافظات الجمهورية العربية السورية (14 محافظة)
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ProvinceItem> syriaProvinces = [
    ProvinceItem(id: 'damascus', nameAr: 'دمشق', nameEn: 'Damascus'),
    ProvinceItem(id: 'rif_dimashq', nameAr: 'ريف دمشق', nameEn: 'Rif Dimashq'),
    ProvinceItem(id: 'aleppo', nameAr: 'حلب', nameEn: 'Aleppo'),
    ProvinceItem(id: 'homs', nameAr: 'حمص', nameEn: 'Homs'),
    ProvinceItem(id: 'hama', nameAr: 'حماة', nameEn: 'Hama'),
    ProvinceItem(id: 'latakia', nameAr: 'اللاذقية', nameEn: 'Latakia'),
    ProvinceItem(id: 'tartus', nameAr: 'طرطوس', nameEn: 'Tartus'),
    ProvinceItem(id: 'idlib', nameAr: 'إدلب', nameEn: 'Idlib'),
    ProvinceItem(id: 'daraa', nameAr: 'درعا', nameEn: 'Daraa'),
    ProvinceItem(id: 'as_suwayda', nameAr: 'السويداء', nameEn: 'As-Suwayda'),
    ProvinceItem(id: 'quneitra', nameAr: 'القنيطرة', nameEn: 'Quneitra'),
    ProvinceItem(id: 'deir_ez_zor', nameAr: 'دير الزور', nameEn: 'Deir ez-Zor'),
    ProvinceItem(id: 'al_hasakah', nameAr: 'الحسكة', nameEn: 'Al-Hasakah'),
    ProvinceItem(id: 'raqqa', nameAr: 'الرقة', nameEn: 'Raqqa'),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 4. محافظات إيران (31 محافظة)
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ProvinceItem> iranProvinces = [
    ProvinceItem(id: 'tehran', nameAr: 'طهران', nameEn: 'Tehran'),
    ProvinceItem(id: 'razavi_khorasan', nameAr: 'خراسان الرضوية (مشهد)', nameEn: 'Razavi Khorasan'),
    ProvinceItem(id: 'isfahan', nameAr: 'أصفهان', nameEn: 'Isfahan'),
    ProvinceItem(id: 'fars', nameAr: 'فارس (شيراز)', nameEn: 'Fars'),
    ProvinceItem(id: 'khuzestan', nameAr: 'خوزستان (الأهواز)', nameEn: 'Khuzestan'),
    ProvinceItem(id: 'east_azerbaijan', nameAr: 'أذربيجان الشرقية (تبريز)', nameEn: 'East Azerbaijan'),
    ProvinceItem(id: 'west_azerbaijan', nameAr: 'أذربيجان الغربية (أورمية)', nameEn: 'West Azerbaijan'),
    ProvinceItem(id: 'alborz', nameAr: 'ألبرز (كرج)', nameEn: 'Alborz'),
    ProvinceItem(id: 'qom', nameAr: 'قم', nameEn: 'Qom'),
    ProvinceItem(id: 'mazandaran', nameAr: 'مازندران (ساري)', nameEn: 'Mazandaran'),
    ProvinceItem(id: 'gilan', nameAr: 'غيلان (رشت)', nameEn: 'Gilan'),
    ProvinceItem(id: 'kermanshah', nameAr: 'كرمانشاه', nameEn: 'Kermanshah'),
    ProvinceItem(id: 'kerman', nameAr: 'كرمان', nameEn: 'Kerman'),
    ProvinceItem(id: 'hormozgan', nameAr: 'هرمزغان (بندر عباس)', nameEn: 'Hormozgan'),
    ProvinceItem(id: 'yazd', nameAr: 'يزد', nameEn: 'Yazd'),
    ProvinceItem(id: 'hamadan', nameAr: 'همدان', nameEn: 'Hamadan'),
    ProvinceItem(id: 'golestan', nameAr: 'غولستان (جرجان)', nameEn: 'Golestan'),
    ProvinceItem(id: 'kurdistan', nameAr: 'كردستان (سنندج)', nameEn: 'Kurdistan'),
    ProvinceItem(id: 'lorestan', nameAr: 'لورستان (خرم آباد)', nameEn: 'Lorestan'),
    ProvinceItem(id: 'markazi', nameAr: 'المركزية (أراك)', nameEn: 'Markazi'),
    ProvinceItem(id: 'ardabil', nameAr: 'أردبيل', nameEn: 'Ardabil'),
    ProvinceItem(id: 'bushehr', nameAr: 'بوشهر', nameEn: 'Bushehr'),
    ProvinceItem(id: 'qazvin', nameAr: 'قزوين', nameEn: 'Qazvin'),
    ProvinceItem(id: 'zanjan', nameAr: 'زنجان', nameEn: 'Zanjan'),
    ProvinceItem(id: 'sistan_and_baluchestan', nameAr: 'سيستان وبلوشستان', nameEn: 'Sistan and Baluchestan'),
    ProvinceItem(id: 'ilam', nameAr: 'إيلام', nameEn: 'Ilam'),
    ProvinceItem(id: 'semnan', nameAr: 'سمنان', nameEn: 'Semnan'),
    ProvinceItem(id: 'chaharmahal_and_bakhtiari', nameAr: 'تشهارمحال وبختياري', nameEn: 'Chaharmahal and Bakhtiari'),
    ProvinceItem(id: 'north_khorasan', nameAr: 'خراسان الشمالية', nameEn: 'North Khorasan'),
    ProvinceItem(id: 'south_khorasan', nameAr: 'خراسان الجنوبية', nameEn: 'South Khorasan'),
    ProvinceItem(id: 'kohgiluyeh_and_boyer_ahmad', nameAr: 'كهكيلويه وبوير أحمد', nameEn: 'Kohgiluyeh and Boyer-Ahmad'),
  ];

  /// الحصول على قائمة محافظات دولة معينة
  static List<ProvinceItem> getProvincesForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'EG':
        return egyptProvinces;
      case 'IQ':
        return iraqProvinces;
      case 'SY':
        return syriaProvinces;
      case 'IR':
        return iranProvinces;
      default:
        return egyptProvinces;
    }
  }

  /// الحصول على المحافظة الافتراضية لكل دولة
  static String getDefaultProvinceForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'EG':
        return 'cairo';
      case 'IQ':
        return 'baghdad';
      case 'SY':
        return 'damascus';
      case 'IR':
        return 'tehran';
      default:
        return 'cairo';
    }
  }

  /// الحصول على الاسم المعرب للمحافظة
  static String getProvinceName(String? provinceId, [String? countryCode]) {
    if (provinceId == null || provinceId.isEmpty) return '';
    final code = countryCode ?? 'EG';
    final list = getProvincesForCountry(code);
    for (final item in list) {
      if (item.id == provinceId.toLowerCase()) {
        return item.nameAr;
      }
    }
    // بحث شامل في كل المحافظات
    for (final item in [...egyptProvinces, ...iraqProvinces, ...syriaProvinces, ...iranProvinces]) {
      if (item.id == provinceId.toLowerCase()) {
        return item.nameAr;
      }
    }
    return provinceId;
  }
}

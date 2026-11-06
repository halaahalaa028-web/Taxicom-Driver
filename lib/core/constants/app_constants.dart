/// الثوابت العامة للتطبيق
/// 
/// تحتوي على API Keys والإعدادات الثابتة
library;

/// فئة الثوابت العامة
class AppConstants {
  AppConstants._(); // منع إنشاء instance

  // Google Maps
  /// مفتاح API لخرائط Google
  static const String googleMapsApiKey = 'AIzaSyDBlYuXQCs0pgqQqTM0nLs-NhP_C_MQQ0o';

  // Google Cloud Translation
  /// مفتاح API لخدمة ترجمة Google Cloud
  static const String googleTranslationApiKey = 'AIzaSyBmxhttZbceTB3F0ZYTthGbg0195Uf6cVI';

  // إعدادات التسعير
  /// أجرة البداية بالدينار العراقي
  static const double baseFare = 1000;
  
  /// سعر الكيلومتر الواحد بالدينار العراقي
  static const double pricePerKm = 500;
  
  /// الحد الأدنى للأجرة
  static const double minimumFare = 1500;

  // إعدادات الخريطة
  /// مستوى التكبير الافتراضي للخريطة
  static const double defaultZoom = 15.0;
  
  /// مستوى التكبير عند عرض المسار
  static const double routeZoom = 13.0;

  // إعدادات OTP
  /// عدد خانات رمز التحقق
  static const int otpLength = 6;
  
  /// مدة انتظار إعادة الإرسال بالثواني
  static const int resendTimeout = 60;

  // إعدادات Firestore & Realtime Database
  /// اسم مجموعة المستخدمين
  static const String usersCollection = 'users';
  
  /// اسم مجموعة الرحلات
  static const String tripsCollection = 'trips';

  /// اسم مجموعة المحافظ
  static const String walletsCollection = 'wallets';

  /// اسم مجموعة المعاملات المالية للمحفظة
  static const String walletTransactionsCollection = 'wallet_transactions';

  /// اسم مجموعة طلبات السحب
  static const String payoutRequestsCollection = 'payout_requests';

  /// اسم مجموعة البطاقات البنكية المحفوظة
  static const String savedCardsCollection = 'saved_cards';

  /// مفتاح Stripe العام (Publishable Key فقط)
  static const String stripePublishableKey =
      'pk_test_51S7zBKJXqTNUkoLg2oMiZbqF3f6qA7KQQnwEsG6azDaogOi7kf5rCztH1BfsAkgNQAtscFrKbDtZYg8pNaZCkSin00UJ3L6Kl6';

  /// عنوان خادم الـ API للمدفوعات الآمنة (Taxicom Backend)
  static const String backendApiUrl = 'https://taxicom-panel.vercel.app';

  /// رابط Realtime Database (europe-west1)
  static const String realtimeDatabaseUrl = 'https://taxicom-4c281-default-rtdb.europe-west1.firebasedatabase.app';


  // إحداثيات كركوك الافتراضية
  /// خط العرض لكركوك
  static const double kirkukLat = 35.4681;
  
  /// خط الطول لكركوك
  static const double kirkukLng = 44.3922;
  
  // حدود كركوك الجغرافية (للتحقق من المواقع)
  /// الحد الأدنى لخط العرض (جنوب كركوك)
  static const double kirkukMinLat = 35.35;
  
  /// الحد الأقصى لخط العرض (شمال كركوك)
  static const double kirkukMaxLat = 35.60;
  
  /// الحد الأدنى لخط الطول (غرب كركوك)
  static const double kirkukMinLng = 44.25;
  
  /// الحد الأقصى لخط الطول (شرق كركوك)
  static const double kirkukMaxLng = 44.55;
  
  /// نصف قطر المنطقة المسموحة بالكيلومتر
  static const double kirkukRadius = 25.0;

  // إحداثيات بغداد الافتراضية
  /// خط العرض لبغداد
  static const double baghdadLat = 33.3152;
  
  /// خط الطول لبغداد
  static const double baghdadLng = 44.3661;
  
  // حدود بغداد الجغرافية (للتحقق من المواقع)
  /// الحد الأدنى لخط العرض (جنوب بغداد)
  static const double baghdadMinLat = 33.15;
  
  /// الحد الأقصى لخط العرض (شمال بغداد)
  static const double baghdadMaxLat = 33.50;
  
  /// الحد الأدنى لخط الطول (غرب بغداد)
  static const double baghdadMinLng = 44.20;
  
  /// الحد الأقصى لخط الطول (شرق بغداد)
  static const double baghdadMaxLng = 44.55;
  
  /// نصف قطر المنطقة المسموحة لبغداد بالكيلومتر
  static const double baghdadRadius = 30.0;

  // إحداثيات البصرة الافتراضية
  /// خط العرض للبصرة
  static const double basraLat = 30.5081;
  
  /// خط الطول للبصرة
  static const double basraLng = 47.7835;

  // إحداثيات السماوة الافتراضية
  /// خط العرض للسماوة
  static const double samawahLat = 31.3325;
  
  /// خط الطول للسماوة
  static const double samawahLng = 45.2865;
  
  // حدود البصرة الجغرافية (للتحقق من المواقع)
  /// الحد الأدنى لخط العرض (جنوب البصرة)
  static const double basraMinLat = 30.30;
  
  /// الحد الأقصى لخط العرض (شمال البصرة)
  static const double basraMaxLat = 30.70;
  
  /// الحد الأدنى لخط الطول (غرب البصرة)
  static const double basraMinLng = 47.50;
  
  /// الحد الأقصى لخط الطول (شرق البصرة)
  static const double basraMaxLng = 48.00;
  
  /// نصف قطر المنطقة المسموحة للبصرة بالكيلومتر
  static const double basraRadius = 30.0;

  // إعدادات التحقق
  /// الحد الأدنى لطول رقم الهاتف (بدون رمز الدولة)
  static const int minPhoneLength = 10;
  
  /// الحد الأقصى لطول رقم الهاتف
  static const int maxPhoneLength = 11;
  
  /// الحد الأدنى لطول الاسم
  static const int minNameLength = 3;

  // المواقع المقترحة - كركوك
  static const List<Map<String, dynamic>> kirkukSuggestions = [
    {'name': 'القلعة', 'address': 'قلعة كركوك التاريخية', 'lat': 35.4701, 'lng': 44.3917},
    {'name': 'سوق كركوك', 'address': 'السوق الكبير، وسط المدينة', 'lat': 35.4685, 'lng': 44.3940},
    {'name': 'جامعة كركوك', 'address': 'الحي الجامعي', 'lat': 35.4520, 'lng': 44.3650},
    {'name': 'مستشفى كركوك', 'address': 'المستشفى العام', 'lat': 35.4600, 'lng': 44.3850},
    {'name': 'ساحة النصر', 'address': 'وسط المدينة', 'lat': 35.4680, 'lng': 44.3920},
    {'name': 'مطار كركوك', 'address': 'المطار الدولي', 'lat': 35.4700, 'lng': 44.3500},
    {'name': 'ملعب كركوك', 'address': 'الملعب الأولمبي', 'lat': 35.4550, 'lng': 44.3780},
    {'name': 'مستشفى آزادي', 'address': 'مستشفى آزادي التعليمي', 'lat': 35.4650, 'lng': 44.4000},
    {'name': 'حي العسكري', 'address': 'منطقة العسكري', 'lat': 35.4580, 'lng': 44.3700},
    {'name': 'حي رحيم آوا', 'address': 'حي رحيم آوا السكني', 'lat': 35.4750, 'lng': 44.4050},
  ];

  // المواقع المقترحة - بغداد
  static const List<Map<String, dynamic>> baghdadSuggestions = [
    {'name': 'مول بغداد', 'address': 'الحارثية', 'lat': 33.3121, 'lng': 44.3615},
    {'name': 'منتزه الزوراء', 'address': 'وسط بغداد', 'lat': 33.3188, 'lng': 44.3756},
    {'name': 'مطار بغداد', 'address': 'مطار بغداد الدولي', 'lat': 33.2626, 'lng': 44.2372},
    {'name': 'جامعة بغداد', 'address': 'الجادرية', 'lat': 33.2709, 'lng': 44.3783},
    {'name': 'شارع المتنبي', 'address': 'المركز الثقافي', 'lat': 33.3395, 'lng': 44.3855},
    {'name': 'مول المنصور', 'address': 'المنصور', 'lat': 33.3082, 'lng': 44.3418},
    {'name': 'بابيلون مول', 'address': 'المنصور', 'lat': 33.2954, 'lng': 44.3622},
    {'name': 'مستشفى اليرموك', 'address': 'اليرموك', 'lat': 33.3050, 'lng': 44.3550},
    {'name': 'ساحة التحرير', 'address': 'الباب الشرقي', 'lat': 33.3333, 'lng': 44.3972},
    {'name': 'مدينة الطب', 'address': 'باب المعظم', 'lat': 33.3500, 'lng': 44.3700},
  ];

  // المواقع المقترحة - البصرة
  static const List<Map<String, dynamic>> basraSuggestions = [
    {'name': 'البصرة تايمز سكوير', 'address': 'شارع الجبيلة', 'lat': 30.5222, 'lng': 47.8228},
    {'name': 'كورنيش البصرة', 'address': 'شارع الكورنيش، شط العرب', 'lat': 30.5186, 'lng': 47.8422},
    {'name': 'جامعة البصرة', 'address': 'مجمع كليات باب الزبير', 'lat': 30.5050, 'lng': 47.8100},
    {'name': 'مطار البصرة الدولي', 'address': 'طريق المطار الدولي', 'lat': 30.5489, 'lng': 47.6621},
    {'name': 'المدينة الرياضية', 'address': 'ملعب البصرة الدولي (جذع النخلة)', 'lat': 30.4350, 'lng': 47.7470},
    {'name': 'منطقة العشار', 'address': 'وسط المدينة، سوق العشار', 'lat': 30.5134, 'lng': 47.8378},
    {'name': 'مستشفى الصدر التعليمي', 'address': 'منطقة البراضعية', 'lat': 30.5011, 'lng': 47.8305},
    {'name': 'جسر شط العرب الجديد', 'address': 'تنومة، البصرة', 'lat': 30.5262, 'lng': 47.8544},
  ];

  // المواقع المقترحة - السماوة
  static const List<Map<String, dynamic>> samawahSuggestions = [
    {'name': 'كورنيش السماوة', 'address': 'شارع الكورنيش، وسط السماوة', 'lat': 31.3325, 'lng': 45.2865},
    {'name': 'جامعة المثنى', 'address': 'طريق السماوة الخضر', 'lat': 31.3090, 'lng': 45.2690},
    {'name': 'مستشفى السماوة العام', 'address': 'حي المعلمين، السماوة', 'lat': 31.3250, 'lng': 45.2810},
    {'name': 'قشلة السماوة التاريخية', 'address': 'صوب الجزيرة، السماوة', 'lat': 31.3315, 'lng': 45.2812},
    {'name': 'ملعب السماوة الأولمبي', 'address': 'المدخل الجنوبي للسماوة', 'lat': 31.3050, 'lng': 45.2600},
    {'name': 'سوق السماوة الكبير', 'address': 'مركز المدينة، السوق العصري', 'lat': 31.3305, 'lng': 45.2825},
    {'name': 'مستشفى الحسين التعليمي', 'address': 'حي الحسين، السماوة', 'lat': 31.3180, 'lng': 45.2750},
    {'name': 'متنزه السماوة العائلي', 'address': 'صوب الشامية، الكورنيش', 'lat': 31.3345, 'lng': 45.2840},
  ];
}

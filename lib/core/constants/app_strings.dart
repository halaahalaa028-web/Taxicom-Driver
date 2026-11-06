/// النصوص العربية للتطبيق
/// 
/// تحتوي على جميع النصوص المستخدمة في التطبيق
/// لدعم اللغة العربية وتسهيل الترجمة مستقبلاً
library;

import '../services/country_service.dart';

/// فئة النصوص العربية
class AppStrings {
  AppStrings._(); // منع إنشاء instance

  // اسم التطبيق
  /// اسم التطبيق الرئيسي
  static const String appName = 'Taxicom Driver';

  // شاشة تسجيل الدخول
  /// عنوان شاشة تسجيل الدخول
  static const String loginTitle = 'أهلاً بك';
  
  /// العنوان الفرعي لشاشة تسجيل الدخول
  static const String loginSubtitle = 'أدخل رقم هاتفك للمتابعة';
  
  /// تلميح حقل رقم الهاتف
  static const String phoneHint = 'رقم الهاتف';
  
  /// زر إرسال الرمز
  static const String sendCode = 'إرسال الرمز';
  
  /// رمز الدولة العراق
  static const String countryCode = '+964';

  // شاشة التحقق من الرمز
  /// عنوان شاشة OTP
  static const String otpTitle = 'التحقق من الرمز';
  
  /// العنوان الفرعي لشاشة OTP
  static const String otpSubtitle = 'أدخل الرمز المرسل إلى';
  
  /// زر التحقق
  static const String verify = 'تحقق';
  
  /// إعادة إرسال الرمز
  static const String resendCode = 'إعادة إرسال الرمز';
  
  /// رسالة انتظار إعادة الإرسال
  static const String resendIn = 'إعادة الإرسال خلال';
  
  /// ثانية
  static const String seconds = 'ثانية';

  // شاشة الملف الشخصي
  /// عنوان شاشة الملف الشخصي
  static const String profileTitle = 'أكمل بياناتك';
  
  /// حقل الاسم
  static const String nameField = 'الاسم والكنية';
  
  /// تلميح حقل الاسم
  static const String nameHint = 'أدخل اسمك الكامل';
  
  /// حقل البريد الإلكتروني
  static const String emailField = 'البريد الإلكتروني (اختياري)';
  
  /// تلميح حقل البريد الإلكتروني
  static const String emailHint = 'example@email.com';
  
  /// حقل العنوان 
  static const String addressField = 'العنوان (اختياري)';
  
  /// حقل العنوان للسائق (إجباري)
  static const String addressFieldRequired = 'العنوان';
  
  /// تلميح حقل العنوان
  static const String addressHint = 'أدخل عنوانك';
  
  /// خطأ العنوان
  static const String addressError = 'يرجى إدخال العنوان';
  
  /// حقل الجنس
  static const String genderField = 'الجنس (اختياري)';
  
  /// حقل الجنس للسائق (إجباري)
  static const String genderFieldRequired = 'الجنس';
  
  /// خيار ذكر
  static const String male = 'ذكر';
  
  /// خيار أنثى
  static const String female = 'أنثى';
  
  /// خطأ الجنس
  static const String genderError = 'يرجى اختيار الجنس';
  
  /// حقل تاريخ الميلاد
  static const String birthDateField = 'تاريخ الميلاد (اختياري)';
  
  /// حقل تاريخ الميلاد للسائق (إجباري)
  static const String birthDateFieldRequired = 'تاريخ الميلاد';
  
  /// تلميح حقل تاريخ الميلاد
  static const String birthDateHint = 'اختر تاريخ ميلادك';
  
  /// خطأ تاريخ الميلاد
  static const String birthDateError = 'يرجى اختيار تاريخ الميلاد';
  
  /// زر الحفظ
  static const String save = 'حفظ';
  
  // حقول السائق
  /// حقل الاسم الثلاثي
  static const String fullNameField = 'الاسم الثلاثي';
  
  /// تلميح حقل الاسم الثلاثي
  static const String fullNameHint = 'أدخل الاسم الثلاثي واللقب';
  
  /// حقل الصورة الشخصية
  static const String profilePhotoField = 'الصورة الشخصية';
  
  /// حقل رقم السيارة
  static const String carNumberField = 'رقم السيارة';
  
  /// تلميح رقم السيارة
  static const String carNumberHint = 'مثال: ٤٥٦٧٨ - بغداد';
  
  /// حقل نوع السيارة
  static const String carTypeField = 'نوع السيارة';
  
  /// تلميح نوع السيارة
  static const String carTypeHint = 'مثال: تويوتا كورولا';
  
  /// حقل موديل السيارة
  static const String carModelField = 'موديل السيارة';
  
  /// تلميح موديل السيارة
  static const String carModelHint = 'مثال: 2022';
  
  /// حقل لون السيارة
  static const String carColorField = 'لون السيارة';
  
  /// تلميح لون السيارة
  static const String carColorHint = 'مثال: أبيض';
  
  // رسائل خطأ السائق
  /// خطأ الاسم الثلاثي
  static const String fullNameError = 'يرجى إدخال الاسم الثلاثي (3 كلمات على الأقل)';
  
  /// خطأ الصورة الشخصية
  static const String profilePhotoError = 'يرجى اختيار صورة شخصية';
  
  /// خطأ رقم السيارة
  static const String carNumberError = 'يرجى إدخال رقم السيارة';
  
  /// خطأ نوع السيارة
  static const String carTypeError = 'يرجى إدخال نوع السيارة';
  
  /// خطأ موديل السيارة
  static const String carModelError = 'يرجى إدخال موديل السيارة';
  
  /// خطأ لون السيارة
  static const String carColorError = 'يرجى إدخال لون السيارة';
  
  /// رسالة رفع الصورة
  static const String uploadingPhoto = 'جاري رفع الصورة...';
  
  /// اختيار من المعرض
  static const String chooseFromGallery = 'اختيار من المعرض';
  
  /// التقاط صورة
  static const String takePhoto = 'التقاط صورة';

  // الشاشة الرئيسية
  /// عنوان حقل الموقع الحالي
  static const String whereAmI = 'أين أنا؟';
  
  /// تلميح حقل الموقع الحالي
  static const String currentLocationHint = 'جاري تحديد موقعك...';
  
  /// عنوان حقل الوجهة
  static const String whereToGo = 'إلى أين تذهب؟';
  static const String whereTo = 'إلى أين تذهب؟';
  
  /// تلميح حقل الوجهة
  static const String destinationHint = 'ابحث عن وجهتك';
  
  /// السعر
  static const String estimatedPrice = 'السعر';
  static const String estimatedTime = 'الوقت المتوقع';
  
  /// زر تأكيد الطلب
  static const String confirmTrip = 'تأكيد الطلب';
  
  /// العملة
  static String get currency => CountryService.instance.selectedCountry.currencyAr;
  
  /// المسافة
  static const String distance = 'المسافة';
  
  /// كيلومتر
  static const String km = 'كم';

  // رسائل الخطأ
  /// خطأ في رقم الهاتف
  static const String phoneError = 'يرجى إدخال رقم هاتف صحيح';
  
  /// خطأ في رمز التحقق
  static const String otpError = 'رمز التحقق غير صحيح';
  
  /// خطأ في الاسم
  static const String nameError = 'يرجى إدخال اسمك';
  
  /// خطأ عام
  static const String generalError = 'حدث خطأ، يرجى المحاولة مرة أخرى';
  
  /// خطأ في الموقع
  static const String locationError = 'تعذر تحديد الموقع';
  
  /// خطأ في الاتصال
  static const String connectionError = 'تحقق من اتصالك بالإنترنت';

  // رسائل النجاح
  /// نجاح حفظ البيانات
  static const String saveSuccess = 'تم حفظ البيانات بنجاح';
  
  /// نجاح إرسال الرمز
  static const String codeSent = 'تم إرسال رمز التحقق';

  // حالات التحميل
  /// جاري التحميل
  static const String loading = 'جاري التحميل...';
  
  /// جاري الإرسال
  static const String sending = 'جاري الإرسال...';
  
  /// جاري التحقق
  static const String verifying = 'جاري التحقق...';
  
  /// جاري الحفظ
  static const String saving = 'جاري الحفظ...';

  // نظام المصادقة الجديد
  /// كلمة المرور
  static const String password = 'كلمة المرور';
  
  /// تلميح كلمة المرور
  static const String passwordHint = 'أدخل كلمة المرور';
  
  /// تأكيد كلمة المرور
  static const String confirmPassword = 'تأكيد كلمة المرور';
  
  /// تلميح تأكيد كلمة المرور
  static const String confirmPasswordHint = 'أعد إدخال كلمة المرور';
  
  /// زر تسجيل الدخول
  static const String login = 'تسجيل الدخول';
  
  /// زر إنشاء حساب
  static const String createAccount = 'إنشاء حساب';
  
  /// اختر نوع الحساب
  static const String chooseAccountType = 'اختر نوع الحساب';
  
  /// مستخدم
  static const String asCustomer = 'مستخدم';
  
  /// وصف المستخدم
  static const String customerDescription = 'اطلب رحلات وتنقل بسهولة';
  
  /// سائق
  static const String asDriver = 'سائق';
  
  /// وصف السائق
  static const String driverDescription = 'استقبل طلبات الرحلات واكسب المال';
  
  /// خطأ كلمة المرور
  static const String passwordError = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  
  /// كلمتا المرور غير متطابقتين
  static const String passwordMismatch = 'كلمتا المرور غير متطابقتين';
  
  /// رقم الهاتف مسجل مسبقاً
  static const String phoneAlreadyExists = 'رقم الهاتف هذا مسجل مسبقاً، قم بتسجيل الدخول';
  
  /// ليس لديك حساب
  static const String noAccount = 'ليس لديك حساب؟';
  
  /// لديك حساب بالفعل
  static const String haveAccount = 'لديك حساب بالفعل؟';
  
  /// تسجيل حساب جديد
  static const String registerTitle = 'تسجيل حساب جديد';
  
  /// جاري تسجيل الدخول
  static const String loggingIn = 'جاري تسجيل الدخول...';
  
  /// جاري إنشاء الحساب
  static const String creatingAccount = 'جاري إنشاء الحساب...';

  /// رقم الهاتف مسجل مسبقاً (للسائقين)
  static const String driverPhoneAlreadyExists = 'رقم الهاتف هذا مسجل مسبقاً.\nإذا كنت مسجلاً كمستخدم وتريد أن تصبح سائقاً، قم بتسجيل الدخول ثم قدم طلب "انضم كسائق" من القائمة الجانبية.';

  // نظام موافقة السائقين
  /// عنوان شاشة الانتظار
  static const String pendingApprovalTitle = 'في انتظار الموافقة';
  
  /// رسالة الانتظار
  static const String pendingApprovalMessage = 'تم استلام طلبك وهو قيد المراجعة من قبل الإدارة';
  
  /// مدة الانتظار
  static const String pendingApprovalTime = 'سيتم مراجعة طلبك خلال 24-48 ساعة كحد أقصى';
  
  /// سيصلك اشعار
  static const String pendingApprovalNotify = 'سيصلك إشعار عند الموافقة على طلبك';
  
  /// زر تعديل البيانات
  static const String editProfile = 'تعديل البيانات';
  
  /// تسجيل الخروج
  static const String logout = 'تسجيل الخروج';
}


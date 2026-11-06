/// النصوص الكردية
/// 
/// ملف الترجمة للغة الكردية (سۆرانی)
library;

const Map<String, String> kuStrings = {
  // اسم التطبيق
  'appName': 'Taxicom Driver',

  // شاشة تسجيل الدخول
  'loginTitle': 'بەخێربێیت',
  'loginSubtitle': 'ژمارەی مۆبایلت بنووسە بۆ بەردەوامبوون',
  'phoneHint': 'ژمارەی مۆبایل',
  'sendCode': 'ناردنی کۆد',
  'countryCode': '+964',
  'selectCountry': 'وڵات هەڵبژێرە',
  'searchCountry': 'گەڕان بەدوای وڵات...',
  'noCountriesFound': 'هیچ وڵاتێک نەدۆزرایەوە',

  // شاشة التحقق من الرمز
  'otpTitle': 'پشتڕاستکردنەوەی کۆد',
  'otpSubtitle': 'کۆدی نێردراو بنووسە بۆ',
  'verify': 'پشتڕاستکردنەوە',
  'resendCode': 'دووبارە ناردنی کۆد',
  'resendOtpIn': 'دووبارە ناردن لە',
  'resendIn': 'دووبارە ناردن لە',
  'seconds': 'چرکە',

  // شاشة الملف الشخصي
  'profileTitle': 'زانیاریەکانت تەواو بکە',
  'nameField': 'ناو و نازناو',
  'nameHint': 'ناوی تەواوت بنووسە',
  'emailField': 'ئیمەیڵ (بەدڵخوازی)',
  'emailHint': 'example@email.com',
  'addressField': 'ناونیشان (بەدڵخوازی)',
  'addressHint': 'ناونیشانت بنووسە',
  'genderField': 'ڕەگەز (بەدڵخوازی)',
  'male': 'نێر',
  'female': 'مێ',
  'birthDateField': 'بەرواری لەدایکبوون (بەدڵخوازی)',
  'birthDateHint': 'بەرواری لەدایکبوونت هەڵبژێرە',
  'save': 'پاشەکەوتکردن',

  // حقول السائق
  'fullNameField': 'ناوی سێ بەشی',
  'fullNameHint': 'وەک: ئەحمەد محەمەد عەلی',
  'profilePhotoField': 'وێنەی کەسی',
  'carNumberField': 'ژمارەی ئۆتۆمبێل',
  'carNumberHint': 'وەک: ٤٥٦٧٨ - کەرکوک',
  'carTypeField': 'جۆری ئۆتۆمبێل',
  'carTypeHint': 'وەک: تۆیۆتا کۆرۆڵا',
  'carModelField': 'مۆدێلی ئۆتۆمبێل',
  'carModelHint': 'وەک: 2022',
  'carColorField': 'ڕەنگی ئۆتۆمبێل',
  'carColorHint': 'وەک: سپی',

  // رسائل خطأ السائق
  'fullNameError': 'تکایە ناوی سێ بەشی بنووسە (لانیکەم ٣ وشە)',
  'profilePhotoError': 'تکایە وێنەی کەسی هەڵبژێرە',
  'carNumberError': 'تکایە ژمارەی ئۆتۆمبێل بنووسە',
  'carTypeError': 'تکایە جۆری ئۆتۆمبێل بنووسە',
  'carModelError': 'تکایە مۆدێلی ئۆتۆمبێل بنووسە',
  'carColorError': 'تکایە ڕەنگی ئۆتۆمبێل بنووسە',
  'uploadingPhoto': 'بارکردنی وێنە...',
  'chooseFromGallery': 'هەڵبژاردن لە گەلەری',
  'takePhoto': 'وێنە گرتن',

  // الشاشة الرئيسية
  'whereAmI': 'لە کوێم؟',
  'currentLocationHint': 'شوێنت دیاری دەکرێت...',
  'whereToGo': 'بۆ کوێ دەچیت؟',
  'destinationHint': 'گەڕان بەدوای مەنزڵ',
  'estimatedPrice': 'نرخ',
  'confirmTrip': 'دڵنیاکردنەوەی داواکاری',
  'pickupPoint': 'شوێنی دەستپێکردن',
  'destinationPoint': 'شوێنی گەیشتن',
  'confirmTripBtn': 'دڵنیاکردنەوەی گەشت',
  'selectDestinationPoint': 'دياریکردنی شوێنی گەیشتن',
  'confirmPickupPoint': 'دڵنیاکردنەوەی شوێنی دەستپێکردن',
  'currency': 'د.ع',
  'distance': 'دووری',
  'km': 'کم',

  // صفحة حجز التكسي
  'selectDestination': 'شوێنی گەیشتن دياری بکە',
  'confirmDestination': 'دڵنياكردنەوەی شوێنی گەیشتن',
  'moveMapToSelectLocation': 'نەخشەکە بجووڵێنە بۆ دیاریکردنی شوێن',
  'selectPickup': 'شوێنی دەستپێکردن دياری بکە',
  'confirmPickup': 'دڵنياكردنەوەی شوێنی دەستپێکردن',
  'searchingForDriver': 'گەڕان بەدوای شۆفێر...',
  'driverAccepted': 'داواکاریەکەت وەرگیرا',
  'driverOnTheWay': 'شۆفێر لە ڕێگایە',
  'tripInProgress': 'گەشتەکە بەڕێوەيە',
  'tripCompleted': 'گەشتەکە تەواو بوو',
  'cancelTrip': 'هەڵوەشاندنەوەی داواکاری',
  'callDriver': 'پەیوەندیبکە بە شۆفێر',
  'chatWithDriver': 'گوفتوگۆ لەگەڵ شۆفێر',
  'waitAMoment': 'چاوەڕوانبە...',
  'price': 'نرخ',
  'tripCancelled': 'داواکاری ھەڵوەشایەوە',
  'sorryTripCancelled': 'ببورە، گەشتەکە لە لایەن شۆفێرەوە ھەڵوەشایەوە.',
  'ok': 'باشە',
  'rateYourExperience': 'ئەزموونەکەت ھەڵسەنگاندن بکە',
  'rateYourTrip': 'گەشتەکەت ھەڵسەنگاندن بکە',
  'thankYouForRating': 'سوپاس بۆ ھەڵسەنگاندنەکەت!',
  'confirmRequest': 'دڵنياکردنەوەی داواکاری',
  'driverFoundMessage': 'شۆفێرێکمان بۆ دۆزیوەتەوە!',
  'theDriver': 'شۆفێر',
  'cancelForDriverContact': 'بۆ ھەڵوەشاندنەوە، پەیوەندی بە شۆفێر بکە و داوای ھەڵوەشاندنەوە لێ بکە',

  // رسائل الخطأ
  'phoneError': 'تکایە ژمارەی مۆبایلی دروست بنووسە',
  'otpError': 'کۆدی پشتڕاستکردنەوە هەڵەیە',
  'nameError': 'تکایە ناوت بنووسە',
  'generalError': 'هەڵەیەک ڕوویدا، تکایە دووبارە هەوڵ بدەرەوە',
  'locationError': 'نەتوانرا شوێن دیاری بکرێت',
  'connectionError': 'پەیوەندی ئینتەرنێتت بپشکنە',

  // رسائل النجاح
  'saveSuccess': 'زانیاریەکان بە سەرکەوتوویی پاشەکەوت کران',
  'codeSent': 'کۆدی پشتڕاستکردنەوە نێردرا',

  // حالات التحميل
  'loading': 'بارکردن...',
  'sending': 'ناردن...',
  'verifying': 'پشتڕاستکردنەوە...',
  'saving': 'پاشەکەوتکردن...',

  // نظام المصادقة
  'password': 'وشەی نهێنی',
  'passwordHint': 'وشەی نهێنی بنووسە',
  'confirmPassword': 'دووبارەکردنەوەی وشەی نهێنی',
  'confirmPasswordHint': 'دووبارە وشەی نهێنی بنووسە',
  'login': 'چوونەژوورەوە',
  'createAccount': 'دروستکردنی هەژمار',
  'chooseAccountType': 'جۆری هەژمار هەڵبژێرە',
  'asCustomer': 'بەکارهێنەر',
  'customerDescription': 'داواکاری گەشت بکە و بە ئاسانی بگوازرێوە',
  'asDriver': 'شۆفێر',
  'driverDescription': 'داواکاریەکانی گەشت وەربگرە و پارە بخەرەوە',
  'passwordError': 'وشەی نهێنی دەبێت لانیکەم ٦ پیت بێت',
  'passwordMismatch': 'وشەی نهێنی یەکناگرنەوە',
  'phoneAlreadyExists': 'ئەم ژمارەی مۆبایلە پێشتر تۆمار کراوە، چوونەژوورەوە بکە',
  'noAccount': 'هەژمارت نییە؟',
  'haveAccount': 'پێشتر هەژمارت هەیە؟',
  'registerTitle': 'تۆمارکردنی هەژماری نوێ',
  'loggingIn': 'چوونەژوورەوە...',
  'creatingAccount': 'دروستکردنی هەژمار...',
  'accountData': 'زانیاریی هەژمار',
  'personalData': 'زانیاریی کەسی',
  'carInfo': 'زانیاریی ئۆتۆمبێل',
  'termsAgree': 'رازیم بە',

  // نظام موافقة السائقين
  'pendingApprovalTitle': 'چاوەڕوانی پەسەندکردن',
  'pendingApprovalMessage': 'داواکاریەکەت وەرگیرا و لە لایەن بەڕێوەبەرایەتییەوە پێداچوونەوەی دەکرێت',
  'pendingApprovalTime': 'داواکاریەکەت لە ماوەی ٢٤-٤٨ کاتژمێر پێداچوونەوەی دەکرێت',
  'pendingApprovalNotify': 'کاتێک داواکاریەکەت پەسەند کرا ئاگادارت دەکەینەوە',
  'editProfile': 'گۆڕینی زانیاریەکان',
  'logout': 'چوونەدەرەوە',

  // القائمة الجانبية
  'myTrips': 'گەشتەکانی پێشووم',
  'myTripsSubtitle': 'بینینی مێژووی گەشتەکان',
  'earningsAndWallet': 'داهات و جزدان',
  'earningsAndWalletSubtitle': 'باڵانس، دانی کۆمیسیۆن ١٥٪، و داهاتەکان',
  'earningsAndDues': 'داهات و قەرزەکان',
  'earningsAndDuesSubtitle': 'پوختەی داهات و قەرزەکان',
  'convertToDriver': 'گۆڕین بۆ شۆفێر',
  'convertToDriverSubtitle': 'وەک شۆفێر بەشداری بکە',
  'offersAndDiscounts': 'ئۆفەر و داشکاندنەکان',
  'offersAndDiscountsSubtitle': 'بەکارهێنانی کۆپۆنی داشکاندن',
  'ratings': 'هەڵسەنگاندنەکان',
  'ratingsSubtitle': 'هەڵسەنگاندنەکانت بۆ شۆفێرەکان',
  'settings': 'ڕێکخستنەکان',
  'settingsSubtitle': 'ڕێکخستنەکانی بەرنامە',
  'termsAndConditions': 'مەرج و ڕێسا',
  'termsAndConditionsSubtitle': 'سیاسەتی بەکارهێنان',
  'privacyPolicy': 'سیاسەتی تایبەتمەندی',
  'privacyPolicySubtitle': 'زانیاریەکانت و تایبەتمەندیت',
  'helpAndSupport': 'یارمەتی و پشتگیری',
  'helpAndSupportSubtitle': 'پەیوەندیمان پێوە بکە',
  'aboutApp': 'دەربارەی بەرنامە',
  'aboutAppSubtitle': 'زانیاری بەرنامە',
  'logoutSubtitle': 'چوونەدەرەوە لە هەژمار',

  // إعدادات اللغة
  'languageSettings': 'ڕێکخستنی زمان',
  'selectLanguage': 'زمان هەڵبژێرە',
  'languageChanged': 'زمان گۆڕدرا',

  // الشاشة الرئيسية
  'bookTaxi': 'داواکاری تاکسی',
  'orderNow': 'ئێستا ئۆتۆمبێلی کرێ داوا بکە',
  'offersAndAds': 'ئۆفەر و ڕێکلام',
  'browseOffers': 'تەماشای ئۆفەرەکان بکە',
  'noOffersNow': 'ئێستا ئۆفەر نییە',
  'customer': 'بەکارهێنەر',
  'driver': 'شۆفێر',

  // رسائل عامة
  'cancel': 'پاشگەزبوونەوە',
  'confirm': 'دڵنیاکردنەوە',
  'yes': 'بەڵێ',
  'no': 'نەخێر',
  'error': 'هەڵە',
  'success': 'سەرکەوتوو',
  'warning': 'ئاگاداری',
  'underDevelopment': 'لەژێر گەشەپێدانە',
  'couldNotOpenLink': 'نەتوانرا لینکەکە بکرێتەوە',
  'logoutConfirmation': 'ئایا دڵنیایت دەتەوێت بچیتە دەرەوە؟',
  'logoutError': 'هەڵەیەک ڕوویدا لە کاتی چوونەدەرەوە',
  'continueText': 'بەردەوام بوون',
  'convertToDriverTitle': 'گۆڕین بۆ شۆفێر',
  'convertToDriverMessage': 'ئایا دەتەوێت ببیتە شۆفێر؟\nپێویستە زانیاری شۆفێر و ئۆتۆمبێل تەواو بکەیت.',

  // صفحة عن التطبيق
  'appDescription': 'بەرنامەی داواکاری تاکسی لە کەرکوک',
  'version': 'وەشان',
  'supportAndContact': 'پشتگیری و پەیوەندی',
  'contactUsAnytime': 'لە هەر کاتێک پەیوەندیمان پێوە بکە',
  'supportPhone': 'ژمارەی پشتگیری',
  'allRightsReserved': 'هەموو مافەکان پارێزراون',
  
  // ميزات التطبيق
  'appFeatures': 'تایبەتمەندیەکانی بەرنامە',
  'featureTracking': 'بەدواداچوونی ڕاستەوخۆ بۆ ئۆتۆمبێل لەسەر نەخشە',
  'featureSafe': 'گەشتی ئارام و سەلامەت',
  'featureFast': 'داواکاری خێرا و ئاسان',
  'featureFairPrice': 'نرخی دادپەروەرانە و ڕوون',
  
  // صفحة المساعدة والدعم
  'frequentQuestions': 'پرسیارە باوەکان',
  'faqHowToBook': 'چۆن گەشتێک داواکاری بکەم؟',
  'faqHowToBookAnswer': 'کلیک لەسەر "داواکاری تاکسی" لە پەڕەی سەرەکی، شوێنی دەستپێکردن و گەیشتن دیاری بکە، پاشان کلیک لەسەر دڵنیاکردنەوەی داواکاری.',
  'faqHowToCancel': 'چۆن داواکاری هەڵوەشێنمەوە؟',
  'faqHowToCancelAnswer': 'دوای دڵنیاکردنەوەی داواکاری، پەیوەندی بە شۆفێر بکە و داوای هەڵوەشاندنەوە لێ بکە.',
  'faqPayment': 'شێوازەکانی پارەدان چین؟',
  'faqPaymentAnswer': 'پارەدان بە نەقد بۆ شۆفێر ڕاستەوخۆ لە کۆتایی گەشت.',

  // التحقق من OTP
  'sendOtp': 'ناردنی کۆدی پشتڕاستکردنەوە',
  'enterOtp': 'کۆدی پشتڕاستکردنەوە بنووسە',
  'otpHint': 'کۆدی ٦ ژمارەیی',
  'otpSent': 'کۆدی پشتڕاستکردنەوە بە واتساپ نێردرا',
  'otpVerified': 'ژمارەکە پشتڕاست کرایەوە',
  'phoneNotVerified': 'سەرەتا دەبێت ژمارەی مۆبایل پشتڕاست بکرێتەوە',
  'otpExpired': 'کۆدەکە بەسەرچوو، دووبارە بنێرە',
  'sendingOtp': 'ناردنی کۆد...',
  'verifyingOtp': 'پشتڕاستکردنەوە...',
  'otpSendError': 'ناردنی کۆد سەرکەوتوو نەبوو، دووبارە هەوڵ بدەرەوە',
  'otpInvalid': 'کۆدی پشتڕاستکردنەوە هەڵەیە',
  'resendOtp': 'دووبارە ناردنی کۆد',
  'verifyPhone': 'پشتڕاستکردنەوەی ژمارەی مۆبایل',
  'otpSentTo': 'کۆدی پشتڕاستکردنەوە نێردرا بۆ',
  'verifyAndRegister': 'پشتڕاستکردنەوە و دروستکردنی هەژمار',

  // نسيت كلمة المرور
  'forgotPassword': 'وشەی نهێنیت بیرچوو؟',
  'resetPassword': 'گۆڕینی وشەی نهێنی',
  'newPassword': 'وشەی نهێنی نوێ',
  'newPasswordHint': 'وشەی نهێنی نوێ بنووسە',
  'confirmNewPassword': 'دووبارەکردنەوەی وشەی نهێنی نوێ',
  'passwordResetSuccess': 'وشەی نهێنی بە سەرکەوتوویی گۆڕدرا',
  'passwordResetError': 'گۆڕینی وشەی نهێنی سەرکەوتوو نەبوو',
  'resettingPassword': 'گۆڕینی وشەی نهێنی...',
  'noAccountWithPhone': 'هەژمارێک بەم ژمارەیە نییە',
  
  // إلغاء الطلب
  'cancelTripTitle': 'هەڵوەشاندنەوەی داواکاری',
  'selectCancellationReason': 'هۆکاری هەڵوەشاندنەوە هەڵبژێرە',
  'cancelReasonDriverDelay': 'دواکەوتنی شۆفێر',
  'cancelReasonDriverDelayDesc': 'دواکەوتن لە گەیشتن بە شوێن',
  'cancelReasonWrongRequest': 'هەڵەی داواکاری',
  'cancelReasonWrongRequestDesc': 'مەنزڵ یان جۆری ئۆتۆمبێل هەڵەیە',
  'cancelReasonPlanChange': 'گۆڕانی پلان',
  'cancelReasonPlanChangeDesc': 'ئیتر پێویستم بە ئۆتۆمبێل نییە',
  'cancelReasonDriverRequested': 'داواکاری شۆفێر',
  'cancelReasonDriverRequestedDesc': 'شۆفێر داوای هەڵوەشاندنەوەی لێکردم',
  'cancelReasonOther': 'هۆکارەکانی تر',
  'confirmCancellation': 'دڵنیاکردنەوەی هەڵوەشاندنەوە',
  'tripCancelledSuccessfully': 'داواکاری بە سەرکەوتوویی هەڵوەشایەوە',
  
  // إلغاء الطلب من قبل السائق
  'driverCancelTripTitle': 'هەڵوەشاندنەوەی گەشت',
  'selectDriverCancellationReason': 'هۆکاری هەڵوەشاندنەوەی گەشت هەڵبژێرە',
  'cancelReasonPassengerNoShow': 'نەهاتنی گەشتیار',
  'cancelReasonPassengerNoShowDesc': 'گەشتیار دەرنەهات بۆ هەڵگرتن',
  'cancelReasonInaccurateLocation': 'شوێنی وردنییە',
  'cancelReasonInaccurateLocationDesc': 'نەتوانرا بگەینە شوێنی گەشتیار',
  'cancelReasonExcessLoad': 'بارە زیادە',
  'cancelReasonExcessLoadDesc': 'ژمارەی گەشتیاران یان کەلوپەل زۆرە',
  'cancelReasonCarMalfunction': 'کێشەی لەناکاو',
  'cancelReasonCarMalfunctionDesc': 'کێشەیەکی لەناکاو لە ئۆتۆمبێل',
  'cancelReasonOtherReasons': 'هۆکارەکانی تر',

  // حذف الحساب
  'deleteAccount': 'سڕینەوەی هەژمار',
  'deleteAccountSubtitle': 'سڕینەوەی هەژمار بە تەواوی',
  'deleteAccountWarning': 'ئایا دڵنیایت دەتەوێت هەژمارەکەت بسڕیتەوە؟\nهەموو زانیاریەکانت بە تەواوی دەسڕێتەوە و ناتوانیت پاشگەزبیتەوە.',
  'deleteAccountConfirm': 'سڕینەوەی هەژمار',
  'enterPasswordToDelete': 'وشەی نهێنی بنووسە بۆ دڵنیاکردنەوە',
  'deletingAccount': 'سڕینەوەی هەژمار...',
  'accountDeletedSuccess': 'هەژمار بە سەرکەوتوویی سڕایەوە',
  'accountDeleteError': 'سڕینەوەی هەژمار سەرکەوتوو نەبوو',

  // رفض طلب السائق
  'driverRequestRejected': 'داواکاریەکەت وەک شۆفێر ڕەتکرایەوە',
  'driverRequestRejectedMessage': 'ببورە، داواکاریەکەت وەک شۆفێر پەسەند نەکرا. دەتوانیت وەک گەشتیار بەردەوام بیت.',

  // شاشة رحلاتي السابقة
  'myTripsTitle': 'گەشتەکانی پێشوو',
  'tripsLoadError': 'هەڵەیەک ڕوویدا لە کاتی بارکردنی گەشتەکان',
  'retry': 'هەوڵدانەوە',
  'noTrips': 'هیچ گەشتێکی پێشوو نییە',
  'tripsWillAppear': 'گەشتەکانت لێرە دەردەکەون دوای تەواوکردنیان',
  'totalTrips': 'کۆی گەشتەکان',
  'loadMoreError': 'بارکردنی زیاتر سەرکەوتوو نەبوو',
  'statusPending': 'چاوەڕوانی',
  'statusAccepted': 'پەسەندکرا',
  'statusCompleted': 'تەواوبوو',
  'statusCancelled': 'هەڵوەشێنرایەوە',
  'statusCancelledByDriver': 'لەلایەن شۆفێرەوە هەڵوەشێنرایەوە',
  'from': 'لە',
  'to': 'بۆ',
  'thePassenger': 'گەشتیار',
  'ratingsSection': 'هەڵسەنگاندنەکان',
  'yourRatingForPassenger': 'هەڵسەنگاندنت بۆ گەشتیار',
  'passengerRatingForYou': 'هەڵسەنگاندنی گەشتیار بۆ تۆ',
  'yourRatingForDriver': 'هەڵسەنگاندنت بۆ شۆفێر',
  'driverRatingForYou': 'هەڵسەنگاندنی شۆفێر بۆ تۆ',
  'today': 'ئەمڕۆ',
  'yesterday': 'دوێنێ',

  // شاشة الرسائل والإشعارات
  'messagesAndNotifications': 'نامە و ئاگاداریەکان',
  'messagesLoadError': 'هەڵەیەک ڕوویدا لە بارکردنی نامەکان',
  'noMessages': 'هیچ نامەیەک نییە لە ئێستادا',
  'newBadge': 'نوێ',
  'close': 'داخستن',
  'minutesAgo': 'پێش {n} خولەک',
  'hoursAgo': 'پێش {n} کاتژمێر',
  'daysAgo': 'پێش {n} ڕۆژ',

  // شاشة تفاصيل التوصيل
  'destinationDetails': 'وردەکاریەکانی مەنزڵ',
  'receiverSection': 'بوارى وەرگر',
  'receiverFullName': 'ناوی تەواوی وەرگر',
  'enterReceiverName': 'تکایە ناوی وەرگر بنووسە',
  'receiverPhone': 'ژمارەی مۆبایلی وەرگر',
  'phoneExample': 'نموونەی ژمارەی مۆبایل: 07123456789',
  'enterPhone': 'تکایە ژمارەی مۆبایل بنووسە',
  'phoneTooShort': 'ژمارەی مۆبایل کورتە',
  'addressLabel': 'ناونیشان',
  'addressExample': 'نموونەی ناونیشان: ناوی شەقام، زقاق، ژمارەی بینا',
  'enterAddress': 'تکایە ناونیشان بنووسە',
  'optionalDescription': 'وەسفی دڵخوازانە',
  'paidByReceiver': 'پارەدان بە نەقد لەلایەن وەرگرەوە',
  'confirmOrder': 'دڵنیاکردنەوەی داواکاری',

  // الشاشة الرئيسية - نصوص إضافية
  'locatingYou': 'شوێنت دیاری دەکرێت...',
  'pleaseWait': 'تکایە کەمێک چاوەڕوان بە',
  'calculatingRoute': 'ڕێگا دیاری دەکرێت...',
  'rideTab': 'گەشت',
  'deliveryTab': 'گەیاندنی داواکاری',
  'unknownLocation': 'شوێنی نەناسراو',

  // شاشة السائق
  'driverMode': 'دۆخی شۆفێر',
  'locatingPosition': 'شوێن دیاری دەکرێت...',
  'availableForWork': 'ئامادە بۆ کارکردن',
  'notAvailable': 'ئامادە نییە',
  'tapToStopReceiving': 'دابگرە بۆ وەستاندنی وەرگرتنی داواکاری',
  'tapToStartReceiving': 'دابگرە بۆ دەستپێکردنی وەرگرتنی داواکاری',
  'todayTrips': 'گەشتەکانی ئەمڕۆ',
  'todayEarnings': 'داهاتی ئەمڕۆ',
  'tripInfo': 'زانیاری گەشت',
  'distanceToYou': 'دووری بۆ لات:',
  'deliveryDetails': 'وردەکاریەکانی گەیاندن',
  'receiver': 'وەرگر:',
  'phone': 'مۆبایل:',
  'package': 'بار:',
  'rideRequest': 'داواکاری گەشت',
  'deliveryRequest': 'داواکاری گەیاندن',
  'showOnMap': 'پیشاندان لەسەر نەخشە',
  'roundTrip': 'چوون و گەڕانەوە',
  'minute': 'خولەک',

  // شاشة معاينة الرحلة
  'tripDetails': 'وردەکاریەکانی گەشت',
  'loadingRoute': 'بارکردنی ڕێگا...',
  'tripDistance': 'دووری گەشت',
  'tripTime': 'کاتی گەشت',
  'dropoffPoint': 'خاڵی دابەزین',
  'distanceToPassenger': 'دووری بۆ لات',
  'timeToPassenger': 'کاتی گەیشتن بۆ گەشتیار',

  // نصوص إضافية
  'tripOptions': 'هەڵبژاردنەکانی گەشت',
  'enterDetails': 'وردەکارییەکان بنووسە',
  'tripOptionsInfo': 'دەتوانیت مەنزڵی دووەم زیاد بکەیت یان گەشتی چوون و گەڕانەوە هەڵبژێریت',
  'addSecondDestination': 'زیادکردنی مەنزڵی دووەم',
  'secondDestination': 'مەنزڵی دووەم:',
  'addSecondDestSubtitle': 'هەڵبژاردنی مەنزڵی زیادە بۆ گەشت',
  'tapToChangeOrDelete': 'کلیک بکە بۆ گۆڕین یان سڕینەوە',
  'waitTime': 'کاتی چاوەڕوانی',
  'waitTimeSubtitle': 'ماوەی وەستان لە مەنزڵی یەکەم دیاری بکە',
  'choose': 'هەڵبژێرە',
  'roundTripLabel': 'چوون و گەڕانەوە',
  'roundTripSubtitle': 'گەڕانەوە بۆ خاڵی سوارکردن لە کۆتایی گەشت',
  'estimatedPriceLabel': 'نرخی خەمڵێنراو:',
  'confirmOptions': 'پشتڕاستکردنەوەی هەڵبژاردنەکان',

  // حقل المحافظة
  'provinceField': 'پارێزگا',
  'provinceBaghdad': 'بەغدا',
  'provinceKirkuk': 'کەرکوک',
  'provinceError': 'تکایە پارێزگا هەڵبژێرە',

  
  // صفحة المساعدة والدعم

  // التحقق من OTP

  // نسيت كلمة المرور
  
  // إلغاء الطلب
  
  // إلغاء الطلب من قبل السائق

  // حذف الحساب

  // رفض طلب السائق

  // شاشة رحلاتي السابقة

  // شاشة الرسائل والإشعارات

  // شاشة تفاصيل التوصيل

  // الشاشة الرئيسية - نصوص إضافية

  // شاشة السائق

  // شاشة معاينة الرحلة

  'gpsDisabledTitle': 'خزمەتگوزاری GPS ناچالاکە',
  'gpsDisabledMessage': 'پێویستە خزمەتگوزاری شوێن (GPS) کارا بێت بۆ کارکردن وەک شۆفێر. تکایە لە ڕێکخستنەکان کارای بکە.',
  'mockLocationDetectedTitle': 'شوێنی ساختە دۆزرایەوە (Fake GPS)',
  'mockLocationDetectedMessage': 'بەکارهێنانی بەرنامەی شوێنی ساختە (Fake GPS) لە تاكسيكۆم بە تەواوی قەدەغەیە بۆ پاراستنی دادپەروەری و سەلامەتی. تکایە بەرنامەکە دابخە بۆ بەردەوامبوون.',
  'openDeveloperSettings': 'هەڵبژاردەکانی گەشەپێدەر',
  'locationPermissionRequired': 'مۆڵەتی شوێن پێویستە',
  'locationPermissionMessage': 'بەرنامەکە پێویستی بە مۆڵەتی شوێن هەیە بۆ کارکردن وەک شۆفێر. تکایە مۆڵەت بدە.',
  'openLocationSettings': 'کردنەوەی ڕێکخستنی شوێن',
  'openAppSettings': 'کردنەوەی ڕێکخستنی بەرنامە',
  'forceOfflineGpsMessage': 'گۆڕدرایت بۆ نابەردەست چونکە GPS داخرا. تکایە GPS چالاک بکەرەوە و دووبارە چالاکی بکەرەوە.',
  'enableGpsToContinue': 'پێویستە GPS کارابکرێت بۆ بەردەوامبوون',
  'noInternetConnection': 'بەستە ئینتەرنێت نییە. پەیوەندیکەت بپشکنەو و دووبارە هەوڵ بدەرەوە.',
  'presenceServiceError': 'پەیوەندی بە خزمەتگوزاری شوێنپێهەڵگرتنی ڕاستەوخۆ نەکرا. تکایە دووبارە هەوڵ بدەرەوە.',
  'updating': 'نوێکردنەوە...',

  // ڕوونکردنەوەی بەکارهێنانی شوێن لە پاشبنەمادا
  'locationDisclosureTitle': 'دەستگەیشتن بە شوێن لە پاشبنەمادا',
  'locationDisclosureMainNotice': 'ئەم بەرنامەیە داتای شوێن کۆدەکاتەوە تەنانەت کاتێک بەرنامەکە داخراوە بۆ وەرگرتنی داواکاری سەرنشینانی نزیک و شوێنپێهەڵگرتنی گەشتەکە.',
  'locationDisclosureFeature1Title': 'وەرگرتنی داواکاری گەشتی نزیک',
  'locationDisclosureFeature1Desc': 'هاوتاکردنی شوێنی ڕاستەقینەت بۆ ناردنی داواکاری سەرنشینانی نزیکت بە شێوەیەکی خێرا.',
  'locationDisclosureFeature2Title': 'شوێنپێهەڵگرتنی گەشت و گەیشتن',
  'locationDisclosureFeature2Desc': 'هاوبەشکردنی ڕێڕەوی لێخوڕین و کاتی گەیشتن بە وردی لەگەڵ سەرنشین لە کاتی گەشتدا.',
  'locationDisclosureFeature3Title': 'سەلامەتی و پاراستنی گەشت',
  'locationDisclosureFeature3Desc': 'چاودێریکردنی ڕێڕەوی گەشتە چالاکەکان بۆ پاراستنی سەلامەتی تۆ و سەرنشینان.',
  'locationDisclosureBackgroundNote': 'شوێنپێهەڵگرتن لە پاشبنەمادا تەنها کاتێک کاردەکات کە لە دۆخی "بەردەست" بیت یان لە کاتی گەشتێکی چالاکدا.',
  'locationDisclosureAccept': 'موافق و بەردەوامبە',
  'locationDisclosureDecline': 'ئێستا نا',
  // Trips Tabs & Empty States
  'allTripsTab': 'هەموو',
  'completedTripsTab': 'تەواوکراو',
  'cancelledTripsTab': 'هەڵوەشاوە',
  'noPastTrips': 'هیچ گەشتێکی پێشوو نییە',
  'noCompletedTrips': 'هیچ گەشتێکی تەواوکراو نییە',
  'noCancelledTrips': 'هیچ گەشتێکی هەڵوەشاوە نییە',
  'pastTripsEmptySubtitle': 'هەموو گەشتەکانی پێشووت و وردەکارییەکانیان لێرە دەردەکەون دوای تەواوکردنی یەکەم گەشت',
  'cancellationReasonLabel': 'هۆکاری هەڵوەشاندنەوە: {reason}',
  'driverTotalEarnings': 'داهاتی گشتی گەشت',
  'cashFromPassenger': 'کاش لە سەرنشین',
  'platformDiscountSubsidy': 'داشکاندنی پاڵپشتیکراو لە ئەپ',
  'supportedDiscountTag': 'داشکاندنی پاڵپشتیکراو',
  // Driver Wallet & Debt Ceiling
  'driverWalletTitle': 'جزدانی شۆفێر و قەرز',
  'driverWalletSubtitle': 'بەڕێوەبردنی باڵانس، کۆمیسیۆن، و ڕاکێشانی داهات',
  'availableEarnings': 'باڵانسی داهاتی بەردەست',
  'outstandingDebt': 'قەرزی ماوەی پلاتفۆرم',
  'noDebt': 'هیچ قەرزێک نییە',
  'payDebt': 'پارەدانی قەرز',
  'requestPayout': 'داواکردنی ڕاکێشانی پارە',
  'debtCeilingWarning': 'ئاگاداری: نزیکبوویتەوە لە ئەوپەڕی قەرز',
  'debtCeilingExceeded': 'وەرگرتنی داواکارییەکان ڕاگیرا بەهۆی تێپەڕاندنی قەرز',
  'platformCommissionTitle': 'کۆمیسیۆنی پلاتفۆرم',
  'driverNetEarningsTitle': 'داهاتی سافی شۆفێر',
  'transactionsHistory': 'مێژووی مامەڵەکان و کۆمیسیۆن',
  // Saved Cards
  'savedCards': 'کارتە خەزنکراوەکان',
  'addCard': 'زیادکردنی کارت',
  'noSavedCards': 'هیچ کارتێکی خەزنکراو نییە',
  'noSavedCardsDesc': 'کارتەکەت زیاد بکە بۆ دانەوەی خێرای قەرز بە یەک کرتە',
  'defaultCard': 'بنەڕەتی',
  'setAsDefault': 'دانان وەک بنەڕەتی',
  'deleteCard': 'سڕینەوەی کارت',
  'deleteCardConfirm': 'دڵنیایت لە سڕینەوەی ئەم کارتە؟',
  'delete': 'سڕینەوە',
  'cardAddedSuccess': 'کارتەکە بە سەرکەوتوویی پاشەکەوت کرا',
  'cardDeleteSuccess': 'کارتەکە سڕایەوە',
  'oneClickSettlement': 'دانەوەی خێرا بە یەک کرتە',
  'payWithOtherMethod': 'کارتی بانکی نوێ',
  'cardHolderName': 'ناوی خاوەنی کارت',
  'setDefaultCardSwitch': 'دانان وەک کارتی بنەڕەتی',
};

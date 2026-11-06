/// نظام الترجمة والتوطين
/// 
/// يدير الترجمات للغات المدعومة
library;

import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/country_service.dart';
import 'translations/ar.dart';
import 'translations/en.dart';
import 'translations/ku.dart';
import 'translations/tk.dart';

/// فئة الترجمة الرئيسية
class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  /// الحصول على instance من context
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(LanguageService.instance.currentLanguage);
  }

  /// الحصول على النصوص حسب اللغة الحالية
  Map<String, String> get _strings {
    switch (language) {
      case AppLanguage.arabic:
        return arStrings;
      case AppLanguage.english:
        return enStrings;
      case AppLanguage.kurdish:
        return kuStrings;
      case AppLanguage.turkmen:
        return tkStrings;
    }
  }

  /// الحصول على نص مترجم
  String get(String key) {
    return _strings[key] ?? arStrings[key] ?? key;
  }

  bool get isRtl => language == AppLanguage.arabic || language == AppLanguage.kurdish;
  bool get isArabic => language == AppLanguage.arabic;

  // === الوصول المباشر للنصوص ===

  // اسم التطبيق
  String get appName => get('appName');

  // شاشة تسجيل الدخول
  String get loginTitle => get('loginTitle');
  String get loginSubtitle => get('loginSubtitle');
  String get phoneHint => get('phoneHint');
  String get sendCode => get('sendCode');
  String get countryCode => CountryService.instance.selectedCountry.dialCode;
  String get selectCountry => get('selectCountry');
  String get searchCountry => get('searchCountry');
  String get noCountriesFound => get('noCountriesFound');

  // شاشة التحقق من الرمز
  String get otpTitle => get('otpTitle');
  String get otpSubtitle => get('otpSubtitle');
  String get verify => get('verify');
  String get resendCode => get('resendCode');
  String get resendIn => get('resendIn');
  String get seconds => get('seconds');

  // شاشة الملف الشخصي
  String get profileTitle => get('profileTitle');
  String get nameField => get('nameField');
  String get nameHint => get('nameHint');
  String get emailField => get('emailField');
  String get emailHint => get('emailHint');
  String get addressField => get('addressField');
  String get addressFieldRequired => get('addressFieldRequired');
  String get addressHint => get('addressHint');
  String get addressError => get('addressError');
  String get genderField => get('genderField');
  String get genderFieldRequired => get('genderFieldRequired');
  String get male => get('male');
  String get female => get('female');
  String get genderError => get('genderError');
  String get birthDateField => get('birthDateField');
  String get birthDateFieldRequired => get('birthDateFieldRequired');
  String get birthDateHint => get('birthDateHint');
  String get birthDateError => get('birthDateError');
  String get save => get('save');

  // حقول السائق
  String get fullNameField => get('fullNameField');
  String get fullNameHint => get('fullNameHint');
  String get profilePhotoField => get('profilePhotoField');
  String get carNumberField => get('carNumberField');
  String get carNumberHint => get('carNumberHint');
  String get carTypeField => get('carTypeField');
  String get carTypeHint => get('carTypeHint');
  String get carModelField => get('carModelField');
  String get carModelHint => get('carModelHint');
  String get carColorField => get('carColorField');
  String get carColorHint => get('carColorHint');

  // رسائل خطأ السائق
  String get fullNameError => get('fullNameError');
  String get profilePhotoError => get('profilePhotoError');
  String get carNumberError => get('carNumberError');
  String get carTypeError => get('carTypeError');
  String get carModelError => get('carModelError');
  String get carColorError => get('carColorError');
  String get uploadingPhoto => get('uploadingPhoto');
  String get chooseFromGallery => get('chooseFromGallery');
  String get takePhoto => get('takePhoto');

  // الشاشة الرئيسية
  String get whereAmI => get('whereAmI');
  String get currentLocationHint => get('currentLocationHint');
  String get whereToGo => get('whereToGo');
  String get destinationHint => get('destinationHint');
  String get estimatedPrice => get('estimatedPrice');
  String get confirmTrip => get('confirmTrip');
  String get pickupPoint => get('pickupPoint');
  String get destinationPoint => get('destinationPoint');
  String get confirmTripBtn => get('confirmTripBtn');
  String get selectDestinationPoint => get('selectDestinationPoint');
  String get confirmPickupPoint => get('confirmPickupPoint');
  String get currency => language == AppLanguage.english
      ? CountryService.instance.selectedCountry.currencyEn
      : CountryService.instance.selectedCountry.currencyAr;
  String get distance => get('distance');
  String get km => get('km');

  // صفحة حجز التكسي
  String get selectDestination => get('selectDestination');
  String get confirmDestination => get('confirmDestination');
  String get moveMapToSelectLocation => get('moveMapToSelectLocation');
  String get selectPickup => get('selectPickup');
  String get confirmPickup => get('confirmPickup');
  String get searchingForDriver => get('searchingForDriver');
  String get driverAccepted => get('driverAccepted');
  String get driverOnTheWay => get('driverOnTheWay');
  String get tripInProgress => get('tripInProgress');
  String get tripCompleted => get('tripCompleted');
  String get cancelTrip => get('cancelTrip');
  String get callDriver => get('callDriver');
  String get chatWithDriver => get('chatWithDriver');
  String get waitAMoment => get('waitAMoment');
  String get price => get('price');
  String get tripCancelled => get('tripCancelled');
  String get sorryTripCancelled => get('sorryTripCancelled');
  String get rateYourExperience => get('rateYourExperience');
  String get rateYourTrip => get('rateYourTrip');
  String get thankYouForRating => get('thankYouForRating');
  String get confirmRequest => get('confirmRequest');
  String get driverFoundMessage => get('driverFoundMessage');
  String get theDriver => get('theDriver');
  String get cancelForDriverContact => get('cancelForDriverContact');

  // رسائل الخطأ
  String get phoneError => get('phoneError');
  String get otpError => get('otpError');
  String get nameError => get('nameError');
  String get generalError => get('generalError');
  String get locationError => get('locationError');
  String get connectionError => get('connectionError');

  // رسائل النجاح
  String get saveSuccess => get('saveSuccess');
  String get codeSent => get('codeSent');

  // حالات التحميل
  String get loading => get('loading');
  String get sending => get('sending');
  String get verifying => get('verifying');
  String get saving => get('saving');

  // نظام المصادقة
  String get password => get('password');
  String get passwordHint => get('passwordHint');
  String get confirmPassword => get('confirmPassword');
  String get confirmPasswordHint => get('confirmPasswordHint');
  String get login => get('login');
  String get createAccount => get('createAccount');
  String get chooseAccountType => get('chooseAccountType');
  String get asCustomer => get('asCustomer');
  String get customerDescription => get('customerDescription');
  String get asDriver => get('asDriver');
  String get driverDescription => get('driverDescription');
  String get passwordError => get('passwordError');
  String get passwordMismatch => get('passwordMismatch');
  String get phoneAlreadyExists => get('phoneAlreadyExists');
  String get noAccount => get('noAccount');
  String get haveAccount => get('haveAccount');
  String get registerTitle => get('registerTitle');
  String get loggingIn => get('loggingIn');
  String get creatingAccount => get('creatingAccount');
  String get accountData => get('accountData');
  String get personalData => get('personalData');
  String get carInfo => get('carInfo');
  String get termsAgree => get('termsAgree');

  // نظام موافقة السائقين
  String get pendingApprovalTitle => get('pendingApprovalTitle');
  String get pendingApprovalMessage => get('pendingApprovalMessage');
  String get pendingApprovalTime => get('pendingApprovalTime');
  String get pendingApprovalNotify => get('pendingApprovalNotify');
  String get editProfile => get('editProfile');
  String get logout => get('logout');

  // القائمة الجانبية
  String get myTrips => get('myTrips');
  String get myTripsSubtitle => get('myTripsSubtitle');
  String get earningsAndWallet => get('earningsAndWallet');
  String get earningsAndWalletSubtitle => get('earningsAndWalletSubtitle');
  String get earningsAndDues => get('earningsAndDues');
  String get earningsAndDuesSubtitle => get('earningsAndDuesSubtitle');
  String get convertToDriver => get('convertToDriver');
  String get convertToDriverSubtitle => get('convertToDriverSubtitle');
  String get offersAndDiscounts => get('offersAndDiscounts');
  String get offersAndDiscountsSubtitle => get('offersAndDiscountsSubtitle');
  String get ratings => get('ratings');
  String get ratingsSubtitle => get('ratingsSubtitle');
  String get settings => get('settings');
  String get settingsSubtitle => get('settingsSubtitle');
  String get termsAndConditions => get('termsAndConditions');
  String get termsAndConditionsSubtitle => get('termsAndConditionsSubtitle');
  String get privacyPolicy => get('privacyPolicy');
  String get privacyPolicySubtitle => get('privacyPolicySubtitle');
  String get helpAndSupport => get('helpAndSupport');
  String get helpAndSupportSubtitle => get('helpAndSupportSubtitle');
  String get aboutApp => get('aboutApp');
  String get aboutAppSubtitle => get('aboutAppSubtitle');
  String get madeBy => get('madeBy');
  String get logoutSubtitle => get('logoutSubtitle');

  // إعدادات اللغة
  String get languageSettings => get('languageSettings');
  String get selectLanguage => get('selectLanguage');
  String get languageChanged => get('languageChanged');

  // الشاشة الرئيسية
  String get bookTaxi => get('bookTaxi');
  String get orderNow => get('orderNow');
  String get offersAndAds => get('offersAndAds');
  String get browseOffers => get('browseOffers');
  String get noOffersNow => get('noOffersNow');
  String get customer => get('customer');
  String get driverRole => get('driver');

  // رسائل عامة
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get yes => get('yes');
  String get no => get('no');
  String get ok => get('ok');
  String get error => get('error');
  String get success => get('success');
  String get warning => get('warning');
  String get underDevelopment => get('underDevelopment');
  String get couldNotOpenLink => get('couldNotOpenLink');
  String get logoutConfirmation => get('logoutConfirmation');
  String get logoutError => get('logoutError');
  String get continueText => get('continueText');
  String get convertToDriverTitle => get('convertToDriverTitle');
  String get convertToDriverMessage => get('convertToDriverMessage');

  // صفحة عن التطبيق
  String get appDescription => get('appDescription');
  String get version => get('version');
  String get supportAndContact => get('supportAndContact');
  String get contactUsAnytime => get('contactUsAnytime');
  String get supportPhone => get('supportPhone');
  String get allRightsReserved => get('allRightsReserved');
  
  // ميزات التطبيق
  String get appFeatures => get('appFeatures');
  String get featureTracking => get('featureTracking');
  String get featureSafe => get('featureSafe');
  String get featureFast => get('featureFast');
  String get featureFairPrice => get('featureFairPrice');
  
  // صفحة المساعدة والدعم
  String get frequentQuestions => get('frequentQuestions');
  String get faqHowToBook => get('faqHowToBook');
  String get faqHowToBookAnswer => get('faqHowToBookAnswer');
  String get faqHowToCancel => get('faqHowToCancel');
  String get faqHowToCancelAnswer => get('faqHowToCancelAnswer');
  String get faqPayment => get('faqPayment');
  String get faqPaymentAnswer => get('faqPaymentAnswer');

  // التحقق من OTP
  String get sendOtp => get('sendOtp');
  String get enterOtp => get('enterOtp');
  String get otpHint => get('otpHint');
  String get otpSent => get('otpSent');
  String get otpVerified => get('otpVerified');
  String get phoneNotVerified => get('phoneNotVerified');
  String get otpExpired => get('otpExpired');
  String get sendingOtp => get('sendingOtp');
  String get verifyingOtp => get('verifyingOtp');
  String get otpSendError => get('otpSendError');
  String get otpInvalid => get('otpInvalid');
  String get resendOtp => get('resendOtp');
  String get resendOtpIn => get('resendOtpIn');
  String get verifyPhone => get('verifyPhone');
  String get otpSentTo => get('otpSentTo');
  String get verifyAndRegister => get('verifyAndRegister');

  // نسيت كلمة المرور
  String get forgotPassword => get('forgotPassword');
  String get resetPassword => get('resetPassword');
  String get newPassword => get('newPassword');
  String get newPasswordHint => get('newPasswordHint');
  String get confirmNewPassword => get('confirmNewPassword');
  String get passwordResetSuccess => get('passwordResetSuccess');
  String get passwordResetError => get('passwordResetError');
  String get resettingPassword => get('resettingPassword');
  String get noAccountWithPhone => get('noAccountWithPhone');

  // إلغاء الطلب
  String get cancelTripTitle => get('cancelTripTitle');
  String get selectCancellationReason => get('selectCancellationReason');
  String get cancelReasonDriverDelay => get('cancelReasonDriverDelay');
  String get cancelReasonDriverDelayDesc => get('cancelReasonDriverDelayDesc');
  String get cancelReasonWrongRequest => get('cancelReasonWrongRequest');
  String get cancelReasonWrongRequestDesc => get('cancelReasonWrongRequestDesc');
  String get cancelReasonPlanChange => get('cancelReasonPlanChange');
  String get cancelReasonPlanChangeDesc => get('cancelReasonPlanChangeDesc');
  String get cancelReasonDriverRequested => get('cancelReasonDriverRequested');
  String get cancelReasonDriverRequestedDesc => get('cancelReasonDriverRequestedDesc');
  String get cancelReasonOther => get('cancelReasonOther');
  String get confirmCancellation => get('confirmCancellation');
  String get tripCancelledSuccessfully => get('tripCancelledSuccessfully');

  // إلغاء الطلب من قبل السائق
  String get driverCancelTripTitle => get('driverCancelTripTitle');
  String get selectDriverCancellationReason => get('selectDriverCancellationReason');
  String get cancelReasonCarMalfunction => get('cancelReasonCarMalfunction');
  String get cancelReasonCarMalfunctionDesc => get('cancelReasonCarMalfunctionDesc');
  String get cancelReasonHeavyTraffic => get('cancelReasonHeavyTraffic');
  String get cancelReasonHeavyTrafficDesc => get('cancelReasonHeavyTrafficDesc');
  String get cancelReasonPickupTooFarOrInaccurate => get('cancelReasonPickupTooFarOrInaccurate');
  String get cancelReasonPickupTooFarOrInaccurateDesc => get('cancelReasonPickupTooFarOrInaccurateDesc');
  String get cancelReasonPassengerRequestedCancel => get('cancelReasonPassengerRequestedCancel');
  String get cancelReasonPassengerRequestedCancelDesc => get('cancelReasonPassengerRequestedCancelDesc');
  String get cancelReasonPersonalEmergency => get('cancelReasonPersonalEmergency');
  String get cancelReasonPersonalEmergencyDesc => get('cancelReasonPersonalEmergencyDesc');
  String get cancelReasonPassengerNoShow => get('cancelReasonPassengerNoShow');
  String get cancelReasonPassengerNoShowDesc => get('cancelReasonPassengerNoShowDesc');
  String get cancelReasonPassengerUnreachable => get('cancelReasonPassengerUnreachable');
  String get cancelReasonPassengerUnreachableDesc => get('cancelReasonPassengerUnreachableDesc');
  String get cancelReasonExcessLoad => get('cancelReasonExcessLoad');
  String get cancelReasonExcessLoadDesc => get('cancelReasonExcessLoadDesc');
  String get cancelReasonInaccurateOrUnsafeLocation => get('cancelReasonInaccurateOrUnsafeLocation');
  String get cancelReasonInaccurateOrUnsafeLocationDesc => get('cancelReasonInaccurateOrUnsafeLocationDesc');
  String get cancelReasonPassengerRefused => get('cancelReasonPassengerRefused');
  String get cancelReasonPassengerRefusedDesc => get('cancelReasonPassengerRefusedDesc');
  String get cancelReasonOtherReasons => get('cancelReasonOtherReasons');

  // حذف الحساب
  String get deleteAccount => get('deleteAccount');
  String get deleteAccountSubtitle => get('deleteAccountSubtitle');
  String get deleteAccountWarning => get('deleteAccountWarning');
  String get deleteAccountConfirm => get('deleteAccountConfirm');
  String get enterPasswordToDelete => get('enterPasswordToDelete');
  String get deletingAccount => get('deletingAccount');
  String get accountDeletedSuccess => get('accountDeletedSuccess');
  String get accountDeleteError => get('accountDeleteError');

  // رفض طلب السائق
  String get driverRequestRejected => get('driverRequestRejected');
  String get driverRequestRejectedMessage => get('driverRequestRejectedMessage');

  // شاشة رحلاتي السابقة
  String get myTripsTitle => get('myTripsTitle');
  String get tripsLoadError => get('tripsLoadError');
  String get retry => get('retry');
  String get noTrips => get('noTrips');
  String get tripsWillAppear => get('tripsWillAppear');
  String get totalTrips => get('totalTrips');
  String get loadMoreError => get('loadMoreError');
  String get statusPending => get('statusPending');
  String get statusAccepted => get('statusAccepted');
  String get statusCompleted => get('statusCompleted');
  String get statusCancelled => get('statusCancelled');
  String get statusCancelledByDriver => get('statusCancelledByDriver');
  String get from => get('from');
  String get to => get('to');
  String get thePassenger => get('thePassenger');
  String get ratingsSection => get('ratingsSection');
  String get yourRatingForPassenger => get('yourRatingForPassenger');
  String get passengerRatingForYou => get('passengerRatingForYou');
  String get yourRatingForDriver => get('yourRatingForDriver');
  String get driverRatingForYou => get('driverRatingForYou');
  String get today => get('today');
  String get yesterday => get('yesterday');

  // شاشة الرسائل والإشعارات
  String get messagesAndNotifications => get('messagesAndNotifications');
  String get messagesLoadError => get('messagesLoadError');
  String get noMessages => get('noMessages');
  String get newBadge => get('newBadge');
  String get close => get('close');
  String minutesAgo(int count) => get('minutesAgo').replaceAll('{n}', '$count');
  String hoursAgo(int count) => get('hoursAgo').replaceAll('{n}', '$count');
  String daysAgo(int count) => get('daysAgo').replaceAll('{n}', '$count');

  // شاشة تفاصيل التوصيل
  String get destinationDetails => get('destinationDetails');
  String get receiverSection => get('receiverSection');
  String get receiverFullName => get('receiverFullName');
  String get enterReceiverName => get('enterReceiverName');
  String get receiverPhone => get('receiverPhone');
  String get phoneExample => get('phoneExample');
  String get enterPhone => get('enterPhone');
  String get phoneTooShort => get('phoneTooShort');
  String get addressLabel => get('addressLabel');
  String get addressExample => get('addressExample');
  String get enterAddress => get('enterAddress');
  String get optionalDescription => get('optionalDescription');
  String get paidByReceiver => get('paidByReceiver');
  String get confirmOrder => get('confirmOrder');

  // الشاشة الرئيسية - نصوص إضافية
  String get locatingYou => get('locatingYou');
  String get pleaseWait => get('pleaseWait');
  String get calculatingRoute => get('calculatingRoute');
  String get rideTab => get('rideTab');
  String get deliveryTab => get('deliveryTab');
  String get unknownLocation => get('unknownLocation');

  // شاشة السائق
  String get driverMode => get('driverMode');
  String get locatingPosition => get('locatingPosition');
  String get availableForWork => get('availableForWork');
  String get notAvailable => get('notAvailable');
  String get tapToStopReceiving => get('tapToStopReceiving');
  String get tapToStartReceiving => get('tapToStartReceiving');
  String get todayTrips => get('todayTrips');
  String get todayEarnings => get('todayEarnings');
  String get tripInfo => get('tripInfo');
  String get distanceToYou => get('distanceToYou');
  String get deliveryDetails => get('deliveryDetails');
  String get receiver => get('receiver');
  String get phone => get('phone');
  String get package => get('package');
  String get rideRequest => get('rideRequest');
  String get deliveryRequest => get('deliveryRequest');
  String get showOnMap => get('showOnMap');
  String get roundTrip => get('roundTrip');
  String get minute => get('minute');

  // شاشة معاينة الرحلة
  String get tripDetails => get('tripDetails');
  String get loadingRoute => get('loadingRoute');
  String get tripDistance => get('tripDistance');
  String get tripTime => get('tripTime');
  String get dropoffPoint => get('dropoffPoint');
  String get distanceToPassenger => get('distanceToPassenger');
  String get timeToPassenger => get('timeToPassenger');

  // نصوص إضافية
  String get tripOptions => get('tripOptions');
  String get enterDetails => get('enterDetails');
  String get tripOptionsInfo => get('tripOptionsInfo');
  String get addSecondDestination => get('addSecondDestination');
  String get secondDestination => get('secondDestination');
  String get addSecondDestSubtitle => get('addSecondDestSubtitle');
  String get tapToChangeOrDelete => get('tapToChangeOrDelete');
  String get waitTime => get('waitTime');
  String get waitTimeSubtitle => get('waitTimeSubtitle');
  String get choose => get('choose');
  String get roundTripLabel => get('roundTripLabel');
  String get roundTripSubtitle => get('roundTripSubtitle');
  String get estimatedPriceLabel => get('estimatedPriceLabel');
  String get confirmOptions => get('confirmOptions');

  // حقل المحافظة
  String get provinceField => get('provinceField');
  String get provinceBaghdad => get('provinceBaghdad');
  String get provinceKirkuk => get('provinceKirkuk');
  String get provinceError => get('provinceError');

  String get gpsDisabledTitle => get('gpsDisabledTitle');
  String get gpsDisabledMessage => get('gpsDisabledMessage');
  String get mockLocationDetectedTitle => get('mockLocationDetectedTitle');
  String get mockLocationDetectedMessage => get('mockLocationDetectedMessage');
  String get openDeveloperSettings => get('openDeveloperSettings');
  String get locationPermissionRequired => get('locationPermissionRequired');
  String get locationPermissionMessage => get('locationPermissionMessage');
  String get openLocationSettings => get('openLocationSettings');
  String get openAppSettings => get('openAppSettings');
  String get forceOfflineGpsMessage => get('forceOfflineGpsMessage');
  String get enableGpsToContinue => get('enableGpsToContinue');
  String get noInternetConnection => get('noInternetConnection');
  String get presenceServiceError => get('presenceServiceError');
  String get updating => get('updating'); // جارٍ التحديث...

  // إفصاح الموقع في الخلفية للسائق
  String get locationDisclosureTitle => get('locationDisclosureTitle');
  String get locationDisclosureMainNotice => get('locationDisclosureMainNotice');
  String get locationDisclosureFeature1Title => get('locationDisclosureFeature1Title');
  String get locationDisclosureFeature1Desc => get('locationDisclosureFeature1Desc');
  String get locationDisclosureFeature2Title => get('locationDisclosureFeature2Title');
  String get locationDisclosureFeature2Desc => get('locationDisclosureFeature2Desc');
  String get locationDisclosureFeature3Title => get('locationDisclosureFeature3Title');
  String get locationDisclosureFeature3Desc => get('locationDisclosureFeature3Desc');
  String get locationDisclosureBackgroundNote => get('locationDisclosureBackgroundNote');
  String get locationDisclosureAccept => get('locationDisclosureAccept');
  String get locationDisclosureDecline => get('locationDisclosureDecline');

  // الكوبونات والهدايا
  String get couponsAndGifts => get('couponsAndGifts');
  String get promoCodeLabel => get('promoCodeLabel');
  String get applyPromo => get('applyPromo');
  String get promoCodeHint => get('promoCodeHint');
  String get promoAppliedSuccess => get('promoAppliedSuccess');
  String get promoInvalid => get('promoInvalid');
  String get promoLimitReached => get('promoLimitReached');
  String get myGiftsLabel => get('myGiftsLabel');
  String get myCouponsLabel => get('myCouponsLabel');
  String get noGiftsYet => get('noGiftsYet');
  String get noCouponsYet => get('noCouponsYet');
  String get useGiftBtn => get('useGiftBtn');
  String get giftUsedSuccess => get('giftUsedSuccess');
  String get giftUsedAlready => get('giftUsedAlready');
  String get giftExpired => get('giftExpired');
  String get freeRideGift => get('freeRideGift');
  String get expiryDate => get('expiryDate');

  String promoMinPriceError(String minPrice) => get('promoMinPriceError').replaceAll('{minPrice}', minPrice);
  String discountApplied(String discount) => get('discountApplied').replaceAll('{discount}', discount);
  String fixedDiscountGift(String amount) => get('fixedDiscountGift').replaceAll('{amount}', amount);

  // تبويبات وسجل الرحلات
  String get allTripsTab => get('allTripsTab');
  String get completedTripsTab => get('completedTripsTab');
  String get cancelledTripsTab => get('cancelledTripsTab');
  String get noPastTrips => get('noPastTrips');
  String get noCompletedTrips => get('noCompletedTrips');
  String get noCancelledTrips => get('noCancelledTrips');
  String get pastTripsEmptySubtitle => get('pastTripsEmptySubtitle');
  String cancellationReasonLabel(String reason) => get('cancellationReasonLabel').replaceAll('{reason}', reason);
  String get driverTotalEarnings => get('driverTotalEarnings');
  String get cashFromPassenger => get('cashFromPassenger');
  String get electronicPaymentFromPassenger => get('electronicPaymentFromPassenger');
  String get platformDiscountSubsidy => get('platformDiscountSubsidy');
  String get supportedDiscountTag => get('supportedDiscountTag');
  String get paymentMethod => get('paymentMethod');
  String get cash => get('cash');
  String get walletPayment => get('walletPayment');
  String get creditCard => get('creditCard');
  String get applePay => get('applePay');

  // محفظة السائق وسقف المديونية
  String get driverWalletTitle => get('driverWalletTitle');
  String get driverWalletSubtitle => get('driverWalletSubtitle');
  String get availableEarnings => get('availableEarnings');
  String get outstandingDebt => get('outstandingDebt');
  String get noDebt => get('noDebt');
  String get payDebt => get('payDebt');
  String get requestPayout => get('requestPayout');
  String get debtCeilingWarning => get('debtCeilingWarning');
  String get debtCeilingExceeded => get('debtCeilingExceeded');
  String get platformCommissionTitle => get('platformCommissionTitle');
  String get driverNetEarningsTitle => get('driverNetEarningsTitle');
  String get transactionsHistory => get('transactionsHistory');

  // دخل المشاوير والأرباح التشغيلية
  String get netTripsEarnings => get('netTripsEarnings');
  String get grossFarePaidByPassengers => get('grossFarePaidByPassengers');
  String get platformCommissionDeducted => get('platformCommissionDeducted');
  String get todayNetEarnings => get('todayNetEarnings');
  String get weekNetEarnings => get('weekNetEarnings');
  String get monthNetEarnings => get('monthNetEarnings');
  String get completedTripsCountLabel => get('completedTripsCountLabel');
  String get netEarningsDescription => get('netEarningsDescription');
  String get promoCommissionOffer => get('promoCommissionOffer');
  String get fullDriverSharePromo => get('fullDriverSharePromo');

  // تفصيل كاش اليوم وأرباح المحفظة
  String get todayCashInHand => get('todayCashInHand');
  String get todayWalletEarnings => get('todayWalletEarnings');
  String get todayEarningsBreakdownTitle => get('todayEarningsBreakdownTitle');
  String todayCashTripsCountText(int count) => get('todayCashTripsCountText').replaceAll('{count}', '$count');
  String todayElectronicTripsCountText(int count) => get('todayElectronicTripsCountText').replaceAll('{count}', '$count');
  String get todayEarningsBreakdownNote => get('todayEarningsBreakdownNote');

  // سجل تتبع طلبات سحب الأرباح
  String get payoutRequestsHistory => get('payoutRequestsHistory');
  String get payoutRequestTitle => get('payoutRequestTitle');
  String get payoutStatusPending => get('payoutStatusPending');
  String get payoutStatusApproved => get('payoutStatusApproved');
  String get payoutStatusRejected => get('payoutStatusRejected');
  String get payoutPendingNotice => get('payoutPendingNotice');
  String get payoutCompletedNotice => get('payoutCompletedNotice');
  String get payoutRejectedNotice => get('payoutRejectedNotice');
  String get rejectionReasonLabel => get('rejectionReasonLabel');
  String get transferReferenceLabel => get('transferReferenceLabel');
  String get noPayoutRequests => get('noPayoutRequests');
  String get noPayoutRequestsSubtitle => get('noPayoutRequestsSubtitle');
  String get viewPayoutHistory => get('viewPayoutHistory');
  String get requestDateLabel => get('requestDateLabel');
  String get executionDateLabel => get('executionDateLabel');
  String get accountDetailsLabel => get('accountDetailsLabel');
  String get accountHolderNameLabel => get('accountHolderNameLabel');

  // البطاقات البنكية المحفوظة
  String get savedCards => get('savedCards');
  String get addCard => get('addCard');
  String get noSavedCards => get('noSavedCards');
  String get noSavedCardsDesc => get('noSavedCardsDesc');
  String get defaultCard => get('defaultCard');
  String get setAsDefault => get('setAsDefault');
  String get deleteCard => get('deleteCard');
  String get deleteCardConfirm => get('deleteCardConfirm');
  String get delete => get('delete');
  String get cardAddedSuccess => get('cardAddedSuccess');
  String get cardDeleteSuccess => get('cardDeleteSuccess');
  String get oneClickSettlement => get('oneClickSettlement');
  String get payWithOtherMethod => get('payWithOtherMethod');
  String get cardHolderName => get('cardHolderName');
  String get setDefaultCardSwitch => get('setDefaultCardSwitch');
}


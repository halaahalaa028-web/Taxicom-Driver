import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/app_constants.dart';

/// نتيجة معالجة الدفع عبر ورقة Stripe أو البطاقة المحفوظة
class DriverPaymentResult {
  final bool success;
  final String? errorMessage;
  final bool isCanceled;
  final String? transactionReference;

  const DriverPaymentResult({
    required this.success,
    this.errorMessage,
    this.isCanceled = false,
    this.transactionReference,
  });
}

/// خدمة الدفع الرسمية عبر بوابة Stripe لتطبيق السائق (تسديد المديونية وحفظ البطاقات)
class StripePaymentService {
  static final StripePaymentService instance = StripePaymentService._();
  StripePaymentService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  /// تهيئة Stripe بالمفتاح العام
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Stripe.publishableKey = AppConstants.stripePublishableKey;
      Stripe.merchantIdentifier = 'merchant.com.taxicom.app.driver';
      await Stripe.instance.applySettings();
      _isInitialized = true;
      debugPrint('💳 [DriverStripeService] Stripe initialized successfully.');
    } catch (e) {
      debugPrint('❌ [DriverStripeService] Stripe initialization failed: $e');
    }
  }

  /// طلب جلسة دفع PaymentIntent من دوال الفايربيس السحابية الآمنة
  Future<Map<String, dynamic>?> createPaymentIntentData({
    required double amount,
    required String currency,
    required String driverId,
    String? paymentMethodId,
    String? driverName,
    String? driverEmail,
    String? driverPhone,
    String purpose = 'commission_settlement',
  }) async {
    _lastErrorMessage = null;
    try {
      final callable = _functions.httpsCallable(
        'createStripePaymentIntent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'amount': amount,
        'currency': currency,
        'userId': driverId,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        'userName': driverName,
        'userEmail': driverEmail,
        'userPhone': driverPhone,
        'userType': 'driver',
        'purpose': purpose,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ [DriverStripeService] PaymentIntent created: ${data['paymentIntentId']}');
      return data;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _lastErrorMessage = e.message ?? e.details?.toString();
      } else {
        _lastErrorMessage = e.toString();
      }
      debugPrint('❌ [DriverStripeService] createPaymentIntent error: $e');
      return null;
    }
  }

  /// طلب جلسة دفع PaymentIntent وإرجاع clientSecret (للتوافق)
  Future<String?> createPaymentIntent({
    required double amount,
    required String currency,
    required String driverId,
    String? driverName,
    String? driverPhone,
    String purpose = 'commission_settlement',
  }) async {
    final data = await createPaymentIntentData(
      amount: amount,
      currency: currency,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      purpose: purpose,
    );
    return data?['clientSecret'] as String?;
  }

  /// إنشاء SetupIntent لحفظ وتشفير بطاقة السائق عبر Cloud Functions (PCI-DSS)
  Future<String?> createSetupIntent({
    required String driverId,
    String? driverName,
    String? driverEmail,
  }) async {
    _lastErrorMessage = null;
    try {
      final callable = _functions.httpsCallable(
        'createStripeSetupIntent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'userId': driverId,
        'userName': driverName,
        'userEmail': driverEmail,
      });

      final data = Map<String, dynamic>.from(result.data);
      final clientSecret = data['clientSecret'] as String?;
      debugPrint('✅ [DriverStripeService] SetupIntent received: ${data['setupIntentId']}');
      return clientSecret;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _lastErrorMessage = e.message ?? e.details?.toString();
      } else {
        _lastErrorMessage = e.toString();
      }
      debugPrint('❌ [DriverStripeService] createSetupIntent error: $e');
      return null;
    }
  }

  /// ربط وسيلة الدفع المشفرة بحساب السائق في Stripe
  Future<bool> attachPaymentMethodToCustomer({
    required String paymentMethodId,
    required String driverId,
    String? driverName,
    String? driverEmail,
    String? driverPhone,
  }) async {
    try {
      final callable = _functions.httpsCallable('attachStripePaymentMethod');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'paymentMethodId': paymentMethodId,
        'userId': driverId,
        'userName': driverName,
        'userEmail': driverEmail,
        'userPhone': driverPhone,
        'userType': 'driver',
      });

      final data = Map<String, dynamic>.from(result.data);
      return data['success'] == true;
    } catch (e) {
      debugPrint('⚠️ [DriverStripeService] attachPaymentMethod exception: $e');
      return false;
    }
  }

  /// فصل وسيلة الدفع من حساب السائق في Stripe عند حذفها
  Future<bool> detachPaymentMethodFromCustomer({
    required String paymentMethodId,
    required String driverId,
  }) async {
    try {
      final callable = _functions.httpsCallable('detachStripePaymentMethod');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'paymentMethodId': paymentMethodId,
        'userId': driverId,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ [DriverStripeService] Payment method detached from Stripe: $paymentMethodId');
      return data['success'] == true;
    } catch (e) {
      debugPrint('⚠️ [DriverStripeService] detachPaymentMethod exception: $e');
      return false;
    }
  }

  /// إعداد وتجهيز ورقة الدفع الرسمية (Payment Sheet)
  Future<bool> setupPaymentSheet({
    required String clientSecret,
    String? customerId,
    String? customerEphemeralKeySecret,
  }) async {
    try {
      await initialize();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          merchantDisplayName: 'Taxicom Driver Settlement',
          allowsDelayedPaymentMethods: false,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF000000),
            ),
          ),
        ),
      );

      debugPrint('💳 [DriverStripeService] PaymentSheet initialized.');
      return true;
    } catch (e) {
      debugPrint('❌ [DriverStripeService] setupPaymentSheet error: $e');
      return false;
    }
  }

  /// عرض ورقة الدفع على شاشة الهاتف
  Future<bool> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      debugPrint('✅ [DriverStripeService] Payment Sheet completed successfully.');
      return true;
    } on StripeException catch (e) {
      debugPrint('⚠️ [DriverStripeService] StripeException: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('❌ [DriverStripeService] presentPaymentSheet error: $e');
      return false;
    }
  }

  /// تسديد المديونية بنقرة واحدة عبر بطاقة السائق المحفوظة (1-Click Debt Settlement)
  Future<DriverPaymentResult> processDebtSettlementWithSavedCard({
    required double amount,
    required String currency,
    required String driverId,
    required String paymentMethodId,
    String? driverName,
    String? driverEmail,
    String? driverPhone,
  }) async {
    try {
      final data = await createPaymentIntentData(
        amount: amount,
        currency: currency,
        driverId: driverId,
        paymentMethodId: paymentMethodId,
        driverName: driverName,
        driverEmail: driverEmail,
        driverPhone: driverPhone,
        purpose: 'commission_settlement',
      );

      if (data == null) {
        return DriverPaymentResult(
          success: false,
          errorMessage: _lastErrorMessage ?? 'تعذر الاتصال بدوال المدفوعات السحابية لمعالجة السداد الفوري',
        );
      }

      final status = data['status'] as String?;
      final clientSecret = data['clientSecret'] as String?;
      final paymentIntentId = data['paymentIntentId'] as String?;

      if (status == 'succeeded') {
        debugPrint('✅ [DriverStripeService] Saved card charged successfully: $paymentIntentId');
        return DriverPaymentResult(
          success: true,
          transactionReference: paymentIntentId,
        );
      } else if (status == 'requires_action' && clientSecret != null) {
        debugPrint('🔐 [DriverStripeService] 3D Secure verification required for saved card');
        try {
          await initialize();
          await Stripe.instance.handleNextAction(clientSecret);
          return DriverPaymentResult(
            success: true,
            transactionReference: paymentIntentId,
          );
        } on StripeException catch (e) {
          if (e.error.code == FailureCode.Canceled) {
            return const DriverPaymentResult(success: false, isCanceled: true);
          }
          return DriverPaymentResult(
            success: false,
            errorMessage: e.error.localizedMessage ?? 'فشلت مصادقة البنك',
          );
        } catch (e) {
          return DriverPaymentResult(success: false, errorMessage: e.toString());
        }
      }

      return DriverPaymentResult(
        success: false,
        errorMessage: _lastErrorMessage ?? 'لم تكتمل عملية الخصم من البطاقة المحفوظة',
      );
    } catch (e) {
      debugPrint('❌ [DriverStripeService] processDebtSettlementWithSavedCard error: $e');
      return DriverPaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// تنفيذ كامل لعملية تسديد المديونية عبر ورقة Stripe التفاعلية (PaymentSheet)
  Future<DriverPaymentResult> processDebtSettlementPayment({
    required double amount,
    required String currency,
    required String driverId,
    String? driverName,
    String? driverPhone,
  }) async {
    try {
      final data = await createPaymentIntentData(
        amount: amount,
        currency: currency,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
        purpose: 'commission_settlement',
      );

      if (data == null || (data['clientSecret'] as String?)?.isEmpty == true) {
        return DriverPaymentResult(
          success: false,
          errorMessage: _lastErrorMessage ?? 'تعذر الاتصال بدوال المدفوعات السحابية لإنشاء جلسة التسديد',
        );
      }

      final clientSecret = data['clientSecret'] as String;
      final customerId = data['customerId'] as String?;
      final ephemeralKey = data['ephemeralKeySecret'] as String?;

      final initialized = await setupPaymentSheet(
        clientSecret: clientSecret,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
      );

      if (!initialized) {
        return const DriverPaymentResult(
          success: false,
          errorMessage: 'فشل في تهيئة نافذة الدفع',
        );
      }

      final success = await presentPaymentSheet();
      if (success) {
        return DriverPaymentResult(
          success: true,
          transactionReference: data['paymentIntentId'] as String?,
        );
      } else {
        return const DriverPaymentResult(
          success: false,
          errorMessage: 'تم إلغاء عملية الدفع أو لم تكتمل',
          isCanceled: true,
        );
      }
    } catch (e) {
      debugPrint('❌ [DriverStripeService] processDebtSettlementPayment error: $e');
      return DriverPaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

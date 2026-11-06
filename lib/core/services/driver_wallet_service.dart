/// خدمة إدارة محفظة السائق والمعاملات المالية وسحب الأرباح وتسديد المديونية
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../features/trips/models/trip_request_model.dart';
import '../../features/wallet/data/models/driver_wallet_model.dart';
import 'country_service.dart';
import 'stripe_payment_service.dart';
import 'models/trip_payment_results.dart';
export 'models/trip_payment_results.dart';

class DriverWalletService {
  DriverWalletService._();

  static final DriverWalletService instance = DriverWalletService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _walletsRef =>
      _firestore.collection('wallets');

  DriverWalletModel _fallbackWallet(String driverId) {
    final country = CountryService.instance.selectedCountry;
    return DriverWalletModel.initial(driverId, countryCode: country.code, currency: country.currencyAr);
  }

  /// الاستماع المباشر لتحديثات محفظة السائق
  Stream<DriverWalletModel> streamWallet(String driverId) {
    return _walletsRef.doc(driverId).snapshots().map((snap) =>
        (snap.exists && snap.data() != null) ? DriverWalletModel.fromMap(snap.data()!, driverId) : _fallbackWallet(driverId));
  }

  /// جلب بيانات المحفظة مرة واحدة
  Future<DriverWalletModel> getWallet(String driverId) async {
    try {
      final doc = await _walletsRef.doc(driverId).get();
      if (!doc.exists || doc.data() == null) return _fallbackWallet(driverId);
      return DriverWalletModel.fromMap(doc.data()!, driverId);
    } catch (e) {
      debugPrint('❌ [DriverWalletService] خطأ في جلب المحفظة: $e');
      return _fallbackWallet(driverId);
    }
  }

  /// الاستماع لسجل المعاملات المالية الحديثة للسائق (الدفعة الأولى 10 معاملات)
  Stream<List<WalletTransactionModel>> streamTransactions(
    String driverId, {
    int limit = 10,
  }) {
    return _walletsRef
        .doc(driverId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WalletTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// جلب الدفعة الأولى من المعاملات مع مؤشر الوثيقة (Cursor)
  Future<({List<WalletTransactionModel> items, DocumentSnapshot? lastDoc, bool hasMore})> fetchInitialTransactions(
    String driverId, {
    int pageSize = 10,
  }) async {
    try {
      final query = await _walletsRef
          .doc(driverId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(pageSize)
          .get();

      final items = query.docs
          .map((doc) => WalletTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      final lastDoc = query.docs.isNotEmpty ? query.docs.last : null;
      final hasMore = query.docs.length == pageSize;

      return (items: items, lastDoc: lastDoc, hasMore: hasMore);
    } catch (e) {
      debugPrint('❌ [DriverWalletService] خطأ في جلب المعاملات: $e');
      return (items: <WalletTransactionModel>[], lastDoc: null, hasMore: false);
    }
  }

  /// جلب الدفعة التالية من المعاملات الأقدم (Pagination)
  Future<({List<WalletTransactionModel> items, DocumentSnapshot? lastDoc, bool hasMore})> fetchMoreTransactions(
    String driverId, {
    required DocumentSnapshot lastDoc,
    int pageSize = 10,
  }) async {
    try {
      final query = await _walletsRef
          .doc(driverId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDoc)
          .limit(pageSize)
          .get();

      final items = query.docs
          .map((doc) => WalletTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      final newLastDoc = query.docs.isNotEmpty ? query.docs.last : lastDoc;
      final hasMore = query.docs.length == pageSize;

      return (items: items, lastDoc: newLastDoc, hasMore: hasMore);
    } catch (e) {
      debugPrint('❌ [DriverWalletService] خطأ في جلب المزيد من المعاملات: $e');
      return (items: <WalletTransactionModel>[], lastDoc: lastDoc, hasMore: false);
    }
  }

  /// تنفيذ الحجز المالي المسبق للبطاقة عند قبول الرحلة (Pre-Auth Hold)
  Future<TripHoldResult> holdTripPayment({
    required String tripId,
    required String passengerId,
    String? paymentMethodId,
    required double amount,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'holdTripPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'tripId': tripId,
        'passengerId': passengerId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (data['success'] == true) {
        debugPrint('✅ [DriverWalletService] تم الحجز المالي المسبق للبطاقة بنجاح: $data');
        return TripHoldResult(
          success: true,
          paymentIntentId: data['paymentIntentId'] as String?,
        );
      } else if (data['fallbackToCash'] == true) {
        debugPrint('⚠️ [DriverWalletService] تعذر الحجز المالي، التحويل للنقد: ${data['message']}');
        return TripHoldResult(
          success: false,
          fallbackToCash: true,
          errorMessage: data['message'] as String? ?? 'تعذر حجز مبلغ الرحلة من بطاقة الراكب',
          reason: data['reason'] as String?,
        );
      } else {
        return TripHoldResult(
          success: false,
          errorMessage: data['message'] as String? ?? 'حدث خطأ في عملية الحجز المالي',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [DriverWalletService] خطأ اتصال في دالة الحجز المالي: $e');
      return const TripHoldResult(
        success: false,
        fallbackToCash: true,
        errorMessage: 'تعذر التحقق من بطاقة الراكب. تم تحويل الرحلة تلقائياً إلى الدفع النقدي.',
      );
    }
  }

  /// فك الحجز المالي المسبق للبطاقة عند إلغاء الرحلة (Release Pre-Auth Hold)
  Future<bool> releaseTripHoldPayment({
    required String tripId,
    String? cancellationReason,
    String cancelledBy = 'driver',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'releaseTripHoldPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'tripId': tripId,
        'cancellationReason': cancellationReason ?? 'cancelled_by_driver',
        'cancelledBy': cancelledBy,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ [DriverWalletService] نتيجة فك الحجز المالي للبطاقة: $data');
      return data['success'] == true;
    } catch (e) {
      debugPrint('⚠️ [DriverWalletService] خطأ أثناء استدعاء فك الحجز المالي: $e');
      return false;
    }
  }

  /// معالجة الحسابات المالية واستقطاع العمولة وإنهاء الرحلة ذرياً في السيرفر
  /// 
  /// - للرحلات النقدية: يستقطع السيرفر عمولة المنصة 15% ذرياً وينهي الرحلة في Firestore
  /// - للرحلات الإلكترونية: يخصم السيرفر بطاقة/محفظة الراكب ويودع صافي 85% في محفظة السائق وينهي الرحلة ذرياً
  /// - في حال تعذر الخصم الإلكتروني: يعيد نتيجة fallbackToCash للمطالبة بالكاش دون إغلاق الرحلة مجاناً
  Future<TripCompletionResult> processTripCompletion({
    required TripRequestModel trip,
    required String driverId,
    required double totalFare,
    required bool isCash,
    String? forcedPaymentMethod,
  }) async {
    try {
      final country = CountryService.instance.selectedCountry;
      final currency = trip.currency ?? country.currencyAr;
      final method = forcedPaymentMethod ??
          (isCash ? 'cash' : (trip.paymentMethod.isNotEmpty ? trip.paymentMethod : 'cash'));

      final callable = _functions.httpsCallable(
        'chargeTripPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'tripId': trip.id,
        'passengerId': trip.passengerId,
        'driverId': driverId,
        'amount': totalFare,
        'currency': currency,
        'paymentMethod': method,
        'paymentMethodId': trip.paymentMethodId,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (data['success'] == true) {
        debugPrint('✅ [DriverWalletService] تم إنهاء الرحلة والتسوية المالية ذرياً بنجاح: $data');
        return TripCompletionResult(
          success: true,
          driverEarnings: (data['driverEarnings'] as num?)?.toDouble(),
          platformCommission: (data['platformCommission'] as num?)?.toDouble(),
        );
      } else if (data['fallbackToCash'] == true) {
        debugPrint('⚠️ [DriverWalletService] تعذر الدفع الإلكتروني، التحويل للنقد: ${data['message']}');
        return TripCompletionResult(
          success: false,
          fallbackToCash: true,
          errorMessage: data['message'] as String? ?? 'تعذر الخصم الإلكتروني من الراكب',
          reason: data['reason'] as String?,
        );
      } else {
        debugPrint('❌ [DriverWalletService] فشل إنهاء الرحلة والتسوية: ${data['error']}');
        return TripCompletionResult(
          success: false,
          errorMessage: data['error'] as String? ?? data['message'] as String? ?? 'حدث خطأ في تسوية الرحلة',
        );
      }
    } catch (e) {
      debugPrint('❌ [DriverWalletService] خطأ اتصال في دالة إنهاء الرحلة: $e');
      return TripCompletionResult(
        success: false,
        errorMessage: 'تعذر الاتصال بالخادم لإنهاء الرحلة وتسوية الحسابات. يرجى التحقق من اتصال الإنترنت والمحاولة ثانية.',
      );
    }
  }

  /// تسديد مديونية السائق أو شحن المحفظة (بالبطاقة المحفوظة بنقرة واحدة أو عبر PaymentSheet)
  Future<DriverPaymentResult> payDebt({
    required String driverId,
    required double amount,
    String? paymentMethodId,
    String? driverName,
    String? driverEmail,
    String? driverPhone,
  }) async {
    if (amount <= 0 || driverId.isEmpty) {
      return const DriverPaymentResult(success: false, errorMessage: 'المبلغ غير صالح');
    }

    try {
      final country = CountryService.instance.selectedCountry;
      final wallet = await getWallet(driverId);
      final currency = wallet.currency.isNotEmpty
          ? wallet.currency
          : country.currencyAr;

      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        return await StripePaymentService.instance.processDebtSettlementWithSavedCard(
          amount: amount,
          currency: currency,
          driverId: driverId,
          paymentMethodId: paymentMethodId,
          driverName: driverName,
          driverEmail: driverEmail,
          driverPhone: driverPhone,
        );
      }

      return await StripePaymentService.instance.processDebtSettlementPayment(
        amount: amount,
        currency: currency,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
      );
    } catch (e) {
      debugPrint('❌ [DriverWalletService] payDebt error: $e');
      return DriverPaymentResult(success: false, errorMessage: e.toString());
    }
  }

  /// تسديد مديونية السائق عبر Stripe PaymentSheet (للتوافق)
  Future<bool> payDebtWithStripe({
    required String driverId,
    required double amount,
    String? driverName,
    String? driverPhone,
  }) async {
    final res = await payDebt(
      driverId: driverId,
      amount: amount,
      driverName: driverName,
      driverPhone: driverPhone,
    );
    return res.success;
  }

  /// طلب سحب أرباح مستحقة للسائق ذرياً عبر الدالة السحابية مع تجميد المبلغ فورياً
  Future<bool> requestPayout({
    required String driverId,
    required double amount,
    required String payoutMethod,
    required String accountDetails,
    required String accountHolderName,
  }) async {
    if (amount <= 0 || driverId.isEmpty) return false;

    try {
      final callable = _functions.httpsCallable(
        'requestDriverPayout',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'driverId': driverId,
        'amount': amount,
        'payoutMethod': payoutMethod,
        'accountDetails': accountDetails,
        'accountHolderName': accountHolderName,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (data['success'] == true) {
        debugPrint('✅ [DriverWalletService] تم طلب سحب الأرباح وتجميد الرصيد سحابياً: ${data['requestId']}');
        return true;
      } else {
        debugPrint('❌ [DriverWalletService] فشل طلب سحب الأرباح: ${data['error'] ?? data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [DriverWalletService] خطأ في طلب سحب الأرباح: $e');
      return false;
    }
  }

  /// الاستماع اللحظي لسجل طلبات سحب الأرباح الخاصة بالسائق
  Stream<List<PayoutRequestModel>> streamPayoutRequests(String driverId) {
    return _firestore
        .collection('payout_requests')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PayoutRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// جلب قائمة طلبات سحب الأرباح مرة واحدة
  Future<List<PayoutRequestModel>> getPayoutRequests(String driverId) async {
    try {
      final snap = await _firestore
          .collection('payout_requests')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((doc) => PayoutRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting payout requests: $e');
      return [];
    }
  }
}

/// متحكم إدارة حالة محفظة السائق
///
/// يدير حالة رصيد السائق، تدفق المعاملات المالية، البطاقات المحفوظة،
/// تسديد المديونية الفوري، وطلبات سحب الأرباح مع التحديث اللحظي
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/country_service.dart';
import '../../../../core/services/driver_cards_service.dart';
import '../../../../core/services/driver_commission_service.dart';
import '../../../../core/services/driver_wallet_service.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../data/models/driver_wallet_model.dart';
import '../../data/models/saved_card_model.dart';

class DriverWalletController extends ChangeNotifier {
  final DriverWalletService _walletService = DriverWalletService.instance;
  final DriverCardsService _cardsService = DriverCardsService.instance;
  final DriverCommissionService _commissionService = DriverCommissionService.instance;

  StreamSubscription<DriverWalletModel>? _walletSubscription;
  StreamSubscription<List<WalletTransactionModel>>? _transactionsSubscription;
  StreamSubscription<List<SavedCardModel>>? _cardsSubscription;

  DriverWalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  final List<WalletTransactionModel> _pageOneTransactions = [];
  final List<WalletTransactionModel> _olderTransactions = [];
  DocumentSnapshot? _lastTransactionDoc;
  bool _hasMoreTransactions = true;
  bool _isLoadingMoreTransactions = false;

  List<SavedCardModel> _savedCards = [];

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  WalletTransactionFilter _selectedFilter = WalletTransactionFilter.all;

  DriverWalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  List<SavedCardModel> get savedCards => _savedCards;
  SavedCardModel? get defaultCard => _savedCards.cast<SavedCardModel?>().firstWhere(
        (c) => c?.isDefault == true,
        orElse: () => _savedCards.isNotEmpty ? _savedCards.first : null,
      );

  WalletTransactionFilter get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get isLoadingMoreTransactions => _isLoadingMoreTransactions;

  /// تغيير فلتر تصفية المعاملات
  void setFilter(WalletTransactionFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  /// قائمة المعاملات المصفاة بحسب الفلتر المختار
  List<WalletTransactionModel> get filteredTransactions {
    if (_selectedFilter == WalletTransactionFilter.all) {
      return _transactions;
    }
    return _transactions.where((tx) {
      switch (_selectedFilter) {
        case WalletTransactionFilter.all:
          return true;
        case WalletTransactionFilter.earnings:
          return tx.type == WalletTransactionType.tripEarning;
        case WalletTransactionFilter.commissions:
          return tx.type == WalletTransactionType.tripCommission;
        case WalletTransactionFilter.debtPayments:
          return tx.type == WalletTransactionType.debtPayment;
        case WalletTransactionFilter.payouts:
          return tx.type == WalletTransactionType.payout;
      }
    }).toList();
  }

  /// حساب عدد المعاملات المطابقة لكل تصنيف تصفية
  int getTransactionCount(WalletTransactionFilter filter) {
    if (filter == WalletTransactionFilter.all) {
      return _transactions.length;
    }
    return _transactions.where((tx) {
      switch (filter) {
        case WalletTransactionFilter.all:
          return true;
        case WalletTransactionFilter.earnings:
          return tx.type == WalletTransactionType.tripEarning;
        case WalletTransactionFilter.commissions:
          return tx.type == WalletTransactionType.tripCommission;
        case WalletTransactionFilter.debtPayments:
          return tx.type == WalletTransactionType.debtPayment;
        case WalletTransactionFilter.payouts:
          return tx.type == WalletTransactionType.payout;
      }
    }).length;
  }

  /// دمج وإلغاء تكرار المعاملات
  void _updateCombinedTransactions() {
    final Map<String, WalletTransactionModel> map = {};
    for (final tx in _pageOneTransactions) {
      map[tx.id] = tx;
    }
    for (final tx in _olderTransactions) {
      map[tx.id] = tx;
    }
    _transactions = map.values.toList();
    notifyListeners();
  }

  /// مقدار المديونية الحالية
  double get currentDebt => _wallet?.currentDebt ?? 0.0;

  /// رصيد الأرباح المتاح
  double get availableEarnings => _wallet?.availableEarnings ?? 0.0;

  /// العملة الحالية
  String get currency => _wallet?.currency.isNotEmpty == true
      ? _wallet!.currency
      : CountryService.instance.selectedCountry.currencyAr;

  /// كود الدولة الحالية
  String get countryCode => _wallet?.countryCode ?? CountryService.instance.selectedCountry.code;

  /// فحص حالة المديونية
  DriverDebtStatus get debtStatus => _commissionService.checkDebtStatus(
        currentDebt: currentDebt,
        countryCode: countryCode,
      );

  /// هل السائق محظور بسبب تجاوز سقف المديونية
  bool get isBlocked => debtStatus.isBlocked;

  /// هل السائق اقترب من سقف المديونية (تحذير)
  bool get isWarning => debtStatus.isWarning;

  /// بدء الاستماع لبيانات المحفظة وسجل المعاملات والبطاقات المحفوظة
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _walletSubscription?.cancel();
    _walletSubscription = _walletService.streamWallet(user.uid).listen(
      (walletData) {
        _wallet = walletData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _walletService.streamTransactions(user.uid, limit: 10).listen(
      (txList) {
        _pageOneTransactions.clear();
        _pageOneTransactions.addAll(txList);
        if (_olderTransactions.isEmpty) {
          _hasMoreTransactions = txList.length == 10;
        }
        _updateCombinedTransactions();
      },
      onError: (e) {
        debugPrint('❌ [DriverWalletController] خطأ في سجل المعاملات: $e');
      },
    );

    _cardsSubscription?.cancel();
    _cardsSubscription = _cardsService.watchSavedCards(user.uid).listen(
      (cards) {
        _savedCards = cards;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('❌ [DriverWalletController] خطأ في جلب البطاقات المحفوظة: $e');
      },
    );

    _fetchInitialCursor(user.uid);
  }

  /// جلب مؤشر الوثيقة للدفعة الأولى
  Future<void> _fetchInitialCursor(String driverId) async {
    final result = await _walletService.fetchInitialTransactions(driverId, pageSize: 10);
    _lastTransactionDoc = result.lastDoc;
    _hasMoreTransactions = result.hasMore;
  }

  /// تحميل المزيد من المعاملات الأقدم عند التمرير للأسفل
  Future<void> loadMoreTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _isLoadingMoreTransactions ||
        !_hasMoreTransactions ||
        _lastTransactionDoc == null) {
      return;
    }

    _isLoadingMoreTransactions = true;
    notifyListeners();

    try {
      final result = await _walletService.fetchMoreTransactions(
        user.uid,
        lastDoc: _lastTransactionDoc!,
        pageSize: 10,
      );

      if (result.items.isEmpty) {
        _hasMoreTransactions = false;
      } else {
        _lastTransactionDoc = result.lastDoc;
        _olderTransactions.addAll(result.items);
        _hasMoreTransactions = result.hasMore;
        _updateCombinedTransactions();
      }
    } catch (e) {
      debugPrint('❌ [DriverWalletController] خطأ في تحميل المزيد من المعاملات: $e');
    } finally {
      _isLoadingMoreTransactions = false;
      notifyListeners();
    }
  }

  /// إعادة تحميل بيانات المحفظة يدوياً
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _olderTransactions.clear();
      _hasMoreTransactions = true;
      _isLoadingMoreTransactions = false;
      _wallet = await _walletService.getWallet(user.uid);
      await _fetchInitialCursor(user.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [DriverWalletController] خطأ في تحديث المحفظة: $e');
    }
  }

  /// إضافة بطاقة بنكية جديدة مشفرة
  Future<bool> addSavedCard(SavedCardModel card) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return await _cardsService.addSavedCard(driverId: user.uid, card: card);
  }

  /// حذف بطاقة بنكية وفصلها من Stripe
  Future<bool> deleteSavedCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return await _cardsService.deleteSavedCard(driverId: user.uid, cardId: cardId);
  }

  /// تعيين بطاقة كافتراضية
  Future<void> setDefaultCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _cardsService.setDefaultCard(driverId: user.uid, cardId: cardId);
  }

  /// تسديد المديونية (بالبطاقة المحفوظة بنقرة واحدة أو عبر نافذة Stripe PaymentSheet)
  Future<DriverPaymentResult> payDebt({
    required double amount,
    String? paymentMethodId,
    String? driverName,
    String? driverEmail,
    String? driverPhone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || amount <= 0) {
      return const DriverPaymentResult(success: false, errorMessage: 'المبلغ غير صالح');
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _walletService.payDebt(
        driverId: user.uid,
        amount: amount,
        paymentMethodId: paymentMethodId,
        driverName: driverName,
        driverEmail: driverEmail,
        driverPhone: driverPhone,
      );

      _isProcessing = false;
      if (!result.success && !result.isCanceled) {
        _errorMessage = result.errorMessage;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return DriverPaymentResult(success: false, errorMessage: e.toString());
    }
  }

  /// طلب سحب أرباح إلكترونية مستحقة
  Future<bool> requestPayout({
    required double amount,
    required String payoutMethod,
    required String accountDetails,
    required String accountHolderName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || amount <= 0) return false;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _walletService.requestPayout(
        driverId: user.uid,
        amount: amount,
        payoutMethod: payoutMethod,
        accountDetails: accountDetails,
        accountHolderName: accountHolderName,
      );

      _isProcessing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _cardsSubscription?.cancel();
    super.dispose();
  }
}

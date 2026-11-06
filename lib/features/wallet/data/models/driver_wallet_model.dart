/// نماذج بيانات محفظة السائق والمعاملات المالية وسحب الأرباح
///
/// تشمل:
/// 1. [DriverWalletModel]: ملخص رصيد المحفظة والمديونية
/// 2. [WalletTransactionModel]: سجل العمليات المالية المفصل لكل مشوار وتسديد
/// 3. [PayoutRequestModel]: طلبات سحب الأرباح المستحقة
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع المعاملة المالية في المحفظة
enum WalletTransactionType {
  /// خصم عمولة المنصة 15% (مشوار كاش)
  tripCommission,

  /// إضافة صافي أرباح السائق 85% (مشوار دفع إلكتروني)
  tripEarning,

  /// تسديد مديونية بواسطة السائق (Stripe)
  debtPayment,

  /// سحب أرباح مستحقة إلى الحساب البنكي / محفظة إلكترونية
  payout,

  /// تسوية أو مكافأة إدارية
  adjustment,
}

/// تصنيف وتصفية المعاملات المالية لمحفظة السائق
enum WalletTransactionFilter {
  /// عرض كافة العمليات المالية
  all,

  /// أرباح الرحلات الإلكترونية (+)
  earnings,

  /// عمولات المنصة المستقطعة (-)
  commissions,

  /// عمليات سداد المديونية
  debtPayments,

  /// طلبات سحب الأرباح
  payouts,
}

/// نموذج محفظة السائق
class DriverWalletModel {
  final String driverId;

  /// رصيد المحفظة:
  /// - إذا كان موجباً (>= 0): يمثل أرباح السائق المتاحة للسحب
  /// - إذا كان سالباً (< 0): يمثل مديونية مستحقة على السائق للمنصة
  final double balance;

  /// مبالغ سحب الأرباح المعلقة قيد المراجعة
  final double pendingPayout;

  /// إجمالي الأرباح التاريخية
  final double totalEarnings;

  /// إجمالي العمولات المسددة للمنصة
  final double totalCommissionPaid;

  /// عدد الرحلات المكتملة
  final int totalTripsCompleted;

  /// كود الدولة
  final String countryCode;

  /// رمز العملة
  final String currency;

  /// تاريخ آخر تحديث
  final DateTime updatedAt;

  const DriverWalletModel({
    required this.driverId,
    this.balance = 0.0,
    this.pendingPayout = 0.0,
    this.totalEarnings = 0.0,
    this.totalCommissionPaid = 0.0,
    this.totalTripsCompleted = 0,
    this.countryCode = 'IQ',
    this.currency = 'د.ع',
    required this.updatedAt,
  });

  /// هل على السائق مديونية مستحقة
  bool get hasDebt => balance < 0;

  /// مقدار المديونية الحالية (قيمة موجبة موجزة)
  double get currentDebt => balance < 0 ? balance.abs() : 0.0;

  /// الرصيد المتاح للسحب (يُمثل الرصيد غير المجمّد بعد خصم المبالغ المعلقة ذرياً)
  double get availableEarnings => balance > 0 ? balance : 0.0;

  /// إنشاء من مستند Firestore
  factory DriverWalletModel.fromMap(Map<String, dynamic> map, String driverId) {
    return DriverWalletModel(
      driverId: driverId,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      pendingPayout: (map['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      totalCommissionPaid: (map['totalCommissionPaid'] as num?)?.toDouble() ?? 0.0,
      totalTripsCompleted: (map['totalTripsCompleted'] as num?)?.toInt() ?? 0,
      countryCode: map['countryCode'] as String? ?? 'IQ',
      currency: map['currency'] as String? ?? 'د.ع',
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// تحويل إلى خريطة Firestore
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'balance': balance,
      'pendingPayout': pendingPayout,
      'totalEarnings': totalEarnings,
      'totalCommissionPaid': totalCommissionPaid,
      'totalTripsCompleted': totalTripsCompleted,
      'countryCode': countryCode,
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// إنشاء كائن أولي جديد لسائق
  factory DriverWalletModel.initial(String driverId, {String countryCode = 'IQ', String currency = 'د.ع'}) {
    return DriverWalletModel(
      driverId: driverId,
      balance: 0.0,
      pendingPayout: 0.0,
      totalEarnings: 0.0,
      totalCommissionPaid: 0.0,
      totalTripsCompleted: 0,
      countryCode: countryCode,
      currency: currency,
      updatedAt: DateTime.now(),
    );
  }
}

/// نموذج المعاملة المالية في سجل المحفظة
class WalletTransactionModel {
  final String id;
  final String driverId;
  final String? tripId;
  final double amount;
  final double? tripFare;
  final double? commissionAmount;
  final WalletTransactionType type;
  final String title;
  final String description;
  final String currency;
  final bool isDebit; // true: خصم / مديونية، false: إضافة / سداد
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.driverId,
    this.tripId,
    required this.amount,
    this.tripFare,
    this.commissionAmount,
    required this.type,
    required this.title,
    required this.description,
    required this.currency,
    required this.isDebit,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransactionModel(
      id: id,
      driverId: map['driverId'] as String? ?? '',
      tripId: map['tripId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      tripFare: (map['tripFare'] as num?)?.toDouble(),
      commissionAmount: (map['commissionAmount'] as num?)?.toDouble(),
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WalletTransactionType.tripCommission,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      currency: map['currency'] as String? ?? 'د.ع',
      isDebit: map['isDebit'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      if (tripId != null) 'tripId': tripId,
      'amount': amount,
      if (tripFare != null) 'tripFare': tripFare,
      if (commissionAmount != null) 'commissionAmount': commissionAmount,
      'type': type.name,
      'title': title,
      'description': description,
      'currency': currency,
      'isDebit': isDebit,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// حالة طلب سحب الأرباح
enum PayoutStatus {
  pending,
  approved,
  rejected,
  completed,
}

/// نموذج طلب سحب الأرباح
class PayoutRequestModel {
  final String id;
  final String driverId;
  final String? driverName;
  final String? driverPhone;
  final double amount;
  final String method; // 'bank_transfer', 'zain_cash', 'wallet', 'manual_transfer'
  final String accountDetails;
  final String accountHolderName;
  final String currency;
  final PayoutStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? note;
  final String? rejectionReason;
  final String? adminNotes;
  final String? transactionReference;

  const PayoutRequestModel({
    required this.id,
    required this.driverId,
    this.driverName,
    this.driverPhone,
    required this.amount,
    required this.method,
    required this.accountDetails,
    required this.accountHolderName,
    required this.currency,
    this.status = PayoutStatus.pending,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
    this.note,
    this.rejectionReason,
    this.adminNotes,
    this.transactionReference,
  });

  bool get isPending => status == PayoutStatus.pending;
  bool get isApproved => status == PayoutStatus.approved || status == PayoutStatus.completed;
  bool get isCompleted => isApproved;
  bool get isRejected => status == PayoutStatus.rejected;

  /// سبب الرفض الفعلي إن وجد
  String? get effectiveRejectionReason => rejectionReason ?? note ?? adminNotes;

  factory PayoutRequestModel.fromMap(Map<String, dynamic> map, String id) {
    final statusStr = map['status'] as String?;
    PayoutStatus parsedStatus;
    if (statusStr == 'approved' || statusStr == 'completed') {
      parsedStatus = PayoutStatus.completed;
    } else if (statusStr == 'rejected') {
      parsedStatus = PayoutStatus.rejected;
    } else {
      parsedStatus = PayoutStatus.pending;
    }

    return PayoutRequestModel(
      id: id,
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String?,
      driverPhone: map['driverPhone'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] as String? ?? map['paymentMethod'] as String? ?? 'bank_transfer',
      accountDetails: map['accountDetails'] as String? ?? '',
      accountHolderName: map['accountHolderName'] as String? ?? '',
      currency: map['currency'] as String? ?? 'د.ع',
      status: parsedStatus,
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: map['processedAt'] != null && map['processedAt'] is Timestamp
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      processedBy: map['processedBy'] as String?,
      note: map['note'] as String?,
      rejectionReason: map['rejectionReason'] as String? ?? map['note'] as String?,
      adminNotes: map['adminNotes'] as String?,
      transactionReference: map['transactionReference'] as String? ??
          map['referenceNumber'] as String? ??
          map['receiptNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      'amount': amount,
      'method': method,
      'paymentMethod': method,
      'accountDetails': accountDetails,
      'accountHolderName': accountHolderName,
      'currency': currency,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt!),
      if (processedBy != null) 'processedBy': processedBy,
      if (note != null) 'note': note,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (transactionReference != null) 'transactionReference': transactionReference,
    };
  }
}

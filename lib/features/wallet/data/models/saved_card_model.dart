import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج البطاقة البنكية المحفوظة للسائق (Driver Saved Card Model)
/// متوافق مع معايير الأمان المصرفي PCI-DSS
class SavedCardModel {
  final String id;
  final String userId;
  final String brand; // Visa, Mastercard, Amex, etc.
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final String? holderName;
  final bool isDefault;
  final String? paymentMethodId; // Stripe PaymentMethod ID
  final DateTime createdAt;

  const SavedCardModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.holderName,
    this.isDefault = false,
    this.paymentMethodId,
    required this.createdAt,
  });

  /// نص منسق لتاريخ انتهاء البطاقة (MM/YY)
  String get formattedExpiry {
    final mm = expiryMonth.toString().padLeft(2, '0');
    final yy = (expiryYear % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  /// رقم البطاقة المقنع (Masked Card Number)
  String get maskedNumber => '\u200E•••• •••• •••• $last4\u200E';

  factory SavedCardModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SavedCardModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      brand: map['brand'] as String? ?? 'Card',
      last4: map['last4'] as String? ?? '****',
      expiryMonth: (map['expiryMonth'] as num?)?.toInt() ?? 1,
      expiryYear: (map['expiryYear'] as num?)?.toInt() ?? 2030,
      holderName: map['holderName'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
      paymentMethodId: map['paymentMethodId'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'brand': brand,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      if (holderName != null) 'holderName': holderName,
      'isDefault': isDefault,
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SavedCardModel copyWith({
    String? id,
    String? userId,
    String? brand,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    String? holderName,
    bool? isDefault,
    String? paymentMethodId,
    DateTime? createdAt,
  }) {
    return SavedCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      holderName: holderName ?? this.holderName,
      isDefault: isDefault ?? this.isDefault,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

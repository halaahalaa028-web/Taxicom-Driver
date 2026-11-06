/// نموذج طلب الرحلة لتطبيق السائق
/// 
/// يمثل بيانات طلب رحلة من راكب مع دعم تعدد البلدان والعملات
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/driver_commission_service.dart';
import '../../chat/models/chat_message_model.dart';
import 'trip_enums.dart';

export 'trip_enums.dart';

/// نموذج طلب الرحلة
class TripRequestModel {
  final String id, passengerId, passengerName, passengerPhone;
  final LatLng pickupLocation, destinationLocation;
  final String pickupAddress, destinationAddress;
  final LatLng? secondDestinationLocation;
  final String? secondDestinationAddress, waitTime, scheduledTime, bookingNote;
  final DateTime? scheduledDate;
  final bool isRoundTrip, paidByReceiver, isPaid;
  final double distance, price;
  final double? originalPrice, discountAmount, commissionRate, commissionAmount, netDriverEarnings;
  final String? couponCode, couponId, currency, countryCode;
  final int? estimatedDuration, numberOfPassengers;
  final TripType tripType;
  final TripStatus status;
  final String? driverId, driverName, driverPhone, driverPhotoUrl;
  final String? carNumber, carModel, carColor, carType;
  final DateTime createdAt, updatedAt;
  final int? passengerRating, driverRating;
  final String? passengerNote, driverNote, cancellationReason;
  final DateTime? passengerRatedAt, driverRatedAt, cancelledByPassengerAt;
  final String? receiverName, receiverPhone, packageDescription, paymentMethodId, startOtp;
  final String paymentMethod;
  final List<ChatMessageModel>? chatMessages;

  TripRequestModel({
    required this.id, required this.passengerId, required this.passengerName, required this.passengerPhone,
    required this.pickupLocation, required this.pickupAddress,
    required this.destinationLocation, required this.destinationAddress,
    this.secondDestinationLocation, this.secondDestinationAddress,
    this.waitTime, this.scheduledDate, this.scheduledTime, this.bookingNote,
    this.isRoundTrip = false, required this.distance, required this.price,
    this.originalPrice, this.discountAmount, this.couponCode, this.couponId,
    this.currency, this.countryCode, this.estimatedDuration, this.numberOfPassengers,
    this.tripType = TripType.ride, this.status = TripStatus.pending,
    this.driverId, this.driverName, this.driverPhone, this.driverPhotoUrl,
    this.carNumber, this.carModel, this.carColor, this.carType,
    DateTime? createdAt, DateTime? updatedAt,
    this.passengerRating, this.passengerNote, this.passengerRatedAt,
    this.driverRating, this.driverNote, this.driverRatedAt,
    this.receiverName, this.receiverPhone, this.packageDescription,
    this.paidByReceiver = false, this.paymentMethod = 'cash', this.paymentMethodId,
    this.isPaid = false, this.startOtp,
    this.commissionRate, this.commissionAmount, this.netDriverEarnings,
    this.cancellationReason, this.cancelledByPassengerAt, this.chatMessages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// هل الرحلة تتضمن خصماً أو كوبوناً ترويجياً
  bool get hasDiscount => discountAmount != null && discountAmount! > 0;

  /// السعر الأصلي الكامل للرحلة قبل أي خصم
  double get effectiveOriginalPrice =>
      originalPrice ?? (hasDiscount ? price + discountAmount! : price);

  /// نسبة عمولة المنصة المعتمدة للرحلة بديناميكية تامة
  double get effectiveCommissionRate {
    if (commissionRate != null) {
      return commissionRate! > 1.0 ? commissionRate! / 100.0 : commissionRate!;
    }
    if (commissionAmount != null && effectiveOriginalPrice > 0) {
      return (commissionAmount! / effectiveOriginalPrice).clamp(0.0, 1.0);
    }
    return DriverCommissionService.instance.currentCommissionRate;
  }

  /// مبلغ عمولة المنصة الفعلي المستقطع من الرحلة
  double get effectiveCommissionAmount =>
      commissionAmount ?? (effectiveOriginalPrice * effectiveCommissionRate);

  /// صافي أرباح السائق المستحقة من الرحلة بعد خصم العمولة
  double get effectiveNetDriverEarnings =>
      netDriverEarnings ?? (effectiveOriginalPrice - effectiveCommissionAmount);

  /// الحصول على عدد الرسائل غير المقروءة للمستخدم الحالي
  int getUnreadMessagesCount(String currentUserId) {
    if (chatMessages == null || chatMessages!.isEmpty) return 0;
    return chatMessages!.where((m) => !m.isRead && m.senderId != currentUserId).length;
  }

  /// إنشاء من Firestore
  factory TripRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    final double? rawCommissionRate = (map['commissionRate'] as num?)?.toDouble() ??
        (map['platformCommissionRate'] as num?)?.toDouble();
    final double? rawCommissionAmount = (map['commissionAmount'] as num?)?.toDouble() ??
        (map['platformCommission'] as num?)?.toDouble();
    final double? rawNetEarnings = (map['netDriverEarnings'] as num?)?.toDouble() ??
        (map['driverEarnings'] as num?)?.toDouble();

    return TripRequestModel(
      id: documentId,
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerPhone: map['passengerPhone'] ?? '',
      pickupLocation: LatLng((map['pickupLat'] ?? 0.0).toDouble(), (map['pickupLng'] ?? 0.0).toDouble()),
      pickupAddress: map['pickupAddress'] ?? '',
      destinationLocation: LatLng((map['destinationLat'] ?? 0.0).toDouble(), (map['destinationLng'] ?? 0.0).toDouble()),
      destinationAddress: map['destinationAddress'] ?? '',
      secondDestinationLocation: map['secondDestinationLat'] != null
          ? LatLng((map['secondDestinationLat'] ?? 0.0).toDouble(), (map['secondDestinationLng'] ?? 0.0).toDouble())
          : null,
      secondDestinationAddress: map['secondDestinationAddress'],
      waitTime: map['waitTime'],
      scheduledDate: map['scheduledDate'] != null ? (map['scheduledDate'] as Timestamp).toDate() : null,
      scheduledTime: map['scheduledTime'],
      bookingNote: map['bookingNote'],
      isRoundTrip: map['isRoundTrip'] ?? false,
      distance: (map['distance'] ?? 0.0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      couponCode: map['couponCode'] as String?,
      couponId: map['couponId'] as String?,
      currency: map['currency'],
      countryCode: map['countryCode'],
      estimatedDuration: (map['estimatedDuration'] as num?)?.toInt(),
      numberOfPassengers: (map['numberOfPassengers'] as num?)?.toInt(),
      tripType: TripType.values.firstWhere(
        (e) => e.name == map['tripType'],
        orElse: () => TripType.ride,
      ),
      status: TripStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TripStatus.pending,
      ),
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      driverPhotoUrl: map['driverPhotoUrl'],
      carNumber: map['carNumber'] as String?,
      carModel: map['carModel'] as String?,
      carColor: map['carColor'] as String?,
      carType: map['carType'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      passengerRating: map['passengerRating'] as int?,
      passengerNote: map['passengerNote'] as String?,
      passengerRatedAt: map['passengerRatedAt'] != null
          ? (map['passengerRatedAt'] as Timestamp).toDate()
          : null,
      driverRating: map['driverRating'] as int?,
      driverNote: map['driverNote'] as String?,
      driverRatedAt: map['driverRatedAt'] != null
          ? (map['driverRatedAt'] as Timestamp).toDate()
          : null,
      receiverName: map['receiverName'],
      receiverPhone: map['receiverPhone'],
      packageDescription: map['packageDescription'],
      paidByReceiver: map['paidByReceiver'] ?? false,
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      paymentMethodId: map['paymentMethodId'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
      startOtp: map['startOtp'] as String?,
      commissionRate: rawCommissionRate,
      commissionAmount: rawCommissionAmount,
      netDriverEarnings: rawNetEarnings,
      cancellationReason: map['cancellationReason'],
      cancelledByPassengerAt: map['cancelledByPassengerAt'] != null
          ? (map['cancelledByPassengerAt'] as Timestamp).toDate()
          : null,
      chatMessages: map['chatMessages'] != null
          ? (map['chatMessages'] as List)
              .map((msg) => ChatMessageModel.fromMap(Map<String, dynamic>.from(msg), msg['id'] ?? ''))
              .toList()
          : null,
    );
  }

  /// تحويل إلى خريطة للحفظ
  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickupLat': pickupLocation.latitude,
      'pickupLng': pickupLocation.longitude,
      'pickupAddress': pickupAddress,
      'destinationLat': destinationLocation.latitude,
      'destinationLng': destinationLocation.longitude,
      'destinationAddress': destinationAddress,
      if (secondDestinationLocation != null) ...{
        'secondDestinationLat': secondDestinationLocation!.latitude,
        'secondDestinationLng': secondDestinationLocation!.longitude,
      },
      if (secondDestinationAddress != null) 'secondDestinationAddress': secondDestinationAddress,
      if (waitTime != null) 'waitTime': waitTime,
      if (scheduledDate != null) 'scheduledDate': Timestamp.fromDate(scheduledDate!),
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
      if (bookingNote != null) 'bookingNote': bookingNote,
      'isRoundTrip': isRoundTrip,
      'distance': distance,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (couponCode != null) 'couponCode': couponCode,
      if (couponId != null) 'couponId': couponId,
      if (currency != null) 'currency': currency,
      if (countryCode != null) 'countryCode': countryCode,
      if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      if (numberOfPassengers != null) 'numberOfPassengers': numberOfPassengers,
      'tripType': tripType.name,
      'status': status.name,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhotoUrl': driverPhotoUrl,
      if (carNumber != null) 'carNumber': carNumber,
      if (carModel != null) 'carModel': carModel,
      if (carColor != null) 'carColor': carColor,
      if (carType != null) 'carType': carType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (passengerRating != null) 'passengerRating': passengerRating,
      if (passengerNote != null) 'passengerNote': passengerNote,
      if (passengerRatedAt != null) 'passengerRatedAt': Timestamp.fromDate(passengerRatedAt!),
      if (driverRating != null) 'driverRating': driverRating,
      if (driverNote != null) 'driverNote': driverNote,
      if (driverRatedAt != null) 'driverRatedAt': Timestamp.fromDate(driverRatedAt!),
      if (receiverName != null) 'receiverName': receiverName,
      if (receiverPhone != null) 'receiverPhone': receiverPhone,
      if (packageDescription != null) 'packageDescription': packageDescription,
      'paidByReceiver': paidByReceiver,
      'paymentMethod': paymentMethod,
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      'isPaid': isPaid,
      if (startOtp != null) 'startOtp': startOtp,
      if (commissionRate != null) 'commissionRate': commissionRate,
      if (commissionAmount != null) 'commissionAmount': commissionAmount,
      if (netDriverEarnings != null) 'netDriverEarnings': netDriverEarnings,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (cancelledByPassengerAt != null) 'cancelledByPassengerAt': Timestamp.fromDate(cancelledByPassengerAt!),
      if (chatMessages != null) 'chatMessages': chatMessages!.map((msg) => msg.toMap()..['id'] = msg.id).toList(),
    };
  }

  /// نسخة محدثة
  TripRequestModel copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    LatLng? pickupLocation,
    String? pickupAddress,
    LatLng? destinationLocation,
    String? destinationAddress,
    LatLng? secondDestinationLocation,
    String? secondDestinationAddress,
    String? waitTime,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? bookingNote,
    bool? isRoundTrip,
    double? distance,
    double? price,
    double? originalPrice,
    double? discountAmount,
    String? couponCode,
    String? couponId,
    String? currency,
    String? countryCode,
    int? estimatedDuration,
    int? numberOfPassengers,
    TripType? tripType,
    TripStatus? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhotoUrl,
    String? carNumber,
    String? carModel,
    String? carColor,
    String? carType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? passengerRating,
    String? passengerNote,
    DateTime? passengerRatedAt,
    int? driverRating,
    String? driverNote,
    DateTime? driverRatedAt,
    String? receiverName,
    String? receiverPhone,
    String? packageDescription,
    bool? paidByReceiver,
    String? paymentMethod,
    String? paymentMethodId,
    bool? isPaid,
    String? startOtp,
    double? commissionRate,
    double? commissionAmount,
    double? netDriverEarnings,
    String? cancellationReason,
    DateTime? cancelledByPassengerAt,
    List<ChatMessageModel>? chatMessages,
  }) {
    return TripRequestModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      secondDestinationLocation: secondDestinationLocation ?? this.secondDestinationLocation,
      secondDestinationAddress: secondDestinationAddress ?? this.secondDestinationAddress,
      waitTime: waitTime ?? this.waitTime,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      bookingNote: bookingNote ?? this.bookingNote,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      distance: distance ?? this.distance,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      couponCode: couponCode ?? this.couponCode,
      couponId: couponId ?? this.couponId,
      currency: currency ?? this.currency,
      countryCode: countryCode ?? this.countryCode,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      numberOfPassengers: numberOfPassengers ?? this.numberOfPassengers,
      tripType: tripType ?? this.tripType,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      carNumber: carNumber ?? this.carNumber,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      carType: carType ?? this.carType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      passengerRating: passengerRating ?? this.passengerRating,
      passengerNote: passengerNote ?? this.passengerNote,
      passengerRatedAt: passengerRatedAt ?? this.passengerRatedAt,
      driverRating: driverRating ?? this.driverRating,
      driverNote: driverNote ?? this.driverNote,
      driverRatedAt: driverRatedAt ?? this.driverRatedAt,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      packageDescription: packageDescription ?? this.packageDescription,
      paidByReceiver: paidByReceiver ?? this.paidByReceiver,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      isPaid: isPaid ?? this.isPaid,
      startOtp: startOtp ?? this.startOtp,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      netDriverEarnings: netDriverEarnings ?? this.netDriverEarnings,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledByPassengerAt: cancelledByPassengerAt ?? this.cancelledByPassengerAt,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

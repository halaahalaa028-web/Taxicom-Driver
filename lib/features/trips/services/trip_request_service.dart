/// خدمة طلبات الرحلات للسائق
/// 
/// توفر وظائف التعامل مع طلبات الرحلات في Firestore وإدارة حالاتها
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../models/trip_request_model.dart';

/// خدمة طلبات الرحلات للسائق
class TripRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  TripRequestService._();
  static final TripRequestService _instance = TripRequestService._();
  static TripRequestService get instance => _instance;

  CollectionReference get _tripsCollection =>
      _firestore.collection(AppConstants.tripsCollection);

  /// حساب السعر التقديري للرحلة
  double calculatePrice(
    double distanceKm, {
    String? waitTime,
    bool isRoundTrip = false,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    LatLng? secondDestinationLocation,
    String? countryCode,
  }) {
    double finalDistance = distanceKm;
    if (pickupLocation != null && destinationLocation != null) {
      finalDistance = getCappedDistance(
        googleDistance: distanceKm,
        pickup: pickupLocation,
        destination: destinationLocation,
        secondDestination: secondDestinationLocation,
      );
    }

    return TripCalculationHelper.calculatePrice(
      finalDistance,
      waitTime: waitTime,
      isRoundTrip: isRoundTrip,
      countryCode: countryCode,
    );
  }

  /// الحصول على المسافة المحددة (Capped Distance) بناءً على صيغة Haversine
  double getCappedDistance({
    required double googleDistance,
    required LatLng pickup,
    required LatLng destination,
    LatLng? secondDestination,
  }) => TripCalculationHelper.getCappedDistance(
    googleDistance: googleDistance,
    pickup: pickup,
    destination: destination,
    secondDestination: secondDestination,
  );

  /// الحصول على الرحلة النشطة للسائق
  Future<TripRequestModel?> getActiveTripForDriver() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final snapshot = await _tripsCollection
        .where('driverId', isEqualTo: user.uid)
        .where('status', whereIn: [
          TripStatus.accepted.name,
          TripStatus.arrivedAtPickup.name,
          TripStatus.pickedUp.name,
        ])
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return TripRequestModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
  }

  /// الحصول على إحصائيات السائق لليوم (الرحلات والأرباح)
  Future<Map<String, dynamic>> getDriverTodayStats(String driverId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _tripsCollection
        .where('driverId', isEqualTo: driverId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
        
    int tripCount = 0;
    double totalEarnings = 0.0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statusStr = data['status'] as String?;
      tripCount++;
      
      if (statusStr == TripStatus.completed.name) {
        final trip = TripRequestModel.fromMap(data, doc.id);
        totalEarnings += trip.effectiveNetDriverEarnings;
      }
    }
    
    return {'count': tripCount, 'earnings': totalEarnings};
  }

  /// الحصول على إحصائيات أعداد رحلات السائق
  Future<Map<String, int>> getDriverTripsCounts(String driverId) async {
    try {
      final allQuery = _tripsCollection.where('driverId', isEqualTo: driverId);
      final completedQuery = allQuery.where('status', isEqualTo: TripStatus.completed.name);
      final cancelledQuery = allQuery.where('status', whereIn: [
        TripStatus.cancelled.name,
        TripStatus.cancelledByDriver.name,
      ]);

      final results = await Future.wait([
        allQuery.count().get(),
        completedQuery.count().get(),
        cancelledQuery.count().get(),
      ]);

      return {
        'all': results[0].count ?? 0,
        'completed': results[1].count ?? 0,
        'cancelled': results[2].count ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting driver trips counts: $e');
      return {'all': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  /// الحصول على سجل رحلات السائق مع التصفح (Pagination)
  Future<List<DocumentSnapshot>> getDriverTripsHistory({
    required String driverId,
    String? statusFilter,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _tripsCollection.where('driverId', isEqualTo: driverId);

    if (statusFilter == 'completed') {
      query = query.where('status', isEqualTo: TripStatus.completed.name);
    } else if (statusFilter == 'cancelled') {
      query = query.where('status', whereIn: [
        TripStatus.cancelled.name,
        TripStatus.cancelledByDriver.name,
      ]);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final QuerySnapshot snapshot = await query.get();
    return snapshot.docs;
  }

  /// الاستماع لحالة طلب معين
  Stream<TripRequestModel?> watchTripRequest(String tripId) {
    return _tripsCollection.doc(tripId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return TripRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// الاستماع للطلبات القريبة (للسائق)
  Stream<List<TripRequestModel>> watchNearbyRequests({
    required LatLng Function() getDriverLocation,
    double radiusKm = 10.0,
    String? countryCode,
  }) {
    Query query = _tripsCollection.where('status', isEqualTo: TripStatus.pending.name);
    if (countryCode != null && countryCode.isNotEmpty) {
      query = query.where('countryCode', isEqualTo: countryCode);
    }

    return query.snapshots().map((snapshot) {
      final driverLocation = getDriverLocation();
      List<TripRequestModel> nearbyRequests = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final pickupLat = data['pickupLat'] ?? 0.0;
        final pickupLng = data['pickupLng'] ?? 0.0;
        
        final distance = calculateDistanceBetween(
          driverLocation.latitude,
          driverLocation.longitude,
          pickupLat,
          pickupLng,
        );
        
        final createdAt = data['createdAt'] != null && data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null;
        if (createdAt != null && DateTime.now().difference(createdAt).inMinutes >= 5) {
          continue;
        }

        double currentTripRadius = (data['currentRadius'] as num?)?.toDouble() ?? 2.0;
        if (createdAt != null) {
          final elapsed = DateTime.now().difference(createdAt).inSeconds;
          if (elapsed >= 120) {
            currentTripRadius = math.max(currentTripRadius, 10.0);
          } else if (elapsed >= 60) {
            currentTripRadius = math.max(currentTripRadius, 8.0);
          } else if (elapsed >= 30) {
            currentTripRadius = math.max(currentTripRadius, 5.0);
          }
        }
        
        if (distance <= currentTripRadius && distance <= radiusKm) {
          nearbyRequests.add(TripRequestModel.fromMap(data, doc.id));
        }
      }
      
      return nearbyRequests;
    });
  }

  /// بدء الرحلة بعد التحقق من رمز OTP
  Future<bool> startTripWithOtp({
    required String tripId,
    required String enteredOtp,
  }) async {
    final docRef = _tripsCollection.doc(tripId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) throw Exception('الرحلة غير موجودة');
    final data = snapshot.data() as Map<String, dynamic>;
    final expectedOtp = data['startOtp'] as String?;
    
    if (expectedOtp != null && expectedOtp.isNotEmpty) {
      if (enteredOtp.trim() != expectedOtp.trim()) {
        return false;
      }
    }
    
    await docRef.update({
      'status': TripStatus.pickedUp.name,
      'pickedUpAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// قبول طلب رحلة
  Future<void> acceptTrip({
    required String tripId,
    required String driverName,
    required String driverPhone,
    String? driverPhotoUrl,
    String? carNumber,
    String? carModel,
    String? carColor,
    String? carType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    final docRef = _tripsCollection.doc(tripId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('الرحلة غير موجودة أو تم حذفها');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String?;

      if (currentStatus == TripStatus.cancelled.name || currentStatus == TripStatus.cancelledByDriver.name) {
        throw Exception('عذراً، قام الراكب بإلغاء هذا الطلب');
      }

      if (currentStatus != TripStatus.pending.name) {
        throw Exception('عذراً، تم قبول هذه الرحلة بالفعل من قبل سائق آخر');
      }

      transaction.update(docRef, {
        'status': TripStatus.accepted.name,
        'driverId': user.uid,
        'driverName': driverName,
        'driverPhone': driverPhone,
        if (driverPhotoUrl != null) 'driverPhotoUrl': driverPhotoUrl,
        if (carNumber != null) 'carNumber': carNumber,
        if (carModel != null) 'carModel': carModel,
        if (carColor != null) 'carColor': carColor,
        if (carType != null) 'carType': carType,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// رفض/إلغاء طلب
  Future<void> cancelTrip(String tripId, {String? cancellationReason}) async {
    await _tripsCollection.doc(tripId).update({
      'status': TripStatus.cancelled.name,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (cancellationReason != null) 'cancelledByPassengerAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// إلغاء طلب من قبل السائق
  Future<void> cancelTripByDriver(String tripId, {required String cancellationReason}) async {
    await _tripsCollection.doc(tripId).update({
      'status': TripStatus.cancelledByDriver.name,
      'driverCancellationReason': cancellationReason,
      'cancelledByDriverAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إكمال رحلة بشكل فوري ومباشر
  Future<void> completeTrip(
    String tripId, {
    double? commissionRate,
    double? commissionAmount,
    double? netDriverEarnings,
  }) async {
    await _tripsCollection.doc(tripId).update({
      'status': TripStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (commissionRate != null) 'commissionRate': commissionRate,
      if (commissionAmount != null) 'commissionAmount': commissionAmount,
      if (netDriverEarnings != null) 'netDriverEarnings': netDriverEarnings,
    });
  }

  /// حفظ تقييم الراكب للرحلة
  Future<void> submitPassengerRating({
    required String tripId,
    required int rating,
    String? note,
  }) async {
    await _tripsCollection.doc(tripId).update({
      'passengerRating': rating,
      'passengerNote': note,
      'passengerRatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حفظ تقييم السائق للرحلة
  Future<void> submitDriverRating({
    required String tripId,
    required int rating,
    String? note,
  }) async {
    await _tripsCollection.doc(tripId).update({
      'driverRating': rating,
      'driverNote': note,
      'driverRatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حساب المسافة بين نقطتين بالكيلومتر
  double calculateDistanceBetween(double lat1, double lng1, double lat2, double lng2) =>
      TripCalculationHelper.calculateDistanceBetween(lat1, lng1, lat2, lng2);

  String formatPrice(double price) => TripCalculationHelper.formatPrice(price);

  String formatDistance(double distanceKm) => TripCalculationHelper.formatDistance(distanceKm);
}

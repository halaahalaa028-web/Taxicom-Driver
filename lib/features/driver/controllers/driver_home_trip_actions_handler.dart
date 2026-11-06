import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/services/driver_wallet_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import '../../trips/widgets/trip_rating_dialog.dart';
import '../../profile/services/user_service.dart';
import '../../profile/models/user_model.dart';
import '../widgets/driver_cancel_trip_dialog.dart';
import '../dialogs/start_trip_otp_dialog.dart';
import '../dialogs/complete_trip_dialog.dart';
import '../dialogs/fallback_to_cash_dialog.dart';
import '../dialogs/driver_trip_confirm_dialog.dart';

/// معالج تنفيذ إجراءات الرحلات (قبول، وصول، ركوب، إكمال، إلغاء)
class DriverHomeTripActionsHandler {
  final TripRequestService _tripService = TripRequestService.instance;
  final UserService _userService = UserService.instance;

  Future<TripRequestModel?> acceptRequest({
    required BuildContext context,
    required TripRequestModel request,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      UserModel? userData = await _userService.getUser(user.uid);
      if (userData == null) return null;

      await _tripService.acceptTrip(
        tripId: request.id,
        driverName: userData.name,
        driverPhone: userData.phone,
        driverPhotoUrl: userData.profilePhotoUrl,
        carNumber: userData.carNumber,
        carModel: userData.carModel,
        carColor: userData.carColor,
        carType: userData.carType,
      );

      var acceptedTrip = request.copyWith(
        status: TripStatus.accepted,
        driverName: userData.name,
        driverPhone: userData.phone,
        driverPhotoUrl: userData.profilePhotoUrl,
        carNumber: userData.carNumber,
        carModel: userData.carModel,
        carColor: userData.carColor,
        carType: userData.carType,
      );

      // 💳 الحجز المالي المسبق للبطاقة البنكية (Pre-Auth Hold)
      if (request.paymentMethod == 'card') {
        final holdResult = await DriverWalletService.instance.holdTripPayment(
          tripId: request.id,
          passengerId: request.passengerId,
          paymentMethodId: request.paymentMethodId,
          amount: request.price,
        );

        if (holdResult.fallbackToCash) {
          acceptedTrip = acceptedTrip.copyWith(paymentMethod: 'cash');
          if (context.mounted) {
            _showSnackBar(
              context,
              'تنبيه: تعذر حجز المبلغ من بطاقة الراكب. تم تحويل الرحلة تلقائياً إلى نقدي (كاش).',
              isError: true,
            );
          }
        } else if (holdResult.success && context.mounted) {
          _showSnackBar(context, 'تم قبول الطلب وتأكيد حجز بطاقة الراكب بنجاح!', isError: false);
        }
      } else if (context.mounted) {
        _showSnackBar(context, 'تم قبول الطلب!', isError: false);
      }

      return acceptedTrip;
    } catch (e) {
      if (context.mounted) {
        final friendlyMessage = AppErrorHandler.getTripAcceptanceErrorMessage(e);
        _showSnackBar(context, friendlyMessage, isError: true);
      }
      return null;
    }
  }

  Future<bool> arrivedAtPassenger(BuildContext context, TripRequestModel trip) async {
    final confirmed = await DriverTripConfirmDialog.show(
      context,
      title: 'تأكيد الوصول',
      message: 'هل وصلت فعلاً لموقع الزبون؟',
      icon: Icons.person_pin_circle_rounded,
      confirmText: 'نعم، وصلت',
    );
    if (!confirmed) return false;

    try {
      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'status': TripStatus.arrivedAtPickup.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) _showSnackBar(context, 'وصلت لموقع الزبون!', isError: false);
      return true;
    } catch (e) {
      if (context.mounted) {
        final friendlyMessage = AppErrorHandler.getFriendlyErrorMessage(
          e,
          defaultMessage: 'حدث خطأ أثناء تحديث حالة الوصول',
        );
        _showSnackBar(context, friendlyMessage, isError: true);
      }
      return false;
    }
  }

  Future<bool> passengerBoarded(BuildContext context, TripRequestModel trip) async {
    if (trip.startOtp != null && trip.startOtp!.isNotEmpty) {
      final verified = await StartTripOtpDialog.show(
        context,
        expectedOtp: trip.startOtp,
        onVerify: (otp) => _tripService.startTripWithOtp(tripId: trip.id, enteredOtp: otp),
      );
      if (verified == true && context.mounted) {
        _showSnackBar(context, 'تم التحقق من الرمز وبدأت الرحلة بنجاح!', isError: false);
        return true;
      }
      return false;
    }

    final confirmed = await DriverTripConfirmDialog.show(
      context,
      title: 'تأكيد الركوب',
      message: 'هل ركب الزبون في السيارة؟',
      icon: Icons.person_add_rounded,
      confirmText: 'نعم، ركب',
    );
    if (!confirmed) return false;

    try {
      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'status': TripStatus.pickedUp.name,
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        _showSnackBar(context, 'الراكب في السيارة! اذهب للوجهة', isError: false);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        final friendlyMessage = AppErrorHandler.getFriendlyErrorMessage(
          e,
          defaultMessage: 'حدث خطأ أثناء تأكيد ركوب الزبون',
        );
        _showSnackBar(context, friendlyMessage, isError: true);
      }
      return false;
    }
  }

  Future<bool> completeTrip(BuildContext context, TripRequestModel trip) async {
    final confirmed = await CompleteTripDialog.show(context, trip: trip);
    if (confirmed != true || !context.mounted) return false;

    return await _processTripCompletionWithFallback(context, trip: trip);
  }

  Future<bool> _processTripCompletionWithFallback(
    BuildContext context, {
    required TripRequestModel trip,
    String? forcedPaymentMethod,
  }) async {
    try {
      final driverId = trip.driverId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      if (driverId.isEmpty) {
        if (context.mounted) _showSnackBar(context, 'لم يتم العثور على حساب السائق', isError: true);
        return false;
      }

      final isCashTrip = forcedPaymentMethod == 'cash' ||
          (forcedPaymentMethod == null && (trip.paymentMethod == 'cash' || trip.paymentMethod.isEmpty));

      final result = await DriverWalletService.instance.processTripCompletion(
        trip: trip,
        driverId: driverId,
        totalFare: trip.effectiveOriginalPrice,
        isCash: isCashTrip,
        forcedPaymentMethod: forcedPaymentMethod,
      );

      if (result.success) {
        if (context.mounted) {
          final rating = await showTripRatingDialog(
            context: context,
            title: 'قيّم الراكب',
            otherPartyName: trip.passengerName,
            isPassengerRating: false,
          );
          if (rating != null) {
            try {
              await _tripService.submitDriverRating(
                tripId: trip.id,
                rating: rating.rating,
                note: rating.note,
              );
            } catch (_) {}
          }
          if (context.mounted) {
            _showSnackBar(context, 'تم إكمال الرحلة واستلام الأجرة بنجاح!', isError: false);
          }
        }
        return true;
      }

      if (result.fallbackToCash) {
        if (!context.mounted) return false;
        final cashConfirmed = await FallbackToCashDialog.show(
          context,
          trip: trip,
          reasonMessage: result.errorMessage,
        );

        if (cashConfirmed == true && context.mounted) {
          return await _processTripCompletionWithFallback(
            context,
            trip: trip,
            forcedPaymentMethod: 'cash',
          );
        }
        return false;
      }

      if (context.mounted) {
        _showSnackBar(
          context,
          result.errorMessage ?? 'تعذر إنهاء الرحلة وتسوية الحسابات. يرجى المحاولة ثانية.',
          isError: true,
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        final friendlyMessage = AppErrorHandler.getFriendlyErrorMessage(
          e,
          defaultMessage: 'حدث خطأ غير متوقع أثناء إنهاء الرحلة',
        );
        _showSnackBar(context, friendlyMessage, isError: true);
      }
      return false;
    }
  }

  Future<bool> cancelTripByDriver(BuildContext context, TripRequestModel trip) async {
    final reason = await showDriverCancelTripDialog(
      context,
      tripStatus: trip.status,
    );
    if (reason == null || reason.isEmpty) return false;

    try {
      await _tripService.cancelTripByDriver(trip.id, cancellationReason: reason);
      if (context.mounted) {
        final rating = await showTripRatingDialog(
          context: context,
          title: 'قيّم الراكب',
          otherPartyName: trip.passengerName,
          isPassengerRating: false,
        );
        if (rating != null) {
          try {
            await _tripService.submitDriverRating(
              tripId: trip.id,
              rating: rating.rating,
              note: rating.note,
            );
          } catch (_) {}
        }
        if (context.mounted) {
          _showSnackBar(context, 'تم إلغاء الرحلة', isError: true);
        }
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        final friendlyMessage = AppErrorHandler.getFriendlyErrorMessage(
          e,
          defaultMessage: 'حدث خطأ أثناء إلغاء الرحلة',
        );
        _showSnackBar(context, friendlyMessage, isError: true);
      }
      return false;
    }
  }

  Future<TripRequestModel?> handleArrivedAtPassenger(BuildContext context, TripRequestModel trip) async {
    if (await arrivedAtPassenger(context, trip)) {
      return trip.copyWith(status: TripStatus.arrivedAtPickup);
    }
    return null;
  }

  Future<TripRequestModel?> handlePassengerBoarded(BuildContext context, TripRequestModel trip) async {
    if (await passengerBoarded(context, trip)) {
      return trip.copyWith(status: TripStatus.pickedUp);
    }
    return null;
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

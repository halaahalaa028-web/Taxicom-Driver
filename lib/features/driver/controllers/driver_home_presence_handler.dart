import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/driver_availability_service.dart';
import '../../../core/services/driver_presence_service.dart';
import '../../../core/services/driver_tracking_service.dart';
import '../../../core/services/gps_monitor_service.dart';
import '../../../core/services/driver_commission_service.dart';
import '../../../core/services/driver_wallet_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/network_service.dart';
import '../../permissions/screens/location_disclosure_screen.dart';
import '../../profile/services/user_service.dart';
import '../../wallet/presentation/widgets/debt_exceeded_dialog.dart';

/// معالج حالة التواجد والاتصال والـ GPS وسقف المديونية وكشف المواقع الوهمية
class DriverHomePresenceHandler {
  final DriverAvailabilityService availabilityService = DriverAvailabilityService.instance;
  final DriverPresenceService presenceService = DriverPresenceService.instance;
  final DriverTrackingService driverTrackingService = DriverTrackingService.instance;
  final UserService userService = UserService.instance;

  Future<bool> hasInternetConnection() => NetworkService.instance.hasInternetConnection();

  Future<void> loadUserToCache(BuildContext context, VoidCallback onStartTracking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (userService.cachedUser == null) await userService.loadCurrentUser(user.uid);
      final cachedUser = userService.cachedUser;
      final wallet = await DriverWalletService.instance.getWallet(user.uid);
      final debtStatus = DriverCommissionService.instance.checkDebtStatus(
        currentDebt: wallet.currentDebt,
        countryCode: wallet.countryCode,
      );

      if (cachedUser != null && cachedUser.isOnline) {
        if (debtStatus.isBlocked) {
          await userService.setDriverOnlineStatus(user.uid, false);
          if (context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DebtExceededDialog.show(
                context,
                debtStatus: debtStatus,
                currency: wallet.currency,
                countryCode: wallet.countryCode,
              );
            });
          }
        }
      }
      onStartTracking();
    }
  }

  StreamSubscription? listenToOnlineStatus({
    required void Function(bool firestoreIsOnline) onStatusChanged,
    required void Function() onStatusInitialized,
    required void Function() onStartWork,
    required void Function() onStopWork,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          onStatusInitialized();
          return;
        }
        final data = snapshot.data()!;
        final firestoreIsOnline = (data['isOnline'] as bool?) ?? false;
        if (firestoreIsOnline == false && WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;

        onStatusInitialized();
        onStatusChanged(firestoreIsOnline);
        if (firestoreIsOnline) {
          onStartWork();
        } else {
          onStopWork();
        }
      },
      onError: (e) {
        debugPrint('⚠️ [DriverHomePresenceHandler] User snapshot stream error handled: $e');
      },
      cancelOnError: false,
    );
  }

  Future<bool> toggleAvailability({
    required BuildContext context,
    required bool currentStatus,
    required VoidCallback onStartTracking,
    required VoidCallback onStopTracking,
  }) async {
    final newStatus = !currentStatus;
    final loc = AppLocalizations.of(context);

    if (!await hasInternetConnection()) {
      if (context.mounted) {
        showSnackBar(context, loc.noInternetConnection, isError: true);
      }
      return currentStatus;
    }

    if (newStatus) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return currentStatus;

      // 1. فحص سقف المديونية
      final wallet = await DriverWalletService.instance.getWallet(user.uid);
      final debtStatus = DriverCommissionService.instance.checkDebtStatus(
        currentDebt: wallet.currentDebt,
        countryCode: wallet.countryCode,
      );

      if (debtStatus.isBlocked) {
        if (context.mounted) {
          DebtExceededDialog.show(
            context,
            debtStatus: debtStatus,
            currency: wallet.currency,
            countryCode: wallet.countryCode,
          );
        }
        return currentStatus;
      }

      // 2. التحقق من الإفصاح البارز عن الموقع (Prominent Disclosure) قبل طلب الصلاحيات
      final disclosureShown = await LocationService.instance.wasDisclosureShown();
      if (!disclosureShown && context.mounted) {
        final accepted = await showLocationDisclosureDialog(context);
        if (accepted) {
          await LocationService.instance.setDisclosureShown();
        } else {
          return currentStatus;
        }
      }

      // 3. فحص جاهزية GPS والصلاحيات والموقع الوهمي
      final checkResult = await availabilityService.checkCanGoOnline();
      if (!checkResult.canProceed) {
        if (context.mounted) {
          showGpsDialog(context, checkResult.error!);
        }
        return currentStatus;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        if (newStatus) {
          await presenceService.goOnline(driverId: user.uid);
          onStartTracking();
        } else {
          await presenceService.goOffline();
          await driverTrackingService.removeDriverLocation(user.uid);
          onStopTracking();
        }
        return newStatus;
      } catch (e) {
        if (context.mounted) {
          showSnackBar(context, loc.presenceServiceError, isError: true);
        }
      }
    }
    return currentStatus;
  }

  void startGpsMonitoring() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    GpsMonitorService.instance.startMonitoring(user.uid);
  }

  void stopGpsMonitoring() {
    GpsMonitorService.instance.stopMonitoring();
  }

  StreamSubscription? listenToBackgroundGps({
    required BuildContext context,
    required VoidCallback onGpsDisabled,
  }) {
    return GpsMonitorService.instance.listenToGpsDisabled(() {
      if (context.mounted) onGpsDisabled();
    });
  }

  Future<void> handleGpsDisabled(BuildContext context) async {
    try {
      await presenceService.goOffline();
    } catch (_) {
      try {
        await availabilityService.forceOffline();
      } catch (_) {}
    }

    if (context.mounted) {
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.gps_off, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(loc.gpsDisabledTitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18)),
              ),
            ],
          ),
          content: Text(loc.forceOfflineGpsMessage, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.ok, style: const TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                availabilityService.openLocationSettings();
              },
              child: Text(loc.openLocationSettings, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }
  }

  /// معالجة اكتشاف الموقع الوهمي فوراً والإيقاف الإجباري
  Future<void> handleMockLocationDetected(BuildContext context) async {
    try {
      await presenceService.goOffline();
      await availabilityService.forceOffline();
    } catch (_) {}

    if (context.mounted) {
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.mockLocationDetectedTitle,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            loc.mockLocationDetectedMessage,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.ok, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }
  }

  void showGpsDialog(BuildContext context, AvailabilityError error) {
    if (error == AvailabilityError.mockLocationDetected) {
      handleMockLocationDetected(context);
      return;
    }

    final loc = AppLocalizations.of(context);
    final String title = error == AvailabilityError.gpsDisabled ? loc.gpsDisabledTitle : loc.locationPermissionRequired;
    final String message = error == AvailabilityError.gpsDisabled ? loc.gpsDisabledMessage : loc.locationPermissionMessage;
    final String actionLabel = error == AvailabilityError.gpsDisabled ? loc.openLocationSettings : loc.openAppSettings;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(error == AvailabilityError.gpsDisabled ? Icons.gps_off : Icons.location_off, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel, style: const TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (error == AvailabilityError.gpsDisabled) {
                availabilityService.openLocationSettings();
              } else {
                availabilityService.openAppSettings();
              }
            },
            child: Text(actionLabel, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

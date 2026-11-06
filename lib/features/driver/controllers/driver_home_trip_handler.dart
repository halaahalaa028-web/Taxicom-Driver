import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import '../dialogs/passenger_cancelled_dialog.dart';
import '../dialogs/navigation_app_sheet.dart';
import 'driver_home_map_handler.dart';
import 'driver_home_trip_actions_handler.dart';

/// معالج تتبع وتحديث مسار وإجراءات الرحلات النشطة للسائق
class DriverHomeTripHandler {
  final TripRequestService _tripService = TripRequestService.instance;
  final DriverHomeTripActionsHandler actions = DriverHomeTripActionsHandler();
  bool isProcessingAction = false;

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return _tripService.calculateDistanceBetween(startLat, startLng, endLat, endLng);
  }

  int estimateTimeToPassenger(double distanceKm) {
    return (distanceKm * 2).ceil();
  }

  Future<void> callPassenger(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openNavigationApp(
    BuildContext context,
    TripRequestModel? activeTrip,
    bool isPassengerPickedUp,
  ) async {
    if (activeTrip == null) return;
    await NavigationAppSheet.show(
      context,
      destination: isPassengerPickedUp ? activeTrip.destinationLocation : activeTrip.pickupLocation,
    );
  }

  Future<TripRequestModel?> acceptRequest({
    required BuildContext context,
    required TripRequestModel request,
  }) =>
      actions.acceptRequest(context: context, request: request);

  StreamSubscription watchActiveTrip({
    required String tripId,
    required BuildContext? context,
    required void Function(TripRequestModel trip) onTripUpdated,
    required void Function() onCancelled,
    required void Function() onCompleted,
  }) {
    return _tripService.watchTripRequest(tripId).listen(
      (trip) {
        if (trip != null) {
          onTripUpdated(trip);
          if (trip.status == TripStatus.cancelled && context != null && context.mounted) {
            PassengerCancelledDialog.show(context, trip: trip);
            onCancelled();
          }
          if (trip.status == TripStatus.completed) {
            onCompleted();
          }
        }
      },
      onError: (e) {
        debugPrint('⚠️ [DriverHomeTripHandler] Watch active trip stream error handled: $e');
      },
      cancelOnError: false,
    );
  }

  Future<void> updateActiveTripRoute({
    required TripRequestModel request,
    required LatLng currentLocation,
    required GoogleMapController? mapController,
    required DriverHomeMapHandler mapHandler,
    required void Function(Set<Marker> markers, Set<Polyline> polylines) onRouteCalculated,
  }) async {
    final isPickedUp = (request.status == TripStatus.pickedUp);
    final destination = isPickedUp ? request.destinationLocation : request.pickupLocation;
    final markers = isPickedUp
        ? mapHandler.buildActiveDestinationMarker(request)
        : mapHandler.buildActivePickupMarker(request);

    onRouteCalculated(markers, {});

    final polylines = await mapHandler.fetchRoutePolylines(
      origin: currentLocation,
      destination: destination,
      color: isPickedUp ? AppColors.success : AppColors.primary,
      polylineId: isPickedUp ? 'route_to_destination' : 'route_to_passenger',
    );

    onRouteCalculated(markers, polylines);
    mapHandler.fitMapToBounds(
      mapController: mapController,
      currentLocation: currentLocation,
      destination: destination,
      routePoints: polylines.isNotEmpty ? polylines.first.points : [],
    );
  }

  Future<void> runTripAction(VoidCallback onStateChanged, Future<void> Function() action) async {
    if (isProcessingAction) return;
    isProcessingAction = true;
    onStateChanged();
    try {
      await action();
    } finally {
      isProcessingAction = false;
      onStateChanged();
    }
  }

  Future<void> handleArrivedAtPassenger({
    required BuildContext context,
    required TripRequestModel activeTrip,
    required VoidCallback onStateChanged,
    required void Function(TripRequestModel trip) onUpdated,
    required Future<void> Function(TripRequestModel trip) onRouteUpdate,
  }) =>
      runTripAction(onStateChanged, () async {
        final updated = await actions.handleArrivedAtPassenger(context, activeTrip);
        if (updated != null) {
          onUpdated(updated);
          await onRouteUpdate(updated);
        }
      });

  Future<void> handlePassengerBoarded({
    required BuildContext context,
    required TripRequestModel activeTrip,
    required VoidCallback onStateChanged,
    required void Function(TripRequestModel trip) onUpdated,
    required Future<void> Function(TripRequestModel trip) onRouteUpdate,
  }) =>
      runTripAction(onStateChanged, () async {
        final updated = await actions.handlePassengerBoarded(context, activeTrip);
        if (updated != null) {
          onUpdated(updated);
          await onRouteUpdate(updated);
        }
      });

  Future<void> handleCompleteTrip({
    required BuildContext context,
    required TripRequestModel activeTrip,
    required VoidCallback onStateChanged,
    required Future<void> Function() onCompleted,
  }) =>
      runTripAction(onStateChanged, () async {
        if (await actions.completeTrip(context, activeTrip)) {
          await onCompleted();
        }
      });

  Future<void> handleCancelTripByDriver({
    required BuildContext context,
    required TripRequestModel activeTrip,
    required VoidCallback onStateChanged,
    required Future<void> Function() onCancelled,
  }) =>
      runTripAction(onStateChanged, () async {
        if (await actions.cancelTripByDriver(context, activeTrip)) {
          await onCancelled();
        }
      });
}

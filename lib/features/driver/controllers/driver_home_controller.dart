// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/ntp_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import 'driver_home_map_handler.dart';
import 'driver_home_presence_handler.dart';
import 'driver_home_trip_handler.dart';
import 'driver_home_location_handler.dart';
import 'driver_home_requests_handler.dart';

/// متحكم منطق وحالة الشاشة الرئيسية للسائق
class DriverHomeController extends ChangeNotifier {
  GoogleMapController? mapController;
  LatLng currentLocation = LatLng(AppConstants.samawahLat, AppConstants.samawahLng);
  String currentAddress = '';
  bool isLoadingLocation = true, isLoadingAddress = true, locationFailed = false;
  bool isAvailable = false, isStatusInitialized = false, isTogglingAvailability = false;
  bool isPassengerPickedUp = false;

  bool get isProcessingTripAction => tripHandler.isProcessingAction;

  Set<Marker> driverMarker = {}, activeTripMarkers = {};
  Set<Polyline> activeTripPolylines = {};
  int todayTrips = 0;
  double todayEarnings = 0.0;
  TripRequestModel? activeTrip;

  final DriverHomeMapHandler mapHandler = DriverHomeMapHandler();
  final DriverHomePresenceHandler presenceHandler = DriverHomePresenceHandler();
  final DriverHomeTripHandler tripHandler = DriverHomeTripHandler();
  final DriverHomeLocationHandler locationHandler = DriverHomeLocationHandler();
  final DriverHomeRequestsHandler requestsHandler = DriverHomeRequestsHandler();
  final TripRequestService _tripService = TripRequestService.instance;

  List<TripRequestModel> get incomingRequests => requestsHandler.incomingRequests;
  Set<Marker> get passengerMarkers => requestsHandler.passengerMarkers;

  StreamSubscription? _activeTripSubscription, _bgServiceSubscription, _onlineStatusSubscription;
  StreamSubscription<ServiceStatus>? _screenGpsSubscription;
  LatLng? _lastStreamLocation;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    locationHandler.dispose();
    requestsHandler.dispose();
    for (final s in [_activeTripSubscription, _bgServiceSubscription, _screenGpsSubscription, _onlineStatusSubscription]) {
      s?.cancel();
    }
    mapController?.dispose();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  void initialize(BuildContext context) {
    NtpService.instance.initialize();
    _loadCarIcon();
    _initLocation(context);
    _startScreenGpsListener(context);
    _listenToBackgroundGpsEvents(context);
    _listenToOnlineStatus();
    presenceHandler.loadUserToCache(context, () => _startLocationTracking(context));
    checkForActiveTrip(context);
    loadTodayStats(context);
  }

  void onAppLifecycleResumed(BuildContext context) {
    if (!isAvailable) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) presenceHandler.presenceService.goOnline(driverId: user.uid).catchError((_) {});
    Geolocator.isLocationServiceEnabled().then((enabled) {
      if (!enabled && isAvailable && context.mounted) _handleGpsDisabled(context);
    });
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    if (!isLoadingLocation) mapHandler.goToLocation(controller, currentLocation);
  }

  void goToCurrentLocation() => mapHandler.goToLocation(mapController, currentLocation);
  void openLocationSettings() => presenceHandler.availabilityService.openLocationSettings();

  Future<void> loadTodayStats(BuildContext? context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final stats = await _tripService.getDriverTodayStats(user.uid);
      todayTrips = stats['count'] as int;
      todayEarnings = (stats['earnings'] as num).toDouble();
      _safeNotifyListeners();
    } catch (_) {}
  }

  Future<void> _loadCarIcon() async {
    await mapHandler.loadCarIcon();
    driverMarker = mapHandler.buildDriverMarker(currentLocation);
    _safeNotifyListeners();
  }

  void _listenToOnlineStatus() {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = presenceHandler.listenToOnlineStatus(
      onStatusInitialized: () {
        if (!isStatusInitialized) {
          isStatusInitialized = true;
          _safeNotifyListeners();
        }
      },
      onStatusChanged: (status) {
        if (isAvailable != status) {
          isAvailable = status;
          isTogglingAvailability = false;
          _safeNotifyListeners();
        }
      },
      onStartWork: () {
        _startListeningForRequests();
        presenceHandler.startGpsMonitoring();
        _startLocationTracking();
      },
      onStopWork: () {
        requestsHandler.stopListening();
        _safeNotifyListeners();
        presenceHandler.stopGpsMonitoring();
      },
    );
  }

  Future<void> _initLocation(BuildContext context) async {
    final position = await locationHandler.initLocation(context);
    isLoadingLocation = false;
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
      driverMarker = mapHandler.buildDriverMarker(currentLocation);
      _updateCurrentAddress(currentLocation, force: true);
      mapHandler.goToLocation(mapController, currentLocation);
      if (isAvailable) {
        locationHandler.pushCurrentLocationToFirebase(
          location: currentLocation,
          hasActiveTrip: activeTrip != null,
        );
      }
    } else {
      isLoadingAddress = false;
      locationFailed = true;
    }
    _safeNotifyListeners();
  }

  void _startScreenGpsListener(BuildContext context) {
    _screenGpsSubscription = presenceHandler.availabilityService.getGpsStatusStream().listen(
      (status) {
        if (status == ServiceStatus.disabled && isAvailable) {
          if (context.mounted) _handleGpsDisabled(context);
        } else if (status == ServiceStatus.enabled && locationFailed) {
          isLoadingAddress = true;
          locationFailed = false;
          _safeNotifyListeners();
          if (context.mounted) _initLocation(context);
        }
      },
      onError: (e) => debugPrint('⚠️ [DriverHomeController] Screen GPS status error: $e'),
      cancelOnError: false,
    );
  }

  Future<void> checkForActiveTrip([BuildContext? context]) async {
    try {
      final trip = await _tripService.getActiveTripForDriver();
      if (trip != null) {
        activeTrip = trip;
        isPassengerPickedUp = (trip.status == TripStatus.pickedUp);
        isAvailable = false;
        _safeNotifyListeners();
        _updateActiveTripRoute(trip);
        _listenToActiveTrip(trip.id, (context != null && context.mounted) ? context : null);
      }
    } catch (_) {}
  }

  void _startLocationTracking([BuildContext? context]) {
    locationHandler.pushCurrentLocationToFirebase(
      location: currentLocation,
      hasActiveTrip: activeTrip != null,
    );
    locationHandler.startTracking(
      isHighAccuracy: activeTrip != null,
      onLocationUpdate: (position, newLocation) {
        currentLocation = newLocation;
        locationFailed = false;
        driverMarker = mapHandler.buildDriverMarker(newLocation);
        if (activeTrip == null) _updateCurrentAddress(newLocation);
        if (!isLoadingLocation && activeTrip == null) {
          mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
        }
        locationHandler.updateFirebaseLocation(position: position, isAvailable: isAvailable || activeTrip != null, hasActiveTrip: activeTrip != null);
        locationHandler.handleSignificantMovement(
          newLocation: newLocation,
          lastStreamLocation: _lastStreamLocation,
          isAvailable: isAvailable,
          onMoved: (loc) {
            _lastStreamLocation = loc;
            _startListeningForRequests();
          },
        );
        _safeNotifyListeners();
      },
      onMockLocationDetected: (_) {
        if (context != null && context.mounted) {
          _handleMockLocationDetected(context);
        } else if (isAvailable) {
          _stopWorkingState();
        }
      },
    );
  }

  void _stopWorkingState() {
    isAvailable = false;
    requestsHandler.stopListening();
    locationHandler.stopTracking();
    _safeNotifyListeners();
  }

  Future<void> _updateCurrentAddress(LatLng location, {bool force = false}) async {
    if (activeTrip != null && !force) return;
    final newAddress = await locationHandler.getAddressFromCoordinates(location, force: force, hasActiveTrip: activeTrip != null);
    if (newAddress.isNotEmpty && (newAddress != currentAddress || isLoadingAddress)) {
      currentAddress = newAddress;
      isLoadingAddress = false;
      _safeNotifyListeners();
    }
  }

  Future<void> toggleAvailability(BuildContext context) async {
    if (isTogglingAvailability) return;
    isTogglingAvailability = true;
    _safeNotifyListeners();
    isAvailable = await presenceHandler.toggleAvailability(
      context: context,
      currentStatus: isAvailable,
      onStartTracking: () {
        isAvailable = true;
        _startLocationTracking(context);
      },
      onStopTracking: () {
        isAvailable = false;
        locationHandler.stopTracking();
      },
    );
    if (isAvailable) {
      locationHandler.pushCurrentLocationToFirebase(
        location: currentLocation,
        hasActiveTrip: activeTrip != null,
      );
    }
    isTogglingAvailability = false;
    _safeNotifyListeners();
  }

  Future<void> _handleGpsDisabled(BuildContext context) async {
    if (!isAvailable) return;
    _stopWorkingState();
    await presenceHandler.handleGpsDisabled(context);
  }

  Future<void> _handleMockLocationDetected(BuildContext context) async {
    if (!isAvailable) return;
    _stopWorkingState();
    await presenceHandler.handleMockLocationDetected(context);
  }

  void _listenToBackgroundGpsEvents(BuildContext context) {
    _bgServiceSubscription?.cancel();
    _bgServiceSubscription = presenceHandler.listenToBackgroundGps(
      context: context,
      onGpsDisabled: () => _handleGpsDisabled(context),
    );
  }

  void _startListeningForRequests() {
    _lastStreamLocation = currentLocation;
    requestsHandler.startListening(
      getDriverLocation: () => currentLocation,
      mapHandler: mapHandler,
      onUpdated: _safeNotifyListeners,
    );
  }

  double getDistanceToActiveTarget(TripRequestModel req) {
    final dest = isPassengerPickedUp ? req.destinationLocation : req.pickupLocation;
    return tripHandler.calculateDistance(currentLocation.latitude, currentLocation.longitude, dest.latitude, dest.longitude);
  }

  double getDistanceToPassenger(TripRequestModel req) => tripHandler.calculateDistance(
      currentLocation.latitude, currentLocation.longitude, req.pickupLocation.latitude, req.pickupLocation.longitude);

  int getEstimatedTimeToPassenger(double km) => tripHandler.estimateTimeToPassenger(km);

  void dismissRequest(TripRequestModel request) {
    requestsHandler.dismissRequest(request);
    _safeNotifyListeners();
  }

  Future<void> acceptRequest(BuildContext context, TripRequestModel request) async {
    final accepted = await tripHandler.acceptRequest(context: context, request: request);
    if (accepted != null) {
      requestsHandler.stopListening();
      activeTrip = accepted;
      todayTrips++;
      _safeNotifyListeners();
      _startLocationTracking(context);
      _updateActiveTripRoute(accepted);
      _listenToActiveTrip(accepted.id, context.mounted ? context : null);
    } else {
      dismissRequest(request);
    }
  }

  void _listenToActiveTrip(String tripId, BuildContext? context) {
    _activeTripSubscription?.cancel();
    _activeTripSubscription = tripHandler.watchActiveTrip(
      tripId: tripId,
      context: context,
      onTripUpdated: (trip) {
        final previousStatus = activeTrip?.status;
        activeTrip = trip;
        isPassengerPickedUp = (trip.status == TripStatus.pickedUp);
        if (previousStatus != trip.status) _updateActiveTripRoute(trip);
        _safeNotifyListeners();
      },
      onCancelled: () {
        endActiveTrip();
        if (context != null && context.mounted) loadTodayStats(context);
      },
      onCompleted: () => endActiveTrip(),
    );
  }

  void endActiveTrip() {
    _activeTripSubscription?.cancel();
    activeTrip = null;
    isPassengerPickedUp = false;
    activeTripMarkers = {};
    activeTripPolylines = {};
    _safeNotifyListeners();
    _startLocationTracking();
    if (isAvailable) _startListeningForRequests();
  }

  Future<void> _updateActiveTripRoute(TripRequestModel request) async {
    await tripHandler.updateActiveTripRoute(
      request: request,
      currentLocation: currentLocation,
      mapController: mapController,
      mapHandler: mapHandler,
      onRouteCalculated: (markers, polylines) {
        activeTripMarkers = markers;
        activeTripPolylines = polylines;
        _safeNotifyListeners();
      },
    );
  }

  Future<void> callPassenger() async => await tripHandler.callPassenger(activeTrip?.passengerPhone);

  Future<void> openNavigationApp(BuildContext context) =>
      tripHandler.openNavigationApp(context, activeTrip, isPassengerPickedUp);

  Future<void> arrivedAtPassenger(BuildContext context) => tripHandler.handleArrivedAtPassenger(
        context: context,
        activeTrip: activeTrip!,
        onStateChanged: _safeNotifyListeners,
        onUpdated: (trip) { activeTrip = trip; isPassengerPickedUp = false; _safeNotifyListeners(); },
        onRouteUpdate: _updateActiveTripRoute,
      );

  Future<void> passengerBoarded(BuildContext context) => tripHandler.handlePassengerBoarded(
        context: context,
        activeTrip: activeTrip!,
        onStateChanged: _safeNotifyListeners,
        onUpdated: (trip) { activeTrip = trip; isPassengerPickedUp = true; _safeNotifyListeners(); },
        onRouteUpdate: _updateActiveTripRoute,
      );

  Future<void> completeTrip(BuildContext context) => tripHandler.handleCompleteTrip(
        context: context,
        activeTrip: activeTrip!,
        onStateChanged: _safeNotifyListeners,
        onCompleted: () async {
          endActiveTrip();
          if (context.mounted) await loadTodayStats(context);
        },
      );

  Future<void> cancelTripByDriver(BuildContext context) => tripHandler.handleCancelTripByDriver(
        context: context,
        activeTrip: activeTrip!,
        onStateChanged: _safeNotifyListeners,
        onCancelled: () async {
          endActiveTrip();
          if (context.mounted) await loadTodayStats(context);
        },
      );
}

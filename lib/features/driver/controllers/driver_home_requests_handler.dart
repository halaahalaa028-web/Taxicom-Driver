import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/country_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import 'driver_home_map_handler.dart';

/// معالج الاستماع لطلبات الرحلات الواردة والتنبيهات الصوتية
class DriverHomeRequestsHandler {
  final TripRequestService _tripService = TripRequestService.instance;
  final SoundService _soundService = SoundService.instance;

  StreamSubscription? _requestsSubscription;
  Set<String> _previousRequestIds = {};
  final Set<String> _dismissedRequestIds = {};
  List<TripRequestModel> incomingRequests = [];
  Set<Marker> passengerMarkers = {};

  void startListening({
    required LatLng Function() getDriverLocation,
    required DriverHomeMapHandler mapHandler,
    required void Function() onUpdated,
  }) {
    _requestsSubscription?.cancel();
    bool isFirstLoad = true;

    _requestsSubscription = _tripService.watchNearbyRequests(
      getDriverLocation: getDriverLocation,
      radiusKm: 10.0,
      countryCode: CountryService.instance.selectedCountry.code,
    ).listen(
      (requests) {
        final visibleRequests = requests.where((r) => !_dismissedRequestIds.contains(r.id)).toList();
        final currentIds = visibleRequests.map((r) => r.id).toSet();
        final newRequestIds = currentIds.difference(_previousRequestIds);

        if (newRequestIds.isNotEmpty && !isFirstLoad) {
          _soundService.playNewTripSound();
        }

        _previousRequestIds = currentIds;
        isFirstLoad = false;
        incomingRequests = visibleRequests;
        passengerMarkers = mapHandler.buildPassengerMarkers(visibleRequests);
        onUpdated();
      },
      onError: (e) {
        debugPrint('⚠️ [DriverHomeRequestsHandler] Watch nearby requests stream error handled: $e');
      },
      cancelOnError: false,
    );
  }

  void dismissRequest(TripRequestModel request) {
    _dismissedRequestIds.add(request.id);
    _previousRequestIds.remove(request.id);
    incomingRequests.removeWhere((r) => r.id == request.id);
  }

  void clearDismissedRequests() {
    _dismissedRequestIds.clear();
  }

  void stopListening() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _previousRequestIds = {};
    incomingRequests = [];
    passengerMarkers = {};
  }

  void dispose() {
    stopListening();
    _dismissedRequestIds.clear();
  }
}

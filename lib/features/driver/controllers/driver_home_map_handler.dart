import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/directions_service.dart';
import '../../trips/models/trip_request_model.dart';

/// معالج عمليات الخريطة وتحديث العلامات والمسارات لشاشة السائق
class DriverHomeMapHandler {
  final DirectionsService _directionsService = DirectionsService.instance;
  BitmapDescriptor? carIcon;

  Future<void> loadCarIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/car_marker.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 45,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        carIcon = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error loading car icon: $e');
    }
  }

  Set<Marker> buildDriverMarker(LatLng location) {
    return {
      Marker(
        markerId: const MarkerId('driver_location'),
        position: location,
        icon: carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: const InfoWindow(title: 'موقعي الحالي'),
      ),
    };
  }

  Set<Marker> buildPassengerMarkers(List<TripRequestModel> requests) {
    return requests.map((req) {
      return Marker(
        markerId: MarkerId(req.id),
        position: req.pickupLocation,
        infoWindow: InfoWindow(title: req.passengerName, snippet: req.pickupAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }).toSet();
  }

  Set<Marker> buildActivePickupMarker(TripRequestModel trip) {
    return {
      Marker(
        markerId: const MarkerId('passenger_pickup'),
        position: trip.pickupLocation,
        infoWindow: InfoWindow(title: trip.passengerName, snippet: 'موقع الاستلام'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
  }

  Set<Marker> buildActiveDestinationMarker(TripRequestModel trip) {
    return {
      Marker(
        markerId: const MarkerId('destination'),
        position: trip.destinationLocation,
        infoWindow: InfoWindow(title: 'الوجهة', snippet: trip.destinationAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Future<Set<Polyline>> fetchRoutePolylines({
    required LatLng origin,
    required LatLng destination,
    required Color color,
    required String polylineId,
  }) async {
    final result = await _directionsService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (result != null && result.polylinePoints.isNotEmpty) {
      return {
        Polyline(
          polylineId: PolylineId(polylineId),
          points: result.polylinePoints,
          color: color,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }
    return {};
  }

  void fitMapToBounds({
    required GoogleMapController? mapController,
    required LatLng currentLocation,
    required LatLng destination,
    List<LatLng> routePoints = const [],
  }) {
    double minLat = currentLocation.latitude;
    double maxLat = currentLocation.latitude;
    double minLng = currentLocation.longitude;
    double maxLng = currentLocation.longitude;

    minLat = minLat < destination.latitude ? minLat : destination.latitude;
    maxLat = maxLat > destination.latitude ? maxLat : destination.latitude;
    minLng = minLng < destination.longitude ? minLng : destination.longitude;
    maxLng = maxLng > destination.longitude ? maxLng : destination.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void goToLocation(GoogleMapController? controller, LatLng location) {
    controller?.animateCamera(
      CameraUpdate.newLatLngZoom(location, AppConstants.defaultZoom),
    );
  }
}

/// شاشة معاينة تفاصيل الرحلة قبل القبول
/// 
/// تعرض خريطة مع نقطة الانطلاق والوجهة والمسار بينهما
/// مع جميع تفاصيل الرحلة والأسعار والعملات
library;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/directions_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../widgets/trip_preview_bottom_panel.dart';

/// شاشة معاينة الرحلة
class TripPreviewScreen extends StatefulWidget {
  final TripRequestModel tripRequest;
  final double driverDistanceKm;
  final int driverEtaMinutes;
  
  const TripPreviewScreen({
    super.key,
    required this.tripRequest,
    required this.driverDistanceKm,
    required this.driverEtaMinutes,
  });

  @override
  State<TripPreviewScreen> createState() => _TripPreviewScreenState();
}

class _TripPreviewScreenState extends State<TripPreviewScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoadingRoute = true;
  
  final DirectionsService _directionsService = DirectionsService.instance;

  @override
  void initState() {
    super.initState();
    _setupMarkersAndRoute();
  }

  /// إعداد العلامات والمسار
  Future<void> _setupMarkersAndRoute() async {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.tripRequest.pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'نقطة الانطلاق',
          snippet: widget.tripRequest.pickupAddress,
        ),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.tripRequest.destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'الوجهة',
          snippet: widget.tripRequest.destinationAddress,
        ),
      ),
    };

    final result = await _directionsService.getDirections(
      origin: widget.tripRequest.pickupLocation,
      destination: widget.tripRequest.destinationLocation,
    );

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;

        if (result != null && result.polylinePoints.isNotEmpty) {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: result.polylinePoints,
              color: AppColors.primary,
              width: 6,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        }
      });

      _fitMapToBounds();
    }
  }

  /// ضبط الخريطة لإظهار المسار كاملاً
  void _fitMapToBounds() {
    if (_mapController == null) return;

    final pickup = widget.tripRequest.pickupLocation;
    final destination = widget.tripRequest.destinationLocation;

    double minLat = pickup.latitude < destination.latitude ? pickup.latitude : destination.latitude;
    double maxLat = pickup.latitude > destination.latitude ? pickup.latitude : destination.latitude;
    double minLng = pickup.longitude < destination.longitude ? pickup.longitude : destination.longitude;
    double maxLng = pickup.longitude > destination.longitude ? pickup.longitude : destination.longitude;

    for (final polyline in _polylines) {
      for (final point in polyline.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = widget.tripRequest;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'معاينة الرحلة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // الخريطة
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: trip.pickupLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToBounds();
            },
          ),
          
          // مؤشر التحميل للمسار
          if (_isLoadingRoute)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.loadingRoute,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // زر إعادة ضبط العرض
          Positioned(
            top: _isLoadingRoute ? 60 : 16,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'fitBounds',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: _fitMapToBounds,
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
          
          // لوحة تفاصيل الرحلة السفلية
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: TripPreviewBottomPanel(
              trip: trip,
              driverDistanceKm: widget.driverDistanceKm,
              driverEtaMinutes: widget.driverEtaMinutes,
            ),
          ),
        ],
      ),
    );
  }
}

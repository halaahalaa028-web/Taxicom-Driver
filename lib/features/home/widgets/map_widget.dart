/// ويدجت الخريطة
/// 
/// يعرض خريطة Google مع علامات الموقع والوجهة والمسار
library;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// ويدجت الخريطة
class MapWidget extends StatefulWidget {
  /// متحكم الخريطة
  final GoogleMapController? mapController;
  
  /// callback عند إنشاء الخريطة
  final Function(GoogleMapController) onMapCreated;
  
  /// الموقع الحالي
  final LatLng currentLocation;
  
  /// موقع الوجهة (اختياري)
  final LatLng? destination;
  
  /// موقع السائق (اختياري - عند قبول الطلب)
  final LatLng? driverLocation;
  
  /// اتجاه السائق (بالدرجات)
  final double driverRotation;
  
  /// نقاط المسار
  final List<LatLng> polylinePoints;
  
  /// هل يتم تحميل الموقع
  final bool isLoadingLocation;

  /// callback عند الضغط على زر الموقع الحالي
  final VoidCallback? onMyLocationPressed;

  const MapWidget({
    super.key,
    this.mapController,
    required this.onMapCreated,
    required this.currentLocation,
    this.destination,
    this.driverLocation,
    this.driverRotation = 0.0,
    this.polylinePoints = const [],
    this.isLoadingLocation = false,
    this.onMyLocationPressed,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  /// أيقونة السيارة
  BitmapDescriptor? _carIcon;
  
  @override
  void initState() {
    super.initState();
    _loadCarIcon();
  }
  
  /// تحميل أيقونة السيارة
  Future<void> _loadCarIcon() async {
    try {
      final icon = await _getBitmapDescriptorFromAsset(
        'assets/images/car_marker.png',
        45, // حجم الأيقونة
      );
      if (mounted) {
        setState(() {
          _carIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('Error loading car icon: $e');
      // استخدام الأيقونة الافتراضية في حالة الخطأ
    }
  }
  
  /// تحويل صورة الـ asset إلى BitmapDescriptor
  Future<BitmapDescriptor> _getBitmapDescriptorFromAsset(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    // إنشاء العلامات
    Set<Marker> markers = {};
    
    // علامة الموقع الحالي (نقطة الانطلاق)
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'موقعي الحالي',
        ),
      ),
    );
    
    // علامة الوجهة
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'الوجهة',
          ),
        ),
      );
    }
    
    // علامة السائق (سيارة)
    if (widget.driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverLocation!,
          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          rotation: widget.driverRotation,
          anchor: const Offset(0.5, 0.5), // مركز الأيقونة
          flat: true, // لتدور مع الخريطة
          infoWindow: const InfoWindow(
            title: 'السائق',
          ),
        ),
      );
    }

    // إنشاء خط المسار
    Set<Polyline> polylines = {};
    if (widget.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.polylinePoints,
          color: AppColors.primary,
          width: 6,
          // خط مستمر وصلب (مثل Uber وCareem) بدلاً من الخط المتقطع
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    return Stack(
      children: [
        // الخريطة
        GoogleMap(
          onMapCreated: widget.onMapCreated,
          initialCameraPosition: CameraPosition(
            target: widget.currentLocation,
            zoom: AppConstants.defaultZoom,
          ),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          mapType: MapType.normal,
        ),
        
        // مؤشر التحميل
        if (widget.isLoadingLocation)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        
        // زر الموقع الحالي
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'myLocation',
            backgroundColor: AppColors.surface,
            onPressed: () {
              if (widget.onMyLocationPressed != null) {
                widget.onMyLocationPressed!();
              } else {
                widget.mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    widget.currentLocation,
                    AppConstants.defaultZoom,
                  ),
                );
              }
            },
            child: const Icon(
              Icons.my_location_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

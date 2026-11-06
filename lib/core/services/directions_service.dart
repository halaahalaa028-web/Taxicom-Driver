/// خدمة الحصول على اتجاهات المسار
///
/// تدعم الاستدعاء عبر Firebase Cloud Functions مع fallback تلقائي مباشر لـ Google Directions API
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

/// نتيجة المسار
class DirectionsResult {
  /// نقاط المسار المفصلة (مجمَّعة من جميع steps)
  final List<LatLng> polylinePoints;

  /// المسافة بالأمتار
  final int distanceMeters;

  /// المسافة كنص
  final String distanceText;

  /// المدة بالثواني
  final int durationSeconds;

  /// المدة كنص
  final String durationText;

  /// حالة الاستجابة من Google API
  final String status;

  DirectionsResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    this.status = 'OK',
  });
}

/// خدمة الاتجاهات مع دعم Cloud Function و Fallback المباشر
class DirectionsService {
  DirectionsService._();

  static final DirectionsService _instance = DirectionsService._();

  /// الحصول على instance وحيد
  static DirectionsService get instance => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// الحصول على المسار بين نقطتين (مع دعم نقاط وسطية)
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    // المحاولة 1: الدالة السحابية المؤمنة
    try {
      final callable = _functions.httpsCallable(
        'getRouteDirections',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 4)),
      );

      final Map<String, dynamic> payload = {
        'origin': {'lat': origin.latitude, 'lng': origin.longitude},
        'destination': {'lat': destination.latitude, 'lng': destination.longitude},
        'mode': 'driving',
        'language': 'ar',
        'region': 'iq',
      };

      if (waypoints != null && waypoints.isNotEmpty) {
        payload['waypoints'] = waypoints
            .map((wp) => {'lat': wp.latitude, 'lng': wp.longitude})
            .toList();
      }

      final response = await callable.call<Map<dynamic, dynamic>>(payload);
      final data = response.data;
      final apiStatus = (data['status'] as String?) ?? 'UNKNOWN_ERROR';

      if (apiStatus == 'OK') {
        final routes = (data['routes'] as List?) ?? [];
        final parsed = _parseRoutes(routes);
        if (parsed != null) return parsed;
      }
    } catch (_) {}

    // المحاولة 2: الاستعلام المباشر عبر Google Directions API (Fallback موثوق)
    return await _getDirectionsFromGoogleHttp(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
  }

  /// الاستعلام المباشر عبر Google Directions API
  Future<DirectionsResult?> _getDirectionsFromGoogleHttp({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      final apiKey = AppConstants.googleMapsApiKey;
      if (apiKey.isEmpty) return null;

      final Map<String, String> params = {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'key': apiKey,
        'mode': 'driving',
        'language': 'ar',
        'region': 'iq',
        'units': 'metric',
        'alternatives': 'true',
      };

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointStr = waypoints
            .map((wp) => '${wp.latitude},${wp.longitude}')
            .join('|');
        params['waypoints'] = 'optimize:false|$waypointStr';
      }

      final uri = Uri.parse('https://maps.googleapis.com/maps/api/directions/json')
          .replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List? ?? [];
          return _parseRoutes(routes);
        }
      }
    } catch (e) {
      debugPrint('❌ [DirectionsService] HTTP fallback error: $e');
    }
    return null;
  }

  /// استخراج أقصر مسار من قائمة المسارات
  DirectionsResult? _parseRoutes(List routes) {
    if (routes.isEmpty) return null;

    List<LatLng>? shortestRoutePoints;
    int? minDistanceMeters;
    int shortestDurationSeconds = 0;
    String shortestDistanceText = '';
    String shortestDurationText = '';

    for (final route in routes) {
      final legs = (route['legs'] as List?) ?? [];
      if (legs.isEmpty) continue;

      final List<LatLng> currentPoints = [];
      int currentDistanceMeters = 0;
      int currentDurationSeconds = 0;
      String currentDistanceText = '';
      String currentDurationText = '';

      for (final leg in legs) {
        final legDistance = leg['distance'] as Map?;
        final legDuration = leg['duration'] as Map?;

        if (legDistance != null) {
          currentDistanceMeters += (legDistance['value'] as num?)?.toInt() ?? 0;
          currentDistanceText = (legDistance['text'] as String?) ?? '';
        }
        if (legDuration != null) {
          currentDurationSeconds += (legDuration['value'] as num?)?.toInt() ?? 0;
          currentDurationText = (legDuration['text'] as String?) ?? '';
        }

        final steps = (leg['steps'] as List?) ?? [];
        for (final step in steps) {
          final stepPolyline = step['polyline'] as Map?;
          if (stepPolyline != null) {
            final encoded = (stepPolyline['points'] as String?) ?? '';
            if (encoded.isNotEmpty) {
              currentPoints.addAll(_decodePolyline(encoded));
            }
          }
        }
      }

      if (minDistanceMeters == null || currentDistanceMeters < minDistanceMeters) {
        minDistanceMeters = currentDistanceMeters;
        shortestRoutePoints = currentPoints;
        shortestDurationSeconds = currentDurationSeconds;
        shortestDistanceText = currentDistanceText;
        shortestDurationText = currentDurationText;
      }
    }

    if (shortestRoutePoints != null && minDistanceMeters != null) {
      return DirectionsResult(
        polylinePoints: shortestRoutePoints,
        distanceMeters: minDistanceMeters,
        distanceText: shortestDistanceText,
        durationSeconds: shortestDurationSeconds,
        durationText: shortestDurationText,
        status: 'OK',
      );
    }
    return null;
  }

  /// فك تشفير Encoded Polyline من Google
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

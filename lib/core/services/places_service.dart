/// خدمة البحث عن الأماكن
/// 
/// تستخدم Google Places API للبحث عن الأماكن
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

/// نموذج اقتراح المكان
class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      mainText: structuredFormatting['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

/// نموذج تفاصيل المكان
class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};
    final geometry = result['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    
    return PlaceDetails(
      placeId: result['place_id'] ?? '',
      name: result['name'] ?? '',
      address: result['formatted_address'] ?? '',
      location: LatLng(
        (location['lat'] ?? 0).toDouble(),
        (location['lng'] ?? 0).toDouble(),
      ),
    );
  }
}

/// خدمة البحث عن الأماكن باستخدام Google Places API
class PlacesService {
  PlacesService._();
  
  static final PlacesService _instance = PlacesService._();
  
  /// الحصول على instance وحيد
  static PlacesService get instance => _instance;
  
  /// مفتاح API
  final String _apiKey = AppConstants.googleMapsApiKey;
  
  /// رابط Autocomplete API
  static const String _autocompleteUrl = 
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  
  /// رابط Place Details API
  static const String _placeDetailsUrl = 
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// البحث عن أماكن
  /// 
  /// [query] - نص البحث
  /// [location] - الموقع الحالي للتركيز على النتائج القريبة (اختياري)
  /// [radius] - نطاق البحث بالمتر (اختياري، افتراضي 200 كم - يشمل كركوك وبغداد)
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    LatLng? location,
    int radius = 200000,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // بناء المعاملات
      final Map<String, String> params = {
        'input': query,
        'key': _apiKey,
        'components': 'country:iq', // التركيز على العراق
        'language': 'ar', // اللغة العربية
      };

      // استخدام موقع المستخدم أو نقطة وسط بين كركوك وبغداد
      if (location != null) {
        params['location'] = '${location.latitude},${location.longitude}';
      } else {
        // نقطة وسط بين السماوة وبغداد
        final centerLat = (AppConstants.samawahLat + AppConstants.baghdadLat) / 2;
        final centerLng = (AppConstants.samawahLng + AppConstants.baghdadLng) / 2;
        params['location'] = '$centerLat,$centerLng';
      }
      params['radius'] = radius.toString();

      // إرسال الطلب
      final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: params);
      debugPrint('🔍 PlacesService: Searching for "$query"');
      debugPrint('🔗 PlacesService: URL = $uri');
      
      final response = await http.get(uri);
      debugPrint('📥 PlacesService: Response status = ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📦 PlacesService: API Status = ${data['status']}');
        
        if (data['status'] != 'OK') {
          debugPrint('⚠️ PlacesService: Error message = ${data['error_message'] ?? 'No error message'}');
        }
        
        final predictions = data['predictions'] as List? ?? [];
        debugPrint('✅ PlacesService: Found ${predictions.length} results');
        
        return predictions
            .map((p) => PlaceSuggestion.fromJson(p))
            .toList();
      }

      debugPrint('❌ PlacesService: HTTP Error ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ PlacesService: Exception = $e');
      return [];
    }
  }

  /// الحصول على تفاصيل المكان
  /// 
  /// [placeId] - معرف المكان من Google Places
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) {
      return null;
    }

    try {
      final Map<String, String> params = {
        'place_id': placeId,
        'key': _apiKey,
        'fields': 'place_id,name,formatted_address,geometry',
        'language': 'ar',
      };

      final uri = Uri.parse(_placeDetailsUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

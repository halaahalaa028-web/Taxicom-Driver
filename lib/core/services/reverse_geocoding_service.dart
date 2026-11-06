/// خدمة تحويل الإحداثيات إلى عناوين دقيقة ومفصلة (Reverse Geocoding Engine)
///
/// تعتمد محركاً ذكياً متعدد المستويات (Cloud Functions -> Google Places/Geocoding -> OSM -> Native Geocoder)
/// مع معالجة ذكية للأماكن والمعالم الحقيقية وإلغاء الأرقام والطرق السريعة المجهولة لضمان أدق توصيف جغرافي.
library;

import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

class ReverseGeocodingService {
  ReverseGeocodingService._();
  static final ReverseGeocodingService _instance = ReverseGeocodingService._();
  static ReverseGeocodingService get instance => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final Map<String, String> _addressCache = {};

  bool _isPlusCode(String text) {
    final plusCodeOnlyPattern = RegExp(r'^\s*[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}\s*$');
    return plusCodeOnlyPattern.hasMatch(text.trim());
  }

  String _removePlusCode(String text) {
    if (_isPlusCode(text)) return '';
    final plusCodePattern = RegExp(r'[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}\s*,?\s*');
    String cleaned = text.replaceAll(plusCodePattern, '').trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^[،,]\s*'), '');
    return cleaned;
  }

  String _cleanAddressComponent(String text) {
    if (text.isEmpty) return '';
    String cleaned = _removePlusCode(text);
    final ignoredWords = [
      'العراق',
      'Iraq',
      'محافظة',
      'Province',
      'Governorate',
    ];
    for (String word in ignoredWords) {
      cleaned = cleaned
          .replaceAll(RegExp(word, caseSensitive: false), '')
          .trim();
    }
    cleaned = cleaned.replaceAll(RegExp(r'^(ناحية|قضاء|حي)\s+'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[،,]\s*[،,]'), '،');
    cleaned = cleaned.replaceAll(RegExp(r'^[،,\s]+|[،,\s]+$'), '');
    return cleaned;
  }

  /// فحص ما إذا كان الشارع اسماً غير مفيد (مثل أرقام الطرق أو Unnamed)
  bool _isUnwantedRoad(String road) {
    if (road.isEmpty) return true;
    final r = road.trim().toLowerCase();
    if (RegExp(r'^\d+$').hasMatch(r)) return true;
    if (RegExp(
      r'^(highway|route|m|hway|road|طريق|شارع)\s*\d+$',
      caseSensitive: false,
    ).hasMatch(r)) {
      return true;
    }
    if (r.contains('unnamed') ||
        r == 'road' ||
        r == 'street' ||
        r == 'طريق بدون اسم' ||
        r == 'شارع بدون اسم') {
      return true;
    }
    return false;
  }

  /// 1. استدعاء دالة Firebase Cloud Functions الوسيطة المؤمنة
  Future<Map<String, String>?> _getAddressFromCloudFunction(
    double latitude,
    double longitude,
  ) async {
    try {
      final callable = _functions.httpsCallable(
        'reverseGeocode',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 3)),
      );

      final response = await callable.call<Map<dynamic, dynamic>>({
        'latitude': latitude,
        'longitude': longitude,
        'language': 'ar',
      });

      final data = response.data;
      final status = data['status'] as String?;
      if (status == 'OK') {
        final formatted = (data['formattedAddress'] as String?) ?? '';
        final city = (data['city'] as String?) ?? '';
        final area = (data['area'] as String?) ?? '';
        final road = (data['road'] as String?) ?? '';

        return {
          'formatted': _cleanAddressComponent(formatted),
          'city': _cleanAddressComponent(city),
          'area': _cleanAddressComponent(area),
          'road': _cleanAddressComponent(road),
        };
      }
    } catch (_) {}
    return null;
  }

  /// 2. الاستعلام المباشر عبر Google Places Nearby Search لجلب أدق المعالم والأماكن
  Future<Map<String, String>?> _getAddressComponentsFromGooglePlaces(
    double latitude,
    double longitude,
  ) async {
    try {
      final apiKey = AppConstants.googleMapsApiKey;
      if (apiKey.isEmpty) return null;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=500&language=ar&key=$apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final results = data['results'] as List;
          String area = '';
          String poi = '';

          for (var res in results) {
            final name = res['name'] as String? ?? '';
            final vicinity = res['vicinity'] as String? ?? '';
            final types = List<String>.from(res['types'] ?? []);

            // أ) استخراج اسم المنطقة أو القضاء أو الحي
            if ((types.contains('sublocality') ||
                    types.contains('neighborhood') ||
                    types.contains('locality') ||
                    types.contains('administrative_area_level_2')) &&
                area.isEmpty) {
              if (name.isNotEmpty && !name.contains('محافظة')) area = name;
            } else if (vicinity.isNotEmpty && area.isEmpty) {
              final parts = vicinity.split('،');
              if (parts.isNotEmpty && !parts.first.contains('محافظة')) {
                area = parts.first.trim();
              }
            }

            // ب) استخراج المعلم أو المركز الخدمي/التجاري البارز
            final isPoiType =
                types.contains('shopping_mall') ||
                types.contains('supermarket') ||
                types.contains('department_store') ||
                types.contains('store') ||
                types.contains('school') ||
                types.contains('primary_school') ||
                types.contains('secondary_school') ||
                types.contains('university') ||
                types.contains('hospital') ||
                types.contains('pharmacy') ||
                types.contains('mosque') ||
                types.contains('place_of_worship') ||
                types.contains('cafe') ||
                types.contains('bank') ||
                types.contains('gas_station') ||
                types.contains('point_of_interest') ||
                types.contains('establishment');

            if (isPoiType && poi.isEmpty) {
              if (name.isNotEmpty &&
                  name.length > 3 &&
                  !name.contains('الهارثة') &&
                  !name.contains('البصرة') &&
                  !_isPlusCode(name) &&
                  !_isUnwantedRoad(name)) {
                poi = name;
              }
            }
          }

          return {
            'area': _cleanAddressComponent(area),
            'poi': _cleanAddressComponent(poi),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// 3. الاستعلام المباشر عبر Google Maps Geocoding API
  Future<Map<String, String>?> _getAddressComponentsFromGoogleHttp(
    double latitude,
    double longitude,
  ) async {
    try {
      final apiKey = AppConstants.googleMapsApiKey;
      if (apiKey.isEmpty) return null;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&language=ar&key=$apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final results = data['results'] as List;
          String city = '';
          String area = '';
          String route = '';
          String formatted = '';

          for (var result in results) {
            if (formatted.isEmpty) {
              formatted = (result['formatted_address'] as String?) ?? '';
            }
            final components = result['address_components'] as List?;
            if (components != null) {
              for (var comp in components) {
                final types = List<String>.from(comp['types'] ?? []);
                final longName = comp['long_name'] as String? ?? '';

                if (types.contains('locality') ||
                    types.contains('administrative_area_level_2')) {
                  if (area.isEmpty) area = longName;
                }
                if (types.contains('administrative_area_level_1')) {
                  if (city.isEmpty) city = longName;
                }
                if (types.contains('route')) {
                  if (route.isEmpty && !_isUnwantedRoad(longName)) {
                    route = longName;
                  }
                }
              }
            }
          }

          return {
            'formatted': _cleanAddressComponent(formatted),
            'city': _cleanAddressComponent(city),
            'area': _cleanAddressComponent(area),
            'road': _cleanAddressComponent(route),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// 4. الاستعلام الاحتياطي من OpenStreetMap (Nominatim)
  Future<Map<String, String>?> _getAddressComponentsFromOSM(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=ar',
      );
      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'TaxicomDriverApp/1.0 (contact@taxicom.app)',
            },
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data.containsKey('address')) {
          final address = data['address'] as Map<String, dynamic>;
          String city =
              address['city'] ??
              address['town'] ??
              address['state'] ??
              address['county'] ??
              '';
          String area =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['quarter'] ??
              address['subdistrict'] ??
              address['village'] ??
              '';
          String road =
              address['road'] ??
              address['highway'] ??
              address['pedestrian'] ??
              '';

          return {
            'city': _cleanAddressComponent(city),
            'area': _cleanAddressComponent(area),
            'road': _cleanAddressComponent(road),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// 5. الاستعلام الاحتياطي من Native Geocoder الخاص بالجهاز
  Future<Map<String, String>?> _getAddressComponentsFromNativeGeocoder(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return {
          'city': _cleanAddressComponent(
            place.locality ?? place.administrativeArea ?? '',
          ),
          'area': _cleanAddressComponent(
            place.subLocality ?? place.subAdministrativeArea ?? '',
          ),
          'road': _cleanAddressComponent(place.street ?? place.name ?? ''),
        };
      }
    } catch (_) {}
    return null;
  }

  /// تحويل الإحداثيات إلى اسم عنوان واضح ومختصر وموثوق ومعلم بارز
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    final cacheKey =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    String city = '';
    String area = '';
    String road = '';
    String poi = '';
    String formatted = '';

    // المستوى 1: Google Places لجلب المعلم الدقيق (POI) والمنطقة
    final placesData = await _getAddressComponentsFromGooglePlaces(
      latitude,
      longitude,
    );
    if (placesData != null) {
      if (area.isEmpty) area = placesData['area'] ?? '';
      if (poi.isEmpty) poi = placesData['poi'] ?? '';
    }

    // المستوى 2: Google Geocoding HTTP
    if (area.isEmpty || city.isEmpty) {
      final googleData = await _getAddressComponentsFromGoogleHttp(
        latitude,
        longitude,
      );
      if (googleData != null) {
        if (area.isEmpty) area = googleData['area'] ?? '';
        if (city.isEmpty) city = googleData['city'] ?? '';
        if (road.isEmpty) road = googleData['road'] ?? '';
        if (formatted.isEmpty) formatted = googleData['formatted'] ?? '';
      }
    }

    // المستوى 3: الدالة السحابية (إذا كانت مفعلة)
    if (area.isEmpty || city.isEmpty) {
      final cloudData = await _getAddressFromCloudFunction(latitude, longitude);
      if (cloudData != null) {
        if (city.isEmpty) city = cloudData['city'] ?? '';
        if (area.isEmpty) area = cloudData['area'] ?? '';
        if (road.isEmpty) road = cloudData['road'] ?? '';
        if (formatted.isEmpty) formatted = cloudData['formatted'] ?? '';
      }
    }

    // المستوى 4: OpenStreetMap
    if (area.isEmpty && city.isEmpty) {
      final osmData = await _getAddressComponentsFromOSM(latitude, longitude);
      if (osmData != null) {
        if (city.isEmpty) city = osmData['city'] ?? '';
        if (area.isEmpty) area = osmData['area'] ?? '';
        if (road.isEmpty) road = osmData['road'] ?? '';
      }
    }

    // المستوى 5: Native Geocoder
    if (area.isEmpty && city.isEmpty) {
      final nativeData = await _getAddressComponentsFromNativeGeocoder(
        latitude,
        longitude,
      );
      if (nativeData != null) {
        if (city.isEmpty) city = nativeData['city'] ?? '';
        if (area.isEmpty) area = nativeData['area'] ?? '';
        if (road.isEmpty) road = nativeData['road'] ?? '';
      }
    }

    // استبعاد الطرق الرقمية وغير المسماة
    if (_isUnwantedRoad(road)) {
      road = '';
    }

    // بناء العنوان بترتيب طبيعي: [اسم المنطقة/الحي]، [مجاور المعلم / اسم الشارع الحقيقي / المدينة]
    List<String> parts = [];
    if (area.isNotEmpty) {
      parts.add(area);
    }

    if (poi.isNotEmpty && poi != area && !parts.contains(poi)) {
      parts.add('مجاور $poi');
    } else if (road.isNotEmpty && road != area && !parts.contains(road)) {
      parts.add(road);
    } else if (city.isNotEmpty && city != area && !parts.contains(city)) {
      parts.add(city);
    }

    String finalAddress = '';
    if (parts.isNotEmpty) {
      finalAddress = parts.join('، ');
    } else if (formatted.isNotEmpty) {
      finalAddress = formatted;
    } else if (city.isNotEmpty) {
      finalAddress = city;
    } else {
      finalAddress = 'موقع السائق الحالي';
    }

    _addressCache[cacheKey] = finalAddress;
    return finalAddress;
  }
}

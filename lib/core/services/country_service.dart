/// خدمة إدارة إعدادات البلدان والبلد المحدد لتطبيق السائق
///
/// تجلب البلدان المفعلة من Firestore وتوفر الدولة الافتراضية (مصر)
/// وتدير اختيار السائق للبلد مع حفظه محلياً
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/country_config.dart';

class CountryService extends ChangeNotifier {
  CountryService._();
  static final CountryService _instance = CountryService._();
  static CountryService get instance => _instance;

  static const String _prefKeySelectedCountry = 'taxicom_driver_selected_country_code';
  static const String _collection = 'settings';
  static const String _document = 'countries';

  Map<String, CountryConfig> _countries = Map.from(defaultCountries);
  CountryConfig _selectedCountry = defaultCountries['EG']!;
  bool _isLoaded = false;
  StreamSubscription<DocumentSnapshot>? _subscription;

  // ─── Getters ────────────────────────────────────────────────────────────────
  CountryConfig get selectedCountry => _selectedCountry;
  Map<String, CountryConfig> get allCountries => _countries;
  bool get isLoaded => _isLoaded;

  /// قائمة الدول المفعلة مرتبة حسب الترتيب المحدد
  List<CountryConfig> get enabledCountries {
    final List<CountryConfig> list = [];
    for (final code in countriesOrder) {
      final country = _countries[code];
      if (country != null && country.isEnabled) {
        list.add(country);
      }
    }
    // التأكد من أن هناك دولة واحدة على الأقل مفعلة (مصر كإحتياط)
    if (list.isEmpty) {
      list.add(defaultCountries['EG']!);
    }
    return list;
  }

  /// هل يوجد أكثر من دولة مفعلة في النظام؟
  bool get isMultipleCountriesEnabled => enabledCountries.length > 1;

  /// استرجاع دولة محددة بالكود
  CountryConfig getCountryByCode(String countryCode) {
    return _countries[countryCode.toUpperCase()] ?? defaultCountries[countryCode.toUpperCase()] ?? _selectedCountry;
  }

  /// تعيين واختيار الدولة
  Future<void> selectCountry(CountryConfig country) async {
    if (_selectedCountry.code == country.code && _selectedCountry.isEnabled) return;
    _selectedCountry = country;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySelectedCountry, country.code);
    } catch (e) {
      debugPrint('⚠️ CountryService: تعذر حفظ الدولة المحددة محلياً: $e');
    }
  }

  /// تعيين الدولة بالكود
  Future<void> selectCountryByCode(String countryCode) async {
    final candidate = _countries[countryCode.toUpperCase()];
    if (candidate != null && candidate.isEnabled) {
      await selectCountry(candidate);
    }
  }

  /// جلب تكوين البلدان من Firestore مع التحقق اللحظي
  Future<List<CountryConfig>> fetchCountries({bool forceRefresh = false}) async {
    try {
      // 1. استرجاع الاختيار المحفوظ محلياً أولاً
      await _loadSavedCountryCode();

      // 2. جلب التكوين من Firestore (محاولة السيرفر أولاً عند الطلب)
      final source = forceRefresh ? Source.server : Source.serverAndCache;
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_document)
          .get(GetOptions(source: source));

      if (doc.exists && doc.data() != null) {
        _applyData(doc.data());
      }
    } catch (e) {
      // محاولة استرداد من الكاش في حال انقطاع الشبكة
      try {
        final cachedDoc = await FirebaseFirestore.instance
            .collection(_collection)
            .doc(_document)
            .get(const GetOptions(source: Source.cache));
        if (cachedDoc.exists && cachedDoc.data() != null) {
          _applyData(cachedDoc.data());
        }
      } catch (_) {}
      debugPrint('⚠️ CountryService: خطأ في جلب الدول من Firestore: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
    return enabledCountries;
  }

  /// التحقق السريع من البلدان المفعلة قبل فتح القائمة
  Future<List<CountryConfig>> refreshAndGetEnabledCountries() async {
    return await fetchCountries(forceRefresh: true);
  }

  /// الاستماع للتحديثات الحية للدول
  void startListening() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection(_collection)
        .doc(_document)
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          _applyData(doc.data());
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('⚠️ CountryService: خطأ في الاستماع للبلدان: $e');
      },
    );
  }

  /// تطبيق البيانات المجلوبة من Firestore
  void _applyData(Map<String, dynamic>? data) {
    if (data == null) return;
    final countriesData = data['countries'] as Map<String, dynamic>?;
    if (countriesData == null) return;

    final Map<String, CountryConfig> updated = Map.from(defaultCountries);

    countriesData.forEach((code, value) {
      if (value is Map<String, dynamic>) {
        final existing = updated[code];
        if (existing != null) {
          updated[code] = CountryConfig.fromMap(code, value, existing);
        }
      }
    });

    _countries = updated;

    // إذا كانت الدولة المحددة حالياً غير مفعلة، نختار أول دولة مفعلة من الترتيب
    final currentInUpdated = _countries[_selectedCountry.code];
    if (currentInUpdated == null || !currentInUpdated.isEnabled) {
      CountryConfig? firstEnabled;
      for (final code in countriesOrder) {
        final candidate = _countries[code];
        if (candidate != null && candidate.isEnabled) {
          firstEnabled = candidate;
          break;
        }
      }
      _selectedCountry = firstEnabled ?? defaultCountries['EG']!;
    } else {
      _selectedCountry = currentInUpdated;
    }
  }

  /// تحميل كود الدولة المحفوظ محلياً
  Future<void> _loadSavedCountryCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKeySelectedCountry);
      if (savedCode != null && _countries.containsKey(savedCode)) {
        final candidate = _countries[savedCode]!;
        if (candidate.isEnabled) {
          _selectedCountry = candidate;
        }
      }
    } catch (e) {
      debugPrint('⚠️ CountryService: خطأ في قراءة الدولة المحفوظة: $e');
    }
  }

  /// إيقاف الاستماع
  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

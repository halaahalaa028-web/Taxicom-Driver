/// خدمة الترجمة الفورية المركزية
/// 
/// توفر وظائف الترجمة التلقائية لرسائل المحادثة
/// باستخدام Google Cloud Translation API مع نظام تخزين مؤقت (Cache)
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// نتيجة عملية الترجمة
class TranslationResult {
  /// النص المترجم
  final String translatedText;

  /// لغة المصدر المكتشفة
  final String detectedSourceLanguage;

  /// هل تختلف الترجمة عن النص الأصلي
  final bool isDifferent;

  const TranslationResult({
    required this.translatedText,
    required this.detectedSourceLanguage,
    required this.isDifferent,
  });
}

/// خدمة الترجمة المركزية
class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance => _instance ??= TranslationService._();

  TranslationService._();

  /// ذاكرة التخزين المؤقت للترجمات (لتجنب تكرار الطلبات وتوفير الرصيد)
  final Map<String, TranslationResult> _cache = {};

  /// حالة تفعيل الترجمة التلقائية
  final ValueNotifier<bool> isAutoTranslateEnabled = ValueNotifier<bool>(true);

  /// تبديل حالة تفعيل الترجمة
  void toggleAutoTranslate() {
    isAutoTranslateEnabled.value = !isAutoTranslateEnabled.value;
  }

  /// ترجمة نص إلى اللغة المستهدفة
  Future<TranslationResult?> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    final cacheKey = '${sourceLanguage ?? 'auto'}_${targetLanguage}_$cleanText';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final uri = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=${AppConstants.googleTranslationApiKey}',
      );

      final body = <String, dynamic>{
        'q': cleanText,
        'target': targetLanguage,
        'format': 'text',
      };

      if (sourceLanguage != null && sourceLanguage.isNotEmpty) {
        body['source'] = sourceLanguage;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final translations = data['data']?['translations'] as List<dynamic>?;

        if (translations != null && translations.isNotEmpty) {
          final first = translations[0] as Map<String, dynamic>;
          final rawTranslated = first['translatedText'] as String? ?? cleanText;
          final detectedSource = (first['detectedSourceLanguage'] as String?) ?? sourceLanguage ?? '';

          // فك رموز HTML entities إن وجدت في الاستجابة
          final translatedText = _unescapeHtml(rawTranslated);
          final isDiff = detectedSource != targetLanguage && 
                         translatedText.trim().toLowerCase() != cleanText.toLowerCase();

          final result = TranslationResult(
            translatedText: translatedText,
            detectedSourceLanguage: detectedSource,
            isDifferent: isDiff,
          );

          _cache[cacheKey] = result;
          return result;
        }
      } else {
        debugPrint('Translation API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Translation error: $e');
    }

    return null;
  }

  /// تنظيف الرموز الخاصة بـ HTML من النص
  String _unescapeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  /// مسح الذاكرة المؤقتة
  void clearCache() {
    _cache.clear();
  }
}

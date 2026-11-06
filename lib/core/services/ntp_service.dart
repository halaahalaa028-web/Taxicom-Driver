/// خدمة NTP للوقت الدقيق
/// 
/// توفر الوقت الدقيق من خوادم NTP لتجنب التلاعب بوقت الجهاز
library;

import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';

/// خدمة الوقت الدقيق
class NtpService {
  NtpService._();
  
  static final NtpService _instance = NtpService._();
  static NtpService get instance => _instance;
  
  /// الفرق بين وقت الجهاز والوقت الحقيقي (بالميلي ثانية)
  int _offset = 0;
  
  /// هل تم تهيئة الخدمة
  bool _initialized = false;

  /// تهيئة الخدمة وجلب الوقت من خادم NTP
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _offset = await NTP.getNtpOffset(
        localTime: DateTime.now(),
        lookUpAddress: 'time.google.com',
        timeout: const Duration(seconds: 5),
      );
      _initialized = true;
      debugPrint('✅ NTP Service initialized. Offset: $_offset ms');
    } catch (e) {
      debugPrint('⚠️ NTP initialization failed: $e. Using device time.');
      _offset = 0;
      _initialized = true; // نعتبرها مهيأة حتى لو فشلت
    }
  }

  /// الحصول على الوقت الحالي الدقيق
  DateTime getCurrentTime() {
    if (!_initialized) {
      debugPrint('⚠️ NTP not initialized, using device time');
      return DateTime.now();
    }
    return DateTime.now().add(Duration(milliseconds: _offset));
  }

  /// إعادة تهيئة الخدمة (لتحديث الوقت)
  Future<void> refresh() async {
    _initialized = false;
    await initialize();
  }
}

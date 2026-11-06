/// خدمة الصوت
/// 
/// تستخدم لتشغيل أصوات الإشعارات في التطبيق
library;

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/foundation.dart';

/// خدمة الصوت للإشعارات
class SoundService {
  // Singleton instance
  static final SoundService _instance = SoundService._internal();
  static SoundService get instance => _instance;
  
  SoundService._internal();
  
  // هل الصوت مفعل
  bool _isSoundEnabled = true;
  
  // مشغل الصوت
  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  
  /// تشغيل صوت إشعار الرحلة الجديدة
  Future<void> playNewTripSound() async {
    if (!_isSoundEnabled) {
      debugPrint('🔇 الصوت معطل');
      return;
    }
    
    try {
      debugPrint('🔊 محاولة تشغيل صوت الإشعار...');
      
      // تشغيل صوت إشعار النظام
      await _player.playNotification();
      
      debugPrint('✅ تم تشغيل الصوت بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الصوت: $e');
    }
  }
  
  /// تفعيل/تعطيل الصوت
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }
  
  /// هل الصوت مفعل
  bool get isSoundEnabled => _isSoundEnabled;
}

/// خدمة التحقق من التحديثات باستخدام Firebase Remote Config
/// 
/// تتحقق من وجود تحديثات جديدة للتطبيق
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'language_service.dart';

/// نموذج معلومات التحديث
class UpdateInfo {
  final String minimumVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrlAndroid;
  final String updateUrlIos;
  final String whatsNewAr;
  final String whatsNewKu;
  final String whatsNewTr;

  UpdateInfo({
    required this.minimumVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrlAndroid,
    required this.updateUrlIos,
    required this.whatsNewAr,
    required this.whatsNewKu,
    required this.whatsNewTr,
  });

  /// الحصول على رابط التحديث حسب نظام التشغيل
  String get updateUrl {
    if (Platform.isIOS) {
      return updateUrlIos.isNotEmpty ? updateUrlIos : updateUrlAndroid;
    }
    return updateUrlAndroid;
  }

  /// الحصول على نص "ما الجديد" حسب اللغة الحالية
  String getWhatsNew() {
    final lang = LanguageService.instance.currentLanguage;
    switch (lang) {
      case AppLanguage.english:
        return whatsNewAr; // English falls back to Arabic for now
      case AppLanguage.kurdish:
        return whatsNewKu.isNotEmpty ? whatsNewKu : whatsNewAr;
      case AppLanguage.turkmen:
        return whatsNewTr.isNotEmpty ? whatsNewTr : whatsNewAr;
      case AppLanguage.arabic:
        return whatsNewAr;
    }
  }
}

/// نتيجة فحص التحديث
enum UpdateStatus {
  /// لا يوجد تحديث متاح
  noUpdate,
  /// تحديث اختياري متاح
  optionalUpdate,
  /// تحديث إجباري مطلوب
  forceUpdate,
}

/// خدمة التحقق من التحديثات
class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  
  UpdateService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  String? _currentVersion;
  bool _isInitialized = false;

  /// تهيئة Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // ضبط إعدادات Remote Config
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1), // للاختبار - غيّرها لساعة في الإنتاج
      ));

      // القيم الافتراضية
      await _remoteConfig.setDefaults({
        'minimum_version': '1.0.0',
        'latest_version': '1.0.0',
        'force_update': false,
        'update_url_android': 'https://play.google.com/store/apps/details?id=com.techsolu.SamawahTaxi',
        'update_url_ios': '',
        'whats_new_ar': '',
        'whats_new_ku': '',
        'whats_new_tr': '',
      });

      // جلب وتفعيل القيم
      final activated = await _remoteConfig.fetchAndActivate();
      debugPrint('🔄 Remote Config activated: $activated');
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Remote Config error: $e');
      _isInitialized = true;
    }
  }

  /// الحصول على إصدار التطبيق الحالي
  Future<String> _getCurrentVersion() async {
    if (_currentVersion != null) return _currentVersion!;
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
    return _currentVersion!;
  }

  /// جلب معلومات التحديث من Remote Config
  UpdateInfo getUpdateInfo() {
    return UpdateInfo(
      minimumVersion: _remoteConfig.getString('minimum_version'),
      latestVersion: _remoteConfig.getString('latest_version'),
      forceUpdate: _remoteConfig.getBool('force_update'),
      updateUrlAndroid: _remoteConfig.getString('update_url_android'),
      updateUrlIos: _remoteConfig.getString('update_url_ios'),
      whatsNewAr: _remoteConfig.getString('whats_new_ar'),
      whatsNewKu: _remoteConfig.getString('whats_new_ku'),
      whatsNewTr: _remoteConfig.getString('whats_new_tr'),
    );
  }

  /// فحص حالة التحديث
  Future<(UpdateStatus, UpdateInfo?)> checkForUpdate() async {
    try {
      // التأكد من التهيئة
      if (!_isInitialized) {
        await initialize();
      }

      final updateInfo = getUpdateInfo();
      final currentVersion = await _getCurrentVersion();
      
      // Debug logging
      debugPrint('📱 Current version: $currentVersion');
      debugPrint('📋 Minimum version: ${updateInfo.minimumVersion}');
      debugPrint('📋 Latest version: ${updateInfo.latestVersion}');
      debugPrint('🔒 Force update: ${updateInfo.forceUpdate}');
      debugPrint('📝 Whats new AR: ${updateInfo.whatsNewAr}');
      
      // إذا كان الإصدار الحالي أقل من الإصدار الأدنى المطلوب - تحديث إجباري دائماً
      if (_compareVersions(currentVersion, updateInfo.minimumVersion) < 0) {
        debugPrint('⚠️ Result: FORCE UPDATE (current < minimum)');
        return (UpdateStatus.forceUpdate, updateInfo);
      }
      
      // إذا كان الإصدار الحالي أقل من أحدث إصدار - تحديث اختياري أو إجباري حسب الإعداد
      if (_compareVersions(currentVersion, updateInfo.latestVersion) < 0) {
        if (updateInfo.forceUpdate) {
          debugPrint('⚠️ Result: FORCE UPDATE (force_update=true)');
          return (UpdateStatus.forceUpdate, updateInfo);
        }
        debugPrint('ℹ️ Result: OPTIONAL UPDATE');
        return (UpdateStatus.optionalUpdate, updateInfo);
      }
      
      debugPrint('✅ Result: NO UPDATE');
      return (UpdateStatus.noUpdate, null);
    } catch (e) {
      debugPrint('❌ Update check error: $e');
      return (UpdateStatus.noUpdate, null);
    }
  }

  /// مقارنة إصدارين (semantic versioning)
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final parts2 = v2.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    
    return 0;
  }
}

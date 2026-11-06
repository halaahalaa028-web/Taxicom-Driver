/// خدمة فحص اتصال الإنترنت (Network Service)
///
/// توفر فحصاً فورياً فائق السرعة عبر الاتصال المباشر بمنفذ DNS (8.8.8.8:53)
/// بالإضافة إلى DNS Lookup احتياطي، وتدعم البث التفاعلي عبر ValueNotifier
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  bool _lastKnownStatus = true;
  DateTime? _lastCheckTime;
  static const Duration _cacheDuration = Duration(seconds: 2);

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(true);
  Timer? _periodicTimer;

  /// التحقق الفوري مما إذا كان الجهاز متصلاً بالإنترنت فعلياً
  Future<bool> hasInternetConnection({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastCheckTime != null &&
        now.difference(_lastCheckTime!) < _cacheDuration) {
      return _lastKnownStatus;
    }

    try {
      // فحص سريع ومباشر على IP بدون انتظار مترجم DNS
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      _updateStatus(true, now);
      return true;
    } catch (_) {
      // فحص احتياطي بديل
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        _updateStatus(isConnected, now);
        return isConnected;
      } catch (e) {
        debugPrint('📡 [NetworkService] Internet connection check failed: Offline');
        _updateStatus(false, now);
        return false;
      }
    }
  }

  void _updateStatus(bool isConnected, DateTime time) {
    _lastKnownStatus = isConnected;
    _lastCheckTime = time;
    if (isConnectedNotifier.value != isConnected) {
      isConnectedNotifier.value = isConnected;
      debugPrint('📡 [NetworkService] isConnected changed to: $isConnected');
    }
  }

  /// بدء الفحص الدوري لحالة الاتصال
  void startPeriodicCheck({Duration interval = const Duration(seconds: 5)}) {
    _periodicTimer?.cancel();
    hasInternetConnection(forceRefresh: true);
    _periodicTimer = Timer.periodic(interval, (_) {
      hasInternetConnection(forceRefresh: true);
    });
  }

  /// إيقاف الفحص الدوري
  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// الحالة الأخيرة المعروفة للاتصال
  bool get isConnected => _lastKnownStatus;
}

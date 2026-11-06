/// نافذة تنبيه انقطاع الإنترنت (No Internet Dialog)
///
/// تعرض تنبيهاً أنيقاً للسائق عند محاولة تنفيذ أي إجراء دون توفر إنترنت
/// متوافقة مع Design System وتدعم إعادة المحاولة الفورية
library;

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/language_service.dart';
import '../../services/network_service.dart';

class NoInternetDialog extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetDialog({
    super.key,
    this.onRetry,
  });

  /// عرض النافذة المنبثقة
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => NoInternetDialog(onRetry: onRetry),
    );
  }

  /// فحص الاتصال وتنفيذ الإجراء، أو عرض النافذة تلقائياً إذا كان مفصولاً
  static Future<bool> ensureConnected(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    final isConnected = await NetworkService.instance.hasInternetConnection();
    if (!isConnected && context.mounted) {
      await show(context, onRetry: onRetry);
      return false;
    }
    return true;
  }

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog> {
  bool _isChecking = false;
  String? _errorMessage;

  Map<String, String> _getTexts() {
    final lang = LanguageService.instance.currentLanguage;
    switch (lang) {
      case AppLanguage.english:
        return {
          'title': 'No Internet Connection',
          'message': 'Please check your connection and enable Wi-Fi or mobile data to continue.',
          'retry': 'Retry',
          'cancel': 'Cancel',
          'stillDisconnected': 'Still not connected to the internet',
        };
      case AppLanguage.kurdish:
        return {
          'title': 'هێڵی ئینتەرنێت نییە',
          'message': 'تکایە دڵنیابە لە پەیوەستبوونی ئینتەرنێت و کاراکردنی Wi-Fi یان داتای مۆبایل بۆ بەردەوامبوون.',
          'retry': 'دووبارە هەوڵبدەوە',
          'cancel': 'پاشگەزبوونەوە',
          'stillDisconnected': 'هێشتا پەیوەست نەبووە بە ئینتەرنێتەوە',
        };
      case AppLanguage.arabic:
      default:
        return {
          'title': 'لا يوجد اتصال بالإنترنت',
          'message': 'يرجى التأكد من تشغيل الواي فاي (Wi-Fi) أو تفعيل بيانات الهاتف للمتابعة.',
          'retry': 'إعادة المحاولة',
          'cancel': 'إلغاء',
          'stillDisconnected': 'ما زال الهاتف غير متصل بالإنترنت',
        };
    }
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final isConnected = await NetworkService.instance.hasInternetConnection(forceRefresh: true);

    if (!mounted) return;

    if (isConnected) {
      Navigator.of(context).pop();
      widget.onRetry?.call();
    } else {
      final texts = _getTexts();
      setState(() {
        _isChecking = false;
        _errorMessage = texts['stillDisconnected'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = _getTexts();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة انقطاع الشبكة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // العنوان
            Text(
              texts['title']!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // الرسالة
            Text(
              texts['message']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // أزرار التحكم
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _handleRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            texts['retry']!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      texts['cancel']!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

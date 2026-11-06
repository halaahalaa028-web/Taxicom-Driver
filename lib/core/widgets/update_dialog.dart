/// نافذة التحديث
/// 
/// تعرض نافذة منبثقة لإعلام المستخدم بوجود تحديث جديد
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/update_service.dart';
import '../services/language_service.dart';

/// نافذة التحديث
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final bool isForceUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.isForceUpdate,
  });

  /// عرض نافذة التحديث
  static Future<void> show(
    BuildContext context, {
    required UpdateInfo updateInfo,
    required bool isForceUpdate,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => PopScope(
        canPop: !isForceUpdate,
        child: UpdateDialog(
          updateInfo: updateInfo,
          isForceUpdate: isForceUpdate,
        ),
      ),
    );
  }

  Map<String, String> _getTexts() {
    final lang = LanguageService.instance.currentLanguage;
    switch (lang) {
      case AppLanguage.english:
        return {
          'title': 'New Update',
          'forceMessage': 'You must install this update to continue',
          'optionalMessage': 'A new update is available',
          'whatsNew': "What's New:",
          'updateNow': 'Update Now',
          'later': 'Later',
          'version': 'Version',
        };
      case AppLanguage.kurdish:
        return {
          'title': 'نوێکردنەوەی نوێ',
          'forceMessage': 'دەبێت ئەم نوێکردنەوەیە دابگریت بۆ بەردەوامبوون',
          'optionalMessage': 'نوێکردنەوەیەکی نوێ بەردەستە',
          'whatsNew': 'چی نوێیە:',
          'updateNow': 'نوێکردنەوە ئێستا',
          'later': 'دواتر',
          'version': 'وەشان',
        };
      case AppLanguage.turkmen:
        return {
          'title': 'Täze güncelleştirme',
          'forceMessage': 'Devam etmek için bu güncelleştirmeyi yüklemelisiniz',
          'optionalMessage': 'Yeni bir güncelleştirme mevcut',
          'whatsNew': 'Yenilikler:',
          'updateNow': 'Şimdi güncelle',
          'later': 'Daha sonra',
          'version': 'Sürüm',
        };
      case AppLanguage.arabic:
        return {
          'title': 'تحديث جديد',
          'forceMessage': 'يجب تثبيت هذا التحديث للمتابعة',
          'optionalMessage': 'يتوفر تحديث جديد للتطبيق',
          'whatsNew': 'ما الجديد:',
          'updateNow': 'تحديث الآن',
          'later': 'لاحقاً',
          'version': 'الإصدار',
        };
    }
  }

  Future<void> _openUpdateUrl() async {
    final uri = Uri.parse(updateInfo.updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = _getTexts();
    final whatsNew = updateInfo.getWhatsNew();

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
            // أيقونة التحديث
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isForceUpdate ? Icons.system_update : Icons.update,
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // رقم الإصدار الجديد
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${texts['version']!} ${updateInfo.latestVersion}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // رسالة التحديث
            Text(
              isForceUpdate ? texts['forceMessage']! : texts['optionalMessage']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // ما الجديد
            if (whatsNew.isNotEmpty) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  texts['whatsNew']!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    whatsNew,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // أزرار التحكم
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openUpdateUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      texts['updateNow']!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                if (!isForceUpdate) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        texts['later']!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

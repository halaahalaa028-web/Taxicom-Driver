import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/language_service.dart';

/// زر اختيار وتغيير لغة التطبيق في شاشات المصادقة
class AuthLanguageButton extends StatelessWidget {
  const AuthLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = LanguageService.instance.currentLanguage;

    return PopupMenuButton<AppLanguage>(
      onSelected: (language) async {
        if (language == AppLanguage.turkmen) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                'تنبيه',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'قريبا ستتوفر هذه اللغة',
                style: TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(fontFamily: 'Cairo', color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );
          return;
        }

        await LanguageService.instance.setLanguage(language);
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              currentLang.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => AppLanguage.values
          .where((l) => l != AppLanguage.turkmen && l != AppLanguage.kurdish)
          .map((language) {
        final isSelected = language == currentLang;
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              const Text('🇮🇶', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language.name,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

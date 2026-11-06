/// شاشة إعدادات اللغة والحساب
/// 
/// تتيح للسائق اختيار لغة التطبيق أو طلب حذف الحساب نهائياً
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../widgets/widgets.dart';

/// شاشة إعدادات اللغة والحساب
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LanguageService.instance.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم اللغة
          _buildSectionTitle(l10n.selectLanguage),
          const SizedBox(height: 12),
          
          // قائمة اللغات
          ...AppLanguage.values
              .where((l) => l != AppLanguage.turkmen && l != AppLanguage.kurdish)
              .map(
                (language) => LanguageItemTile(
                  language: language,
                  isSelected: _selectedLanguage == language,
                  onSelect: _selectLanguage,
                ),
              ),
          
          const SizedBox(height: 32),
          
          // قسم الحساب
          _buildSectionTitle(l10n.accountData),
          const SizedBox(height: 12),
          
          // زر حذف الحساب
          DeleteAccountSection(
            onTap: () => DeleteAccountDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Future<void> _selectLanguage(AppLanguage language) async {
    // إذا كانت اللغة المختارة هي التركمانية (قريباً)
    if (language == AppLanguage.turkmen) {
      if (mounted) {
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
      }
      return;
    }

    if (_selectedLanguage == language) return;
    
    setState(() {
      _selectedLanguage = language;
    });
    
    await LanguageService.instance.setLanguage(language);
    // لا حاجة للتنقل - المفتاح (ValueKey) في MaterialApp يجبر إعادة إنشاء الشجرة تلقائياً
  }
}

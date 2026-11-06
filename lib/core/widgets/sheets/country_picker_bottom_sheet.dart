/// واجهة اختيار الدولة السفلية لتطبيق السائق
///
/// تعرض قائمة الدول المفعلة فقط بنمط أحادي أنيق متوافق مع معايير التصميم
library;

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/country_config.dart';
import '../../services/country_service.dart';
import '../../services/language_service.dart';

class CountryPickerBottomSheet extends StatefulWidget {
  const CountryPickerBottomSheet({super.key});

  /// فتح النافذة السفلية لاختيار الدولة مع التحقق اللحظي المسبق
  static Future<CountryConfig?> show(BuildContext context) async {
    // تشغيل جلب فوري متزامن/سريع قبل العرض
    await CountryService.instance.fetchCountries();

    if (!context.mounted) return null;

    return showModalBottomSheet<CountryConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CountryPickerBottomSheet(),
    );
  }

  @override
  State<CountryPickerBottomSheet> createState() => _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // فحص إضافي سريع في الخلفية لتحديث أي تغييرات طارئة في لوحة التحكم
    CountryService.instance.refreshAndGetEnabledCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = LanguageService.instance.currentLanguage == AppLanguage.arabic;
    final langCode = isArabic ? 'ar' : 'en';

    return ListenableBuilder(
      listenable: CountryService.instance,
      builder: (context, _) {
        final enabledCountries = CountryService.instance.enabledCountries;
        final selectedCountry = CountryService.instance.selectedCountry;

        // تصفية الدول بناءً على نص البحث
        final filteredCountries = enabledCountries.where((c) {
          if (_searchQuery.trim().isEmpty) return true;
          final query = _searchQuery.trim().toLowerCase();
          final name = c.getName(langCode).toLowerCase();
          final dialCode = c.dialCode.toLowerCase();
          return name.contains(query) || dialCode.contains(query);
        }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // مقبض السحب العلوي
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // عنوان النافذة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.selectCountry,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // حقل البحث إذا كان هناك أكثر من 4 دول
          if (enabledCountries.length > 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.searchCountry,
                  hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // قائمة البلدان
          Flexible(
            child: filteredCountries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      l10n.noCountriesFound,
                      style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredCountries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected = country.code == selectedCountry.code;

                      return InkWell(
                        onTap: () {
                          CountryService.instance.selectCountry(country);
                          Navigator.pop(context, country);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Row(
                            children: [
                              // العلم
                              Text(
                                country.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 14),
                              // اسم الدولة
                              Expanded(
                                child: Text(
                                  country.getName(langCode),
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // مفتاح الاتصال
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  country.dialCode,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // مؤشر الاختيار
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? AppColors.primary : AppColors.border,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
      },
    );
  }
}

/// بطاقة إدخال رقم الهاتف مع رمز الدولة لتطبيق السائق
///
/// تدعم التحديد الديناميكي للدولة وفتح نافذة الاختيار عند تفعيل أكثر من دولة
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/country_service.dart';
import '../../../../core/widgets/sheets/country_picker_bottom_sheet.dart';

class PhoneInputCard extends StatelessWidget {
  final TextEditingController phoneController;
  final String? Function(String?)? validator;

  const PhoneInputCard({
    super.key,
    required this.phoneController,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: CountryService.instance,
      builder: (context, _) {
        final countryService = CountryService.instance;
        final selectedCountry = countryService.selectedCountry;
        final isMultipleEnabled = countryService.isMultipleCountriesEnabled;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Cairo',
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(selectedCountry.maxPhoneLength > 0 ? selectedCountry.maxPhoneLength : AppConstants.maxPhoneLength),
              ],
              validator: validator,
              decoration: InputDecoration(
                labelText: l10n.phoneHint,
                hintText: selectedCountry.phonePlaceholder,
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                hintStyle: const TextStyle(letterSpacing: 1, color: AppColors.textSecondary, fontSize: 13),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                prefixIcon: InkWell(
                  onTap: () => CountryPickerBottomSheet.show(context),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // العلم
                        Text(
                          selectedCountry.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 6),
                        // رمز الاتصال الدولي
                        Text(
                          selectedCountry.dialCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        // سهم القائمة المنسدلة يظهر فقط إذا كان مسموحاً بالاختيار (عدة بلدان مفعلة)
                        if (isMultipleEnabled) ...[
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                        const SizedBox(width: 8),
                        // خط فاصل عمودي
                        Container(
                          width: 1,
                          height: 18,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

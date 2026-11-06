/// ويدجت إدخال البيانات الشخصية للسائق
///
/// يحتوي على حقول الاسم، المحافظة، الجنس، وتاريخ الميلاد مع دعم الدولة الديناميكية
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'province_city_picker.dart';

/// ويدجت نموذج البيانات الشخصية للسائق
class DriverPersonalInfoFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedProvince;
  final String? countryCode;
  final String? selectedGender;
  final DateTime? selectedBirthDate;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onSelectBirthDate;

  const DriverPersonalInfoFormWidget({
    super.key,
    required this.nameController,
    required this.selectedProvince,
    this.countryCode,
    required this.selectedGender,
    required this.selectedBirthDate,
    required this.onProvinceChanged,
    required this.onGenderChanged,
    required this.onSelectBirthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'البيانات الشخصية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'يرجى إدخال الاسم الثلاثي واللقب';
              }
              if (val.trim().split(RegExp(r'\s+')).length < 3) {
                return 'يرجى كتابة الاسم الثلاثي واللقب';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'الاسم الثلاثي واللقب *',
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ProvinceCityPicker(
            value: selectedProvince,
            countryCode: countryCode,
            isRequired: true,
            onChanged: (val) {
              if (val != null) onProvinceChanged(val);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedGender,
            decoration: InputDecoration(
              labelText: 'الجنس *',
              prefixIcon: const Icon(
                Icons.wc_rounded,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'male',
                child: Text('ذكر', style: TextStyle(fontFamily: 'Cairo')),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Text('أنثى', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
            validator: (val) => val == null ? 'يرجى اختيار الجنس' : null,
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            leading: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              selectedBirthDate == null
                  ? 'تاريخ الميلاد (اختياري)'
                  : '${selectedBirthDate!.year}/${selectedBirthDate!.month}/${selectedBirthDate!.day}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: onSelectBirthDate,
          ),
        ],
      ),
    );
  }
}

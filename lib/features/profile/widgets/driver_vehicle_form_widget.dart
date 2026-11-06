import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// ويدجت إدخال بيانات مركبة السائق
class DriverVehicleFormWidget extends StatelessWidget {
  final TextEditingController carTypeController;
  final TextEditingController carModelController;
  final TextEditingController carColorController;
  final TextEditingController carNumberController;

  const DriverVehicleFormWidget({
    super.key,
    required this.carTypeController,
    required this.carModelController,
    required this.carColorController,
    required this.carNumberController,
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
            'بيانات المركبة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: carTypeController,
            validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال نوع السيارة' : null,
            decoration: InputDecoration(
              labelText: 'نوع السيارة *',
              hintText: 'مثال: سايبا، كيا، هونداي، تويوتا',
              prefixIcon: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: carModelController,
            validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال سنة الصنع / الموديل' : null,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'الموديل / سنة الصنع *',
              hintText: 'مثال: 2021',
              prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: carColorController,
            validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال لون السيارة' : null,
            decoration: InputDecoration(
              labelText: 'لون السيارة *',
              hintText: 'مثال: أصفر، أبيض، أسود',
              prefixIcon: const Icon(Icons.color_lens_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: carNumberController,
            validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال رقم لوحة السيارة' : null,
            decoration: InputDecoration(
              labelText: 'رقم لوحة السيارة *',
              hintText: 'مثال: 12345 بغداد أ أجرة',
              prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

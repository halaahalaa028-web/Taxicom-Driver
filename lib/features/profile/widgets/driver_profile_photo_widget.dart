import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// ويدجت اختيار الصورة الشخصية للسائق
class DriverProfilePhotoWidget extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onPickImage;

  const DriverProfilePhotoWidget({
    super.key,
    required this.selectedImage,
    required this.onPickImage,
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
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedImage != null ? AppColors.success : AppColors.primary,
                      width: 2.5,
                    ),
                    image: selectedImage != null
                        ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: selectedImage == null
                      ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.profilePhotoField,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

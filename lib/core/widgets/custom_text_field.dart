/// حقل نص مخصص
/// 
/// ويدجت قابل لإعادة الاستخدام لحقول الإدخال
/// مع تصميم موحد ودعم RTL
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// حقل نص مخصص قابل لإعادة الاستخدام
class CustomTextField extends StatelessWidget {
  /// التسمية (Label)
  final String label;
  
  /// التلميح (Hint)
  final String? hint;
  
  /// المتحكم بالنص
  final TextEditingController? controller;
  
  /// نوع لوحة المفاتيح
  final TextInputType keyboardType;
  
  /// هل الحقل للقراءة فقط
  final bool readOnly;
  
  /// هل هو حقل كلمة مرور
  final bool obscureText;
  
  /// أيقونة البداية
  final IconData? prefixIcon;
  
  /// ويدجت البداية (للنص مثلاً)
  final Widget? prefix;
  
  /// أيقونة النهاية
  final IconData? suffixIcon;
  
  /// callback عند الضغط على أيقونة النهاية
  final VoidCallback? onSuffixTap;
  
  /// دالة التحقق
  final String? Function(String?)? validator;
  
  /// callback عند تغيير النص
  final void Function(String)? onChanged;
  
  /// callback عند الضغط على الحقل
  final VoidCallback? onTap;
  
  /// الحد الأقصى للأسطر
  final int maxLines;
  
  /// الحد الأقصى للأحرف
  final int? maxLength;
  
  /// فلاتر الإدخال
  final List<TextInputFormatter>? inputFormatters;
  
  /// هل الحقل مفعل
  final bool enabled;
  
  /// نص أولي
  final String? initialValue;
  
  /// لون الخلفية
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.obscureText = false,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.initialValue,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: fillColor ?? (readOnly ? AppColors.surfaceVariant : AppColors.surface),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary)
            : null,
        prefix: prefix,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: AppColors.textSecondary),
                onPressed: onSuffixTap,
              )
            : null,
        // تصميم الحدود
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

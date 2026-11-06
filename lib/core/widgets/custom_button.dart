/// زر مخصص
/// 
/// ويدجت زر قابل لإعادة الاستخدام
/// مع دعم حالة التحميل والتعطيل
library;

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// زر رئيسي مخصص
class CustomButton extends StatelessWidget {
  /// نص الزر
  final String text;
  
  /// callback عند الضغط
  final VoidCallback? onPressed;
  
  /// هل الزر في حالة تحميل
  final bool isLoading;
  
  /// هل الزر معطل
  final bool disabled;
  
  /// عرض الزر
  final double? width;
  
  /// ارتفاع الزر
  final double height;
  
  /// لون الخلفية
  final Color? backgroundColor;
  
  /// لون النص
  final Color? textColor;
  
  /// حجم الخط
  final double fontSize;
  
  /// أيقونة (اختياري)
  final IconData? icon;
  
  /// نصف قطر الحواف
  final double borderRadius;
  
  /// ظل الزر
  final double elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height = 56,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 18,
    this.icon,
    this.borderRadius = 12,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = disabled || isLoading || onPressed == null;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: isDisabled ? 0 : elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// زر ثانوي (Outlined)
class CustomOutlinedButton extends StatelessWidget {
  /// نص الزر
  final String text;
  
  /// callback عند الضغط
  final VoidCallback? onPressed;
  
  /// هل الزر في حالة تحميل
  final bool isLoading;
  
  /// عرض الزر
  final double? width;
  
  /// ارتفاع الزر
  final double height;
  
  /// لون الحدود والنص
  final Color? color;
  
  /// أيقونة (اختياري)
  final IconData? icon;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

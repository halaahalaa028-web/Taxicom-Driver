/// حوار تقييم الرحلة
/// 
/// يعرض واجهة لتقييم الرحلة مع نجوم وملاحظات
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// نتيجة التقييم
class TripRatingResult {
  final int rating;
  final String? note;
  
  TripRatingResult({required this.rating, this.note});
}

/// حوار تقييم الرحلة
class TripRatingDialog extends StatefulWidget {
  /// عنوان الحوار
  final String title;
  
  /// الاسم الآخر (السائق أو الراكب)
  final String otherPartyName;
  
  /// هل الراكب يقيم (true) أم السائق (false)
  final bool isPassengerRating;
  
  const TripRatingDialog({
    super.key,
    required this.title,
    required this.otherPartyName,
    this.isPassengerRating = true,
  });

  @override
  State<TripRatingDialog> createState() => _TripRatingDialogState();
}

class _TripRatingDialogState extends State<TripRatingDialog> {
  int _selectedRating = 0;
  final TextEditingController _noteController = TextEditingController();
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الأيقونة العلوية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // العنوان
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // الوصف
            Text(
              widget.isPassengerRating 
                  ? 'كيف كانت تجربتك مع السائق ${widget.otherPartyName}؟'
                  : 'كيف كان الراكب ${widget.otherPartyName}؟',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // نجوم التقييم
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starNumber;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      child: Icon(
                        _selectedRating >= starNumber 
                            ? Icons.star_rounded 
                            : Icons.star_outline_rounded,
                        color: _selectedRating >= starNumber 
                            ? Colors.amber 
                            : AppColors.border,
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // وصف التقييم
            if (_selectedRating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _getRatingDescription(_selectedRating),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getRatingColor(_selectedRating),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // حقل الملاحظات
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظاتك هنا (اختياري)',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            ),
            
            const SizedBox(height: 24),
            
            // أزرار الإجراء
            Row(
              children: [
                // زر التخطي
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // زر الإرسال
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedRating > 0 
                        ? () {
                            Navigator.pop(
                              context, 
                              TripRatingResult(
                                rating: _selectedRating,
                                note: _noteController.text.trim().isEmpty 
                                    ? null 
                                    : _noteController.text.trim(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إرسال التقييم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// الحصول على وصف التقييم
  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً 😞';
      case 2:
        return 'سيء 😕';
      case 3:
        return 'مقبول 😐';
      case 4:
        return 'جيد 🙂';
      case 5:
        return 'ممتاز! 🤩';
      default:
        return '';
    }
  }
  
  /// الحصول على لون التقييم
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return AppColors.error;
      case 3:
        return AppColors.primary;
      case 4:
      case 5:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// دالة مساعدة لعرض حوار التقييم
Future<TripRatingResult?> showTripRatingDialog({
  required BuildContext context,
  required String title,
  required String otherPartyName,
  bool isPassengerRating = true,
}) {
  return showDialog<TripRatingResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TripRatingDialog(
      title: title,
      otherPartyName: otherPartyName,
      isPassengerRating: isPassengerRating,
    ),
  );
}

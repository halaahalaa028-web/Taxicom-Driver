/// ويجت أرقام الدعم القابل لإعادة الاستخدام
///
/// يعرض أرقام هواتف الدعم مع إمكانية الاتصال والنسخ
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../localization/app_localizations.dart';

/// ويجت أرقام الدعم - يمكن استخدامه في أي مكان بالتطبيق
class SupportPhonesWidget extends StatelessWidget {
  /// أرقام الهواتف المعروضة
  final List<String> phoneNumbers;

  /// عرض العنوان أم لا
  final bool showHeader;

  const SupportPhonesWidget({
    super.key,
    this.phoneNumbers = const [
      '+964 773 700 7700',
    ],
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Icon(
                    Icons.headset_mic_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.supportPhone,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // بطاقات أرقام الهاتف
          for (int i = 0; i < phoneNumbers.length; i++) ...[
            _PhoneCard(phoneNumber: phoneNumbers[i]),
            if (i < phoneNumbers.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// بطاقة رقم الهاتف
class _PhoneCard extends StatelessWidget {
  final String phoneNumber;

  const _PhoneCard({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _callPhone(context, phoneNumber),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // رقم الهاتف
                Expanded(
                  child: Text(
                    phoneNumber,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // أزرار الإجراءات
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر النسخ
                    IconButton(
                      onPressed: () => _copyToClipboard(context, phoneNumber),
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      tooltip: 'نسخ',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    const SizedBox(width: 6),
                    // زر الاتصال
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.call_rounded,
                        color: AppColors.textOnPrimary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// الاتصال برقم الهاتف
  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر إجراء الاتصال',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// نسخ رقم الهاتف
  void _copyToClipboard(BuildContext context, String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    Clipboard.setData(ClipboardData(text: cleanNumber));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ الرقم بنجاح',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

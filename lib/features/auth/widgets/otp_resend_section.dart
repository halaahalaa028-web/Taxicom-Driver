import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// قسم إعادة إرسال رمز OTP مع العداد التنازلي
class OtpResendSection extends StatelessWidget {
  final int resendCountdown;
  final bool isSendingOtp;
  final VoidCallback onResend;

  const OtpResendSection({
    super.key,
    required this.resendCountdown,
    required this.isSendingOtp,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: resendCountdown > 0
          ? Text(
              '${l10n.resendIn} $resendCountdown ${l10n.seconds}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            )
          : TextButton.icon(
              onPressed: isSendingOtp ? null : onResend,
              icon: isSendingOtp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                l10n.resendCode,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}

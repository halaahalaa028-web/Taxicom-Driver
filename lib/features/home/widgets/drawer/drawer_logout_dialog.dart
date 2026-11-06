import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';

/// حوار تأكيد تسجيل الخروج للقائمة الجانبية
void showDrawerLogoutDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  bool isLoggingOut = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.logout,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            l10n.logoutConfirmation,
            style: const TextStyle(
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: isLoggingOut
                  ? null
                  : () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoggingOut
                  ? null
                  : () async {
                      setDialogState(() => isLoggingOut = true);

                      try {
                        // تنفيذ تسجيل الخروج الشامل
                        await AuthService.instance.signOut();

                        // إغلاق الحوار بأمان
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                        }

                        // الانتقال الجذري إلى شاشة تسجيل الدخول ومسح شجرة التنقل بالكامل
                        final navState =
                            NotificationService.navigatorKey.currentState;
                        if (navState != null) {
                          navState.pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ [Logout] Error: $e');
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoggingOut = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.logoutError,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.logout,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

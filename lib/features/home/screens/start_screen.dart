import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class StartScreen extends StatefulWidget {
  /// هل يجب عرض بانر الرفض كسائق
  final bool showDriverRejectionBanner;
  
  const StartScreen({
    super.key,
    this.showDriverRejectionBanner = false,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signOut();
      final navState = NotificationService.navigatorKey.currentState;
      if (navState != null) {
        navState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // أيقونة التنبيه
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (widget.showDriverRejectionBanner ? AppColors.error : AppColors.warning).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.showDriverRejectionBanner ? Icons.block_rounded : Icons.warning_amber_rounded,
                  size: 56,
                  color: widget.showDriverRejectionBanner ? AppColors.error : AppColors.warning,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // عنوان التنبيه
              Text(
                widget.showDriverRejectionBanner ? 'طلب انضمامك مرفوض' : 'تنبيه الحساب',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // نص الوصف
              Text(
                widget.showDriverRejectionBanner
                    ? 'للأسف، تم رفض طلب انضمامك كسائق من قبل الإدارة. يرجى التواصل مع الدعم الفني للاستفسار أو مراجعة بياناتك.'
                    : 'عذراً، هذا التطبيق مخصص للسائقين فقط. حسابك الحالي مسجل كحساب زبون (راكب)، ولا يمكنك تصفح التطبيق من هنا.',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // صندوق الدعم الفني
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.support_agent_rounded, color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'للتواصل مع الدعم الفني',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _callPhone('+9647737007700'),
                        icon: const Icon(Icons.phone, size: 16, color: AppColors.success),
                        label: const Text(
                          '+964 773 700 7700',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // زر تسجيل الخروج
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: AppStrings.logout,
                      onPressed: _handleLogout,
                      icon: Icons.logout_rounded,
                      backgroundColor: AppColors.error,
                    ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

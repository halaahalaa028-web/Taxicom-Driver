/// شاشة انتظار موافقة السائق
/// 
/// تظهر للسائقين الجدد الذين ينتظرون موافقة الإدارة
/// تراقب التغييرات على حالة السائق بشكل مباشر
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/support_phones_widget.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/edit_driver_profile_screen.dart';
import '../../home/screens/start_screen.dart';
import 'driver_home_screen.dart';

/// شاشة انتظار الموافقة
class DriverPendingScreen extends StatefulWidget {
  const DriverPendingScreen({super.key});

  @override
  State<DriverPendingScreen> createState() => _DriverPendingScreenState();
}

class _DriverPendingScreenState extends State<DriverPendingScreen> {
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startListeningToStatusChanges();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  /// بدء الاستماع لتغييرات حالة السائق
  void _startListeningToStatusChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _statusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted || _isNavigating) return;

        final data = snapshot.data();
        if (data == null) return;

        final driverStatus = data['driverStatus'] as String?;
        
        debugPrint('📡 تغيير حالة السائق: $driverStatus');

        if (driverStatus == 'approved') {
          _isNavigating = true;
          _navigateToDriverHome();
        } else if (driverStatus == 'rejected') {
          _isNavigating = true;
          _navigateToRejectedScreen();
        }
      },
      onError: (e) {
        debugPrint('⚠️ [DriverPendingScreen] Status subscription error handled: $e');
      },
      cancelOnError: false,
    );
  }

  /// الانتقال لشاشة السائق المعتمد
  void _navigateToDriverHome() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'مبروك! تم قبول طلبك كسائق 🎉',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverHomeScreen(),
      ),
      (route) => false,
    );
  }

  /// الانتقال لشاشة البداية مع بانر الرفض
  void _navigateToRejectedScreen() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'للأسف، لم تتم الموافقة على طلبك حالياً',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const StartScreen(showDriverRejectionBanner: true),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // أيقونة الانتظار
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 64,
                  color: AppColors.warning,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // العنوان
              Text(
                AppStrings.pendingApprovalTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // الرسالة
              Text(
                AppStrings.pendingApprovalMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // معلومات إضافية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // المدة
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            AppStrings.pendingApprovalTime,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // الاشعار
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            AppStrings.pendingApprovalNotify,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // قسم أرقام الدعم المركزي الموحد
              const SupportPhonesWidget(
                phoneNumbers: [
                  '+964 773 700 7700',
                ],
                showHeader: true,
              ),
              
              const SizedBox(height: 32),
              
              // زر تعديل البيانات
              CustomButton(
                text: AppStrings.editProfile,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditDriverProfileScreen(),
                    ),
                  );
                },
                icon: Icons.edit_rounded,
                backgroundColor: AppColors.primary,
              ),
              
              const SizedBox(height: 12),
              
              // زر تسجيل الخروج
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  final navState =
                      NotificationService.navigatorKey.currentState;
                  if (navState != null) {
                    navState.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  } else if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  AppStrings.logout,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// شاشة عن التطبيق
/// 
/// تعرض معلومات التطبيق والإصدار
library;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/developer_signature_widget.dart';

/// شاشة عن التطبيق
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _buildNumber = '';
  int _developerModeTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  /// معالجة الضغط على الإصدار لتفعيل وضع المطور
  Future<void> _handleVersionTap() async {
    final now = DateTime.now();
    
    // إذا مر أكثر من 3 ثوانٍ على آخر ضغطة، نعيد تعيين العداد
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 3) {
      _developerModeTapCount = 0;
    }
    
    _lastTapTime = now;
    _developerModeTapCount++;
    
    if (_developerModeTapCount == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اضغط 10 مرات متتالية لتفعيل وضع المطور',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_developerModeTapCount >= 10) {
      // تفعيل وضع المطور
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('developer_mode_enabled', true);
      LocationService.isDeveloperModeEnabled = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // إظهار نافذة منبثقة
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'وضع المطور',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'يمكنك الان اختيار نقطة انطلاق ووصول في محافظة البصرة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo', color: AppColors.primary)),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
      _developerModeTapCount = 0; // إعادة التعيين بعد التفعيل لتجنب التكرار المتواصل
    } else if (_developerModeTapCount > 1) {
      // اختياري: إظهار عدد المرات المتبقية
      int remaining = 10 - _developerModeTapCount;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اضغط $remaining مرات إضافية لتفعيل وضع المطور',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// تحميل إصدار التطبيق
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.aboutApp,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // شعار التطبيق
            _buildAppLogo(),
            
            const SizedBox(height: 32),
            
            // معلومات التطبيق
            _buildAppInfo(context, l10n),
            
            const SizedBox(height: 32),
            
            // ميزات التطبيق
            _buildAppFeatures(l10n),
            
            const SizedBox(height: 32),
            
            // حقوق النشر
            _buildCopyright(l10n),
            
            // مساحة فارغة لتجنب التداخل مع أزرار النظام
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  /// بناء شعار التطبيق
  Widget _buildAppLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.local_taxi_rounded,
            size: 60,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// بناء معلومات التطبيق
  Widget _buildAppInfo(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.appName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appDescription,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _handleVersionTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _appVersion.isNotEmpty 
                    ? '${l10n.version} $_appVersion ($_buildNumber)'
                    : '${l10n.version} ...',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء ميزات التطبيق
  Widget _buildAppFeatures(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appFeatures,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.location_on_rounded, l10n.featureTracking),
          _buildFeatureItem(Icons.security_rounded, l10n.featureSafe),
          _buildFeatureItem(Icons.speed_rounded, l10n.featureFast),
          _buildFeatureItem(Icons.attach_money_rounded, l10n.featureFairPrice),
        ],
      ),
    );
  }

  /// بناء عنصر ميزة
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حقوق النشر وتوقيع الشركة المطورة
  Widget _buildCopyright(AppLocalizations l10n) {
    return Column(
      children: [
        const DeveloperSignatureWidget(),
        const SizedBox(height: 24),
        Text(
          '© 2026 ${l10n.appName}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.allRightsReserved,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

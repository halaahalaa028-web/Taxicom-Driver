/// شاشة تسجيل الدخول للسائق
/// 
/// الشاشة الأولى لتطبيق السائق حيث يدخل رقم هاتفه لاستلام رمز التحقق OTP
/// تدعم التحديد الديناميكي للبلد الافتراضي (مصر) أو اختيار البلد من بين المفعلة
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/country_service.dart';
import '../services/auth_service.dart';
import '../widgets/auth_language_button.dart';
import '../widgets/phone_input_card.dart';
import 'otp_verification_screen.dart';

/// شاشة تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  
  final AuthService _authService = AuthService.instance;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// تسجيل الدخول - إرسال كود التحقق عبر Firebase Phone Auth
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final selectedCountry = CountryService.instance.selectedCountry;

      // إذا كانت الدولة خارج البلدان الأربعة المدعومة حالياً للتسجيل
      if (!AppProvinces.isCountrySupported(selectedCountry.code)) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'خدمة تاكسيكوم في ${selectedCountry.nameAr} ستتوفر قريباً!',
          isError: false,
        );
        return;
      }

      String phone = _phoneController.text.trim();
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }
      String fullPhone = '${selectedCountry.dialCode}$phone';

      // إرسال كود التحقق الذكي عبر WhatsApp / SMS
      final result = await _authService.sendCustomOtp(
        phoneNumber: fullPhone,
        channel: 'auto',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        final verificationId = result['verificationId']?.toString() ?? '';
        final channelSent = result['channelSent']?.toString() ?? 'whatsapp';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: fullPhone,
              verificationId: verificationId,
              initialChannel: channelSent,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.phoneError;
    }
    String phone = value.trim();
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    
    final selectedCountry = CountryService.instance.selectedCountry;
    final minLen = selectedCountry.minPhoneLength > 0 ? selectedCountry.minPhoneLength - 1 : AppConstants.minPhoneLength - 1;
    final maxLen = selectedCountry.maxPhoneLength > 0 ? selectedCountry.maxPhoneLength : AppConstants.maxPhoneLength;

    if (phone.length < minLen || phone.length > maxLen) {
      return AppStrings.phoneError;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return AppStrings.phoneError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: l10n.loggingIn,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.topLeft,
                  child: AuthLanguageButton(),
                ),
                
                const SizedBox(height: 20),
                
                // عنوان الترحيب البسيط بدون شعار أو أشكال معقدة
                const Text(
                  'سائق Taxicom ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PhoneInputCard(
                        phoneController: _phoneController,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        text: l10n.login,
                        onPressed: _login,
                        isLoading: _isLoading,
                        icon: Icons.arrow_back_rounded,
                        borderRadius: 14,
                        height: 48,
                        fontSize: 15,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

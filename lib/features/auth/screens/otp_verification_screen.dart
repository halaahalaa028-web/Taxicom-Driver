/// شاشة التحقق من OTP للسائق
/// 
/// شاشة للتحقق من رقم الهاتف عبر Firebase Phone Auth
/// قبل الدخول أو إتمام حفظ بيانات السائق
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/country_service.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import '../widgets/otp_input_field.dart';
import '../widgets/otp_resend_section.dart';
import '../../profile/services/user_service.dart';
import '../../profile/screens/profile_setup_screen.dart';
import '../../driver/screens/driver_home_screen.dart';
import '../../driver/screens/driver_pending_screen.dart';
import '../../home/screens/start_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/phone_formatter.dart';

/// شاشة التحقق من OTP
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String initialChannel;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.initialChannel = 'whatsapp',
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  
  final AuthService _authService = AuthService.instance;
  final UserService _userService = UserService.instance;
  
  late String _currentVerificationId;
  late String _currentChannel;
  
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isRegistering = false;
  
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentChannel = widget.initialChannel;
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _resendTimer?.cancel();
          }
        });
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  /// إعادة إرسال رمز OTP عبر Cloud Functions للسائق (يدعم تحديد القناة مثل SMS)
  Future<void> _resendOtp({String? forcedChannel}) async {
    setState(() => _isSendingOtp = true);

    try {
      final targetChannel = forcedChannel ?? (_currentChannel == 'whatsapp' ? 'sms' : 'whatsapp');
      final result = await _authService.resendCustomOtp(
        phoneNumber: widget.phoneNumber,
        channel: targetChannel,
      );

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _currentVerificationId = result['verificationId']?.toString() ?? _currentVerificationId;
          _currentChannel = result['channelSent']?.toString() ?? targetChannel;
          _startResendTimer();
        });

        final channelMsg = _currentChannel == 'whatsapp'
            ? 'تم إرسال رمز التحقق إلى واتساب'
            : 'تم إرسال رمز التحقق عبر رسالة SMS';
        _showSnackBar(channelMsg, isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        _showSnackBar('حدث خطأ أثناء إرسال رمز التحقق', isError: true);
      }
    }
  }

  /// التحقق من رمز OTP المدخل وتسجيل الدخول للسائق بواسطة Custom Token
  Future<void> _verifyAndProceed() async {
    String otpCode = _otpController.text.trim();
    if (otpCode.length != 6) {
      _showSnackBar('يرجى إدخال رمز تحقق صحيح مكون من 6 أرقام', isError: true);
      return;
    }
    
    setState(() => _isVerifyingOtp = true);
    
    try {
      final user = await _authService.verifyCustomOtpAndSignIn(
        phoneNumber: widget.phoneNumber,
        otpCode: otpCode,
        verificationId: _currentVerificationId,
      );

      if (user != null) {
        await _onAuthSuccess(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _onAuthSuccess(User user) async {
    setState(() {
      _isVerifyingOtp = false;
      _isRegistering = true;
    });

    try {
      final existingUser = await _userService.getUser(user.uid);

      if (existingUser != null) {
        final countryCode = existingUser.countryCode ?? AppProvinces.detectCountryCodeFromPhone(existingUser.phone);
        await CountryService.instance.selectCountryByCode(countryCode);

        final userType = existingUser.userType;
        await SessionService.instance.registerDevice(user.uid, userType);
        await NotificationService.instance.updateFcmTokenOnLogin();

        if (mounted) {
          if (userType == 'driver') {
            if (existingUser.driverStatus == 'approved') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                (route) => false,
              );
            } else if (existingUser.driverStatus == 'rejected') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StartScreen(showDriverRejectionBanner: true)),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DriverPendingScreen()),
                (route) => false,
              );
            }
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const StartScreen()),
              (route) => false,
            );
          }

          await SessionService.instance.startSessionListener(user.uid, userType);
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(
                phoneNumber: widget.phoneNumber,
                isDriver: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBusy = _isSendingOtp || _isVerifyingOtp || _isRegistering;
    
    String loadingMessage = l10n.verifying;
    if (_isSendingOtp) {
      loadingMessage = 'جاري إرسال رمز التحقق...';
    } else if (_isRegistering) {
      loadingMessage = 'جاري التحقق من الحساب...';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.otpTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: isBusy,
        message: loadingMessage,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentChannel == 'whatsapp' ? Icons.chat_bubble_rounded : Icons.sms_rounded,
                      size: 45,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _currentChannel == 'whatsapp'
                      ? 'تم إرسال رمز التحقق إلى حسابك على واتساب'
                      : l10n.otpSubtitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    PhoneFormatter.format(widget.phoneNumber),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                OtpInputField(
                  controller: _otpController,
                  onChanged: (val) {
                    if (val.length == 6) {
                      _verifyAndProceed();
                    }
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isBusy ? null : _verifyAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.verify,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OtpResendSection(
                  resendCountdown: _resendCountdown,
                  isSendingOtp: _isSendingOtp,
                  onResend: () => _resendOtp(),
                ),
                if (_currentChannel == 'whatsapp') ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: isBusy ? null : () => _resendOtp(forcedChannel: 'sms'),
                      icon: const Icon(Icons.sms_rounded, size: 16),
                      label: const Text(
                        'لم يصلك الرمز؟ أرسل عبر رسالة SMS',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// غلاف المصادقة والتحقق من التحديثات
/// 
/// يتحقق من التحديثات وحالة مصادقة السائق ويوجهه للشاشة المناسبة
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/services/country_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/update_dialog.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../../home/screens/start_screen.dart';
import '../../driver/screens/driver_home_screen.dart';
import '../../driver/screens/driver_pending_screen.dart';
import '../../profile/screens/profile_setup_screen.dart';
import '../../profile/services/user_service.dart';
import '../../profile/models/user_model.dart';

/// ويدجت للتحكم في التوجيه بناءً على حالة المصادقة
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isForceUpdate = false;
  UpdateInfo? _updateInfo;

  // === كاش بيانات المستخدم لتجنب الوميض ===
  String? _cachedUid;
  bool? _userExists;
  UserModel? _userData;
  bool _isLoadingUserData = false;
  bool _initialAuthResolved = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _tryLoadLocalCachedUser();
  }

  /// محاولة تحميل بيانات المستخدم المحفوظة محلياً للبدء الفوري
  void _tryLoadLocalCachedUser() {
    final cached = UserService.instance.cachedUser;
    if (cached != null) {
      _userData = cached;
      _userExists = true;
      _cachedUid = cached.uid;
      final countryCode = cached.countryCode ?? AppProvinces.detectCountryCodeFromPhone(cached.phone);
      CountryService.instance.selectCountryByCode(countryCode);
      return;
    }
    
    // جلب من التخزين المحلي (SharedPreferences)
    UserService.instance.loadUserFromLocalStorage().then((localUser) {
      if (mounted && localUser != null && _userExists == null) {
        setState(() {
          _userData = localUser;
          _userExists = true;
          _cachedUid = localUser.uid;
        });
        final countryCode = localUser.countryCode ?? AppProvinces.detectCountryCodeFromPhone(localUser.phone);
        CountryService.instance.selectCountryByCode(countryCode);
      }
    });
  }

  /// فحص التحديثات في الخلفية بدون حظر الواجهة
  Future<void> _checkForUpdate() async {
    final (status, info) = await UpdateService.instance.checkForUpdate();
    
    if (!mounted) return;

    if (status == UpdateStatus.forceUpdate || status == UpdateStatus.optionalUpdate) {
      setState(() {
        _updateInfo = info;
        _isForceUpdate = status == UpdateStatus.forceUpdate;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _updateInfo != null) {
          UpdateDialog.show(
            context,
            updateInfo: _updateInfo!,
            isForceUpdate: _isForceUpdate,
          ).then((_) {
            if (!_isForceUpdate && mounted) {
              setState(() {
                _updateInfo = null;
              });
            }
          });
        }
      });
    }
  }

  /// تحميل بيانات المستخدم وتخزينها في الكاش
  Future<void> _loadUserData(String uid) async {
    if (_isLoadingUserData && _cachedUid == uid && _userExists != null) return;
    
    _isLoadingUserData = true;
    _cachedUid = uid;

    try {
      final exists = await AuthService.instance.checkUserExists(uid);
      if (!mounted) return;
      
      if (exists) {
        final user = await UserService.instance.getUser(uid);
        if (!mounted) return;

        if (user != null) {
          final countryCode = user.countryCode ?? AppProvinces.detectCountryCodeFromPhone(user.phone);
          CountryService.instance.selectCountryByCode(countryCode);
          await UserService.instance.updateCache(user);
        }
        
        setState(() {
          _userExists = true;
          _userData = user;
          _isLoadingUserData = false;
        });
        
        // استئناف مستمع الجلسة بعد إعادة فتح التطبيق
        if (user != null && !SessionService.instance.isListening) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              SessionService.instance.refreshDeviceIdIfNeeded(uid, user.userType);
              SessionService.instance.startSessionListener(uid, user.userType);
            }
          });
        }
      } else {
        setState(() {
          _userExists = false;
          _userData = null;
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [AuthWrapper] Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان التحديث إجباري، نعرض شاشة انتظار
    if (_isForceUpdate && _updateInfo != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                LanguageService.instance.currentLanguage == AppLanguage.arabic
                    ? 'يرجى تحديث التطبيق للمتابعة'
                    : LanguageService.instance.currentLanguage == AppLanguage.kurdish
                        ? 'تکایە بەرنامەکە نوێبکەوە بۆ بەردەوامبوون'
                        : 'Devam etmek için uygulamayı güncelleyin',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // حالة التحميل الأولى فقط
        if (snapshot.connectionState == ConnectionState.waiting && !_initialAuthResolved && _userExists == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // المستخدم مسجل الدخول
        if (snapshot.hasData && snapshot.data != null) {
          _initialAuthResolved = true;
          final uid = snapshot.data!.uid;
          
          if (_cachedUid != uid || (_userExists == null && !_isLoadingUserData)) {
            _cachedUid = null;
            _userExists = null;
            _userData = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadUserData(uid);
            });
          }
          
          if (_userExists == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // المستخدم موجود في Firestore - التوجيه بناءً على نوعه
          if (_userExists == true) {
            final userType = _userData?.userType;
            if (userType == 'driver') {
              final driverStatus = _userData?.driverStatus;
              if (driverStatus == 'approved') {
                return const DriverHomeScreen();
              } else if (driverStatus == 'rejected') {
                return const StartScreen(showDriverRejectionBanner: true);
              }
              return const DriverPendingScreen();
            }
            return const StartScreen();
          }
          
          // مستخدم جديد - يحتاج إكمال الملف الشخصي
          return ProfileSetupScreen(
            phoneNumber: snapshot.data!.phoneNumber ?? '',
          );
        }
        
        // المستخدم غير مسجل الدخول
        _initialAuthResolved = true;
        _cachedUid = null;
        _userExists = null;
        _userData = null;
        return const LoginScreen();
      },
    );
  }
}

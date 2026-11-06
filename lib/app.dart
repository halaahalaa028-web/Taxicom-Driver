/// تطبيق تكسيكوم - السائق
/// 
/// ويدجت MaterialApp الرئيسي للتطبيق
/// يتضمن إعدادات الثيم واللغة والتوجيه
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/services/language_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/screens/auth_wrapper.dart';

/// ويدجت التطبيق الرئيسي
class TaxicomDriverApp extends StatefulWidget {
  const TaxicomDriverApp({super.key});

  @override
  State<TaxicomDriverApp> createState() => _TaxicomDriverAppState();
}

class _TaxicomDriverAppState extends State<TaxicomDriverApp> {
  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات اللغة
    LanguageService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.instance;
    
    return MaterialApp(
      // مفتاح فريد لكل لغة - يجبر Flutter على إعادة إنشاء الشجرة بالكامل عند تغيير اللغة
      key: ValueKey('app_${languageService.currentLanguage.code}'),
      // مفتاح التنقل للإشعارات
      navigatorKey: NotificationService.navigatorKey,
      
      // اسم التطبيق
      title: AppStrings.appName,
      
      // إخفاء شعار Debug
      debugShowCheckedModeBanner: false,
      
      // الثيم - فقط النمط الفاتح
      theme: AppTheme.lightTheme,
      
      // إجبار استخدام النمط الفاتح فقط بغض النظر عن إعدادات النظام
      themeMode: ThemeMode.light,
      
      // دعم اللغة الحالية - نستخدم العربية كأساس للـ Material widgets
      locale: const Locale('ar'),
      
      // دعم اللغات
      supportedLocales: const [
        Locale('ar'), // العربية
        Locale('en'), // الإنجليزية (للتوافق)
      ],

      // مفوضو الترجمة
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // بناء التطبيق مع ضبط مقياس النصوص واتجاه النص المناسب للغة
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.0,
            ),
          ),
          child: Directionality(
            textDirection: languageService.textDirection,
            child: child!,
          ),
        );
      },
      
      // الشاشة الرئيسية - التوجيه المباشر عبر غلاف المصادقة
      home: const AuthWrapper(),
    );
  }
}

/// القائمة الجانبية لتطبيق السائق (Menu Drawer)
///
/// قائمة جانبية قياسية عصرية تعرض معلومات السائق وحالة الاشتراك وخيارات القائمة
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../profile/models/user_model.dart';
import '../../profile/screens/profile_details_screen.dart';
import '../../profile/services/user_service.dart';
import '../../settings/screens/about_screen.dart';
import '../../settings/screens/help_support_screen.dart';
import '../../settings/screens/language_settings_screen.dart';
import '../../trips/screens/my_trips_screen.dart';
import '../../wallet/presentation/screens/driver_wallet_screen.dart';
import 'drawer/drawer_header_widget.dart';
import 'drawer/drawer_logout_dialog.dart';
import 'drawer/drawer_menu_item_widget.dart';

// رابط الشروط والأحكام للسائقين
const String _driverTermsUrl =
    'https://sites.google.com/view/taxicoma/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9-%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9';
// رابط سياسة الخصوصية
const String _privacyUrl =
    'https://sites.google.com/view/taxicoma/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9-%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9';

/// فتح القائمة الجانبية (للتوافق المستقبلي)
void showMenuBottomSheet(BuildContext context) {
  Scaffold.maybeOf(context)?.openDrawer();
}

/// ويدجت القائمة الجانبية (Driver Menu Drawer)
class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

/// للتوافق مع المسميات القديمة
typedef MenuBottomSheet = MenuDrawer;

class _MenuDrawerState extends State<MenuDrawer> {
  String _userName = '';
  String _userPhone = '';
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// تحميل بيانات المستخدم من الكاش أو التخزين المحلي
  Future<void> _loadUserData() async {
    // 1. أولاً: استخدام البيانات المحفوظة في الكاش
    var cachedUser = UserService.instance.cachedUser;

    // 2. إذا لم تكن موجودة في الكاش، حاول التحميل من التخزين المحلي أولاً (أسرع)
    cachedUser ??= await UserService.instance.loadUserFromLocalStorage();

    // 3. عرض البيانات المتوفرة فوراً
    if (cachedUser != null && mounted) {
      setState(() {
        _userData = cachedUser;
        _userName = cachedUser!.name.isNotEmpty ? cachedUser.name : '';
        _userPhone = PhoneFormatter.format(cachedUser.phone);
      });
    }

    // 4. إذا مازالت البيانات غير موجودة، حاول التحميل من Firestore
    if (cachedUser == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.instance.loadCurrentUser(user.uid);
        cachedUser = UserService.instance.cachedUser;

        if (cachedUser != null && mounted) {
          setState(() {
            _userData = cachedUser;
            _userName = cachedUser!.name.isNotEmpty ? cachedUser.name : '';
            _userPhone = PhoneFormatter.format(cachedUser.phone);
          });
        }
      }
    }

    // 5. استخدام بيانات Firebase Auth كاحتياطي أخير
    if (_userName.isEmpty && mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? '';
          _userPhone = PhoneFormatter.format(user.phoneNumber ?? '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // رأس القائمة الجانبية
          DrawerHeaderWidget(
            userData: _userData,
            userName: _userName,
            userPhone: _userPhone,
            onTap: _navigateToProfile,
          ),

          // قائمة الخيارات
          Expanded(
            child: _buildMenuOptions(context),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    if (_userData != null) {
      Navigator.pop(context); // إغلاق القائمة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileDetailsScreen(user: _userData!),
        ),
      );
    }
  }

  /// بناء قائمة الخيارات
  Widget _buildMenuOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final menuItems = [
      DrawerMenuItem(
        icon: Icons.history_rounded,
        title: l10n.myTrips,
        subtitle: l10n.myTripsSubtitle,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyTripsScreen()),
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.account_balance_wallet_rounded,
        title: l10n.earningsAndWallet,
        subtitle: l10n.earningsAndWalletSubtitle,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DriverWalletScreen()),
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.language_rounded,
        title: l10n.settings,
        subtitle: l10n.settingsSubtitle,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LanguageSettingsScreen(),
            ),
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.description_rounded,
        title: l10n.termsAndConditions,
        subtitle: l10n.termsAndConditionsSubtitle,
        onTap: () => _openUrl(context, _driverTermsUrl),
      ),
      DrawerMenuItem(
        icon: Icons.privacy_tip_rounded,
        title: l10n.privacyPolicy,
        subtitle: l10n.privacyPolicySubtitle,
        onTap: () => _openUrl(context, _privacyUrl),
      ),
      DrawerMenuItem(
        icon: Icons.help_outline_rounded,
        title: l10n.helpAndSupport,
        subtitle: l10n.helpAndSupportSubtitle,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.info_outline_rounded,
        title: l10n.aboutApp,
        subtitle: l10n.aboutAppSubtitle,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.logout_rounded,
        title: l10n.logout,
        subtitle: l10n.logoutSubtitle,
        onTap: () => showDrawerLogoutDialog(context),
        isDestructive: true,
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return DrawerMenuItemWidget(item: menuItems[index]);
      },
    );
  }

  /// فتح رابط خارجي
  Future<void> _openUrl(BuildContext context, String url) async {
    Navigator.pop(context); // إغلاق القائمة أولاً
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح الرابط',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

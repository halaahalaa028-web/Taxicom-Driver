/// شاشة الإشعارات والرسائل الموحدة للسائق
///
/// تدمج التبويب العام للإعلانات والتحديثات وتبويب الإشعارات الشخصية
/// لحساب السائق وطلبات سحب الأرباح والمديونية
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/general_notifications_tab.dart';
import '../widgets/personal_notifications_tab.dart';

class DriverMessagesScreen extends StatefulWidget {
  final int initialTabIndex;

  const DriverMessagesScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<DriverMessagesScreen> createState() => _DriverMessagesScreenState();
}

class _DriverMessagesScreenState extends State<DriverMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.messagesAndNotifications,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign_outlined, size: 20),
              text: 'عام',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.person_outline_rounded, size: 20),
              text: 'شخصي',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GeneralNotificationsTab(driverId: driverId),
          PersonalNotificationsTab(driverId: driverId),
        ],
      ),
    );
  }
}

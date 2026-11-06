/// شاشة الأرباح والمحفظة الموحدة للسائق (Driver Earnings & Wallet Hub)
///
/// مركز مالي موحد يدمج:
/// 1. تبويب المحفظة والمديونية والعمولة (15%) وتسديد الديون وسحب الأرباح
/// 2. تبويب الأرباح التشغيلية وإحصائيات اليوم والأسبوع والشهر وسجل المشاوير
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../controllers/driver_wallet_controller.dart';
import '../widgets/earnings_tab_view.dart';
import '../widgets/pay_debt_sheet.dart';
import '../widgets/request_payout_sheet.dart';
import '../widgets/wallet_tab_view.dart';
import 'payout_requests_screen.dart';

class DriverWalletScreen extends StatefulWidget {
  /// الفهرس الابتدائي للتبويب (0 للمحفظة والمديونية، 1 للأرباح والمشاوير)
  final int initialTabIndex;

  const DriverWalletScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen>
  with SingleTickerProviderStateMixin {
  late final DriverWalletController _walletController;
  late final TabController _tabController;
  final ScrollController _walletScrollController = ScrollController();
  final GlobalKey<State<EarningsTabView>> _earningsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _walletController = DriverWalletController();
    _walletController.initialize();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _walletScrollController.addListener(_onWalletScroll);
  }

  @override
  void dispose() {
    _walletScrollController.removeListener(_onWalletScroll);
    _walletScrollController.dispose();
    _tabController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  void _onWalletScroll() {
    if (!_walletScrollController.hasClients) return;
    final maxScroll = _walletScrollController.position.maxScrollExtent;
    final currentScroll = _walletScrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      if (_walletController.hasMoreTransactions &&
          !_walletController.isLoadingMoreTransactions) {
        _walletController.loadMoreTransactions();
      }
    }
  }

  void _openPayDebtSheet() {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    PayDebtSheet.show(
      context,
      currentDebt: _walletController.currentDebt,
      currency: _walletController.currency,
      countryCode: _walletController.countryCode,
      driverId: driverId,
      driverName: FirebaseAuth.instance.currentUser?.displayName,
      driverPhone: FirebaseAuth.instance.currentUser?.phoneNumber,
    );
  }

  void _openRequestPayoutSheet() {
    RequestPayoutSheet.show(
      context,
      availableEarnings: _walletController.availableEarnings,
      currency: _walletController.currency,
      countryCode: _walletController.countryCode,
      onRequest: _walletController.requestPayout,
    );
  }

  void _openPayoutRequestsScreen() {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayoutRequestsScreen(
          driverId: driverId,
          currency: _walletController.currency,
          countryCode: _walletController.countryCode,
          availableEarnings: _walletController.availableEarnings,
          onRequestPayout: _openRequestPayoutSheet,
        ),
      ),
    );
  }

  void _handleRefresh() {
    if (_tabController.index == 0) {
      _walletController.refresh();
    } else {
      // إعادة تحميل تبويب الأرباح
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.earningsAndWallet.isNotEmpty
        ? l10n.earningsAndWallet
        : 'الأرباح والمحفظة';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: _openPayoutRequestsScreen,
            tooltip: 'سجل طلبات السحب',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleRefresh,
            tooltip: 'تحديث',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
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
                  icon: Icon(Icons.account_balance_wallet_rounded, size: 20),
                  text: 'المحفظة والمديونية',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: Icon(Icons.insights_rounded, size: 20),
                  text: 'دخل المشاوير والأداء',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. تبويب المحفظة والمديونية
          ListenableBuilder(
            listenable: _walletController,
            builder: (context, _) {
              return WalletTabView(
                controller: _walletController,
                scrollController: _walletScrollController,
                onPayDebtPressed: _openPayDebtSheet,
                onRequestPayoutPressed: _openRequestPayoutSheet,
                onPayoutRequestsHistoryPressed: _openPayoutRequestsScreen,
              );
            },
          ),

          // 2. تبويب الأرباح والمشاوير
          EarningsTabView(key: _earningsKey),
        ],
      ),
    );
  }
}

/// تبويب المحفظة والمديونية والعمليات المالية للسائق
///
/// يعرض بطاقة الرصيد الصافي، تنبيه سقف المديونية،
/// تفاصيل العمولة، البطاقات البنكية المحفوظة، وسجل القيود المحاسبية
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/driver_commission_service.dart';
import '../../data/models/driver_wallet_model.dart';
import '../controllers/driver_wallet_controller.dart';
import 'add_card_sheet.dart';
import 'debt_warning_banner.dart';
import 'driver_balance_header.dart';
import 'driver_transactions_list.dart';
import 'saved_cards_list.dart';
import 'wallet_transaction_filter_chips.dart';

class WalletTabView extends StatelessWidget {
  final DriverWalletController controller;
  final ScrollController scrollController;
  final VoidCallback onPayDebtPressed;
  final VoidCallback onRequestPayoutPressed;
  final VoidCallback? onPayoutRequestsHistoryPressed;

  const WalletTabView({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onPayDebtPressed,
    required this.onRequestPayoutPressed,
    this.onPayoutRequestsHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط تحذير سقف المديونية
            DebtWarningBanner(
              debtStatus: controller.debtStatus,
              currency: controller.currency,
              countryCode: controller.countryCode,
              onPayPressed: onPayDebtPressed,
            ),

            // بطاقة الرصيد الرئيسية
            DriverBalanceHeader(
              wallet: controller.wallet,
              currency: controller.currency,
              countryCode: controller.countryCode,
              onPayDebtPressed: onPayDebtPressed,
              onRequestPayoutPressed: onRequestPayoutPressed,
              onPayoutRequestsHistoryPressed: onPayoutRequestsHistoryPressed,
            ),

            const SizedBox(height: 14),

            // زر وسجل تتبع طلبات سحب الأرباح
            if (onPayoutRequestsHistoryPressed != null)
              _buildPayoutHistoryQuickAccess(context),

            if (onPayoutRequestsHistoryPressed != null)
              const SizedBox(height: 14),

            // بطاقة توضيح آلية العمولة
            _buildCommissionInfoCard(),

            const SizedBox(height: 20),

            // قسم البطاقات البنكية المحفوظة وإدارتها
            SavedCardsList(
              cards: controller.savedCards,
              onAddCard: () => AddCardSheet.show(
                context,
                onSaveCard: controller.addSavedCard,
              ),
              onDeleteCard: (cardId) => controller.deleteSavedCard(cardId),
              onSetDefaultCard: (cardId) => controller.setDefaultCard(cardId),
            ),

            const SizedBox(height: 24),

            // عنوان سجل العمليات المالية
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل المعاملات والعمولات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // شريط تصفية وتصنيف المعاملات
            WalletTransactionFilterChips(
              selectedFilter: controller.selectedFilter,
              onFilterSelected: controller.setFilter,
              getCount: controller.getTransactionCount,
            ),

            const SizedBox(height: 12),

            // قائمة المعاملات المالية المصفاة
            DriverTransactionsList(
              transactions: controller.filteredTransactions,
              currency: controller.currency,
              countryCode: controller.countryCode,
              isLoadingMore: controller.isLoadingMoreTransactions,
              hasMore: controller.hasMoreTransactions,
              onLoadMore: controller.loadMoreTransactions,
              selectedFilter: controller.selectedFilter,
              onResetFilter: () => controller.setFilter(WalletTransactionFilter.all),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistoryQuickAccess(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPayoutRequestsHistoryPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل طلبات سحب الأرباح',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'متابعة حالة التحويل والحوالات البنكية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommissionInfoCard() {
    final rate = DriverCommissionService.instance.currentCommissionRate;
    final ratePercent = (rate * 100).toStringAsFixed((rate * 100 % 1 == 0) ? 0 : 1);
    final driverPercent = ((1.0 - rate) * 100).toStringAsFixed(((1.0 - rate) * 100 % 1 == 0) ? 0 : 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آلية استقطاع عمولة المنصة ($ratePercent%)',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'في الرحلات النقدية تُخصم $ratePercent% من المحفظة كمديونية، وفي الرحلات الإلكترونية يُضاف صافي $driverPercent% إلى أرباحك مباشرة.',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

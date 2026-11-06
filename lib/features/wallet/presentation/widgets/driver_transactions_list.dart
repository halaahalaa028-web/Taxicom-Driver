/// قائمة سجل العمليات المالية لمحفظة السائق
///
/// تعرض تفاصيل استقطاع العمولات، إيداع أرباح الرحلات،
/// تسديدات المديونية، وطلبات سحب الأرباح
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../../data/models/driver_wallet_model.dart';

class DriverTransactionsList extends StatelessWidget {
  final List<WalletTransactionModel> transactions;
  final String currency;
  final String countryCode;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final WalletTransactionFilter selectedFilter;
  final VoidCallback? onResetFilter;

  const DriverTransactionsList({
    super.key,
    required this.transactions,
    required this.currency,
    required this.countryCode,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.selectedFilter = WalletTransactionFilter.all,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return _buildTransactionTile(tx);
          },
        ),
        if (isLoadingMore)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(WalletTransactionModel tx) {
    final isDebit = tx.isDebit;
    final color = isDebit ? AppColors.error : AppColors.success;
    final icon = _getTransactionIcon(tx.type);
    final formattedDate = DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(tx.createdAt);
    final formattedAmount = TripCalculationHelper.formatPrice(
      tx.amount,
      currency: tx.currency.isNotEmpty ? tx.currency : currency,
      countryCode: countryCode,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          // أيقونة نوع المعاملة
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // تفاصيل المعاملة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // المبلغ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'} $formattedAmount',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (tx.tripFare != null && tx.tripFare! > 0)
                Text(
                  'الأجرة: ${TripCalculationHelper.formatPrice(tx.tripFare!, currency: tx.currency, countryCode: countryCode)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.tripCommission:
        return Icons.percent_rounded;
      case WalletTransactionType.tripEarning:
        return Icons.add_circle_outline_rounded;
      case WalletTransactionType.debtPayment:
        return Icons.credit_card_rounded;
      case WalletTransactionType.payout:
        return Icons.account_balance_rounded;
      case WalletTransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }

  Widget _buildEmptyState() {
    final isFiltered = selectedFilter != WalletTransactionFilter.all;
    final info = _getEmptyStateInfo(selectedFilter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              info.$1,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            info.$2,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.$3,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (isFiltered && onResetFilter != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onResetFilter,
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text(
                'عرض كافة العمليات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, String, String) _getEmptyStateInfo(WalletTransactionFilter filter) {
    switch (filter) {
      case WalletTransactionFilter.all:
        return (
          Icons.receipt_long_outlined,
          'لا توجد عمليات مالية مسجلة بعد',
          'ستظهر جميع استقطاعات العمولة وأرباح المشاوير وتسديداتك هنا',
        );
      case WalletTransactionFilter.earnings:
        return (
          Icons.add_circle_outline_rounded,
          'لا توجد أرباح مشاوير إلكترونية',
          'ستظهر أرباح الرحلات المدفوعة بالمحفظة والبطاقات البنكية هنا',
        );
      case WalletTransactionFilter.commissions:
        return (
          Icons.percent_rounded,
          'لا توجد استقطاعات عمولة مسجلة',
          'تُستقطع عمولة المنصة تلقائياً عند إتمام المشاوير النقدية',
        );
      case WalletTransactionFilter.debtPayments:
        return (
          Icons.credit_card_rounded,
          'لا توجد عمليات سداد مديونية',
          'سجل تسديد المديونية المستحقة عبر البطاقة البنكية يظهر هنا',
        );
      case WalletTransactionFilter.payouts:
        return (
          Icons.account_balance_rounded,
          'لا توجد طلبات سحب أرباح منفذة',
          'سجل طلبات سحب الأرباح المحولة لحسابك البنكي يظهر هنا',
        );
    }
  }
}

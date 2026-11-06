/// شريط شرائح تصفية وتصنيف المعاملات المالية لمحفظة السائق
///
/// يدعم التصفية حسب: الكل، أرباح الرحلات، عمولات المنصة،
/// سداد المديونية، وطلبات سحب الأرباح مع شارات العداد
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/driver_wallet_model.dart';

class WalletTransactionFilterChips extends StatelessWidget {
  final WalletTransactionFilter selectedFilter;
  final ValueChanged<WalletTransactionFilter> onFilterSelected;
  final int Function(WalletTransactionFilter filter)? getCount;

  const WalletTransactionFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.getCount,
  });

  @override
  Widget build(BuildContext context) {
    const filters = WalletTransactionFilter.values;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          final count = getCount?.call(filter);

          return _buildChip(
            filter: filter,
            isSelected: isSelected,
            count: count,
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required WalletTransactionFilter filter,
    required bool isSelected,
    int? count,
  }) {
    final title = _getFilterTitle(filter);
    final icon = _getFilterIcon(filter);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterSelected(filter),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.8),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterTitle(WalletTransactionFilter filter) {
    switch (filter) {
      case WalletTransactionFilter.all:
        return 'الكل';
      case WalletTransactionFilter.earnings:
        return 'أرباح الرحلات';
      case WalletTransactionFilter.commissions:
        return 'العمولات';
      case WalletTransactionFilter.debtPayments:
        return 'سداد مديونية';
      case WalletTransactionFilter.payouts:
        return 'سحب أرباح';
    }
  }

  IconData _getFilterIcon(WalletTransactionFilter filter) {
    switch (filter) {
      case WalletTransactionFilter.all:
        return Icons.receipt_long_rounded;
      case WalletTransactionFilter.earnings:
        return Icons.add_circle_outline_rounded;
      case WalletTransactionFilter.commissions:
        return Icons.percent_rounded;
      case WalletTransactionFilter.debtPayments:
        return Icons.credit_card_rounded;
      case WalletTransactionFilter.payouts:
        return Icons.account_balance_rounded;
    }
  }
}

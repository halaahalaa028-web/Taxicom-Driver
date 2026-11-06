/// بطاقة تفصيلية لعرض حالة وبيانات طلب سحب الأرباح الفردي
///
/// توضح حالة الطلب (قيد المراجعة، تم التحويل، أو مرفوض)،
/// تفاصيل الحساب، المبلغ، ورقم الحوالة أو سبب الرفض بشفافية
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../../data/models/driver_wallet_model.dart';

class PayoutRequestCard extends StatelessWidget {
  final PayoutRequestModel request;
  final String? currency;
  final String? countryCode;

  const PayoutRequestCard({
    super.key,
    required this.request,
    this.currency,
    this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final activeCurrency = currency ?? request.currency;
    final formattedAmount = TripCalculationHelper.formatPrice(
      request.amount,
      currency: activeCurrency,
      countryCode: countryCode,
    );

    final dateFormat = DateFormat('yyyy/MM/dd • hh:mm a');
    final formattedCreatedDate = dateFormat.format(request.createdAt);
    final formattedProcessedDate = request.processedAt != null
        ? dateFormat.format(request.processedAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. الترويسة: المبلغ وشارة الحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formattedAmount,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              _buildStatusBadge(context, loc),
            ],
          ),

          const SizedBox(height: 12),

          // 2. تفاصيل وسيلة التحويل والحساب
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getMethodIcon(request.method),
                      size: 15,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_formatMethodName(request.method)} • ${request.accountDetails}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (request.accountHolderName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${loc.accountHolderNameLabel}: ${request.accountHolderName}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. التواريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.requestDateLabel}: $formattedCreatedDate',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. بطاقة الحالة التوضيحية السياقية
          _buildContextNotice(loc, formattedProcessedDate),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (request.isRejected) return AppColors.error.withValues(alpha: 0.3);
    if (request.isCompleted) return AppColors.success.withValues(alpha: 0.3);
    return AppColors.border.withValues(alpha: 0.8);
  }

  Widget _buildStatusBadge(BuildContext context, AppLocalizations loc) {
    if (request.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 13,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              loc.payoutStatusPending,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    if (request.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              loc.payoutStatusApproved,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cancel_rounded,
            size: 13,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            loc.payoutStatusRejected,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextNotice(AppLocalizations loc, String? processedDate) {
    if (request.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppColors.warning,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loc.payoutPendingNotice,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (request.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.payoutCompletedNotice,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (processedDate != null) ...[
              const SizedBox(height: 3),
              Text(
                '${loc.executionDateLabel}: $processedDate',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
            ],
            if (request.transactionReference != null &&
                request.transactionReference!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${loc.transferReferenceLabel}: ${request.transactionReference}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Rejected state
    final reason = request.effectiveRejectionReason ?? 'تم رفض الطلب بواسطة الإدارة';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${loc.rejectionReasonLabel}: $reason',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.payoutRejectedNotice,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
      case 'bank':
        return Icons.account_balance_rounded;
      case 'zain_cash':
      case 'zain':
        return Icons.phone_android_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  String _formatMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
      case 'bank':
        return 'تحويل بنكي';
      case 'zain_cash':
      case 'zain':
        return 'زين كاش';
      case 'wallet':
        return 'محفظة إلكترونية';
      default:
        return 'تحويل بنكي / إلكتروني';
    }
  }
}

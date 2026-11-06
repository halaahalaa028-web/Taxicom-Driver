/// رأس بطاقة تفاصيل الرحلة في تطبيق السائق (الحالة، التاريخ، والسعر)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../models/trip_request_model.dart';

/// رأس بطاقة تفاصيل الرحلة (الحالة، التاريخ، والسعر)
class TripCardHeader extends StatelessWidget {
  final TripRequestModel trip;

  const TripCardHeader({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(trip.status);
    final isCompleted = trip.status == TripStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.surfaceVariant
            : statusColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // أيقونة وشارة الحالة
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(trip.status),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(context, trip.status),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  _formatDate(context, trip.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // شارة السعر وتفاصيل الخصم
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.textPrimary : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  TripCalculationHelper.formatPrice(
                    trip.effectiveOriginalPrice,
                    currency: trip.currency,
                    countryCode: trip.countryCode,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trip.hasDiscount) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${PaymentHelper.getPaymentMethodTitle(context, trip.paymentMethod)}: ${TripCalculationHelper.formatPrice(trip.price, currency: trip.currency, countryCode: trip.countryCode)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${AppLocalizations.of(context).supportedDiscountTag} ${TripCalculationHelper.formatPrice(trip.discountAmount!, currency: trip.currency, countryCode: trip.countryCode)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
      case TripStatus.accepted:
      case TripStatus.arrivedAtPickup:
      case TripStatus.pickedUp:
        return AppColors.textPrimary;
      case TripStatus.completed:
        return AppColors.primary;
      case TripStatus.cancelled:
      case TripStatus.cancelledByDriver:
        return const Color(0xFF555555);
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TripStatus.accepted:
      case TripStatus.arrivedAtPickup:
      case TripStatus.pickedUp:
        return Icons.drive_eta_rounded;
      case TripStatus.completed:
        return Icons.check_rounded;
      case TripStatus.cancelled:
      case TripStatus.cancelledByDriver:
        return Icons.close_rounded;
    }
  }

  String _getStatusText(BuildContext context, TripStatus status) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case TripStatus.pending:
        return loc.statusPending;
      case TripStatus.accepted:
        return loc.statusAccepted;
      case TripStatus.arrivedAtPickup:
        return 'وصل السائق';
      case TripStatus.pickedUp:
        return 'في الطريق';
      case TripStatus.completed:
        return loc.statusCompleted;
      case TripStatus.cancelled:
        return loc.statusCancelled;
      case TripStatus.cancelledByDriver:
        return loc.statusCancelledByDriver;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDate = DateTime(date.year, date.month, date.day);

    final loc = AppLocalizations.of(context);
    final isRtl = loc.isRtl;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? (isRtl ? 'صباحاً' : 'AM') : (isRtl ? 'مساءً' : 'PM');
    final timeStr = '$hour:$minute $period';

    if (tripDate == today) {
      return '${loc.today} $timeStr';
    } else if (tripDate == today.subtract(const Duration(days: 1))) {
      return '${loc.yesterday} $timeStr';
    } else {
      final dateStr = DateFormat('dd/MM/yyyy', isRtl ? 'ar' : 'en').format(date);
      return '$dateStr - $timeStr';
    }
  }
}

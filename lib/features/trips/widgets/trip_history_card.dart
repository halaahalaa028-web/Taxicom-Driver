/// بطاقة عرض تفاصيل الرحلة في سجل الرحلات لتطبيق السائق بتصميم موحد
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/utils/phone_formatter.dart';
import '../models/trip_request_model.dart';
import 'trip_card_header.dart';
import 'trip_history_price_breakdown.dart';
import 'trip_history_ratings_section.dart';

/// بطاقة تفاصيل الرحلة السابقة
class TripHistoryCard extends StatelessWidget {
  final TripRequestModel trip;
  final bool isDriver;
  final ValueChanged<TripRequestModel>? onTap;

  const TripHistoryCard({
    super.key,
    required this.trip,
    this.isDriver = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap != null ? () => onTap!(trip) : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TripCardHeader(trip: trip),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteSection(context),
                    const SizedBox(height: 14),
                    _buildInfoChips(context),
                    if (trip.hasDiscount) ...[
                      const SizedBox(height: 12),
                      TripHistoryPriceBreakdown(trip: trip),
                    ],
                    if (_hasCancellationReason) ...[
                      const SizedBox(height: 12),
                      _buildCancellationReason(context),
                    ],
                    if (trip.passengerRating != null ||
                        trip.driverRating != null) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),
                      TripHistoryRatingsSection(trip: trip, isDriver: isDriver),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasCancellationReason {
    return trip.cancellationReason != null && trip.cancellationReason!.isNotEmpty;
  }

  String get _cancellationReasonText {
    return trip.cancellationReason ?? '';
  }

  /// مسار الرحلة (الانطلاق والوصول والوجهة الثانية إن وجدت)
  Widget _buildRouteSection(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationItem(
          icon: Icons.trip_origin_rounded,
          iconColor: AppColors.textPrimary,
          label: loc.from,
          address: trip.pickupAddress,
        ),
        const SizedBox(height: 12),
        _buildLocationItem(
          icon: Icons.location_on_rounded,
          iconColor: AppColors.textPrimary,
          label: loc.to,
          address: trip.destinationAddress,
        ),
        if (trip.secondDestinationAddress != null &&
            trip.secondDestinationAddress!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLocationItem(
            icon: Icons.add_location_alt_rounded,
            iconColor: AppColors.textSecondary,
            label: loc.secondDestination,
            address: trip.secondDestinationAddress!,
          ),
        ],
      ],
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// رقاقات معلومات الرحلة (المسافة، الراكب ورقم الهاتف، المدة)
  Widget _buildInfoChips(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          icon: Icons.straighten_rounded,
          value: '${trip.distance.toStringAsFixed(1)} ${loc.km}',
        ),
        if (trip.estimatedDuration != null && trip.estimatedDuration! > 0)
          _buildInfoChip(
            icon: Icons.access_time_rounded,
            value: '${trip.estimatedDuration} ${loc.minute}',
          ),
        _buildInfoChip(
          icon: PaymentHelper.getPaymentMethodIcon(trip.paymentMethod),
          value: '${loc.paymentMethod}: ${PaymentHelper.getPaymentMethodTitle(context, trip.paymentMethod)}',
        ),
        if (trip.passengerName.isNotEmpty)
          _buildInfoChip(
            icon: Icons.person_outline_rounded,
            value: trip.passengerPhone.isNotEmpty
                ? '${loc.thePassenger}: ${trip.passengerName} (${PhoneFormatter.format(trip.passengerPhone)})'
                : '${loc.thePassenger}: ${trip.passengerName}',
          ),
        if (trip.tripType == TripType.delivery)
          _buildInfoChip(
            icon: Icons.inventory_2_outlined,
            value: loc.deliveryTab,
          ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// سبب الإلغاء إذا كان متوفراً
  Widget _buildCancellationReason(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.cancellationReasonLabel(_cancellationReasonText),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/trip_request_model.dart';

/// قسم تقييمات الرحلة السابقة
class TripHistoryRatingsSection extends StatelessWidget {
  final TripRequestModel trip;
  final bool isDriver;

  const TripHistoryRatingsSection({
    super.key,
    required this.trip,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ratingsSection,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        if (isDriver) ...[
          if (trip.driverRating != null)
            _buildRatingItem(
              label: l10n.yourRatingForPassenger,
              rating: trip.driverRating!,
              note: trip.driverNote,
            ),
          if (trip.passengerRating != null)
            _buildRatingItem(
              label: l10n.passengerRatingForYou,
              rating: trip.passengerRating!,
              note: trip.passengerNote,
            ),
        ] else ...[
          if (trip.passengerRating != null)
            _buildRatingItem(
              label: l10n.yourRatingForDriver,
              rating: trip.passengerRating!,
              note: trip.passengerNote,
            ),
          if (trip.driverRating != null)
            _buildRatingItem(
              label: l10n.driverRatingForYou,
              rating: trip.driverRating!,
              note: trip.driverNote,
            ),
        ]
      ],
    );
  }

  Widget _buildRatingItem({
    required String label,
    required int rating,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < rating ? Colors.amber : AppColors.border,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '"$note"',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
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

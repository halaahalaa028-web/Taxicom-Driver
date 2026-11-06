/// حوار إلغاء الطلب للسائق (نافذة تحتية - Bottom Sheet)
///
/// يعرض قائمة بأسباب الإلغاء ديناميكياً بحسب مرحلة الرحلة (في الطريق للاستلام / تم الوصول والانتظار)
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../trips/models/trip_request_model.dart';
import '../models/driver_cancellation_reason_model.dart';
import 'driver_cancel_reason_tile.dart';

export '../models/driver_cancellation_reason_model.dart';

/// عرض نافذة إلغاء الطلب التحتية للسائق (Modal Bottom Sheet)
///
/// [tripStatus] تحدد مرحلة الرحلة (في الطريق أو وصل لموقع الاستلام)
Future<String?> showDriverCancelTripDialog(
  BuildContext context, {
  TripStatus tripStatus = TripStatus.accepted,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (bottomSheetContext) => DriverCancelTripDialog(
      tripStatus: tripStatus,
    ),
  );
}

/// نافذة إلغاء الطلب التحتية للسائق
class DriverCancelTripDialog extends StatefulWidget {
  final TripStatus tripStatus;

  const DriverCancelTripDialog({
    super.key,
    this.tripStatus = TripStatus.accepted,
  });

  @override
  State<DriverCancelTripDialog> createState() => _DriverCancelTripDialogState();
}

class _DriverCancelTripDialogState extends State<DriverCancelTripDialog> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final currentReasons = getDriverCancellationReasonsForStatus(widget.tripStatus);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: 20 + mediaQuery.padding.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // مقبض السحب للأعلى
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // العنوان وزر الإغلاق
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loc.driverCancelTripTitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // النص التوضيحي
          Text(
            loc.selectDriverCancellationReason,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // قائمة الأسباب القابلة للتمرير
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: currentReasons
                    .map(
                      (reason) => DriverCancelReasonTile(
                        reason: reason,
                        isSelected: _selectedReason == reason.key,
                        onTap: () {
                          setState(() {
                            _selectedReason = reason.key;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    loc.cancel,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedReason != null
                      ? () => Navigator.pop(context, _selectedReason)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.confirmCancellation,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

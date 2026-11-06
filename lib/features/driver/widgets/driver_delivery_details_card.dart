import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../trips/models/trip_request_model.dart';

/// بطاقة تفاصيل التوصيل لطلبات الطرود
class DriverDeliveryDetailsCard extends StatelessWidget {
  final TripRequestModel request;

  const DriverDeliveryDetailsCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
              SizedBox(width: 6),
              Text(
                'تفاصيل التوصيل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (request.receiverName != null && request.receiverName!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(loc.receiver, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Text(request.receiverName!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          if (request.receiverPhone != null && request.receiverPhone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text('هاتف:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Text(request.receiverPhone!, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (request.packageDescription != null && request.packageDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(loc.package, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(request.packageDescription!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.payment_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('الدفع:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              Text(
                request.paidByReceiver ? 'على المستلم' : 'على المرسل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: request.paidByReceiver ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

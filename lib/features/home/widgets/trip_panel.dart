/// لوحة الرحلة السفلية لتطبيق السائق
/// 
/// تحتوي على حقول الموقع والوجهة والسعر وزر التأكيد
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../services/trip_service.dart';

/// لوحة الرحلة السفلية
class TripPanel extends StatelessWidget {
  final String currentAddress;
  final bool isLoadingAddress;
  final String? destinationAddress;
  final double? distance;
  final VoidCallback onDestinationTap;
  final VoidCallback? onPickupTap;
  final VoidCallback onConfirmTrip;
  final bool canConfirm;

  const TripPanel({
    super.key,
    required this.currentAddress,
    this.isLoadingAddress = false,
    this.destinationAddress,
    this.distance,
    required this.onDestinationTap,
    this.onPickupTap,
    required this.onConfirmTrip,
    this.canConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    final tripService = TripService.instance;
    
    double? price;
    int? estimatedTime;
    if (distance != null) {
      price = tripService.calculatePrice(distance!);
      estimatedTime = tripService.estimateTripTime(distance!);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // حقل الموقع الحالي
                  _buildLocationField(
                    context: context,
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.primary,
                    title: AppStrings.whereAmI,
                    subtitle: isLoadingAddress ? AppStrings.currentLocationHint : currentAddress,
                    isLoading: isLoadingAddress,
                    onTap: onPickupTap,
                    isPickup: true,
                  ),
                  
                  // خط الاتصال بين النقطتين
                  Container(
                    margin: const EdgeInsets.only(right: 27),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 30,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  ),
                  
                  // حقل الوجهة
                  _buildLocationField(
                    context: context,
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.secondary,
                    title: AppStrings.whereTo,
                    subtitle: destinationAddress ?? AppStrings.destinationHint,
                    onTap: onDestinationTap,
                    isDestination: true,
                  ),
                  
                  // تفاصيل الرحلة (إذا تم تحديد الوجهة)
                  if (distance != null && price != null) ...[
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                icon: Icons.straighten_rounded,
                                label: AppStrings.distance,
                                value: tripService.formatDistance(distance!),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppColors.border,
                              ),
                              _buildInfoItem(
                                icon: Icons.access_time_rounded,
                                label: AppStrings.estimatedTime,
                                value: tripService.formatTime(estimatedTime ?? 0),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.payments_rounded,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    AppStrings.estimatedPrice,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    tripService.formatPrice(price),
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // زر تأكيد الطلب
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canConfirm ? onConfirmTrip : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.disabled,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_taxi_rounded, size: 24),
                            SizedBox(width: 12),
                            Text(
                              AppStrings.confirmTrip,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDestination = false,
    bool isPickup = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDestination ? AppColors.background : null,
          borderRadius: BorderRadius.circular(12),
          border: isDestination ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  isLoading
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDestination && subtitle == AppStrings.destinationHint
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            if (isDestination)
              const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            if (isPickup && onTap != null)
              const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

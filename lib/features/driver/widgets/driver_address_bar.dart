import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// ويدجت شريط عنوان السائق الحالي ومؤشر الـ GPS
class DriverAddressBar extends StatelessWidget {
  final String currentAddress;
  final bool isLoadingAddress;
  final bool locationFailed;
  final VoidCallback onRecenter;
  final VoidCallback onOpenLocationSettings;

  const DriverAddressBar({
    super.key,
    required this.currentAddress,
    required this.isLoadingAddress,
    required this.locationFailed,
    required this.onRecenter,
    required this.onOpenLocationSettings,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // أصفر فاتح
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر العودة للموقع الحالي
          GestureDetector(
            onTap: onRecenter,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // العنوان الحالي أو رسالة الخطأ
          Expanded(
            child: isLoadingAddress
                ? Text(
                    loc.locatingPosition,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  )
                : locationFailed
                    ? GestureDetector(
                        onTap: onOpenLocationSettings,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gps_off, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                loc.enableGpsToContinue,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        currentAddress.isNotEmpty
                            ? currentAddress
                            : loc.unknownLocation,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
          ),
        ],
      ),
    );
  }
}

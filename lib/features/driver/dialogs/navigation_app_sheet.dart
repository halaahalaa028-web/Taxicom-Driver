import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

/// فتح تطبيق ملاحة خارجي (Google Maps أو Waze)
class NavigationAppSheet {
  /// عرض ورقة اختيار تطبيق الملاحة وتشغيله
  static Future<void> show(
    BuildContext context, {
    required LatLng destination,
  }) async {
    final lat = destination.latitude;
    final lng = destination.longitude;

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر تطبيق الملاحة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Google Maps
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, 'google'),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.map,
                          size: 40,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Google Maps',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Waze
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, 'waze'),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          size: 40,
                          color: Colors.lightBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Waze',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (choice == null) return;

    Uri uri;
    if (choice == 'google') {
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      if (!await canLaunchUrl(uri)) {
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
        );
      }
    } else {
      uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
      if (!await canLaunchUrl(uri)) {
        uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
      }
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح تطبيق الملاحة: ${choice == 'google' ? 'Google Maps' : 'Waze'}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

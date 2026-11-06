/// نافذة عرض تفاصيل الإشعار للسائق
///
/// تعرض عنوان وتفاصيل الإشعار وتاريخه مع دعم إجراءات سياقية
/// مثل فتح شاشة سجل طلبات سحب الأرباح عند إشعارات الدفع
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../wallet/presentation/screens/payout_requests_screen.dart';
import '../models/notification_model.dart';

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationModel notification;
  final String currentUserId;

  const NotificationDetailsSheet({
    super.key,
    required this.notification,
    required this.currentUserId,
  });

  static void show(BuildContext context, NotificationModel notification, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationDetailsSheet(
        notification: notification,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPayout = notification.type == 'payout_approved' || notification.type == 'payout_rejected';

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              // مقبض السحب
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          size: 38,
                          color: _getNotificationColor(notification.type),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // العنوان
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // التاريخ
                    Text(
                      intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(notification.timestamp),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // نص المحتوى
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        notification.body,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    if (isPayout) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayoutRequestsScreen(driverId: currentUserId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: const Text(
                          'عرض سجل طلبات السحب',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // زر الإغلاق
              SafeArea(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).close,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'payout_approved':
        return Icons.account_balance_wallet_rounded;
      case 'payout_rejected':
        return Icons.error_outline_rounded;
      case 'driver_approved':
        return Icons.check_circle_rounded;
      case 'driver_rejected':
        return Icons.cancel_rounded;
      case 'discount':
        return Icons.local_offer_rounded;
      case 'update':
        return Icons.system_update_rounded;
      case 'promo':
        return Icons.card_giftcard_rounded;
      case 'system':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'payout_approved':
      case 'driver_approved':
        return AppColors.success;
      case 'payout_rejected':
      case 'driver_rejected':
        return AppColors.error;
      case 'discount':
        return Colors.orange;
      case 'promo':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}

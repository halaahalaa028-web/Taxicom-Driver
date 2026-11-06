
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/notification_model.dart';
// import 'package:timeago/timeago.dart' as timeago;

class NotificationItemWidget extends StatelessWidget {
  final NotificationModel notification;
  final String currentUserId;
  final VoidCallback onTap;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isReadBy(currentUserId);
    
    // Determine icon based on type
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case 'payout_approved':
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = AppColors.success;
        break;
      case 'payout_rejected':
        iconData = Icons.error_outline_rounded;
        iconColor = AppColors.error;
        break;
      case 'driver_approved':
        iconData = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        break;
      case 'driver_rejected':
        iconData = Icons.cancel_rounded;
        iconColor = AppColors.error;
        break;
      case 'discount':
        iconData = Icons.local_offer_rounded;
        iconColor = Colors.orange;
        break;
      case 'update':
        iconData = Icons.system_update_rounded;
        iconColor = AppColors.primary;
        break;
      case 'promo':
        iconData = Icons.card_giftcard_rounded;
        iconColor = Colors.green;
        break;
      case 'system':
      default:
        iconData = Icons.notifications_rounded;
        iconColor = AppColors.primary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: isUnread 
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          _formatDate(context, notification.timestamp),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Now'; // Or localized 'Now'
        }
        return AppLocalizations.of(context).minutesAgo(difference.inMinutes);
      }
      return AppLocalizations.of(context).hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context).daysAgo(difference.inDays);
    } else {
      return intl.DateFormat('yyyy/MM/dd', 'en').format(date);
    }
  }
}

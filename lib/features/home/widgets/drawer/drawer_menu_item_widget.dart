import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// نموذج بيانات عنصر القائمة الجانبية
class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// ويدجت عنصر القائمة الجانبية للسائق
class DrawerMenuItemWidget extends StatelessWidget {
  final DrawerMenuItem item;

  const DrawerMenuItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // الأيقونة
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.isDestructive ? Colors.red : AppColors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: item.isDestructive
                            ? Colors.red
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // سهم التنقل
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

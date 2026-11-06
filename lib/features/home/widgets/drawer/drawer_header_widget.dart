import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/models/user_model.dart';

/// ويدجت رأس القائمة الجانبية (Drawer Header) للسائق
class DrawerHeaderWidget extends StatelessWidget {
  final UserModel? userData;
  final String userName;
  final String userPhone;
  final VoidCallback onTap;

  const DrawerHeaderWidget({
    super.key,
    required this.userData,
    required this.userName,
    required this.userPhone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fallbackName = userData?.userType == 'driver' ? l10n.asDriver : l10n.asCustomer;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // صورة السائق
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: userData?.profilePhotoUrl != null &&
                        userData!.profilePhotoUrl!.isNotEmpty
                    ? Image.network(
                        userData!.profilePhotoUrl!,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // اسم السائق
            Text(
              userName.isNotEmpty ? userName : fallbackName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // رقم الهاتف
            if (userPhone.isNotEmpty)
              Text(
                userPhone,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

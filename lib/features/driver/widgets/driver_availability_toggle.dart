import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// ويدجت تبديل حالة توفر السائق للعمل مع التلميح المتحرك
class DriverAvailabilityToggle extends StatelessWidget {
  final bool isStatusInitialized;
  final bool isAvailable;
  final bool isTogglingAvailability;
  final VoidCallback onToggle;

  const DriverAvailabilityToggle({
    super.key,
    required this.isStatusInitialized,
    required this.isAvailable,
    required this.isTogglingAvailability,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (!isStatusInitialized) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              loc.updating,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isTogglingAvailability ? null : onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAvailable ? AppColors.success : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.success : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.power_settings_new_rounded
                        : Icons.power_off_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable
                            ? loc.availableForWork
                            : loc.notAvailable,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        isTogglingAvailability
                            ? loc.updating
                            : (isAvailable
                                ? loc.tapToStopReceiving
                                : loc.tapToStartReceiving),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTogglingAvailability)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  Switch(
                    value: isAvailable,
                    onChanged: (value) => onToggle(),
                    activeThumbColor: AppColors.success,
                  ),
              ],
            ),
          ),
        ),
        // تلميح تصغير التطبيق المتحرك — يظهر فقط عند التفعيل
        if (isAvailable)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: _PulsingHint(),
          ),
      ],
    );
  }
}

/// تلميح متحرك: يُذكّر السائق بتصغير التطبيق بدلاً من إغلاقه
class _PulsingHint extends StatefulWidget {
  const _PulsingHint();

  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_rounded, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'لاستلام الطلبات لا تُغلق التطبيق تماماً\nصغّره فقط وتصفّح هاتفك بحرية ✓',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

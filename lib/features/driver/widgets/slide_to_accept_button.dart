import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class SlideToAcceptButton extends StatefulWidget {
  final VoidCallback onAccepted;
  final String label;
  final Color? glowColor;

  const SlideToAcceptButton({
    super.key,
    required this.onAccepted,
    this.label = 'اسحب للقبول وتوصيل الطلب',
    this.glowColor,
  });

  @override
  State<SlideToAcceptButton> createState() => _SlideToAcceptButtonState();
}

class _SlideToAcceptButtonState extends State<SlideToAcceptButton>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  late AnimationController _glowController;
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeGlow = widget.glowColor ?? AppColors.success;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double knobSize = 56.0;
        final double maxDragDistance = width - knobSize - 4.0; // 2px padding each side

        return AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glowValue = _glowController.value;
            final double glowSpread = 2.0 + (glowValue * 6.0);

            return Container(
              width: width,
              height: knobSize + 4.0,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: themeGlow.withValues(alpha: 0.3 + (glowValue * 0.4)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeGlow.withValues(alpha: 0.15 + (glowValue * 0.15)),
                    blurRadius: 10 + (glowValue * 8),
                    spreadRadius: glowSpread,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Text label
                  Center(
                    child: Opacity(
                      opacity: 0.6 + (glowValue * 0.4),
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Background fill
                  Positioned(
                    left: 2,
                    top: 2,
                    bottom: 2,
                    child: Container(
                      width: _dragValue * maxDragDistance + knobSize / 2,
                      decoration: BoxDecoration(
                        color: themeGlow.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  // Knob
                  Positioned(
                    left: 2 + (_dragValue * maxDragDistance),
                    top: 2,
                    bottom: 2,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        HapticFeedback.selectionClick();
                      },
                      onHorizontalDragUpdate: (details) {
                        if (_isAccepted) return;
                        setState(() {
                          _dragValue += details.primaryDelta! / maxDragDistance;
                          if (_dragValue < 0.0) _dragValue = 0.0;
                          if (_dragValue > 1.0) _dragValue = 1.0;
                        });
                        if ((_dragValue * 10).toInt() % 2 == 0) {
                          HapticFeedback.lightImpact();
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        if (_isAccepted) return;
                        if (_dragValue >= 0.9) {
                          HapticFeedback.vibrate();
                          setState(() {
                            _dragValue = 1.0;
                            _isAccepted = true;
                          });
                          widget.onAccepted();
                        } else {
                          setState(() {
                            _dragValue = 0.0;
                          });
                          HapticFeedback.mediumImpact();
                        }
                      },
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.double_arrow_rounded,
                          color: themeGlow,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

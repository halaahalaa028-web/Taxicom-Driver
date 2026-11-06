/// زر الضغط المطول
/// 
/// زر يتطلب الضغط لمدة محددة للتفعيل مع تأثير تعبئة تدريجية
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// زر الضغط المطول للقبول
class HoldToAcceptButton extends StatefulWidget {
  /// المدة المطلوبة للضغط (بالثواني)
  final double holdDuration;
  
  /// دالة تنفذ عند اكتمال الضغط
  final VoidCallback onAccepted;
  
  /// نص الزر
  final String label;
  
  /// أيقونة الزر
  final IconData icon;
  
  const HoldToAcceptButton({
    super.key,
    this.holdDuration = 1.0,
    required this.onAccepted,
    this.label = 'اضغط مع الاستمرار للقبول',
    this.icon = Icons.check_rounded,
  });

  @override
  State<HoldToAcceptButton> createState() => _HoldToAcceptButtonState();
}

class _HoldToAcceptButtonState extends State<HoldToAcceptButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHolding = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.holdDuration * 1000).toInt()),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // اهتزاز خفيف عند الاكتمال
        widget.onAccepted();
        _resetState();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _startHolding() {
    setState(() {
      _isHolding = true;
    });
    _animationController.forward();
  }
  
  void _stopHolding() {
    if (_isHolding) {
      _resetState();
    }
  }
  
  void _resetState() {
    setState(() {
      _isHolding = false;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHolding(),
      onLongPressEnd: (_) => _stopHolding(),
      onLongPressCancel: _stopHolding,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHolding ? AppColors.success : AppColors.success.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: _isHolding
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // الخلفية الثابتة
                  Container(
                    color: AppColors.success.withValues(alpha: 0.1),
                  ),
                  
                  // شريط التقدم المتحرك
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: _animationController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success.withValues(alpha: 0.8),
                              AppColors.success,
                            ],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // المحتوى
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // أيقونة متحركة
                        Transform.scale(
                          scale: _isHolding ? 1.2 : 1.0,
                          child: Icon(
                            _isHolding ? Icons.check_circle_rounded : widget.icon,
                            color: _animationController.value > 0.5
                                ? Colors.white
                                : AppColors.success,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // النص
                        Text(
                          _isHolding 
                              ? 'استمر... ${((1 - _animationController.value) * widget.holdDuration).toStringAsFixed(1)} ث'
                              : widget.label,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _animationController.value > 0.5
                                ? Colors.white
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // تأثير النبض عند الضغط
                  if (_isHolding)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3 * (1 - _animationController.value)),
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

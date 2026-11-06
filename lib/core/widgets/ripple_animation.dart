
import 'package:flutter/material.dart';

class RippleAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final double size;

  const RippleAnimation({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.size = 60.0,
  });

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildRipple(0.0),
        _buildRipple(0.5),
        widget.child,
      ],
    );
  }

  Widget _buildRipple(double startDelay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = (_controller.value + startDelay) % 1.0;
        final double scale = 1.0 + (progress * 0.5); // Grows from 1.0 to 1.5
        final double opacity = 1.0 - progress; // Fades out

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: opacity * 0.3),
            ),
          ),
        );
      },
    );
  }
}

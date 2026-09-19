import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';

class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius = 999,
    super.key,
  });

  final double value;
  final Color color;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  double _settledValue = 0;

  @override
  void initState() {
    super.initState();
    _settledValue = widget.value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    final trackColor =
        widget.backgroundColor ?? widget.color.withValues(alpha: 0.15);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _settledValue, end: target),
      duration: AppMotion.resolve(context, AppMotion.progress),
      curve: AppMotion.standard,
      onEnd: () {
        if (mounted && _settledValue != target) {
          setState(() => _settledValue = target);
        }
      },
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: widget.height,
            backgroundColor: trackColor,
            color: widget.color,
          ),
        );
      },
    );
  }
}

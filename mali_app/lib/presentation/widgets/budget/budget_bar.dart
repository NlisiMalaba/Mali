import 'package:flutter/material.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';

class BudgetBar extends StatefulWidget {
  const BudgetBar({
    required this.usage,
    this.height = 8,
    this.borderRadius = 6,
    super.key,
  });

  final double usage;
  final double height;
  final double borderRadius;

  @override
  State<BudgetBar> createState() => _BudgetBarState();
}

class _BudgetBarState extends State<BudgetBar> {
  static const Duration _animationDuration = Duration(milliseconds: 350);

  double _settledUsage = 0;

  @override
  void initState() {
    super.initState();
    _settledUsage = widget.usage.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final targetUsage = widget.usage.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _settledUsage, end: targetUsage),
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      onEnd: () {
        if (mounted && _settledUsage != targetUsage) {
          setState(() => _settledUsage = targetUsage);
        }
      },
      builder: (context, animatedUsage, _) {
        final color = BudgetUsage.progressColor(animatedUsage);

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: LinearProgressIndicator(
            value: animatedUsage,
            minHeight: widget.height,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        );
      },
    );
  }
}

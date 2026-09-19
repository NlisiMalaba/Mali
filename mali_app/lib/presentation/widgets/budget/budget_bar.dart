import 'package:flutter/material.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/widgets/common/animated_progress_bar.dart';

class BudgetBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final targetUsage = usage.clamp(0.0, 1.0);
    final color = BudgetUsage.progressColor(targetUsage);

    return AnimatedProgressBar(
      value: targetUsage,
      color: color,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

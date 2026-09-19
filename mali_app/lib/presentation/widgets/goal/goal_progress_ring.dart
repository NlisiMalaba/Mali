import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';

class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    required this.progress,
    this.size = defaultSize,
    this.strokeWidth = defaultStrokeWidth,
    this.milestoneSize = milestoneMarkerSize,
    this.showMilestones = true,
    this.child,
    super.key,
  });

  static const double defaultSize = 72;
  static const double defaultStrokeWidth = 7;
  static const double detailSize = 176;
  static const double detailStrokeWidth = 14;
  static const double milestoneMarkerSize = 6;
  static const double detailMilestoneSize = 10;
  static const double milestoneBorderWidth = 1.5;
  static const double startDegreeOffset = -90;
  static const double unfilledTrackOpacity = 0.15;
  static const Duration chartAnimationDuration = Duration.zero;

  static Key milestoneKey(int percent) => Key('goal-milestone-$percent');

  /// Fraction of the ring to fill, typically 0–1.
  final double progress;
  final double size;
  final double strokeWidth;
  final double milestoneSize;
  final bool showMilestones;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final color = clamped >= 1 ? AppColors.success : AppColors.tealPrimary;
    final centerSpaceRadius = (size / 2) - strokeWidth;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  startDegreeOffset: startDegreeOffset,
                  centerSpaceRadius: centerSpaceRadius,
                  pieTouchData: PieTouchData(enabled: false),
                  borderData: FlBorderData(show: false),
                  sections: _sections(clamped, color),
                ),
                duration: chartAnimationDuration,
              ),
            ),
          ),
          if (showMilestones)
            ...GoalProgress.milestoneFractions.map(
              (fraction) => _milestoneMarker(
                fraction: fraction,
                reached: clamped >= fraction,
                color: color,
              ),
            ),
          ?child,
        ],
      ),
    );
  }

  List<PieChartSectionData> _sections(double clamped, Color color) {
    final remaining = 1 - clamped;
    return [
      if (clamped > 0)
        PieChartSectionData(
          value: clamped,
          color: color,
          radius: strokeWidth,
          showTitle: false,
        ),
      if (remaining > 0)
        PieChartSectionData(
          value: remaining,
          color: color.withValues(alpha: unfilledTrackOpacity),
          radius: strokeWidth,
          showTitle: false,
        ),
    ];
  }

  Widget _milestoneMarker({
    required double fraction,
    required bool reached,
    required Color color,
  }) {
    final percent = (fraction * 100).round();
    final angle = (startDegreeOffset * math.pi / 180) + (2 * math.pi * fraction);
    final ringRadius = (size / 2) - (strokeWidth / 2);
    final center = size / 2;
    final left = center + ringRadius * math.cos(angle) - (milestoneSize / 2);
    final top = center + ringRadius * math.sin(angle) - (milestoneSize / 2);

    return Positioned(
      key: milestoneKey(percent),
      left: left,
      top: top,
      width: milestoneSize,
      height: milestoneSize,
      child: Semantics(
        label: '$percent% milestone',
        value: reached ? 'reached' : 'upcoming',
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? color : Colors.white,
            border: Border.all(color: color, width: milestoneBorderWidth),
          ),
        ),
      ),
    );
  }
}

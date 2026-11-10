import 'package:flutter/material.dart';

/// Shared motion tokens for consistent, presentation-ready animations.
class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration progress = Duration(milliseconds: 400);
  static const Duration celebration = Duration(milliseconds: 550);
  static const Duration staggerStep = Duration(milliseconds: 60);

  static const Duration countUp = Duration(milliseconds: 1200);
  static const Duration sheet = Duration(milliseconds: 420);
  static const Duration ring = Duration(milliseconds: 1400);

  static const Curve standard = Curves.easeOutCubic;

  /// Slight overshoot for sheets and buttons that "spring" into place.
  static const Curve spring = Cubic(0.2, 0.9, 0.25, 1.15);
  static const Curve decelerate = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;

  static Duration resolve(BuildContext context, Duration duration) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return duration;
  }

  static Duration staggerDelay(int index) {
    return Duration(milliseconds: staggerStep.inMilliseconds * index);
  }
}

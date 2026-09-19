import 'package:flutter/material.dart';

/// Shared motion tokens for consistent, presentation-ready animations.
class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration progress = Duration(milliseconds: 400);
  static const Duration celebration = Duration(milliseconds: 550);
  static const Duration staggerStep = Duration(milliseconds: 60);

  static const Curve standard = Curves.easeOutCubic;
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

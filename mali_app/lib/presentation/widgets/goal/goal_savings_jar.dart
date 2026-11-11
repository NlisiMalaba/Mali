import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Glass jar that fills with green “savings liquid” based on goal progress.
class GoalSavingsJar extends StatelessWidget {
  const GoalSavingsJar({
    required this.progress,
    this.width = 138,
    this.height = 168,
    super.key,
  });

  static const Key jarKey = Key('goal-savings-jar');
  static const Color liquid = AppColors.success;
  static const Color liquidWave = Color(0xFF3A8A5F);
  static const Color glassBorder = Color(0xFFC8CFDD);

  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      key: jarKey,
      width: width,
      height: height + 16,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 70,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            top: 12,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: glassBorder, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: clamped.clamp(0.04, 1.0),
                        widthFactor: 1,
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: liquid),
                            Align(
                              alignment: Alignment.topCenter,
                              child: CustomPaint(
                                size: Size(width, 16),
                                painter: _WavePainter(
                                  color: liquidWave.withValues(alpha: 0.6),
                                  amplitude: 4,
                                  wavelength: 34,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: CustomPaint(
                                  size: Size(width, 14),
                                  painter: const _WavePainter(
                                    color: liquid,
                                    amplitude: 3.5,
                                    wavelength: 46,
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 30,
                              bottom: 28,
                              child: _Bubble(size: 6),
                            ),
                            const Positioned(
                              right: 30,
                              bottom: 36,
                              child: _Bubble(size: 4),
                            ),
                            const Positioned(
                              right: 12,
                              bottom: 20,
                              child: _Bubble(size: 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 20,
                      child: Container(
                        width: 10,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.silver,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.color,
    required this.amplitude,
    required this.wavelength,
  });

  final Color color;
  final double amplitude;
  final double wavelength;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 1) {
      final y = amplitude * math.sin((x / wavelength) * 2 * math.pi) +
          amplitude +
          2;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.wavelength != wavelength;
  }
}

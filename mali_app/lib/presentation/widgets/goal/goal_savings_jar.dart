import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';

/// Glass jar that fills with green “savings liquid” based on goal progress.
class GoalSavingsJar extends StatefulWidget {
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
  State<GoalSavingsJar> createState() => _GoalSavingsJarState();
}

class _GoalSavingsJarState extends State<GoalSavingsJar>
    with TickerProviderStateMixin {
  late final AnimationController _fill;
  late final AnimationController _ambient;
  late final Animation<double> _fillCurve;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: AppMotion.ring,
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _fillCurve = CurvedAnimation(
      parent: _fill,
      curve: AppMotion.standard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _fill.value = 1;
      if (_ambient.isAnimating) {
        _ambient.stop();
      }
      _ambient.value = 0;
      return;
    }

    if (_fill.status == AnimationStatus.dismissed) {
      _fill.forward();
    }
    if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GoalSavingsJar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress &&
        !MediaQuery.disableAnimationsOf(context)) {
      _fill
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final target = widget.progress.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_fillCurve, _ambient]),
      builder: (context, _) {
        final fillT = reduceMotion ? 1.0 : _fillCurve.value;
        final filled = (target * fillT).clamp(0.0, 1.0);
        final wavePhase = reduceMotion ? 0.0 : _ambient.value * math.pi * 2;
        final float = reduceMotion
            ? 0.0
            : math.sin(_ambient.value * math.pi * 2) * 3.5;
        final tilt = reduceMotion
            ? 0.0
            : math.sin(_ambient.value * math.pi * 2 + 0.6) * 0.035;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..translateByDouble(0, float, 0, 1)
            ..rotateY(tilt)
            ..rotateX(-0.04 + (1 - fillT) * 0.12),
          child: SizedBox(
            key: GoalSavingsJar.jarKey,
            width: widget.width,
            height: widget.height + 16,
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
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                        bottom: Radius.circular(38),
                      ),
                      border: Border.all(
                        color: GoalSavingsJar.glassBorder,
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 24),
                          spreadRadius: -18,
                        ),
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(-14, 0),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30.4),
                        bottom: Radius.circular(36.4),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: filled.clamp(0.04, 1.0),
                              widthFactor: 1,
                              alignment: Alignment.bottomCenter,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const ColoredBox(color: GoalSavingsJar.liquid),
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: CustomPaint(
                                      size: Size(widget.width, 16),
                                      painter: _WavePainter(
                                        color: GoalSavingsJar.liquidWave
                                            .withValues(alpha: 0.6),
                                        amplitude: 4,
                                        wavelength: 34,
                                        phase: wavePhase,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: CustomPaint(
                                        size: Size(widget.width, 14),
                                        painter: _WavePainter(
                                          color: GoalSavingsJar.liquid,
                                          amplitude: 3.5,
                                          wavelength: 46,
                                          phase: -wavePhase * 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _AnimatedBubble(
                                    left: 30,
                                    bottom: 10 +
                                        (reduceMotion
                                            ? 18
                                            : 14 +
                                                math.sin(wavePhase + 0.4) * 8),
                                    size: 6,
                                    opacity: 0.9,
                                  ),
                                  _AnimatedBubble(
                                    left: 78,
                                    bottom: 20 +
                                        (reduceMotion
                                            ? 16
                                            : 12 +
                                                math.sin(wavePhase + 1.6) * 10),
                                    size: 4,
                                    opacity: 0.85,
                                  ),
                                  _AnimatedBubble(
                                    left: 100,
                                    bottom: 6 +
                                        (reduceMotion
                                            ? 14
                                            : 10 +
                                                math.sin(wavePhase + 2.4) * 7),
                                    size: 5,
                                    opacity: 0.8,
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
          ),
        );
      },
    );
  }
}

class _AnimatedBubble extends StatelessWidget {
  const _AnimatedBubble({
    required this.left,
    required this.bottom,
    required this.size,
    required this.opacity,
  });

  final double left;
  final double bottom;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.silver,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.color,
    required this.amplitude,
    required this.wavelength,
    this.phase = 0,
  });

  final Color color;
  final double amplitude;
  final double wavelength;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 1) {
      final y = amplitude *
              math.sin((x / wavelength) * 2 * math.pi + phase) +
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
        oldDelegate.wavelength != wavelength ||
        oldDelegate.phase != phase;
  }
}

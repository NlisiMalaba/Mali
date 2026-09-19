import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// One-shot confetti burst used by [MilestoneCelebrationOverlay].
///
/// The animation is finite so the overlay can idle until auto-dismiss.
class MilestoneConfetti extends StatefulWidget {
  const MilestoneConfetti({super.key});

  static const Key confettiKey = Key('milestone-confetti');
  static const Duration burstDuration = Duration(milliseconds: 1200);
  static const int particleCount = 42;
  static const int randomSeed = 42;
  static const double gravity = 2.2;
  static const double fadeStartProgress = 0.65;
  static const double startYMin = -0.08;
  static const double startYRange = 0.12;
  static const double velocityXSpread = 0.85;
  static const double velocityYMin = 0.3;
  static const double velocityYRange = 0.55;
  static const double rotationTurnsSpread = 4;
  static const double minParticleWidth = 6;
  static const double particleWidthRange = 5;
  static const double minParticleHeight = 8;
  static const double particleHeightRange = 6;
  static const double particleCornerRadius = 1.5;
  static const Color goldAccent = Color(0xFFFBBF24);

  static const List<Color> colors = [
    AppColors.tealPrimary,
    AppColors.tealPrimaryLight,
    AppColors.success,
    AppColors.warning,
    goldAccent,
  ];

  @override
  State<MilestoneConfetti> createState() => _MilestoneConfettiState();
}

class _MilestoneConfettiState extends State<MilestoneConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _createParticles();
    _controller = AnimationController(
      vsync: this,
      duration: MilestoneConfetti.burstDuration,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _createParticles() {
    final random = math.Random(MilestoneConfetti.randomSeed);
    return [
      for (var index = 0; index < MilestoneConfetti.particleCount; index++)
        _ConfettiParticle(
          startX: random.nextDouble(),
          startY: MilestoneConfetti.startYMin +
              random.nextDouble() * MilestoneConfetti.startYRange,
          velocityX:
              (random.nextDouble() - 0.5) * MilestoneConfetti.velocityXSpread,
          velocityY: MilestoneConfetti.velocityYMin +
              random.nextDouble() * MilestoneConfetti.velocityYRange,
          rotationTurns:
              (random.nextDouble() - 0.5) * MilestoneConfetti.rotationTurnsSpread,
          color: MilestoneConfetti.colors[index % MilestoneConfetti.colors.length],
          width: MilestoneConfetti.minParticleWidth +
              random.nextDouble() * MilestoneConfetti.particleWidthRange,
          height: MilestoneConfetti.minParticleHeight +
              random.nextDouble() * MilestoneConfetti.particleHeightRange,
          isCircle: index.isEven,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            key: MilestoneConfetti.confettiKey,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
            child: child,
          );
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotationTurns,
    required this.color,
    required this.width,
    required this.height,
    required this.isCircle,
  });

  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotationTurns;
  final Color color;
  final double width;
  final double height;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final opacity = _opacityFor(progress);
    if (opacity <= 0) {
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    final fall = progress * progress * MilestoneConfetti.gravity;

    for (final particle in particles) {
      final dx = (particle.startX + particle.velocityX * progress) * size.width;
      final dy =
          (particle.startY + particle.velocityY * progress + fall) * size.height;
      paint.color = particle.color.withValues(alpha: opacity);

      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(particle.rotationTurns * progress * 2 * math.pi);

      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.width / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.width,
              height: particle.height,
            ),
            const Radius.circular(MilestoneConfetti.particleCornerRadius),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  double _opacityFor(double t) {
    if (t <= MilestoneConfetti.fadeStartProgress) {
      return 1;
    }
    final fadeRange = 1 - MilestoneConfetti.fadeStartProgress;
    return (1 - (t - MilestoneConfetti.fadeStartProgress) / fadeRange)
        .clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

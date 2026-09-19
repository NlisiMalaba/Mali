import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.width,
    this.height,
    this.borderRadius = 12,
    super.key,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _baseBox(opacity: 0.35);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + (_controller.value * 2), 0),
              end: Alignment(1 + (_controller.value * 2), 0),
              colors: const [
                AppColors.surfaceContainerHigh,
                AppColors.surfaceContainerLowest,
                AppColors.surfaceContainerHigh,
              ],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: _baseBox(),
    );
  }

  Widget _baseBox({double opacity = 1}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }
}

class NetWorthCardSkeleton extends StatelessWidget {
  const NetWorthCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primaryContainer.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 120, height: 12, borderRadius: 6),
          SizedBox(height: 16),
          ShimmerBox(width: 200, height: 36, borderRadius: 8),
          SizedBox(height: 24),
          ShimmerBox(width: 140, height: 24, borderRadius: 999),
        ],
      ),
    );
  }
}

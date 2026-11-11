import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';

enum SovereignNavDestination {
  home,
  insights,
  goals,
  settings,
}

/// Floating navy bottom bar matching the Master of Coin HTML redesign:
/// Home · Insights · + (add) · Goals · Settings.
class SovereignBottomNav extends StatelessWidget {
  const SovereignBottomNav({
    required this.selected,
    required this.onDestinationSelected,
    required this.onAddPressed,
    super.key,
  });

  static const double _barHeight = 70;
  static const double _sideMargin = 16;
  static const double _bottomMargin = 18;
  static const double _barRadius = 26;

  /// Space to reserve so scrollable content and sheets are not hidden behind
  /// the floating bar.
  static double contentInset(BuildContext context) {
    return _barHeight + _bottomMargin + MediaQuery.paddingOf(context).bottom;
  }

  final SovereignNavDestination selected;
  final ValueChanged<SovereignNavDestination> onDestinationSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _sideMargin,
          0,
          _sideMargin,
          _bottomMargin,
        ),
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(_barRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.5),
                blurRadius: 34,
                spreadRadius: -8,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Home',
                selected: selected == SovereignNavDestination.home,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.home),
                child: const Icon(Icons.home_outlined, size: 22),
              ),
              _NavItem(
                label: 'Insights',
                selected: selected == SovereignNavDestination.insights,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.insights),
                child: const Icon(Icons.pie_chart_outline, size: 22),
              ),
              _AddFab(onPressed: onAddPressed),
              _NavItem(
                label: 'Goals',
                selected: selected == SovereignNavDestination.goals,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.goals),
                child: const _TargetIcon(size: 22),
              ),
              _NavItem(
                label: 'Settings',
                selected: selected == SovereignNavDestination.settings,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.settings),
                child: const Icon(Icons.tune_rounded, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  static const double _tapSize = 48;
  static const double _dotSize = 4;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.silver : AppColors.navInactive;
    final duration = AppMotion.resolve(context, AppMotion.normal);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: _tapSize / 2,
          child: SizedBox(
            width: _tapSize,
            height: _tapSize,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 22),
                  child: child,
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.spring,
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.silver : Colors.transparent,
                    borderRadius: BorderRadius.circular(_dotSize),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Concentric-circle target icon from the redesign Goals tab.
class _TargetIcon extends StatelessWidget {
  const _TargetIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? AppColors.navInactive;
    return CustomPaint(
      size: Size.square(size),
      painter: _TargetPainter(color: color),
    );
  }
}

class _TargetPainter extends CustomPainter {
  const _TargetPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.42, paint);
    canvas.drawCircle(center, size.width * 0.24, paint);
    canvas.drawCircle(center, size.width * 0.06, paint);
  }

  @override
  bool shouldRepaint(covariant _TargetPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  static const double _size = 58;
  static const double _lift = -30;
  static const double _ringWidth = 5;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, _lift),
      child: Semantics(
        button: true,
        label: 'Add transaction',
        child: PressableScale(
          scale: 0.92,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(_ringWidth),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: AppColors.silver,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.55),
                    blurRadius: 24,
                    spreadRadius: -8,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 26,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

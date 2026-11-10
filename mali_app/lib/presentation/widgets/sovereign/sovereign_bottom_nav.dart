import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';

enum SovereignNavDestination {
  home,
  wallets,
  budgets,
  goals,
}

/// Floating navy bottom bar with a raised silver "add" button in the middle.
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
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                selected: selected == SovereignNavDestination.home,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.home),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: 'Wallets',
                selected: selected == SovereignNavDestination.wallets,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.wallets),
              ),
              _AddFab(onPressed: onAddPressed),
              _NavItem(
                icon: Icons.pie_chart_outline,
                selectedIcon: Icons.pie_chart,
                label: 'Budgets',
                selected: selected == SovereignNavDestination.budgets,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.budgets),
              ),
              _NavItem(
                icon: Icons.track_changes_outlined,
                selectedIcon: Icons.track_changes,
                label: 'Goals',
                selected: selected == SovereignNavDestination.goals,
                onTap: () =>
                    onDestinationSelected(SovereignNavDestination.goals),
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
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _tapSize = 52;
  static const double _iconSize = 24;
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
                AnimatedSwitcher(
                  duration: duration,
                  child: Icon(
                    selected ? (selectedIcon ?? icon) : icon,
                    key: ValueKey(selected),
                    size: _iconSize,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.spring,
                  width: selected ? _dotSize * 4 : _dotSize,
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

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  static const double _size = 58;
  static const double _lift = -26;
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
            width: _size + _ringWidth * 2,
            height: _size + _ringWidth * 2,
            padding: const EdgeInsets.all(_ringWidth),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: DecoratedBox(
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
              child: const Icon(Icons.add_rounded, size: 30, color: AppColors.navy),
            ),
          ),
        ),
      ),
    );
  }
}

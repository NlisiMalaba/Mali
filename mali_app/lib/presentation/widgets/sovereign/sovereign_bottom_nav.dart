import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';

enum SovereignNavDestination {
  home,
  wallets,
  budgets,
  goals,
}

class SovereignBottomNav extends StatelessWidget {
  const SovereignBottomNav({
    required this.selected,
    required this.onDestinationSelected,
    required this.onAddPressed,
    super.key,
  });

  final SovereignNavDestination selected;
  final ValueChanged<SovereignNavDestination> onDestinationSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppDecorations.glassBar(
      backgroundColor: isDark
          ? AppColors.darkSurface
          : AppColors.surfaceContainerLowest,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDecorations.radiusHero),
      ),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: AppDecorations.bottomNavShadow(),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDecorations.radiusHero),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Home',
              selected: selected == SovereignNavDestination.home,
              onTap: () => onDestinationSelected(SovereignNavDestination.home),
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
              icon: Icons.layers_outlined,
              selectedIcon: Icons.layers,
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
              onTap: () => onDestinationSelected(SovereignNavDestination.goals),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: selected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryFixed.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? (selectedIcon ?? icon) : icon,
              size: 24,
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: selected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Material(
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          child: Ink(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppDecorations.primaryButtonGradient,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            ),
            child: const Icon(
              Icons.add,
              size: 36,
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/animated_progress_bar.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';

/// Compact white goal row used under “Also saving for”.
class GoalListTile extends StatelessWidget {
  const GoalListTile({
    required this.goal,
    this.index = 0,
    this.onTap,
    super.key,
  });

  final SavingsGoal goal;
  final int index;
  final VoidCallback? onTap;

  static Key tileKey(String goalId) => Key('goal-list-tile-$goalId');

  void _openDetail(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    context.push('/goals/${goal.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = GoalProgress.ratio(goal).clamp(0.0, 1.0);
    final emoji = goal.emoji?.trim();
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    final palette = _paletteFor(index);
    final current = MoneyDisplay.compact(
      amount: goal.currentAmount,
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );
    final target = MoneyDisplay.compact(
      amount: goal.targetAmount,
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );

    return PressableScale(
      key: tileKey(goal.id),
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppDecorations.surfaceCard(
          radius: AppDecorations.radiusLg,
          withShadow: false,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: AppDecorations.iconTile(
                palette.tile,
                radius: 14,
              ),
              alignment: Alignment.center,
              child: hasEmoji
                  ? Text(emoji, style: theme.textTheme.titleMedium)
                  : Icon(palette.icon, color: palette.ink, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$current / $target',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedProgressBar(
                    value: progress,
                    color: palette.bar,
                    backgroundColor: AppColors.surfaceContainer,
                    height: 7,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ({Color tile, Color ink, Color bar, IconData icon}) _paletteFor(
    int index,
  ) {
    if (index.isEven) {
      return (
        tile: AppColors.infoContainer,
        ink: AppColors.info,
        bar: AppColors.info,
        icon: Icons.laptop_mac_outlined,
      );
    }
    return (
      tile: AppColors.warningContainer,
      ink: AppColors.moneyOut,
      bar: AppColors.tertiaryFixedDim,
      icon: Icons.home_outlined,
    );
  }
}

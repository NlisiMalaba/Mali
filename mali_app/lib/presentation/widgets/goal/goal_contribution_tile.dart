import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class GoalContributionTile extends StatelessWidget {
  const GoalContributionTile({
    required this.contribution,
    super.key,
  });

  final GoalContribution contribution;

  static Key tileKey(String contributionId) =>
      Key('goal-contribution-tile-$contributionId');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = contribution.note?.trim();
    final hasNote = note != null && note.isNotEmpty;

    return ListTile(
      key: tileKey(contribution.id),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.tealPrimary.withValues(alpha: 0.15),
        child: const Icon(
          Icons.savings_outlined,
          color: AppColors.tealPrimary,
          size: 22,
        ),
      ),
      title: Text(
        '+ ${MoneyDisplay.withCurrency(
          amount: contribution.amount,
          currencyCode: contribution.currencyCode,
        )}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
      subtitle: Text(
        hasNote
            ? '$note · ${DateFormat.yMMMd().format(contribution.contributionDate)}'
            : DateFormat.yMMMd().format(contribution.contributionDate),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

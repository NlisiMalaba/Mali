import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class GoalContributionTile extends ConsumerWidget {
  const GoalContributionTile({
    required this.contribution,
    this.showDivider = false,
    super.key,
  });

  final GoalContribution contribution;
  final bool showDivider;

  static Key tileKey(String contributionId) =>
      Key('goal-contribution-tile-$contributionId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final note = contribution.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final title = hasNote ? note : 'Contribution';
    final dateLabel = DateFormat('d MMM').format(contribution.contributionDate);
    final walletId = contribution.walletId;
    final walletAsync =
        walletId == null ? null : ref.watch(walletByIdProvider(walletId));
    final walletName = walletAsync?.maybeWhen(
      data: (wallet) => wallet?.name,
      orElse: () => null,
    );
    final source = walletName == null
        ? '$dateLabel · ${contribution.currencyCode}'
        : '$dateLabel · $walletName ${contribution.currencyCode}';

    return Column(
      key: tileKey(contribution.id),
      children: [
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: Color(0xFFEDF0F6),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                MoneyDisplay.compactSigned(
                  amount: contribution.amount,
                  currencyCode: contribution.currencyCode,
                  prefix: '+',
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

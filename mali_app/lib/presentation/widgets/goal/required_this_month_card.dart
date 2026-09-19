import 'package:flutter/material.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class RequiredThisMonthCard extends StatelessWidget {
  const RequiredThisMonthCard({
    required this.requiredThisMonth,
    required this.currencyCode,
    super.key,
  });

  static const Key cardKey = Key('required-this-month-card');

  final RequiredThisMonth requiredThisMonth;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountLabel = MoneyDisplay.withCurrency(
      amount: requiredThisMonth.amount.toString(),
      currencyCode: currencyCode,
    );
    final originalLabel = MoneyDisplay.withCurrency(
      amount: requiredThisMonth.originalAmount.toString(),
      currencyCode: currencyCode,
    );
    final isBehind = requiredThisMonth.isBehindSchedule;

    return Card(
      key: cardKey,
      color: isBehind
          ? AppColors.warning.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Required this month',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              amountLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isBehind ? AppColors.warning : AppColors.tealPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBehind
                  ? 'You are behind schedule. This is adjusted from the original $originalLabel/month.'
                  : 'Save this amount to stay on track for your deadline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

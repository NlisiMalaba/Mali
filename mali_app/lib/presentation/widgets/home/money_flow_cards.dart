import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Side-by-side Money in / Money out cards for the Home dashboard.
class MoneyFlowCards extends ConsumerWidget {
  const MoneyFlowCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);

    return summaryAsync.when(
      loading: () => const SizedBox(height: 76),
      error: (_, _) => const SizedBox.shrink(),
      data: (summary) {
        final currency = summary.displayCurrency.value;
        return Row(
          children: [
            Expanded(
              child: _FlowCard(
                label: 'Money in',
                icon: Icons.north_east_rounded,
                color: AppColors.income,
                amount: MoneyDisplay.compactSigned(
                  amount: summary.income.toString(),
                  currencyCode: currency,
                  prefix: '+',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FlowCard(
                label: 'Money out',
                icon: Icons.south_east_rounded,
                color: AppColors.expense,
                amount: MoneyDisplay.compactSigned(
                  amount: summary.expenses.toString(),
                  currencyCode: currency,
                  prefix: '\u2212',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.amount,
  });

  final String label;
  final IconData icon;
  /// Income green or expense red, used for both the arrow and the amount.
  final Color color;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AppDecorations.surfaceCard(
        radius: AppDecorations.radiusLg,
        withShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTypography.money(
                fontSize: 22,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

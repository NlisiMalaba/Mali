import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class CurrencyNetTable extends StatelessWidget {
  const CurrencyNetTable({
    required this.totals,
    super.key,
  });

  static const Key tableKey = Key('currency-net-table');

  static Key rowKey(String currencyCode) =>
      Key('currency-net-row-$currencyCode');

  final List<CurrencyMonthlyTotals> totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (totals.isEmpty) {
      return Text(
        'No activity in this month.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      );
    }

    return Card(
      key: tableKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            _HeaderRow(theme: theme),
            const Divider(),
            for (final total in totals) _CurrencyNetRow(total: total),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(flex: 2, child: Text('Currency', style: style)),
        Expanded(child: Text('Income', style: style, textAlign: TextAlign.end)),
        Expanded(
          child: Text('Expenses', style: style, textAlign: TextAlign.end),
        ),
        Expanded(child: Text('Net', style: style, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _CurrencyNetRow extends StatelessWidget {
  const _CurrencyNetRow({required this.total});

  final CurrencyMonthlyTotals total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor =
        total.net >= Decimal.zero ? AppColors.success : AppColors.error;
    final amountStyle = theme.textTheme.bodySmall;

    return Padding(
      key: CurrencyNetTable.rowKey(total.currencyCode),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              total.currencyCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              MoneyDisplay.formatAmount(total.income.toString()),
              style: amountStyle,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              MoneyDisplay.formatAmount(total.expenses.toString()),
              style: amountStyle,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              MoneyDisplay.formatAmount(total.net.toString()),
              style: amountStyle?.copyWith(
                color: netColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

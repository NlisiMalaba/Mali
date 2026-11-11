import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Builds the right-side day summary shown on Activity section headers.
///
/// Expenses become `Out …`, incomes become `In …`, and transfers are ignored.
String formatTransactionDaySummary(List<Transaction> transactions) {
  final expenseByCurrency = <String, Decimal>{};
  final incomeByCurrency = <String, Decimal>{};

  for (final transaction in transactions) {
    final amount = _parseAmount(transaction.amount);
    if (amount == null) {
      continue;
    }

    switch (transaction.type) {
      case 'expense':
        expenseByCurrency.update(
          transaction.currencyCode,
          (current) => current + amount,
          ifAbsent: () => amount,
        );
      case 'income':
        incomeByCurrency.update(
          transaction.currencyCode,
          (current) => current + amount,
          ifAbsent: () => amount,
        );
      default:
        break;
    }
  }

  final parts = <String>[];
  if (incomeByCurrency.isNotEmpty) {
    parts.add('In ${_joinCurrencyTotals(incomeByCurrency)}');
  }
  if (expenseByCurrency.isNotEmpty) {
    parts.add('Out ${_joinCurrencyTotals(expenseByCurrency)}');
  }
  return parts.join(' · ');
}

String _joinCurrencyTotals(Map<String, Decimal> totals) {
  return totals.entries
      .map(
        (entry) => MoneyDisplay.compactSigned(
          amount: entry.value.toString(),
          currencyCode: entry.key,
          prefix: '',
        ),
      )
      .join(' + ');
}

Decimal? _parseAmount(String amount) {
  try {
    return Decimal.parse(amount.trim());
  } catch (_) {
    return null;
  }
}

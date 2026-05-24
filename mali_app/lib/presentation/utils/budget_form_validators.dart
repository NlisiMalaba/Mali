import 'package:decimal/decimal.dart';

class BudgetFormValidators {
  const BudgetFormValidators._();

  static String? budgetAmount(String? value, {required bool touched}) {
    if (!touched) {
      return null;
    }

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a budget amount';
    }

    try {
      if (Decimal.parse(trimmed) <= Decimal.zero) {
        return 'Enter an amount greater than zero';
      }
    } catch (_) {
      return 'Enter a valid amount';
    }

    return null;
  }
}

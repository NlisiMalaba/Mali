import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class HomeMonthlySummaryDisplay {
  const HomeMonthlySummaryDisplay({
    required this.month,
    required this.income,
    required this.expenses,
    required this.displayCurrency,
  });

  final DateTime month;
  final Decimal income;
  final Decimal expenses;
  final CurrencyCode displayCurrency;

  Decimal get net => income - expenses;

  bool get isSurplus => net >= Decimal.zero;
}

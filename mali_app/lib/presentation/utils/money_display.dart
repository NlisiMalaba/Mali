import 'package:decimal/decimal.dart';

class MoneyDisplay {
  const MoneyDisplay._();

  /// Formats a decimal-safe amount string for display (2 fractional digits).
  static String formatAmount(String amount) {
    try {
      final parsed = Decimal.parse(amount.trim());
      final scaled = parsed.round(scale: 2);
      final text = scaled.toString();
      final parts = text.split('.');
      final fraction = parts.length > 1 ? parts[1] : '';
      final paddedFraction = fraction.padRight(2, '0').substring(0, 2);
      return '${parts[0]}.$paddedFraction';
    } catch (_) {
      return amount;
    }
  }

  static String withCurrency({
    required String amount,
    required String currencyCode,
  }) {
    return '$currencyCode ${formatAmount(amount)}';
  }
}

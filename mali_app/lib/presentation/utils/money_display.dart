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

  /// Compact amount with symbol/prefix, e.g. `$3,120.40`, `ZiG 41,200.00`, `R 2,450.00`.
  static String compact({
    required String amount,
    required String currencyCode,
    bool trimTrailingZeros = false,
  }) {
    var formatted = _formatWithSeparators(amount);
    if (trimTrailingZeros && formatted.endsWith('.00')) {
      formatted = formatted.substring(0, formatted.length - 3);
    }

    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$$formatted';
      case 'ZAR':
        return 'R $formatted';
      case 'ZWG':
        return 'ZiG $formatted';
      default:
        return '$currencyCode $formatted';
    }
  }

  /// Compact signed amount for activity rows, e.g. `+$24.50` or `-ZiG 134.00`.
  static String compactSigned({
    required String amount,
    required String currencyCode,
    required String prefix,
  }) {
    return '$prefix${compact(amount: amount, currencyCode: currencyCode)}';
  }

  static String _formatWithSeparators(String amount) {
    final normalized = formatAmount(amount);
    final parts = normalized.split('.');
    final whole = parts[0];
    final fraction = parts.length > 1 ? parts[1] : '00';

    final buffer = StringBuffer();
    final digits = whole.startsWith('-') ? whole.substring(1) : whole;
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    final signed = whole.startsWith('-') ? '-${buffer.toString()}' : buffer.toString();
    return '$signed.$fraction';
  }
}

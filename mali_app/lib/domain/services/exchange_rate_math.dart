import 'package:decimal/decimal.dart';

/// Decimal-safe helpers for exchange-rate persistence.
abstract final class ExchangeRateMath {
  static const int _inverseScale = 8;

  static Decimal? parsePositiveRate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final parsed = Decimal.parse(trimmed);
      if (parsed <= Decimal.zero) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static String? invertRateString(String rate) {
    final parsed = parsePositiveRate(rate);
    if (parsed == null) {
      return null;
    }
    final inverted = (Decimal.one / parsed).toDecimal(
      scaleOnInfinitePrecision: _inverseScale,
    );
    return inverted.toString();
  }
}

import 'package:decimal/decimal.dart';

class ShareFraction {
  const ShareFraction._();

  /// Display-only 0–1 fraction of [amount] relative to [total].
  static double of({
    required Decimal amount,
    required Decimal total,
  }) {
    if (total <= Decimal.zero || amount <= Decimal.zero) {
      return 0;
    }
    return (amount / total).toDouble().clamp(0, 1);
  }
}

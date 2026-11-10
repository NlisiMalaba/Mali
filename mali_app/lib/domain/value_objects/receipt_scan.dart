import 'package:mali_app/domain/value_objects/currency_code.dart';

/// Fields read from a photographed receipt. Every field is optional because
/// OCR on crumpled thermal paper is unreliable; the user always confirms.
class ReceiptScan {
  const ReceiptScan({
    this.amount,
    this.currency,
    this.date,
    this.merchant,
  });

  /// Canonical decimal string (for example `"24.50"`), never a double.
  final String? amount;
  final CurrencyCode? currency;
  final DateTime? date;
  final String? merchant;

  bool get isEmpty =>
      amount == null && currency == null && date == null && merchant == null;
}

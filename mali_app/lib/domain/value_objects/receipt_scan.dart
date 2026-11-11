import 'package:mali_app/domain/value_objects/currency_code.dart';

/// Fields read from a photographed receipt. Every field is optional because
/// OCR on crumpled thermal paper is unreliable; the user always confirms.
class ReceiptScan {
  const ReceiptScan({
    this.amount,
    this.currency,
    this.date,
    this.merchant,
    this.imagePath,
  });

  /// Canonical decimal string (for example `"24.50"`), never a double.
  final String? amount;
  final CurrencyCode? currency;
  final DateTime? date;
  final String? merchant;

  /// Local path to the photo that was scanned, for the review screen.
  final String? imagePath;

  bool get isEmpty =>
      amount == null && currency == null && date == null && merchant == null;

  /// How many of the primary review fields were found (total, date, shop).
  int get foundFieldCount {
    var count = 0;
    if (amount != null) count++;
    if (date != null) count++;
    if (merchant != null) count++;
    return count;
  }

  static const int expectedFieldCount = 3;

  ReceiptScan copyWith({
    String? amount,
    CurrencyCode? currency,
    DateTime? date,
    String? merchant,
    String? imagePath,
  }) {
    return ReceiptScan(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

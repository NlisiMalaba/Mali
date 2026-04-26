import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class Money {
  const Money({
    required this.amount,
    required this.currency,
  });

  final Decimal amount;
  final CurrencyCode currency;

  factory Money.fromString({
    required String amount,
    required CurrencyCode currency,
  }) {
    return Money(
      amount: Decimal.parse(amount),
      currency: currency,
    );
  }

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(
      amount: amount + other.amount,
      currency: currency,
    );
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(
      amount: amount - other.amount,
      currency: currency,
    );
  }

  bool get isNegative => amount < Decimal.zero;

  Money copyWith({
    Decimal? amount,
    CurrencyCode? currency,
  }) {
    return Money(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw StateError(
        'Money arithmetic requires matching currencies. '
        'Left: ${currency.value}, right: ${other.currency.value}',
      );
    }
  }

  @override
  String toString() => '${currency.value} ${amount.toString()}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money && other.amount == amount && other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(amount, currency);
}

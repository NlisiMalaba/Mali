import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/presentation/utils/share_fraction.dart';

void main() {
  test('returns 0 when the total is not positive', () {
    expect(
      ShareFraction.of(amount: Decimal.parse('10'), total: Decimal.zero),
      0,
    );
  });

  test('returns the display-only fraction of the total', () {
    expect(
      ShareFraction.of(amount: Decimal.parse('40'), total: Decimal.parse('80')),
      0.5,
    );
  });
}

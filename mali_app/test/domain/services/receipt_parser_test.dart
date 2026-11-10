import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/services/receipt_parser.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

void main() {
  final parser = ReceiptParser(clock: () => DateTime(2026, 11, 10, 12));

  const supermarketReceipt = '''
OK ZIMBABWE LTD
Borrowdale Branch
Tel: +263 242 123456
TAX INVOICE
Date: 08/11/2026 14:32
Bread 750g  1.20
Milk 2L  2.50
Cooking Oil 2L  1 234.50
SUBTOTAL  1 238.20
VAT 15%  161.50
TOTAL USD  1 238.20
CASH  1 300.00
CHANGE  61.80
''';

  group('ReceiptParser', () {
    test('reads total, currency, day-first date and merchant', () {
      final scan = parser.parse(supermarketReceipt);

      expect(scan.amount, '1238.2');
      expect(scan.currency, CurrencyCode.usd);
      expect(scan.date, DateTime(2026, 11, 8));
      expect(scan.merchant, 'OK ZIMBABWE LTD');
    });

    test('ignores cash tendered and change when picking the total', () {
      final scan = parser.parse('Shop\nTOTAL  10.00\nCASH  50.00\nCHANGE 40.00');

      expect(scan.amount, '10');
    });

    test('takes the amount from the next line when the label stands alone', () {
      final scan = parser.parse('Cafe Nush\nAmount Due\nZWG 345,60');

      expect(scan.amount, '345.6');
      expect(scan.currency, CurrencyCode.zwg);
    });

    test('falls back to the largest amount when no total label exists', () {
      final scan = parser.parse('Kiosk\nAirtime 5.00\nBundle 12.00');

      expect(scan.amount, '12');
    });

    test('does not treat phone numbers or quantities as amounts', () {
      final scan = parser.parse('Hardware\nTel 0772123456\nQty 3');

      expect(scan.amount, isNull);
    });

    test('parses written month dates', () {
      final scan = parser.parse('Pick n Pay\n3 Nov 2026\nTotal R 99.99');

      expect(scan.date, DateTime(2026, 11, 3));
    });

    test('rejects future and implausibly old dates', () {
      expect(parser.parse('Shop\n25/12/2026').date, isNull);
      expect(parser.parse('Shop\n01/01/2019').date, isNull);
    });

    test('returns an empty scan for unreadable text', () {
      expect(parser.parse('~~ ## ..').isEmpty, isTrue);
    });
  });
}

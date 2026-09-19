import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/core/csv/csv_writer.dart';

void main() {
  group('CsvWriter.escapeField', () {
    test('leaves plain values untouched', () {
      expect(CsvWriter.escapeField('Groceries'), 'Groceries');
    });

    test('quotes values containing a separator', () {
      expect(CsvWriter.escapeField('Food, drink'), '"Food, drink"');
    });

    test('doubles embedded quotes', () {
      expect(
        CsvWriter.escapeField('Paid "in full"'),
        '"Paid ""in full"""',
      );
    });

    test('quotes values containing newlines', () {
      expect(CsvWriter.escapeField('line1\nline2'), '"line1\nline2"');
      expect(CsvWriter.escapeField('line1\r\nline2'), '"line1\r\nline2"');
    });

    test('quotes values with surrounding whitespace', () {
      expect(CsvWriter.escapeField('  padded  '), '"  padded  "');
    });

    test('leaves an empty value as an empty field', () {
      expect(CsvWriter.escapeField(''), '');
    });
  });

  group('CsvWriter.encode', () {
    test('joins fields and terminates every row with CRLF', () {
      final csv = CsvWriter.encode([
        ['a', 'b'],
        ['c', 'd'],
      ]);

      expect(csv, 'a,b\r\nc,d\r\n');
    });

    test('escapes fields while encoding', () {
      final csv = CsvWriter.encode([
        ['plain', 'has,comma', 'has"quote'],
      ]);

      expect(csv, 'plain,"has,comma","has""quote"\r\n');
    });

    test('encodes an empty table as an empty string', () {
      expect(CsvWriter.encode(const []), '');
    });
  });
}
